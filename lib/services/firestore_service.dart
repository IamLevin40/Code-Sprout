import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_data.dart';

/// Service class to handle Firestore operations for user data
class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _usersCollection =
      _firestore.collection('users');

  /// Create a new user document in Firestore
  /// This should be called right after successful user registration
  static Future<void> createUserDocument({
    required String uid,
    required String username,
  }) async {
    try {
      final userData = UserData(
        uid: uid,
        username: username,
        hasPlayedTutorial: false,
        hasLearnedModule: false,
      );

      await userData.save();
    } catch (e) {
      throw Exception('Failed to create user document: $e');
    }
  }

  /// Check if a username already exists in the database
  static Future<bool> usernameExists(String username) async {
    try {
      final querySnapshot = await _usersCollection
          .where('accountInformation.username', isEqualTo: username)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check username existence: $e');
    }
  }

  /// Get user data by UID
  static Future<UserData?> getUserData(String uid) async {
    try {
      return await UserData.load(uid);
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  /// Update user data
  static Future<void> updateUserData(UserData userData) async {
    try {
      await userData.save();
    } catch (e) {
      throw Exception('Failed to update user data: $e');
    }
  }

  /// Delete user document (useful when deleting account)
  static Future<void> deleteUserDocument(String uid) async {
    try {
      await _usersCollection.doc(uid).delete();
    } catch (e) {
      throw Exception('Failed to delete user document: $e');
    }
  }
}
