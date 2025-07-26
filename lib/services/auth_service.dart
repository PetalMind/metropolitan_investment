import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  // Sign in with email and password
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (result.user != null) {
        // Update last login time
        await _updateUserLastLogin(result.user!.uid);
        return AuthResult.success(result.user!);
      } else {
        return AuthResult.error('Nie udało się zalogować');
      }
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_getAuthErrorMessage(e.code));
    } catch (e) {
      return AuthResult.error('Wystąpił nieoczekiwany błąd: ${e.toString()}');
    }
  }

  // Register with email and password
  Future<AuthResult> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? company,
    String? phone,
  }) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (result.user != null) {
        // Update user display name
        await result.user!.updateDisplayName('$firstName $lastName');

        // Create user profile in Firestore
        await _createUserProfile(
          uid: result.user!.uid,
          email: email.trim(),
          firstName: firstName,
          lastName: lastName,
          company: company,
          phone: phone,
        );

        return AuthResult.success(result.user!);
      } else {
        return AuthResult.error('Nie udało się utworzyć konta');
      }
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_getAuthErrorMessage(e.code));
    } catch (e) {
      return AuthResult.error('Wystąpił nieoczekiwany błąd: ${e.toString()}');
    }
  }

  // Reset password
  Future<AuthResult> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return AuthResult.success(
        null,
        'Link do resetowania hasła został wysłany na podany adres email',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_getAuthErrorMessage(e.code));
    } catch (e) {
      return AuthResult.error('Wystąpił nieoczekiwany błąd: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      if (kDebugMode) {
        print('Error signing out: $e');
      }
    }
  }

  // Get user profile data
  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserProfile.fromMap(doc.data()!);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user profile: $e');
      }
    }
    return null;
  }

  // Update user profile
  Future<bool> updateUserProfile({
    required String uid,
    String? firstName,
    String? lastName,
    String? company,
    String? phone,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (firstName != null) updates['firstName'] = firstName;
      if (lastName != null) updates['lastName'] = lastName;
      if (company != null) updates['company'] = company;
      if (phone != null) updates['phone'] = phone;

      await _firestore.collection('users').doc(uid).update(updates);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user profile: $e');
      }
      return false;
    }
  }

  // Private methods
  Future<void> _createUserProfile({
    required String uid,
    required String email,
    required String firstName,
    required String lastName,
    String? company,
    String? phone,
  }) async {
    final userData = {
      'uid': uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'company': company,
      'phone': phone,
      'role': 'user', // Default role
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('users').doc(uid).set(userData);
  }

  Future<void> _updateUserLastLogin(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error updating last login: $e');
      }
    }
  }

  String _getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'Nie znaleziono użytkownika z podanym adresem email';
      case 'wrong-password':
        return 'Nieprawidłowe hasło';
      case 'email-already-in-use':
        return 'Konto z tym adresem email już istnieje';
      case 'weak-password':
        return 'Hasło jest zbyt słabe. Musi mieć co najmniej 6 znaków';
      case 'invalid-email':
        return 'Nieprawidłowy format adresu email';
      case 'user-disabled':
        return 'To konto zostało zablokowane';
      case 'too-many-requests':
        return 'Zbyt wiele prób logowania. Spróbuj ponownie później';
      case 'operation-not-allowed':
        return 'Logowanie za pomocą email i hasła nie jest włączone';
      case 'invalid-credential':
        return 'Nieprawidłowe dane logowania';
      default:
        return 'Wystąpił błąd podczas autoryzacji: $errorCode';
    }
  }
}

// Auth Result class
class AuthResult {
  final bool isSuccess;
  final User? user;
  final String? error;
  final String? message;

  AuthResult._(this.isSuccess, this.user, this.error, this.message);

  factory AuthResult.success(User? user, [String? message]) {
    return AuthResult._(true, user, null, message);
  }

  factory AuthResult.error(String error) {
    return AuthResult._(false, null, error, null);
  }
}

// User Profile class
class UserProfile {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String? company;
  final String? phone;
  final String role;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLoginAt;

  UserProfile({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.company,
    this.phone,
    required this.role,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
  });

  String get fullName => '$firstName $lastName';

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      company: map['company'],
      phone: map['phone'],
      role: map['role'] ?? 'user',
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt']?.toDate(),
      updatedAt: map['updatedAt']?.toDate(),
      lastLoginAt: map['lastLoginAt']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'company': company,
      'phone': phone,
      'role': role,
      'isActive': isActive,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'lastLoginAt': lastLoginAt != null
          ? Timestamp.fromDate(lastLoginAt!)
          : null,
    };
  }
}
