import 'package:cloud_firestore/cloud_firestore.dart';

class Company {
  final String id;
  final String name;
  final String fullName;
  final String taxId;
  final String address;
  final String phone;
  final String email;
  final String website;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final Map<String, dynamic> additionalInfo;

  Company({
    required this.id,
    required this.name,
    required this.fullName,
    required this.taxId,
    required this.address,
    required this.phone,
    required this.email,
    this.website = '',
    this.description = '',
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.additionalInfo = const {},
  });

  factory Company.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Company(
      id: doc.id,
      name: data['name'] ?? '',
      fullName: data['fullName'] ?? '',
      taxId: data['taxId'] ?? '',
      address: data['address'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      website: data['website'] ?? '',
      description: data['description'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      additionalInfo: data['additionalInfo'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'fullName': fullName,
      'taxId': taxId,
      'address': address,
      'phone': phone,
      'email': email,
      'website': website,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'additionalInfo': additionalInfo,
    };
  }

  Company copyWith({
    String? id,
    String? name,
    String? fullName,
    String? taxId,
    String? address,
    String? phone,
    String? email,
    String? website,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    Map<String, dynamic>? additionalInfo,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      fullName: fullName ?? this.fullName,
      taxId: taxId ?? this.taxId,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }
}
