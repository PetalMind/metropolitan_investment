import 'package:flutter_test/flutter_test.dart';    test('should format date correctly', () {
      final testDate = DateTime(2024, 1, 15, 14, 30);
      final change = VotingStatusChange(
        id: 'test-id',
        investorId: 'investor-123',
        clientId: 'client-123',
        clientName: 'Test Client',
        changeType: VotingStatusChangeType.statusChanged,
        editedBy: 'Test User',
        editedByEmail: 'test@example.com',
        timestamp: testDate,
        metadata: {},
      );kage:cloud_firestore/cloud_firestore.dart';
import 'package:metropolitan_investment/models/voting_status_change.dart';

void main() {
  group('VotingStatusChange Tests', () {
    test('should create VotingStatusChange from valid data', () {
      final change = VotingStatusChange(
        id: 'test-id',
        investorId: 'investor-123',
        clientId: 'client-123',
        clientName: 'Test Client',
        oldStatus: VotingStatus.yes,
        newStatus: VotingStatus.no,
        changeType: VotingStatusChangeType.statusChanged,
        editedBy: 'Test User',
        editedByEmail: 'test@example.com',
        timestamp: DateTime.now(),
        metadata: {},
        reason: 'Test reason',
      );

      expect(change.id, equals('test-id'));
      expect(change.clientName, equals('Test Client'));
      expect(change.changeType, equals(VotingStatusChangeType.statusChanged));
      expect(change.isVotingStatusChange, isTrue);
    });

    test('should generate correct change description', () {
      final change = VotingStatusChange(
        id: 'test-id',
        investorId: 'investor-123',
        clientId: 'client-123',
        clientName: 'Test Client',
        oldStatus: VotingStatus.yes,
        newStatus: VotingStatus.no,
        changeType: VotingStatusChangeType.statusChanged,
        editedBy: 'Test User',
        editedByEmail: 'test@example.com',
        timestamp: DateTime.now(),
        metadata: {},
      );

      expect(change.changeDescription, contains('Zmieniono status głosowania'));
      expect(change.changeDescription, contains('Za'));
      expect(change.changeDescription, contains('Przeciw'));
    });

    test('should format date correctly', () {
      final testDate = DateTime(2024, 1, 15, 14, 30);
      final change = VotingStatusChange(
        id: 'test-id',
        investorId: 'investor-123',
        clientId: 'client-123',
        clientName: 'Test Client',
        changeType: VotingStatusChangeType.created,
        editedBy: 'Test User',
        editedByEmail: 'test@example.com',
        timestamp: testDate,
        metadata: {},
      );

      expect(change.formattedDate, equals('15.01.2024 14:30'));
    });

    test('should serialize to Firestore correctly', () {
      final testDate = DateTime(2024, 1, 15, 14, 30);
      final change = VotingStatusChange(
        id: 'test-id',
        investorId: 'investor-123',
        clientId: 'client-123',
        clientName: 'Test Client',
        oldStatus: VotingStatus.yes,
        newStatus: VotingStatus.no,
        changeType: VotingStatusChangeType.statusChanged,
        editedBy: 'Test User',
        editedByEmail: 'test@example.com',
        timestamp: testDate,
        metadata: {},
        reason: 'Test reason',
      );

      final firestoreData = change.toFirestore();

      expect(firestoreData['investorId'], equals('investor-123'));
      expect(firestoreData['clientId'], equals('client-123'));
      expect(firestoreData['clientName'], equals('Test Client'));
      expect(firestoreData['oldStatus'], equals('Za'));
      expect(firestoreData['newStatus'], equals('Przeciw'));
      expect(firestoreData['changeType'], equals('statusChanged'));
      expect(firestoreData['editedBy'], equals('Test User'));
      expect(firestoreData['editedByEmail'], equals('test@example.com'));
      expect(firestoreData['timestamp'], isA<Timestamp>());
      expect(firestoreData['reason'], equals('Test reason'));
    });
  });
}