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

/// Data model representing a crop item instance
class CropItem {
  final String id;
  final String displayName;
  final bool isLocked;
  final int quantity;

  CropItem({
    required this.id,
    required this.displayName,
    required this.isLocked,
    required this.quantity,
  });

  CropItem copyWith({String? displayName, bool? isLocked, int? quantity}) {
    return CropItem(
      id: id,
      displayName: displayName ?? this.displayName,
      isLocked: isLocked ?? this.isLocked,
      quantity: quantity ?? this.quantity,
    );
  }
}

class SproutDataHelpers {
  /// Return the ordered list of crop ids defined in the user data schema
  static Future<List<String>> getCropKeysFromSchema() async {
    final schema = await UserData.getSchema();
    final Map<String, dynamic> structure = schema.getStructureAtPath('sproutProgress.cropItems');
    return structure.keys.toList();
  }

  /// Build a list of CropItem for a given user (or defaults if userData is null)
  static Future<List<CropItem>> getCropItemsForUser(UserData? userData) async {
    final schema = await UserData.getSchema();
    final Map<String, dynamic> defaults = schema.createDefaultData();
    final List<String> keys = (schema.getStructureAtPath('sproutProgress.cropItems')).keys.toList();
    final List<CropItem> items = [];

    for (final k in keys) {
      final dynamic defIsLocked = (defaults['sproutProgress']?['cropItems']?[k]?['isLocked']);
      final dynamic defQuantity = (defaults['sproutProgress']?['cropItems']?[k]?['quantity']);

      bool isLocked = true;
      int qty = 0;

      if (defIsLocked is bool) isLocked = defIsLocked;
      if (defQuantity is num) qty = defQuantity.toInt();

      if (userData != null) {
        final dynamic uIsLocked = userData.get('sproutProgress.cropItems.$k.isLocked');
        final dynamic uQty = userData.get('sproutProgress.cropItems.$k.quantity');

        if (uIsLocked is bool) isLocked = uIsLocked;
        if (uQty is num) qty = uQty.toInt();
      }

      final display = '${k[0].toUpperCase()}${k.substring(1)}';

      items.add(CropItem(id: k, displayName: display, isLocked: isLocked, quantity: qty));
    }

    return items;
  }

  /// Update a crop's quantity by delta (positive or negative) 
  /// Will only perform the update when the crop is unlocked
  static Future<UserData> updateCropQuantity({
    required UserData userData,
    required String cropId,
    required int delta,
  }) async {
    final Map<String, dynamic> originalMap = userData.toFirestore();
    final cropInfo = _readCropInfo(originalMap, cropId);
    final bool isLocked = cropInfo['isLocked'] as bool;
    final int currentQty = cropInfo['quantity'] as int;

    if (isLocked) {
      throw Exception('Crop $cropId is locked and cannot be modified');
    }

    final int newQty = (currentQty + delta) < 0 ? 0 : (currentQty + delta);

    try {
      await userData.updateFields({'sproutProgress.cropItems.$cropId.quantity': newQty});
    } catch (e) {
      throw Exception('Failed to persist crop quantity update: $e');
    }

    try {
      final refreshed = await FirestoreService.getUserData(userData.uid, forceRefresh: true);
      if (refreshed != null) return refreshed;
    } catch (e) {
      debugPrint('Failed to refresh user data after updating crop quantity: $e');
    }

    return userData.copyWith({'sproutProgress.cropItems.$cropId.quantity': newQty});
  }

  /// Return a new copy of the userData map with updated crop quantity
  static Map<String, dynamic> _withUpdatedCropQuantityMap(Map<String, dynamic> userData, String cropId, int newQty) {
    final newData = Map<String, dynamic>.from(userData);

    final sp = (userData['sproutProgress'] is Map<String, dynamic>)
        ? Map<String, dynamic>.from(userData['sproutProgress'] as Map<String, dynamic>)
        : <String, dynamic>{};

    final cropItems = (sp['cropItems'] is Map<String, dynamic>)
        ? Map<String, dynamic>.from(sp['cropItems'] as Map<String, dynamic>)
        : <String, dynamic>{};

    final crop = (cropItems[cropId] is Map<String, dynamic>)
        ? Map<String, dynamic>.from(cropItems[cropId] as Map<String, dynamic>)
        : <String, dynamic>{};

    crop['quantity'] = newQty;
    cropItems[cropId] = crop;
    sp['cropItems'] = cropItems;
    newData['sproutProgress'] = sp;
    return newData;
  }

  /// Apply a delta to a crop's quantity in a plain userData map
  /// If the crop is locked the original map is returned unchanged
  static Map<String, dynamic> applyCropQuantityDelta(Map<String, dynamic> userData, String cropId, int delta) {
    final sp = userData['sproutProgress'] as Map<String, dynamic>?;
    final cropItems = sp != null ? (sp['cropItems'] as Map<String, dynamic>?) : null;
    final crop = (cropItems != null) ? (cropItems[cropId] as Map<String, dynamic>?) : null;

    final bool isLocked = crop != null && crop['isLocked'] is bool ? crop['isLocked'] as bool : true;
    final int currentQty = crop != null && crop['quantity'] is num ? (crop['quantity'] as num).toInt() : 0;

    if (isLocked) {
      // Locked: do not modify
      return userData;
    }

    int newQty = currentQty + delta;
    if (newQty < 0) newQty = 0;
    return _withUpdatedCropQuantityMap(userData, cropId, newQty);
  }

  /// Convenience helpers for add/subtract
  static Map<String, dynamic> addCropQuantity(Map<String, dynamic> userData, String cropId, int amount) {
    if (amount <= 0) return userData;
    return applyCropQuantityDelta(userData, cropId, amount);
  }

  static Map<String, dynamic> subtractCropQuantity(Map<String, dynamic> userData, String cropId, int amount) {
    if (amount <= 0) return userData;
    return applyCropQuantityDelta(userData, cropId, -amount);
  }

  /// Read crop info (isLocked, quantity) from a plain userData map
  static Map<String, Object> _readCropInfo(Map<String, dynamic> userData, String cropId) {
    final sp = userData['sproutProgress'] as Map<String, dynamic>?;
    final cropItems = sp != null ? (sp['cropItems'] as Map<String, dynamic>?) : null;
    final crop = (cropItems != null) ? (cropItems[cropId] as Map<String, dynamic>?) : null;

    final bool isLocked = crop != null && crop['isLocked'] is bool ? crop['isLocked'] as bool : true;
    final int qty = crop != null && crop['quantity'] is num ? (crop['quantity'] as num).toInt() : 0;

    return {'isLocked': isLocked, 'quantity': qty};
  }
}
