import 'package:cloud_firestore/cloud_firestore.dart';
import '../models_and_services.dart';
import 'base_service.dart';

/// Unified service for all voting status operations
///
/// This service combines all voting-related functionality into a single,
/// consistent interface for updating voting status and recording changes.
class UnifiedVotingStatusService extends BaseService {
  final ClientService _clientService = ClientService();

  /// Updates voting status with comprehensive history tracking
  /// This is the ONLY method that should be used for voting status changes
  Future<VotingStatusUpdateResult> updateVotingStatus(
    String clientId,
    VotingStatus newStatus, {
    String? reason,
    String? editedBy,
    String? editedByEmail,
    String? editedByName,
    String? userId,
    String? updatedVia,
    Map<String, dynamic>? additionalChanges,
  }) async {
    try {
      print(
        '🗳️ [UnifiedVotingStatus] Rozpoczynam aktualizację statusu dla klienta: $clientId',
      );
      print('🗳️ [UnifiedVotingStatus] Nowy status: ${newStatus.name}');
      print('🗳️ [UnifiedVotingStatus] Parametry użytkownika:');
      print('  - editedBy: "$editedBy"');
      print('  - editedByEmail: "$editedByEmail"');
      print('  - editedByName: "$editedByName"');
      print('  - userId: "$userId"');
      print('  - updatedVia: "$updatedVia"');

      // Get current client data
      final client = await _clientService.getClient(clientId);
      if (client == null) {
        print('❌ [UnifiedVotingStatus] Klient nie znaleziony: $clientId');
        return VotingStatusUpdateResult(
          isSuccess: false,
          error: 'Client not found: $clientId',
        );
      }

      final oldStatus = client.votingStatus;
      print('🗳️ [UnifiedVotingStatus] Poprzedni status: ${oldStatus.name}');

      // Skip if status is the same
      if (oldStatus == newStatus) {
        print('🗳️ [UnifiedVotingStatus] Status bez zmian - pomijam');
        return VotingStatusUpdateResult(
          isSuccess: true,
          previousStatus: oldStatus,
          newStatus: newStatus,
        );
      }

      // 1. Update the voting status in client document
      final updateFields = <String, dynamic>{
        'votingStatus': newStatus.name,
        'lastVotingStatusUpdate': FieldValue.serverTimestamp(),
      };

      // Add additional changes if provided
      if (additionalChanges != null) {
        updateFields.addAll(additionalChanges);
      }

      // Add user tracking fields
      if (editedBy != null) updateFields['lastEditedBy'] = editedBy;
      if (editedByEmail != null) {
        updateFields['lastEditedByEmail'] = editedByEmail;
      }
      if (editedByName != null) updateFields['lastEditedByName'] = editedByName;
      if (userId != null) updateFields['lastEditedByUserId'] = userId;

      await _clientService.updateClientFields(clientId, updateFields);
      print('✅ [UnifiedVotingStatus] Zaktualizowano dokument klienta');

      // 2. Record the change in voting_status_changes collection
      await _recordVotingStatusChange(
        clientId: clientId,
        clientName: client.name,
        oldStatus: oldStatus,
        newStatus: newStatus,
        reason: reason ?? 'Status change via system',
        editedBy: editedBy,
        editedByEmail: editedByEmail,
        editedByName: editedByName,
        userId: userId,
        updatedVia: updatedVia ?? 'investor_details_modal',
      );

      // 3. Clear relevant caches
      clearCache('voting_statistics');
      clearCache('voting_status_statistics');
      clearCache('voting_status_change_stats');
      clearCache('client_$clientId');

      print(
        '✅ [UnifiedVotingStatus] Pomyślnie zaktualizowano status głosowania',
      );

      return VotingStatusUpdateResult(
        isSuccess: true,
        previousStatus: oldStatus,
        newStatus: newStatus,
      );
    } catch (e) {
      print('❌ [UnifiedVotingStatus] Błąd aktualizacji statusu: $e');
      logError('updateVotingStatus', e);
      return VotingStatusUpdateResult(
        isSuccess: false,
        error: e.toString(),
        previousStatus: null,
        newStatus: newStatus,
      );
    }
  }

  /// Internal method to record voting status changes
  Future<void> _recordVotingStatusChange({
    required String clientId,
    required String clientName,
    required VotingStatus oldStatus,
    required VotingStatus newStatus,
    required String reason,
    String? editedBy,
    String? editedByEmail,
    String? editedByName,
    String? userId,
    String? updatedVia,
  }) async {
    try {
      final changeRecord = <String, dynamic>{
        // Core change data
        'clientId': clientId,
        'clientName': clientName,
        'investorId':
            clientId, // Użyj clientId jako investorId (kompatybilność)
        'oldStatus': oldStatus.name,
        'newStatus': newStatus.name,
        'changeType': 'statusChanged', // Typ zmiany dla VotingStatusChange
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),

        // User tracking - all at root level for Firebase compatibility
        'editedBy': editedBy ?? 'system',
        'editedByEmail': editedByEmail ?? 'system@local',
        'editedByName': editedByName ?? editedBy ?? 'System',
        'userId': userId ?? 'system',
        'updated_via': updatedVia ?? 'system',
      };

      print('🔍 [UnifiedVotingStatus] Zapisuję zmianę z danymi:');
      print('  - clientId: $clientId');
      print('  - clientName: $clientName');
      print('  - editedBy: "$editedBy" (original: "${editedBy ?? 'NULL'}")');
      print(
        '  - editedByEmail: "$editedByEmail" (original: "${editedByEmail ?? 'NULL'}")',
      );
      print(
        '  - editedByName: "$editedByName" (original: "${editedByName ?? 'NULL'}")',
      );
      print('  - userId: "$userId" (original: "${userId ?? 'NULL'}")');
      print(
        '  - updatedVia: "$updatedVia" (original: "${updatedVia ?? 'NULL'}")',
      );
      changeRecord.forEach((key, value) {
        print('    $key: $value');
      });

      await firestore.collection('voting_status_changes').add(changeRecord);
      print('✅ [UnifiedVotingStatus] Zapisano historię zmiany statusu');
    } catch (e) {
      print('❌ [UnifiedVotingStatus] Błąd zapisu historii: $e');
      logError('_recordVotingStatusChange', e);
      rethrow;
    }
  }

  /// Gets voting status history for a client
  Future<List<VotingStatusChange>> getVotingStatusHistory(
    String clientId,
  ) async {
    try {
      print(
        '🔍 [UnifiedVotingStatus] Pobieranie historii dla klienta: $clientId',
      );

      // Najpierw sprawdź wszystkie dostępne zmiany w kolekcji
      final allChangesSnapshot = await firestore
          .collection('voting_status_changes')
          .limit(10)
          .get();

      print('🔍 [UnifiedVotingStatus] Wszystkie zmiany w bazie (pierwsze 10):');
      for (final doc in allChangesSnapshot.docs) {
        final data = doc.data();
        print(
          '  - ID: ${doc.id}, clientId: "${data['clientId']}", clientName: "${data['clientName']}"',
        );
      }

      final snapshot = await firestore
          .collection('voting_status_changes')
          .where('clientId', isEqualTo: clientId)
          .orderBy(
            'timestamp',
            descending: true,
          ) // Użyj 'timestamp' zamiast 'changedAt'
          .get();

      print(
        '🔍 [UnifiedVotingStatus] Znaleziono ${snapshot.docs.length} zmian',
      );

      return snapshot.docs.map((doc) {
        print(
          '🔍 [UnifiedVotingStatus] Dokument: ${doc.id}, dane: ${doc.data()}',
        );
        return VotingStatusChange.fromFirestore(doc);
      }).toList();
    } catch (e) {
      print('❌ [UnifiedVotingStatus] Błąd pobierania historii: $e');
      logError('getVotingStatusHistory', e);
      return [];
    }
  }

  /// Gets all voting status changes (paginated)
  Future<List<VotingStatusChange>> getAllVotingStatusChanges({
    int limit = 100,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = firestore
          .collection('voting_status_changes')
          .orderBy(
            'timestamp',
            descending: true,
          ) // Użyj 'timestamp' zamiast 'changedAt'
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return VotingStatusChange.fromFirestore(doc);
      }).toList();
    } catch (e) {
      logError('getAllVotingStatusChanges', e);
      return [];
    }
  }

  /// Gets voting statistics for dashboard
  Future<VotingStatusStatistics> getVotingStatusStatistics() async {
    try {
      return await getCachedData('voting_status_statistics', () async {
        final snapshot = await firestore
            .collection('clients')
            .where('isActive', isEqualTo: true)
            .get();

        final Map<VotingStatus, int> statusCounts = {};
        int totalClients = 0;

        for (final doc in snapshot.docs) {
          final data = doc.data();
          final statusName = data['votingStatus'] as String? ?? 'undecided';
          final status = VotingStatus.values.firstWhere(
            (s) => s.name == statusName,
            orElse: () => VotingStatus.undecided,
          );

          statusCounts[status] = (statusCounts[status] ?? 0) + 1;
          totalClients++;
        }

        return VotingStatusStatistics(
          totalClients: totalClients,
          statusCounts: statusCounts,
          lastUpdated: DateTime.now(),
        );
      });
    } catch (e) {
      logError('getVotingStatusStatistics', e);
      return VotingStatusStatistics(
        totalClients: 0,
        statusCounts: {},
        lastUpdated: DateTime.now(),
      );
    }
  }
}

/// Result of voting status update operation
class VotingStatusUpdateResult {
  final bool isSuccess;
  final String? error;
  final VotingStatus? previousStatus;
  final VotingStatus? newStatus;

  VotingStatusUpdateResult({
    required this.isSuccess,
    this.error,
    this.previousStatus,
    this.newStatus,
  });

  bool get hasChanged => isSuccess && previousStatus != newStatus;

  @override
  String toString() {
    return 'VotingStatusUpdateResult(isSuccess: $isSuccess, error: $error, '
        'previousStatus: $previousStatus, newStatus: $newStatus)';
  }
}

/// Statistics about voting status distribution
class VotingStatusStatistics {
  final int totalClients;
  final Map<VotingStatus, int> statusCounts;
  final DateTime lastUpdated;

  VotingStatusStatistics({
    required this.totalClients,
    required this.statusCounts,
    required this.lastUpdated,
  });

  int getCountForStatus(VotingStatus status) => statusCounts[status] ?? 0;

  double getPercentageForStatus(VotingStatus status) {
    if (totalClients == 0) return 0.0;
    return (getCountForStatus(status) / totalClients) * 100;
  }

  @override
  String toString() {
    return 'VotingStatusStatistics(totalClients: $totalClients, '
        'statusCounts: $statusCounts, lastUpdated: $lastUpdated)';
  }
}
