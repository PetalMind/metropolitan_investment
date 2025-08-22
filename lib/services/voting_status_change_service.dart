import 'package:cloud_firestore/cloud_firestore.dart';
import '../models_and_services.dart';

/// Service for managing voting status changes and history
class VotingStatusChangeService extends BaseService {
  /// Records a voting status change
  Future<void> recordVotingStatusChange({
    required String clientId,
    required VotingStatus oldStatus,
    required VotingStatus newStatus,
    required String reason,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final changeRecord = {
        'clientId': clientId,
        'oldStatus': oldStatus.name,
        'newStatus': newStatus.name,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
        'metadata': metadata ?? {},
      };

      await firestore.collection('voting_status_changes').add(changeRecord);

      print(
        '✅ [VotingStatusChange] Zapisano zmianę statusu dla klienta $clientId: ${oldStatus.name} -> ${newStatus.name}',
      );
    } catch (e) {
      logError('recordVotingStatusChange', e);
      rethrow;
    }
  }

  /// Gets voting status changes for a specific client
  Future<List<VotingStatusChangeRecord>> getClientVotingStatusHistory(
    String clientId,
  ) async {
    try {
      final snapshot = await firestore
          .collection('voting_status_changes')
          .where('clientId', isEqualTo: clientId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => VotingStatusChangeRecord.fromFirestore(doc))
          .toList();
    } catch (e) {
      logError('getClientVotingStatusHistory', e);
      return [];
    }
  }

  /// Gets all recent voting status changes
  Future<List<VotingStatusChangeRecord>> getRecentVotingStatusChanges({
    int limit = 100,
    DateTime? since,
  }) async {
    try {
      Query query = firestore
          .collection('voting_status_changes')
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (since != null) {
        query = query.where('timestamp', isGreaterThan: since);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => VotingStatusChangeRecord.fromFirestore(doc))
          .toList();
    } catch (e) {
      logError('getRecentVotingStatusChanges', e);
      return [];
    }
  }

  /// Gets voting status change statistics
  Future<VotingStatusChangeStatistics> getVotingStatusChangeStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return getCachedData('voting_status_change_stats', () async {
      try {
        Query query = firestore.collection('voting_status_changes');

        if (startDate != null) {
          query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
        }
        if (endDate != null) {
          query = query.where('timestamp', isLessThanOrEqualTo: endDate);
        }

        final snapshot = await query.get();

        final Map<String, int> changeTypeCounts = {};
        int totalChanges = 0;

        for (final doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final oldStatus = data['oldStatus'] as String?;
          final newStatus = data['newStatus'] as String?;

          if (oldStatus != null && newStatus != null) {
            final changeType = '$oldStatus->$newStatus';
            changeTypeCounts[changeType] =
                (changeTypeCounts[changeType] ?? 0) + 1;
            totalChanges++;
          }
        }

        return VotingStatusChangeStatistics(
          totalChanges: totalChanges,
          changeTypeCounts: changeTypeCounts,
          periodStart: startDate,
          periodEnd: endDate,
          lastUpdated: DateTime.now(),
        );
      } catch (e) {
        logError('getVotingStatusChangeStats', e);
        return VotingStatusChangeStatistics(
          totalChanges: 0,
          changeTypeCounts: {},
          periodStart: startDate,
          periodEnd: endDate,
          lastUpdated: DateTime.now(),
        );
      }
    });
  }
}

/// Represents a voting status change record
class VotingStatusChangeRecord {
  final String id;
  final String clientId;
  final VotingStatus oldStatus;
  final VotingStatus newStatus;
  final String reason;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  VotingStatusChangeRecord({
    required this.id,
    required this.clientId,
    required this.oldStatus,
    required this.newStatus,
    required this.reason,
    required this.timestamp,
    required this.metadata,
  });

  factory VotingStatusChangeRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return VotingStatusChangeRecord(
      id: doc.id,
      clientId: data['clientId'] ?? '',
      oldStatus: VotingStatus.values.firstWhere(
        (status) => status.name == data['oldStatus'],
        orElse: () => VotingStatus.undecided,
      ),
      newStatus: VotingStatus.values.firstWhere(
        (status) => status.name == data['newStatus'],
        orElse: () => VotingStatus.undecided,
      ),
      reason: data['reason'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'oldStatus': oldStatus.name,
      'newStatus': newStatus.name,
      'reason': reason,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata,
    };
  }
}

/// Statistics about voting status changes
class VotingStatusChangeStatistics {
  final int totalChanges;
  final Map<String, int> changeTypeCounts;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final DateTime lastUpdated;

  VotingStatusChangeStatistics({
    required this.totalChanges,
    required this.changeTypeCounts,
    this.periodStart,
    this.periodEnd,
    required this.lastUpdated,
  });

  List<MapEntry<String, int>> get topChangeTypes {
    final entries = changeTypeCounts.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  int getChangeTypeCount(String changeType) =>
      changeTypeCounts[changeType] ?? 0;
}
