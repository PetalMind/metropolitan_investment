import 'package:cloud_firestore/cloud_firestore.dart';

enum VotingStatusChangeType {
  created,
  updated,
  deleted,
  statusChanged,
}

class VotingStatusChange {
  final String id;
  final String investorId;
  final String clientId;
  final String clientName;
  final String? previousVotingStatus;
  final String? newVotingStatus;
  final VotingStatusChangeType changeType;
  final String editedBy;
  final String editedByEmail;
  final DateTime changedAt;
  final Map<String, dynamic>? additionalChanges;
  final String? reason;

  VotingStatusChange({
    required this.id,
    required this.investorId,
    required this.clientId,
    required this.clientName,
    this.previousVotingStatus,
    this.newVotingStatus,
    required this.changeType,
    required this.editedBy,
    required this.editedByEmail,
    required this.changedAt,
    this.additionalChanges,
    this.reason,
  });

  factory VotingStatusChange.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VotingStatusChange(
      id: doc.id,
      investorId: data['investorId'] ?? '',
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'] ?? '',
      previousVotingStatus: data['previousVotingStatus'],
      newVotingStatus: data['newVotingStatus'],
      changeType: VotingStatusChangeType.values.firstWhere(
        (e) => e.name == data['changeType'],
        orElse: () => VotingStatusChangeType.updated,
      ),
      editedBy: data['editedBy'] ?? '',
      editedByEmail: data['editedByEmail'] ?? '',
      changedAt: (data['changedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      additionalChanges: data['additionalChanges'] as Map<String, dynamic>?,
      reason: data['reason'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'investorId': investorId,
      'clientId': clientId,
      'clientName': clientName,
      'previousVotingStatus': previousVotingStatus,
      'newVotingStatus': newVotingStatus,
      'changeType': changeType.name,
      'editedBy': editedBy,
      'editedByEmail': editedByEmail,
      'changedAt': Timestamp.fromDate(changedAt),
      'additionalChanges': additionalChanges,
      'reason': reason,
    };
  }

  String get changeDescription {
    switch (changeType) {
      case VotingStatusChangeType.created:
        return 'Utworzono inwestora z statusem głosowania: ${newVotingStatus ?? "brak"}';
      case VotingStatusChangeType.updated:
        if (previousVotingStatus != newVotingStatus) {
          return 'Zmieniono status głosowania z "$previousVotingStatus" na "$newVotingStatus"';
        }
        return 'Zaktualizowano dane inwestora';
      case VotingStatusChangeType.deleted:
        return 'Usunięto inwestora';
      case VotingStatusChangeType.statusChanged:
        return 'Zmieniono status głosowania z "$previousVotingStatus" na "$newVotingStatus"';
    }
  }

  String get formattedDate {
    return '${changedAt.day.toString().padLeft(2, '0')}.${changedAt.month.toString().padLeft(2, '0')}.${changedAt.year} ${changedAt.hour.toString().padLeft(2, '0')}:${changedAt.minute.toString().padLeft(2, '0')}';
  }

  bool get isVotingStatusChange {
    return changeType == VotingStatusChangeType.statusChanged ||
        (changeType == VotingStatusChangeType.updated && 
         previousVotingStatus != newVotingStatus);
  }
}