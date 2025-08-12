import 'package:cloud_firestore/cloud_firestore.dart';

// Import VotingStatus enum from client.dart
import 'client.dart' show VotingStatus;

enum VotingStatusChangeType { created, updated, deleted, statusChanged }

class VotingStatusChange {
  final String id;
  final String investorId;
  final String clientId;
  final String clientName;
  final VotingStatus? oldStatus;
  final VotingStatus? newStatus;
  final VotingStatusChangeType changeType;
  final String editedBy;
  final String editedByEmail;
  final String? editedByName;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  final String? reason;

  VotingStatusChange({
    required this.id,
    required this.investorId,
    required this.clientId,
    required this.clientName,
    this.oldStatus,
    this.newStatus,
    required this.changeType,
    required this.editedBy,
    required this.editedByEmail,
    this.editedByName,
    required this.timestamp,
    required this.metadata,
    this.reason,
  });

  factory VotingStatusChange.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VotingStatusChange(
      id: doc.id,
      investorId: data['investorId'] ?? '',
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'] ?? '',
      oldStatus: _parseVotingStatus(
        data['oldStatus'] ?? data['previousVotingStatus'],
      ),
      newStatus: _parseVotingStatus(
        data['newStatus'] ?? data['newVotingStatus'],
      ),
      changeType: VotingStatusChangeType.values.firstWhere(
        (e) => e.name == data['changeType'],
        orElse: () => VotingStatusChangeType.updated,
      ),
      editedBy: data['editedBy'] ?? '',
      editedByEmail: data['editedByEmail'] ?? '',
      editedByName: data['editedByName'],
      timestamp:
          (data['timestamp'] ?? data['changedAt'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      metadata: Map<String, dynamic>.from(
        data['metadata'] ?? data['additionalChanges'] ?? {},
      ),
      reason: data['reason'],
    );
  }

  static VotingStatus? _parseVotingStatus(dynamic statusData) {
    if (statusData == null) return null;
    final statusString = statusData.toString();
    try {
      return VotingStatus.values.firstWhere(
        (status) => status.name == statusString,
        orElse: () => VotingStatus.undecided,
      );
    } catch (e) {
      return VotingStatus.undecided;
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'investorId': investorId,
      'clientId': clientId,
      'clientName': clientName,
      'oldStatus': oldStatus?.name,
      'newStatus': newStatus?.name,
      // Keep legacy field names for compatibility
      'previousVotingStatus': oldStatus?.name,
      'newVotingStatus': newStatus?.name,
      'changeType': changeType.name,
      'editedBy': editedBy,
      'editedByEmail': editedByEmail,
      'editedByName': editedByName,
      'timestamp': Timestamp.fromDate(timestamp),
      'changedAt': Timestamp.fromDate(timestamp), // Legacy field name
      'metadata': metadata,
      'additionalChanges': metadata, // Legacy field name
      'reason': reason,
    };
  }

  String get changeDescription {
    switch (changeType) {
      case VotingStatusChangeType.created:
        return 'Utworzono inwestora z statusem głosowania: ${newStatus?.displayName ?? "brak"}';
      case VotingStatusChangeType.updated:
        if (oldStatus != newStatus) {
          return 'Zmieniono status głosowania z "${oldStatus?.displayName ?? "nieznany"}" na "${newStatus?.displayName ?? "nieznany"}"';
        }
        return 'Zaktualizowano dane inwestora';
      case VotingStatusChangeType.deleted:
        return 'Usunięto inwestora';
      case VotingStatusChangeType.statusChanged:
        return 'Zmieniono status głosowania z "${oldStatus?.displayName ?? "nieznany"}" na "${newStatus?.displayName ?? "nieznany"}"';
    }
  }

  String get formattedDate {
    return '${timestamp.day.toString().padLeft(2, '0')}.${timestamp.month.toString().padLeft(2, '0')}.${timestamp.year} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  bool get isVotingStatusChange {
    return changeType == VotingStatusChangeType.statusChanged ||
        (changeType == VotingStatusChangeType.updated &&
            oldStatus != newStatus);
  }
}
