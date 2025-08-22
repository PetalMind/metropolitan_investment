import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { admin, user, superAdmin, unknown }

UserRole userRoleFromString(String? role) {
  switch (role?.toLowerCase()) {
    case 'admin':
      return UserRole.admin;
    case 'user':
      return UserRole.user;
    case 'super-admin':
    case 'superadmin':
      return UserRole.superAdmin;
    default:
      return UserRole.unknown;
  }
}

class UserProfile {
  final String uid;
  final String email;
  final String? displayName;
  final String? firstName;
  final String? lastName;
  final String? company;
  final String? phone;
  final UserRole role;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLoginAt;

  UserProfile({
    required this.uid,
    required this.email,
    this.displayName,
    this.firstName,
    this.lastName,
    this.company,
    this.phone,
    required this.role,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
  });

  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return displayName ?? email;
  }

  bool get isAdmin => role == UserRole.admin || role == UserRole.superAdmin;
  bool get isSuperAdmin => role == UserRole.superAdmin;
  bool get isVisibleAdmin => role == UserRole.admin; // Admin widoczny w interfejsach

  factory UserProfile.fromMap(Map<String, dynamic> map, String uid) {
    return UserProfile(
      uid: uid,
      email: map['email'] ?? '',
      displayName: map['displayName'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      company: map['company'],
      phone: map['phone'],
      role: userRoleFromString(map['role']),
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      lastLoginAt: (map['lastLoginAt'] as Timestamp?)?.toDate(),
    );
  }

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'firstName': firstName,
      'lastName': lastName,
      'company': company,
      'phone': phone,
      'role': role.name,
      'isActive': isActive,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
      'lastLoginAt': lastLoginAt != null
          ? Timestamp.fromDate(lastLoginAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
