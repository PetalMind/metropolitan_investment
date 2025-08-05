import 'package:flutter_test/flutter_test.dart';
import '../lib/services/enhanced_voting_status_service.dart';
import '../lib/models/client.dart';

void main() {
  group('EnhancedVotingStatusService Tests', () {
    test('VotingStatusChangeResult should create success result correctly', () {
      final result = VotingStatusChangeResult.success(
        clientId: 'client-123',
        clientName: 'Test Client',
        previousStatus: VotingStatus.undecided,
        newStatus: VotingStatus.yes,
        changeId: 'change-123',
      );

      expect(result.isSuccess, isTrue);
      expect(result.hasChanged, isTrue);
      expect(result.clientId, equals('client-123'));
      expect(result.previousStatus, equals(VotingStatus.undecided));
      expect(result.newStatus, equals(VotingStatus.yes));
      expect(result.changeId, equals('change-123'));
      expect(result.error, isNull);
    });

    test('VotingStatusChangeResult should create no-change result correctly', () {
      final result = VotingStatusChangeResult.noChange(
        clientId: 'client-123',
        clientName: 'Test Client',
        status: VotingStatus.yes,
      );

      expect(result.isSuccess, isTrue);
      expect(result.hasChanged, isFalse);
      expect(result.clientId, equals('client-123'));
      expect(result.newStatus, equals(VotingStatus.yes));
      expect(result.changeId, isNull);
      expect(result.error, isNull);
    });

    test('VotingStatusChangeResult should create error result correctly', () {
      final result = VotingStatusChangeResult.error(
        clientId: 'client-123',
        error: 'Test error message',
        clientName: 'Test Client',
      );

      expect(result.isSuccess, isFalse);
      expect(result.hasChanged, isFalse);
      expect(result.clientId, equals('client-123'));
      expect(result.error, equals('Test error message'));
      expect(result.changeId, isNull);
    });

    test('BatchVotingStatusResult should calculate statistics correctly', () {
      final results = [
        VotingStatusChangeResult.success(
          clientId: 'client-1',
          clientName: 'Client 1',
          previousStatus: VotingStatus.undecided,
          newStatus: VotingStatus.yes,
          changeId: 'change-1',
        ),
        VotingStatusChangeResult.noChange(
          clientId: 'client-2',
          clientName: 'Client 2',
          status: VotingStatus.yes,
        ),
        VotingStatusChangeResult.error(
          clientId: 'client-3',
          error: 'Test error',
        ),
      ];

      final batchResult = BatchVotingStatusResult(
        totalUpdates: 3,
        successfulUpdates: 2,
        failedUpdates: 1,
        results: results,
        errors: {'client-3': 'Test error'},
      );

      expect(batchResult.totalUpdates, equals(3));
      expect(batchResult.successfulUpdates, equals(2));
      expect(batchResult.failedUpdates, equals(1));
      expect(batchResult.hasErrors, isTrue);
      expect(batchResult.isCompleteSuccess, isFalse);
      expect(batchResult.successRate, closeTo(0.67, 0.01));
    });

    test('VotingStatusUpdate should create correctly', () {
      final update = VotingStatusUpdate(
        clientId: 'client-123',
        newStatus: VotingStatus.yes,
        reason: 'Test reason',
        additionalChanges: {'field': 'value'},
      );

      expect(update.clientId, equals('client-123'));
      expect(update.newStatus, equals(VotingStatus.yes));
      expect(update.reason, equals('Test reason'));
      expect(update.additionalChanges, containsPair('field', 'value'));
    });

    test('VotingStatusException should format message correctly', () {
      const exception = VotingStatusException('Test error message');
      expect(exception.toString(), equals('VotingStatusException: Test error message'));
    });

    test('VotingStatusStatistics should create empty statistics correctly', () {
      final stats = VotingStatusStatistics.empty();

      expect(stats.totalChanges, equals(0));
      expect(stats.changesByType, isEmpty);
      expect(stats.changesByUser, isEmpty);
      expect(stats.changesByStatus, isEmpty);
      expect(stats.changesByDay, isEmpty);
      expect(stats.fromDate, isNull);
      expect(stats.toDate, isNull);
      expect(stats.generatedAt, isNotNull);
    });
  });
}