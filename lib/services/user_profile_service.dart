import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:metropolitan_investment/models/user_profile.dart';

class UserProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'user_profiles';

  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection(_collectionPath).doc(uid).get();
      if (doc.exists) {
        return UserProfile.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  Future<void> createUserProfile({
    required String uid,
    required String? email,
    required String? displayName,
  }) async {
    try {
      final userProfile = UserProfile(
        uid: uid,
        email: email ?? '',
        displayName: displayName,
        role: UserRole.user, // Default role
        isActive: true,
      );
      await _firestore
          .collection(_collectionPath)
          .doc(uid)
          .set(userProfile.toMap());
    } catch (e) {
      print('Error creating user profile: $e');
    }
  }
}
