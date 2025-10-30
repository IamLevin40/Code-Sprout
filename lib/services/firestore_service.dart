import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_data.dart';
import 'local_storage_service.dart';

/// Service class to handle Firestore operations for user data
/// Implements cache-first strategy using secure local storage
class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _usersCollection =
      _firestore.collection('users');
  static final LocalStorageService _localStorage = LocalStorageService.instance;

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

  /// Get user data by UID (cache-first strategy)
  /// 1. First checks local cache
  /// 2. If not cached, fetches from Firestore and caches result
  /// 3. If forceRefresh is true, always fetches from Firestore
  static Future<UserData?> getUserData(String uid, {bool forceRefresh = false}) async {
    try {
      // If not forcing refresh, try to get from cache first
      if (!forceRefresh) {
        final cachedData = await _localStorage.getUserData();
        if (cachedData != null && cachedData.uid == uid) {
          return cachedData;
        }
      }

      // Fetch from Firestore
      final userData = await UserData.load(uid);
      
      // Cache the result if successful
      if (userData != null) {
        await _localStorage.saveUserData(userData);
      }
      
      return userData;
    } catch (e) {
      // If Firestore fails, try to return cached data as fallback
      if (!forceRefresh) {
        final cachedData = await _localStorage.getUserData();
        if (cachedData != null && cachedData.uid == uid) {
          return cachedData;
        }
      }
      throw Exception('Failed to get user data: $e');
    }
  }

  /// Update user data
  /// Updates local cache first, then syncs to Firestore
  static Future<void> updateUserData(UserData userData) async {
    try {
      // Update local cache first for immediate UI update
      await _localStorage.saveUserData(userData);
      
      // Then sync to Firestore
      await userData.save();
    } catch (e) {
      throw Exception('Failed to update user data: $e');
    }
  }

  /// Clear cached user data (call on logout)
  static Future<void> clearCache() async {
    try {
      await _localStorage.clearUserData();
    } catch (e) {
      throw Exception('Failed to clear cache: $e');
    }
  }

  /// Get cached user data without fetching from Firestore
  static Future<UserData?> getCachedUserData() async {
    try {
      return await _localStorage.getUserData();
    } catch (e) {
      return null;
    }
  }

  /// Check if user data is cached locally
  static Future<bool> hasCachedData() async {
    try {
      return await _localStorage.hasCachedData();
    } catch (e) {
      return false;
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
