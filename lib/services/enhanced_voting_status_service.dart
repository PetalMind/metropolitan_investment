import 'package:cloud_firestore/cloud_firestore.dart';
import '../models_and_services.dart';
import 'base_service.dart';

/// Enhanced service for managing voting status with history tracking
class EnhancedVotingStatusService extends BaseService {
  final ClientService _clientService = ClientService();
  final VotingStatusChangeService _changeService = VotingStatusChangeService();

  /// Updates voting status with history tracking
  Future<VotingStatusUpdateResult> updateVotingStatusWithHistory(
    String clientId,
    VotingStatus newStatus, {
    String? reason,
    Map<String, dynamic>? additionalChanges,
  }) async {
    try {
      print(
        '🗳️ [EnhancedVotingStatus] Aktualizacja statusu dla klienta: $clientId',
      );

      // Get current client data
      final client = await _clientService.getClient(clientId);
      if (client == null) {
        return VotingStatusUpdateResult(
          isSuccess: false,
          error: 'Client not found: $clientId',
        );
      }

      final oldStatus = client.votingStatus;
      
      // Skip if status is the same
      if (oldStatus == newStatus) {
        return VotingStatusUpdateResult(
          isSuccess: true,
          previousStatus: oldStatus,
          newStatus: newStatus,
        );
      }

      // Update the voting status in client document
      await _clientService.updateClientFields(clientId, {
        'votingStatus': newStatus.name,
        'lastVotingStatusUpdate': FieldValue.serverTimestamp(),
        'votingStatusHistory': FieldValue.arrayUnion([
          {
            'previousStatus': oldStatus.name,
            'newStatus': newStatus.name,
            'timestamp': FieldValue.serverTimestamp(),
            'reason': reason ?? 'Status update',
            'additionalData': additionalChanges ?? {},
          },
        ]),
      });

      // Also record in separate voting_status_changes collection
      await _changeService.recordVotingStatusChange(
        clientId: clientId,
        oldStatus: oldStatus,
        newStatus: newStatus,
        reason: reason ?? 'Status update',
        metadata: additionalChanges ?? {},
      );

      print(
        '✅ [EnhancedVotingStatus] Status zaktualizowany: ${oldStatus.name} -> ${newStatus.name}',
      );

      return VotingStatusUpdateResult(
        isSuccess: true,
        previousStatus: oldStatus,
        newStatus: newStatus,
      );
    } catch (e) {
      print('❌ [EnhancedVotingStatus] Błąd aktualizacji statusu: $e');
      logError('updateVotingStatusWithHistory', e);
      return VotingStatusUpdateResult(isSuccess: false, error: e.toString());
    }
  }

  /// Gets voting status change history for a client
  Future<List<VotingStatusChangeEvent>> getVotingStatusHistory(
    String clientId,
  ) async {
    try {
      // First try to get from voting_status_changes collection (preferred)
      final changeRecords = await _changeService.getClientVotingStatusHistory(clientId);
      
      if (changeRecords.isNotEmpty) {
        return changeRecords.map((record) => VotingStatusChangeEvent(
          previousStatus: record.oldStatus,
          newStatus: record.newStatus,
          timestamp: record.timestamp,
          reason: record.reason,
          additionalData: record.metadata,
        )).toList();
      }

      // Fallback to client document history if no records in separate collection
      final client = await _clientService.getClient(clientId);
      if (client == null) return [];

      final doc = await firestore.collection('clients').doc(clientId).get();
      final data = doc.data();
      if (data == null) return [];

      final historyData = data['votingStatusHistory'] as List<dynamic>? ?? [];

      return historyData
          .map(
            (item) =>
                VotingStatusChangeEvent.fromMap(item as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      logError('getVotingStatusHistory', e);
      return [];
    }
  }

  /// Gets voting status statistics
  Future<VotingStatusStatistics> getVotingStatusStatistics() async {
    return getCachedData('voting_status_statistics', () async {
      try {
        final clients = await _clientService.getAllClients();

        final Map<VotingStatus, int> statusCounts = {};
        for (final status in VotingStatus.values) {
          statusCounts[status] = 0;
        }

        for (final client in clients) {
          statusCounts[client.votingStatus] =
              (statusCounts[client.votingStatus] ?? 0) + 1;
        }

        return VotingStatusStatistics(
          totalClients: clients.length,
          statusCounts: statusCounts,
          lastUpdated: DateTime.now(),
        );
      } catch (e) {
        logError('getVotingStatusStatistics', e);
        return VotingStatusStatistics(
          totalClients: 0,
          statusCounts: {},
          lastUpdated: DateTime.now(),
        );
      }
    });
  }

  /// Batch update multiple voting statuses
  Future<BatchVotingStatusResult> updateMultipleVotingStatuses(
    List<VotingStatusUpdate> updates, {
    String? batchReason,
  }) async {
    try {
      print('🔄 [EnhancedVotingStatus] Batch update dla ${updates.length} klientów');
      
      final List<VotingStatusChangeResult> results = [];
      int successfulUpdates = 0;
      int failedUpdates = 0;
      final Map<String, String> errors = {};

      for (final update in updates) {
        try {
          final result = await updateVotingStatusWithHistory(
            update.clientId,
            update.newStatus,
            reason: batchReason ?? update.reason,
            additionalChanges: update.additionalChanges,
          );

          if (result.isSuccess) {
            successfulUpdates++;
            results.add(VotingStatusChangeResult.success(
              clientId: update.clientId,
              clientName: update.clientName ?? update.clientId,
              previousStatus: result.previousStatus!,
              newStatus: result.newStatus!,
              changeId: 'batch_${DateTime.now().millisecondsSinceEpoch}',
            ));
          } else {
            failedUpdates++;
            errors[update.clientId] = result.error ?? 'Unknown error';
            results.add(VotingStatusChangeResult.error(
              clientId: update.clientId,
              error: result.error ?? 'Unknown error',
            ));
          }
        } catch (e) {
          failedUpdates++;
          errors[update.clientId] = e.toString();
          results.add(VotingStatusChangeResult.error(
            clientId: update.clientId,
            error: e.toString(),
          ));
        }
      }

      print('✅ [EnhancedVotingStatus] Batch update zakończony: $successfulUpdates sukces, $failedUpdates błędów');

      return BatchVotingStatusResult(
        totalUpdates: updates.length,
        successfulUpdates: successfulUpdates,
        failedUpdates: failedUpdates,
        results: results,
        errors: errors,
      );
    } catch (e) {
      logError('updateMultipleVotingStatuses', e);
      rethrow;
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
}

/// Represents a voting status change event
class VotingStatusChangeEvent {
  final VotingStatus previousStatus;
  final VotingStatus newStatus;
  final DateTime timestamp;
  final String reason;
  final Map<String, dynamic> additionalData;

  VotingStatusChangeEvent({
    required this.previousStatus,
    required this.newStatus,
    required this.timestamp,
    required this.reason,
    required this.additionalData,
  });

  factory VotingStatusChangeEvent.fromMap(Map<String, dynamic> map) {
    return VotingStatusChangeEvent(
      previousStatus: VotingStatus.values.firstWhere(
        (status) => status.name == map['previousStatus'],
        orElse: () => VotingStatus.undecided,
      ),
      newStatus: VotingStatus.values.firstWhere(
        (status) => status.name == map['newStatus'],
        orElse: () => VotingStatus.undecided,
      ),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reason: map['reason']?.toString() ?? '',
      additionalData: Map<String, dynamic>.from(map['additionalData'] ?? {}),
    );
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

  int getCount(VotingStatus status) => statusCounts[status] ?? 0;

  double getPercentage(VotingStatus status) {
    if (totalClients == 0) return 0.0;
    return (getCount(status) / totalClients) * 100;
  }
}

/// Update request for voting status batch operations
class VotingStatusUpdate {
  final String clientId;
  final String? clientName;
  final VotingStatus newStatus;
  final String? reason;
  final Map<String, dynamic>? additionalChanges;

  VotingStatusUpdate({
    required this.clientId,
    this.clientName,
    required this.newStatus,
    this.reason,
    this.additionalChanges,
  });
}

/// Result of batch voting status update operation
class BatchVotingStatusResult {
  final int totalUpdates;
  final int successfulUpdates;
  final int failedUpdates;
  final List<VotingStatusChangeResult> results;
  final Map<String, String> errors;

  BatchVotingStatusResult({
    required this.totalUpdates,
    required this.successfulUpdates,
    required this.failedUpdates,
    required this.results,
    required this.errors,
  });

  bool get hasErrors => failedUpdates > 0;
  bool get isCompleteSuccess => failedUpdates == 0;
  double get successRate => totalUpdates > 0 ? successfulUpdates / totalUpdates : 0.0;
}

/// Individual result of voting status change
class VotingStatusChangeResult {
  final String clientId;
  final String? clientName;
  final VotingStatus? previousStatus;
  final VotingStatus? newStatus;
  final String? changeId;
  final String? error;
  final bool isSuccess;

  VotingStatusChangeResult._({
    required this.clientId,
    this.clientName,
    this.previousStatus,
    this.newStatus,
    this.changeId,
    this.error,
    required this.isSuccess,
  });

  factory VotingStatusChangeResult.success({
    required String clientId,
    required String clientName,
    required VotingStatus previousStatus,
    required VotingStatus newStatus,
    required String changeId,
  }) {
    return VotingStatusChangeResult._(
      clientId: clientId,
      clientName: clientName,
      previousStatus: previousStatus,
      newStatus: newStatus,
      changeId: changeId,
      isSuccess: true,
    );
  }

  factory VotingStatusChangeResult.noChange({
    required String clientId,
    required String clientName,
    required VotingStatus status,
  }) {
    return VotingStatusChangeResult._(
      clientId: clientId,
      clientName: clientName,
      previousStatus: status,
      newStatus: status,
      isSuccess: true,
    );
  }

  factory VotingStatusChangeResult.error({
    required String clientId,
    required String error,
  }) {
    return VotingStatusChangeResult._(
      clientId: clientId,
      error: error,
      isSuccess: false,
    );
  }
}
