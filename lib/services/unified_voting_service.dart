import '../models_and_services.dart' hide VotingCapitalInfo;
import 'base_service.dart';
import 'firebase_functions_analytics_service.dart' show VotingCapitalInfo;

/// Unified service for all voting status operations
///
/// This service combines the functionality of multiple voting services
/// and provides a single point of entry for all voting-related operations.
class UnifiedVotingService extends BaseService {
  final EnhancedVotingStatusService _enhancedService =
      EnhancedVotingStatusService();
  final VotingStatusChangeService _changeService = VotingStatusChangeService();

  /// Updates voting status with comprehensive history tracking
  Future<VotingStatusUpdateResult> updateVotingStatus(
    String clientId,
    VotingStatus newStatus, {
    String? reason,
    Map<String, dynamic>? additionalChanges,
  }) async {
    try {
      print('🗳️ [UnifiedVoting] Aktualizacja statusu dla klienta: $clientId');

      final result = await _enhancedService.updateVotingStatusWithHistory(
        clientId,
        newStatus,
        reason: reason,
        additionalChanges: additionalChanges,
      );

      // Clear cache if successful
      if (result.isSuccess && result.hasChanged) {
        clearCache('voting_statistics');
        clearCache('voting_status_statistics');
        clearCache('voting_status_change_stats');
      }

      return result;
    } catch (e) {
      logError('updateVotingStatus', e);
      rethrow;
    }
  }

  /// Gets voting status history for a client
  Future<List<VotingStatusChangeRecord>> getVotingStatusHistory(
    String clientId,
  ) async {
    try {
      // Use the VotingStatusChangeService for history
      return await _changeService.getClientVotingStatusHistory(clientId);
    } catch (e) {
      logError('getVotingStatusHistory', e);
      return [];
    }
  }

  /// Gets voting status statistics
  Future<VotingStatusStatistics> getVotingStatusStatistics() async {
    try {
      return await _enhancedService.getVotingStatusStatistics();
    } catch (e) {
      logError('getVotingStatusStatistics', e);
      return VotingStatusStatistics(
        totalClients: 0,
        statusCounts: {},
        lastUpdated: DateTime.now(),
      );
    }
  }

  /// Gets recent voting status changes across all clients
  Future<List<VotingStatusChangeRecord>> getRecentVotingStatusChanges({
    int limit = 100,
    DateTime? since,
  }) async {
    try {
      return await _changeService.getRecentVotingStatusChanges(
        limit: limit,
        since: since,
      );
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
    try {
      return await _changeService.getVotingStatusChangeStats(
        startDate: startDate,
        endDate: endDate,
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
  }

  /// Batch update multiple voting statuses
  Future<BatchVotingStatusResult> updateMultipleVotingStatuses(
    List<VotingStatusUpdate> updates, {
    String? batchReason,
  }) async {
    try {
      return await _enhancedService.updateMultipleVotingStatuses(
        updates,
        batchReason: batchReason,
      );
    } catch (e) {
      logError('updateMultipleVotingStatuses', e);
      rethrow;
    }
  }

  /// Convenience method for updating voting status by client ID with string status
  Future<VotingStatusUpdateResult> updateVotingStatusByName(
    String clientId,
    String statusName, {
    String? reason,
  }) async {
    try {
      final status = VotingStatus.values.firstWhere(
        (s) => s.name == statusName.toLowerCase(),
        orElse: () => VotingStatus.undecided,
      );

      return await updateVotingStatus(clientId, status, reason: reason);
    } catch (e) {
      logError('updateVotingStatusByName', e);
      rethrow;
    }
  }

  /// Gets voting status distribution for analytics
  Future<Map<VotingStatus, VotingCapitalInfo>> getVotingCapitalDistribution(
    List<InvestorSummary> investors,
  ) async {
    try {
      final distribution = <VotingStatus, VotingCapitalInfo>{};

      // Initialize all statuses
      for (final status in VotingStatus.values) {
        distribution[status] = VotingCapitalInfo(count: 0, capital: 0.0);
      }

      // Calculate distribution
      for (final investor in investors) {
        final status = investor.client.votingStatus;
        final capital = investor.viableRemainingCapital;

        distribution[status] = VotingCapitalInfo(
          count: distribution[status]!.count + 1,
          capital: distribution[status]!.capital + capital,
        );
      }

      return distribution;
    } catch (e) {
      logError('getVotingCapitalDistribution', e);
      return {};
    }
  }
}
