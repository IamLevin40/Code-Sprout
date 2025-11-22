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

/// Data model representing an inventory item instance (seeds or crops)
class InventoryItem {
  final String id;
  final String displayName;
  final bool isLocked;
  final int quantity;

  InventoryItem({
    required this.id,
    required this.displayName,
    required this.isLocked,
    required this.quantity,
  });

  InventoryItem copyWith({String? displayName, bool? isLocked, int? quantity}) {
    return InventoryItem(
      id: id,
      displayName: displayName ?? this.displayName,
      isLocked: isLocked ?? this.isLocked,
      quantity: quantity ?? this.quantity,
    );
  }
}

class SproutDataHelpers {
  /// Return the ordered list of inventory item ids defined in the user data schema
  static Future<List<String>> getInventoryKeysFromSchema() async {
    final schema = await UserData.getSchema();
    final Map<String, dynamic> structure = schema.getStructureAtPath('sproutProgress.inventory');
    return structure.keys.toList();
  }

  /// Build a list of InventoryItem for a given user (or defaults if userData is null)
  static Future<List<InventoryItem>> getInventoryItemsForUser(UserData? userData) async {
    final schema = await UserData.getSchema();
    final Map<String, dynamic> defaults = schema.createDefaultData();
    final List<String> keys = (schema.getStructureAtPath('sproutProgress.inventory')).keys.toList();
    final List<InventoryItem> items = [];

    for (final k in keys) {
      final dynamic defIsLocked = (defaults['sproutProgress']?['inventory']?[k]?['isLocked']);
      final dynamic defQuantity = (defaults['sproutProgress']?['inventory']?[k]?['quantity']);

      bool isLocked = true;
      int qty = 0;

      if (defIsLocked is bool) isLocked = defIsLocked;
      if (defQuantity is num) qty = defQuantity.toInt();

      if (userData != null) {
        final dynamic uIsLocked = userData.get('sproutProgress.inventory.$k.isLocked');
        final dynamic uQty = userData.get('sproutProgress.inventory.$k.quantity');

        if (uIsLocked is bool) isLocked = uIsLocked;
        if (uQty is num) qty = uQty.toInt();
      }

      // Format display name properly for both seeds and crops
      String display;
      if (k.endsWith('Seeds')) {
        final base = k.replaceAll('Seeds', '');
        display = '${base[0].toUpperCase()}${base.substring(1)} Seeds';
      } else {
        display = '${k[0].toUpperCase()}${k.substring(1)}';
      }

      items.add(InventoryItem(id: k, displayName: display, isLocked: isLocked, quantity: qty));
    }

    return items;
  }

  /// Update an inventory item's quantity by delta (positive or negative) 
  /// Will only perform the update when the item is unlocked
  static Future<UserData> updateInventoryQuantity({
    required UserData userData,
    required String itemId,
    required int delta,
  }) async {
    final Map<String, dynamic> originalMap = userData.toFirestore();
    final itemInfo = _readInventoryInfo(originalMap, itemId);
    final bool isLocked = itemInfo['isLocked'] as bool;
    final int currentQty = itemInfo['quantity'] as int;

    if (isLocked) {
      throw Exception('Inventory item $itemId is locked and cannot be modified');
    }

    final int newQty = (currentQty + delta) < 0 ? 0 : (currentQty + delta);

    try {
      await userData.updateFields({'sproutProgress.inventory.$itemId.quantity': newQty});
    } catch (e) {
      throw Exception('Failed to persist inventory quantity update: $e');
    }

    try {
      final refreshed = await FirestoreService.getUserData(userData.uid, forceRefresh: true);
      if (refreshed != null) return refreshed;
    } catch (e) {
      debugPrint('Failed to refresh user data after updating inventory quantity: $e');
    }

    return userData.copyWith({'sproutProgress.inventory.$itemId.quantity': newQty});
  }

  /// Return a new copy of the userData map with updated inventory item quantity
  static Map<String, dynamic> _withUpdatedInventoryQuantityMap(Map<String, dynamic> userData, String itemId, int newQty) {
    final newData = Map<String, dynamic>.from(userData);

    final sp = (userData['sproutProgress'] is Map<String, dynamic>)
        ? Map<String, dynamic>.from(userData['sproutProgress'] as Map<String, dynamic>)
        : <String, dynamic>{};

    final inventory = (sp['inventory'] is Map<String, dynamic>)
        ? Map<String, dynamic>.from(sp['inventory'] as Map<String, dynamic>)
        : <String, dynamic>{};

    final item = (inventory[itemId] is Map<String, dynamic>)
        ? Map<String, dynamic>.from(inventory[itemId] as Map<String, dynamic>)
        : <String, dynamic>{};

    item['quantity'] = newQty;
    inventory[itemId] = item;
    sp['inventory'] = inventory;
    newData['sproutProgress'] = sp;
    return newData;
  }

  /// Apply a delta to an inventory item's quantity in a plain userData map
  /// If the item is locked the original map is returned unchanged
  static Map<String, dynamic> applyInventoryQuantityDelta(Map<String, dynamic> userData, String itemId, int delta) {
    final sp = userData['sproutProgress'] as Map<String, dynamic>?;
    final inventory = sp != null ? (sp['inventory'] as Map<String, dynamic>?) : null;
    final item = (inventory != null) ? (inventory[itemId] as Map<String, dynamic>?) : null;

    final bool isLocked = item != null && item['isLocked'] is bool ? item['isLocked'] as bool : true;
    final int currentQty = item != null && item['quantity'] is num ? (item['quantity'] as num).toInt() : 0;

    if (isLocked) {
      // Locked: do not modify
      return userData;
    }

    int newQty = currentQty + delta;
    if (newQty < 0) newQty = 0;
    return _withUpdatedInventoryQuantityMap(userData, itemId, newQty);
  }

  /// Convenience helpers for add/subtract
  static Map<String, dynamic> addInventoryQuantity(Map<String, dynamic> userData, String itemId, int amount) {
    if (amount <= 0) return userData;
    return applyInventoryQuantityDelta(userData, itemId, amount);
  }

  static Map<String, dynamic> subtractInventoryQuantity(Map<String, dynamic> userData, String itemId, int amount) {
    if (amount <= 0) return userData;
    return applyInventoryQuantityDelta(userData, itemId, -amount);
  }

  /// Read inventory item info (isLocked, quantity) from a plain userData map
  static Map<String, Object> _readInventoryInfo(Map<String, dynamic> userData, String itemId) {
    final sp = userData['sproutProgress'] as Map<String, dynamic>?;
    final inventory = sp != null ? (sp['inventory'] as Map<String, dynamic>?) : null;
    final item = (inventory != null) ? (inventory[itemId] as Map<String, dynamic>?) : null;

    final bool isLocked = item != null && item['isLocked'] is bool ? item['isLocked'] as bool : true;
    final int qty = item != null && item['quantity'] is num ? (item['quantity'] as num).toInt() : 0;

    return {'isLocked': isLocked, 'quantity': qty};
  }
}
