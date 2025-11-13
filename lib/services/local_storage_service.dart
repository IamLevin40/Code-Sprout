import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_data.dart';

/// Service class to handle secure local storage of user data
/// Uses flutter_secure_storage to encrypt data at rest
class LocalStorageService {
  // Private constructor for singleton pattern
  LocalStorageService._();
  
  static final LocalStorageService _instance = LocalStorageService._();
  static LocalStorageService get instance => _instance;

  // Secure storage instance with enhanced security options
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // Storage keys
  static const String _userDataKey = 'cached_user_data';
  static const String _lastSyncKey = 'last_sync_timestamp';

  /// Notifier that emits the current cached UserData when it changes.
  /// Listeners can subscribe to this to receive updates when `saveUserData` or `clearUserData` is called.
  final ValueNotifier<UserData?> userDataNotifier = ValueNotifier<UserData?>(null);

  /// Save user data to secure local storage
  Future<void> saveUserData(UserData userData) async {
    try {
      final jsonString = jsonEncode(userData.toJson());
      await _storage.write(key: _userDataKey, value: jsonString);
      
      // Update last sync timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      await _storage.write(key: _lastSyncKey, value: timestamp);
      // Update in-memory notifier so listeners (UI) can react immediately
      try {
        userDataNotifier.value = userData;
      } catch (_) {}
    } catch (e) {
      throw Exception('Failed to save user data to local storage: $e');
    }
  }

  /// Retrieve user data from secure local storage
  Future<UserData?> getUserData() async {
    try {
      final jsonString = await _storage.read(key: _userDataKey);
      
      if (jsonString == null) {
        return null;
      }

      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      final ud = UserData.fromJson(jsonMap);
      // Keep the notifier in sync with cached value
      try {
        userDataNotifier.value = ud;
      } catch (_) {}
      return ud;
    } catch (e) {
      // If there's an error reading/parsing, clear the corrupted data
      await clearUserData();
      return null;
    }
  }

  /// Clear all cached user data (e.g., on logout)
  Future<void> clearUserData() async {
    try {
      await _storage.delete(key: _userDataKey);
      await _storage.delete(key: _lastSyncKey);
      try {
        userDataNotifier.value = null;
      } catch (_) {}
    } catch (e) {
      throw Exception('Failed to clear user data from local storage: $e');
    }
  }

  /// Get the last sync timestamp
  Future<DateTime?> getLastSyncTime() async {
    try {
      final timestampString = await _storage.read(key: _lastSyncKey);
      
      if (timestampString == null) {
        return null;
      }

      final milliseconds = int.parse(timestampString);
      return DateTime.fromMillisecondsSinceEpoch(milliseconds);
    } catch (e) {
      return null;
    }
  }

  /// Check if cached data exists
  Future<bool> hasCachedData() async {
    try {
      final data = await _storage.read(key: _userDataKey);
      return data != null;
    } catch (e) {
      return false;
    }
  }

  /// Clear all stored data (useful for debugging or account deletion)
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      throw Exception('Failed to clear all data from local storage: $e');
    }
  }
}
