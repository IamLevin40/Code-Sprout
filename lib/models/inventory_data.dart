import 'dart:convert';
import 'package:flutter/services.dart';

/// Model representing an inventory item from the inventory schema
class InventoryItem {
  final String id;
  final String name;
  final String icon;
  final int sellAmount;
  final bool isLockedByDefault;
  final int defaultQuantity;

  InventoryItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.sellAmount,
    required this.isLockedByDefault,
    required this.defaultQuantity,
  });

  factory InventoryItem.fromJson(String id, Map<String, dynamic> json) {
    return InventoryItem(
      id: id,
      name: json['name'] as String? ?? id,
      icon: json['icon'] as String,
      sellAmount: json['sell_amount'] as int? ?? 0,
      isLockedByDefault: _parseBooleanValue(json['is_locked']),
      defaultQuantity: _parseNumberValue(json['quantity']),
    );
  }

  static bool _parseBooleanValue(dynamic value) {
    if (value is bool) return value;

    if (value is String) {
      final normalized = value.trim().toLowerCase();

      // Accept exact patterns:
      if (normalized == "true") return true;
      if (normalized == "false") return false;

      // Accept "boolean (true)" or "boolean(true)" or "boolean    (false)"
      final match = RegExp(r'boolean\s*\(\s*(true|false)\s*\)')
          .firstMatch(normalized);

      if (match != null) {
        return match.group(1) == 'true';
      }
    }
    return false;
  }

  static int _parseNumberValue(dynamic value) {
    if (value is int) return value;
    if (value is String) {
      final match = RegExp(r'number \((\d+)\)').firstMatch(value);
      if (match != null) {
        return int.tryParse(match.group(1)!) ?? 0;
      }
    }
    return 0;
  }
}

/// Schema for inventory items loaded from schemas/inventory_schema.txt
class InventorySchema {
  final Map<String, InventoryItem> items;

  InventorySchema({required this.items});

  /// Load inventory schema from assets
  static Future<InventorySchema> load() async {
    try {
      final String schemaText = await rootBundle.loadString('schemas/inventory_schema.txt');
      final Map<String, dynamic> schemaJson = json.decode(schemaText);
      
      final itemsData = schemaJson['items'] as Map<String, dynamic>? ?? {};
      final Map<String, InventoryItem> items = {};
      
      itemsData.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          items[key] = InventoryItem.fromJson(key, value);
        }
      });
      
      return InventorySchema(items: items);
    } catch (e) {
      throw Exception('Failed to load inventory schema: $e');
    }
  }

  /// Get an inventory item by ID
  InventoryItem? getItem(String itemId) {
    return items[itemId];
  }

  /// Get icon path for any item (unified method for seeds and crops)
  String? getItemIcon(String itemId) {
    return items[itemId]?.icon;
  }

  /// Get display name for an item
  String? getItemName(String itemId) {
    return items[itemId]?.name;
  }

  /// Get all item IDs
  List<String> getAllItemIds() {
    return items.keys.toList();
  }

  /// Create default inventory structure for user data
  Map<String, dynamic> createDefaultInventory() {
    final Map<String, dynamic> inventory = {};
    
    items.forEach((id, item) {
      inventory[id] = {
        'isLocked': item.isLockedByDefault,
        'quantity': item.defaultQuantity,
      };
    });
    
    return inventory;
  }

  /// Check if an item exists in the schema
  bool hasItem(String itemId) {
    return items.containsKey(itemId);
  }
}
