import 'package:cloud_firestore/cloud_firestore.dart';
import '../models_and_services.dart';
import 'base_service.dart';

/// Enhanced service for managing voting status with history tracking
class EnhancedVotingStatusService extends BaseService {
  final ClientService _clientService = ClientService();

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

      // Update the voting status
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
