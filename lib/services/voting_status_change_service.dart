import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/voting_status_change.dart';
import 'base_service.dart';

class VotingStatusChangeService extends BaseService {
  static const String _collection = 'voting_status_changes';

  Future<void> recordVotingStatusChange({
    required String investorId,
    required String clientId,
    required String clientName,
    String? previousVotingStatus,
    String? newVotingStatus,
    required VotingStatusChangeType changeType,
    Map<String, dynamic>? additionalChanges,
    String? reason,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Użytkownik nie jest zalogowany');
      }

      final change = VotingStatusChange(
        id: '', // Will be set by Firestore
        investorId: investorId,
        clientId: clientId,
        clientName: clientName,
        previousVotingStatus: previousVotingStatus,
        newVotingStatus: newVotingStatus,
        changeType: changeType,
        editedBy: user.displayName ?? user.email ?? 'Nieznany użytkownik',
        editedByEmail: user.email ?? 'brak@email.com',
        changedAt: DateTime.now(),
        additionalChanges: additionalChanges,
        reason: reason,
      );

      await FirebaseFirestore.instance
          .collection(_collection)
          .add(change.toFirestore());

      print('✅ [VotingStatusChange] Zapisano zmianę statusu głosowania dla ${clientName}');
    } catch (e) {
      print('❌ [VotingStatusChange] Błąd zapisu zmiany: $e');
      logError('recordVotingStatusChange', e);
      rethrow;
    }
  }

  Future<List<VotingStatusChange>> getChangesForInvestor(String investorId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection(_collection)
          .where('investorId', isEqualTo: investorId)
          .orderBy('changedAt', descending: true)
          .limit(100)
          .get();

      return querySnapshot.docs
          .map((doc) => VotingStatusChange.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ [VotingStatusChange] Błąd pobierania zmian dla inwestora $investorId: $e');
      logError('getChangesForInvestor', e);
      return [];
    }
  }

  Future<List<VotingStatusChange>> getChangesForClient(String clientId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection(_collection)
          .where('clientId', isEqualTo: clientId)
          .orderBy('changedAt', descending: true)
          .limit(50)
          .get();

      return querySnapshot.docs
          .map((doc) => VotingStatusChange.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ [VotingStatusChange] Błąd pobierania zmian dla klienta $clientId: $e');
      logError('getChangesForClient', e);
      return [];
    }
  }

  Future<List<VotingStatusChange>> getAllRecentChanges({
    int limit = 50,
    DateTime? since,
  }) async {
    try {
      Query query = FirebaseFirestore.instance
          .collection(_collection)
          .orderBy('changedAt', descending: true);

      if (since != null) {
        query = query.where('changedAt', isGreaterThan: Timestamp.fromDate(since));
      }

      final querySnapshot = await query.limit(limit).get();

      return querySnapshot.docs
          .map((doc) => VotingStatusChange.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ [VotingStatusChange] Błąd pobierania ostatnich zmian: $e');
      logError('getAllRecentChanges', e);
      return [];
    }
  }

  Future<Map<String, dynamic>> getChangeStatistics({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      Query query = FirebaseFirestore.instance.collection(_collection);

      if (fromDate != null) {
        query = query.where('changedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate));
      }

      if (toDate != null) {
        query = query.where('changedAt', isLessThanOrEqualTo: Timestamp.fromDate(toDate));
      }

      final querySnapshot = await query.get();
      final changes = querySnapshot.docs
          .map((doc) => VotingStatusChange.fromFirestore(doc))
          .toList();

      final Map<String, int> changesByType = {};
      final Map<String, int> changesByUser = {};
      final Map<String, int> changesByStatus = {};

      for (final change in changes) {
        // Count by change type
        changesByType[change.changeType.name] = 
            (changesByType[change.changeType.name] ?? 0) + 1;

        // Count by user
        changesByUser[change.editedBy] = 
            (changesByUser[change.editedBy] ?? 0) + 1;

        // Count by new voting status
        if (change.newVotingStatus != null) {
          changesByStatus[change.newVotingStatus!] = 
              (changesByStatus[change.newVotingStatus!] ?? 0) + 1;
        }
      }

      return {
        'totalChanges': changes.length,
        'changesByType': changesByType,
        'changesByUser': changesByUser,
        'changesByStatus': changesByStatus,
        'period': {
          'from': fromDate?.toIso8601String(),
          'to': toDate?.toIso8601String(),
        },
      };
    } catch (e) {
      print('❌ [VotingStatusChange] Błąd pobierania statystyk: $e');
      logError('getChangeStatistics', e);
      return {
        'totalChanges': 0,
        'changesByType': {},
        'changesByUser': {},
        'changesByStatus': {},
      };
    }
  }

  Stream<List<VotingStatusChange>> watchChangesForInvestor(String investorId) {
    return FirebaseFirestore.instance
        .collection(_collection)
        .where('investorId', isEqualTo: investorId)
        .orderBy('changedAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VotingStatusChange.fromFirestore(doc))
            .toList());
  }

  Stream<List<VotingStatusChange>> watchRecentChanges({int limit = 20}) {
    return FirebaseFirestore.instance
        .collection(_collection)
        .orderBy('changedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VotingStatusChange.fromFirestore(doc))
            .toList());
  }

  Future<void> deleteChangeHistory(String investorId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection(_collection)
          .where('investorId', isEqualTo: investorId)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('✅ [VotingStatusChange] Usunięto historię zmian dla inwestora $investorId');
    } catch (e) {
      print('❌ [VotingStatusChange] Błąd usuwania historii: $e');
      logError('deleteChangeHistory', e);
      rethrow;
    }
  }

  Future<void> cleanupOldChanges({Duration? olderThan}) async {
    try {
      final cutoffDate = DateTime.now().subtract(olderThan ?? const Duration(days: 365));
      
      final querySnapshot = await FirebaseFirestore.instance
          .collection(_collection)
          .where('changedAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .limit(500) // Process in batches
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('ℹ️ [VotingStatusChange] Brak starych zmian do usunięcia');
        return;
      }

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('✅ [VotingStatusChange] Usunięto ${querySnapshot.docs.length} starych zmian');
    } catch (e) {
      print('❌ [VotingStatusChange] Błąd czyszczenia starych zmian: $e');
      logError('cleanupOldChanges', e);
      rethrow;
    }
  }
}