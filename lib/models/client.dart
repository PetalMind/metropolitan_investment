import 'package:cloud_firestore/cloud_firestore.dart';

enum VotingStatus {
  undecided('Niezdecydowany'),
  yes('Tak'),
  no('Nie'),
  abstain('Wstrzymuje się');

  const VotingStatus(this.displayName);
  final String displayName;
}

enum ClientType {
  individual('Osoba fizyczna'),
  marriage('Małżeństwo'),
  company('Spółka'),
  other('Inne');

  const ClientType(this.displayName);
  final String displayName;
}

class Client {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String? pesel;
  final String? companyName;
  final ClientType type;
  final String notes;
  final VotingStatus votingStatus;
  final String colorCode;
  final List<String> unviableInvestments;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final Map<String, dynamic> additionalInfo;

  Client({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    this.pesel,
    this.companyName,
    this.type = ClientType.individual,
    this.notes = '',
    this.votingStatus = VotingStatus.undecided,
    this.colorCode = '#FFFFFF',
    this.unviableInvestments = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.additionalInfo = const {},
  });

  factory Client.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Client(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      pesel: data['pesel'],
      companyName: data['companyName'],
      type: ClientType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ClientType.individual,
      ),
      notes: data['notes'] ?? '',
      votingStatus: VotingStatus.values.firstWhere(
        (e) => e.name == data['votingStatus'],
        orElse: () => VotingStatus.undecided,
      ),
      colorCode: data['colorCode'] ?? '#FFFFFF',
      unviableInvestments: List<String>.from(data['unviableInvestments'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      additionalInfo: data['additionalInfo'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'pesel': pesel,
      'companyName': companyName,
      'type': type.name,
      'notes': notes,
      'votingStatus': votingStatus.name,
      'colorCode': colorCode,
      'unviableInvestments': unviableInvestments,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'additionalInfo': additionalInfo,
    };
  }

  Client copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? pesel,
    String? companyName,
    ClientType? type,
    String? notes,
    VotingStatus? votingStatus,
    String? colorCode,
    List<String>? unviableInvestments,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    Map<String, dynamic>? additionalInfo,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      pesel: pesel ?? this.pesel,
      companyName: companyName ?? this.companyName,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      votingStatus: votingStatus ?? this.votingStatus,
      colorCode: colorCode ?? this.colorCode,
      unviableInvestments: unviableInvestments ?? this.unviableInvestments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }
}
