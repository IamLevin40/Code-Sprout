import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'inventory_data.dart';

/// Crop research item from schema
class CropResearchItemSchema {
  final String id;
  final String icon;
  final String defaultName;
  final Map<String, String> languageSpecificName;
  final String description;
  final List<String> predecessorIds;
  final Map<String, int> requirements; // itemId -> quantity

  CropResearchItemSchema({
    required this.id,
    required this.icon,
    required this.defaultName,
    required this.languageSpecificName,
    required this.description,
    required this.predecessorIds,
    required this.requirements,
  });

  factory CropResearchItemSchema.fromJson(String id, Map<String, dynamic> json) {
    final Map<String, int> requirements = {};
    final reqData = json['requirements'] as Map<String, dynamic>? ?? {};
    reqData.forEach((key, value) {
      if (value is int) {
        requirements[key] = value;
      }
    });

    return CropResearchItemSchema(
      id: id,
      icon: json['icon'] as String? ?? '',
      defaultName: json['default_name'] as String? ?? id,
      languageSpecificName: Map<String, String>.from(
        json['language_specific_name'] as Map<String, dynamic>? ?? {},
      ),
      description: json['description'] as String? ?? '',
      predecessorIds: List<String>.from(json['predecessor_ids'] as List? ?? []),
      requirements: requirements,
    );
  }

  /// Get the display name for a specific language
  String getNameForLanguage(String? languageId) {
    if (languageId == null || languageId.isEmpty) {
      return defaultName;
    }
    return languageSpecificName[languageId] ?? defaultName;
  }
}

/// Farm research item from schema
class FarmResearchItemSchema {
  final String id;
  final String icon;
  final String name;
  final String description;
  final List<String> predecessorIds;
  final Map<String, int> requirements; // itemId -> quantity

  FarmResearchItemSchema({
    required this.id,
    required this.icon,
    required this.name,
    required this.description,
    required this.predecessorIds,
    required this.requirements,
  });

  factory FarmResearchItemSchema.fromJson(String id, Map<String, dynamic> json) {
    final Map<String, int> requirements = {};
    final reqData = json['requirements'] as Map<String, dynamic>? ?? {};
    reqData.forEach((key, value) {
      if (value is int) {
        requirements[key] = value;
      }
    });

    return FarmResearchItemSchema(
      id: id,
      icon: json['icon'] as String? ?? '',
      name: json['name'] as String? ?? id,
      description: json['description'] as String? ?? '',
      predecessorIds: List<String>.from(json['predecessor_ids'] as List? ?? []),
      requirements: requirements,
    );
  }
}

/// Functions research item from schema
class FunctionsResearchItemSchema {
  final String id;
  final String icon;
  final String name;
  final Map<String, String> languageSpecificDescription;
  final List<String> predecessorIds;
  final Map<String, int> requirements; // itemId -> quantity

  FunctionsResearchItemSchema({
    required this.id,
    required this.icon,
    required this.name,
    required this.languageSpecificDescription,
    required this.predecessorIds,
    required this.requirements,
  });

  factory FunctionsResearchItemSchema.fromJson(String id, Map<String, dynamic> json) {
    final Map<String, int> requirements = {};
    final reqData = json['requirements'] as Map<String, dynamic>? ?? {};
    reqData.forEach((key, value) {
      if (value is int) {
        requirements[key] = value;
      }
    });

    return FunctionsResearchItemSchema(
      id: id,
      icon: json['icon'] as String? ?? '',
      name: json['name'] as String? ?? id,
      languageSpecificDescription: Map<String, String>.from(
        json['language_specific_description'] as Map<String, dynamic>? ?? {},
      ),
      predecessorIds: List<String>.from(json['predecessor_ids'] as List? ?? []),
      requirements: requirements,
    );
  }

  /// Get the description for a specific language
  String getDescriptionForLanguage(String? languageId) {
    if (languageId == null || languageId.isEmpty) {
      return languageSpecificDescription.values.first;
    }
    return languageSpecificDescription[languageId] ?? 
           languageSpecificDescription.values.first;
  }
}

/// Schema loader for research items
class ResearchItemsSchema {
  static ResearchItemsSchema? _instance;
  
  Map<String, CropResearchItemSchema> _cropItems = {};
  Map<String, FarmResearchItemSchema> _farmItems = {};
  Map<String, FunctionsResearchItemSchema> _functionsItems = {};
  
  InventorySchema? _inventorySchema;

  ResearchItemsSchema._();

  static ResearchItemsSchema get instance {
    _instance ??= ResearchItemsSchema._();
    return _instance!;
  }

  /// Load all research schemas
  Future<void> loadSchemas() async {
    await Future.wait([
      _loadCropResearchSchema(),
      _loadFarmResearchSchema(),
      _loadFunctionsResearchSchema(),
      _loadInventorySchema(),
    ]);
  }

  Future<void> _loadCropResearchSchema() async {
    try {
      final String schemaText = await rootBundle.loadString(
        'schemas/researches/crop_research_items_schema.txt',
      );
      final Map<String, dynamic> schemaJson = json.decode(schemaText);
      
      final Map<String, CropResearchItemSchema> items = {};
      schemaJson.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          items[key] = CropResearchItemSchema.fromJson(key, value);
        }
      });
      
      _cropItems = items;
    } catch (e) {
      throw Exception('Failed to load crop research schema: $e');
    }
  }

  Future<void> _loadFarmResearchSchema() async {
    try {
      final String schemaText = await rootBundle.loadString(
        'schemas/researches/farm_research_items_schema.txt',
      );
      final Map<String, dynamic> schemaJson = json.decode(schemaText);
      
      final Map<String, FarmResearchItemSchema> items = {};
      schemaJson.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          items[key] = FarmResearchItemSchema.fromJson(key, value);
        }
      });
      
      _farmItems = items;
    } catch (e) {
      throw Exception('Failed to load farm research schema: $e');
    }
  }

  Future<void> _loadFunctionsResearchSchema() async {
    try {
      final String schemaText = await rootBundle.loadString(
        'schemas/researches/functions_research_items_schema.txt',
      );
      final Map<String, dynamic> schemaJson = json.decode(schemaText);
      
      final Map<String, FunctionsResearchItemSchema> items = {};
      schemaJson.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          items[key] = FunctionsResearchItemSchema.fromJson(key, value);
        }
      });
      
      _functionsItems = items;
    } catch (e) {
      throw Exception('Failed to load functions research schema: $e');
    }
  }

  Future<void> _loadInventorySchema() async {
    try {
      _inventorySchema = await InventorySchema.load();
    } catch (e) {
      throw Exception('Failed to load inventory schema: $e');
    }
  }

  /// Get all crop research items
  List<CropResearchItemSchema> getCropResearchItems() {
    return _cropItems.values.toList();
  }

  /// Get all farm research items
  List<FarmResearchItemSchema> getFarmResearchItems() {
    return _farmItems.values.toList();
  }

  /// Get all functions research items
  List<FunctionsResearchItemSchema> getFunctionsResearchItems() {
    return _functionsItems.values.toList();
  }

  /// Get crop research item by ID
  CropResearchItemSchema? getCropItem(String id) {
    return _cropItems[id];
  }

  /// Get farm research item by ID
  FarmResearchItemSchema? getFarmItem(String id) {
    return _farmItems[id];
  }

  /// Get functions research item by ID
  FunctionsResearchItemSchema? getFunctionsItem(String id) {
    return _functionsItems[id];
  }

  /// Get inventory icon for an item ID
  String? getInventoryIcon(String itemId) {
    return _inventorySchema?.getItemIcon(itemId);
  }

  /// Check if user has enough inventory items for requirements
  bool hasEnoughItems(Map<String, int> requirements, Map<String, dynamic> userData) {
    for (final entry in requirements.entries) {
      final itemId = entry.key;
      final required = entry.value;
      
      // Access inventory using the simplified path
      final inventoryPath = 'sproutProgress.inventory.$itemId.quantity';
      final available = _getNestedValue(userData, inventoryPath) as int? ?? 0;
      debugPrint('Checking item $itemId: required $required, available $available');
      
      if (available < required) {
        return false;
      }
    }
    return true;
  }

  /// Helper to get nested value from map using dot notation
  dynamic _getNestedValue(Map<String, dynamic> map, String path) {
    final keys = path.split('.');
    dynamic current = map;
    
    for (final key in keys) {
      if (current is Map) {
        current = current[key];
      } else {
        return null;
      }
    }
    
    return current;
  }
}
