import 'package:flutter/foundation.dart';
import 'user_data.dart';
import '../services/firestore_service.dart';

/// Helper utilities for Sprout-related user data and logic
class SproutData {
  /// Resolve the selected language for the Sprout UI
  static Future<String?> resolveSelectedLanguage({
    required List<String> availableLanguages,
    UserData? userData,
  }) async {
    try {
      if (userData != null) {
        final dynamic val = userData.get('sproutProgress.selectedLanguage');
        if (val is String && val.isNotEmpty) {
          return val;
        }
      }

      if (availableLanguages.isNotEmpty) {
        final String defaultLang = availableLanguages.first;

        if (userData != null) {
          try {
            await userData.updateField('sproutProgress.selectedLanguage', defaultLang);

            try {
              final refreshed = await FirestoreService.getUserData(userData.uid, forceRefresh: true);
              if (refreshed != null) {
                final dynamic rVal = refreshed.get('sproutProgress.selectedLanguage');
                if (rVal is String && rVal.isNotEmpty) return rVal;
              }
            } catch (e) {
              debugPrint('Failed to refresh user data after persisting default sprout language: $e');
            }

            return defaultLang;
          } catch (e) {
            debugPrint('Failed to persist default sprout language: $e');
            return defaultLang;
          }
        }

        return defaultLang;
      }

      return null;
    } catch (e) {
      debugPrint('Error resolving selected language: $e');
      return availableLanguages.isNotEmpty ? availableLanguages.first : null;
    }
  }

  /// Set the selected language for a user and return an updated in-memory
  static Future<UserData> setSelectedLanguage({
    required UserData userData,
    required String languageId,
  }) async {
    await userData.updateField('sproutProgress.selectedLanguage', languageId);

    try {
      final refreshed = await FirestoreService.getUserData(userData.uid, forceRefresh: true);
      if (refreshed != null) return refreshed;
    } catch (e) {
      debugPrint('Failed to refresh user data after setting selected language: $e');
    }

    return userData.copyWith({'sproutProgress.selectedLanguage': languageId});
  }
}
