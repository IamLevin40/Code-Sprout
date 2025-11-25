import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'inventory_data.dart';

/// Service class to handle farm data schema from farm_data_schema.txt
/// This provides centralized crop information management including growth durations,
/// harvest quantities, visual stages, and item icons
class FarmDataSchema {
  // Singleton pattern
  static final FarmDataSchema _instance = FarmDataSchema._internal();
  factory FarmDataSchema() => _instance;
  FarmDataSchema._internal();

  // Cache for loaded schema data
  Map<String, dynamic>? _schemaData;
  InventorySchema? _inventorySchema;

  /// Load farm data schema from the schema file
  Future<void> loadSchema() async {
    if (_schemaData != null) return; // Already loaded

    try {
      final String jsonString = await rootBundle.loadString('assets/schemas/farm_data_schema.txt');
      _schemaData = jsonDecode(jsonString);
      
      // Load inventory schema for icon lookups
      _inventorySchema = await InventorySchema.load();
    } catch (e) {
      throw Exception('Failed to load farm data schema: $e');
    }
  }

  /// Get crop info for a specific crop type
  /// Returns null if crop type doesn't exist
  Map<String, dynamic>? getCropInfo(String cropType) {
    if (_schemaData == null) {
      throw Exception('Farm data schema not loaded. Call loadSchema() first.');
    }

    final cropInfo = _schemaData!['crop_info'];
    if (cropInfo == null || cropInfo is! Map) {
      throw Exception('Invalid farm data schema: missing crop_info');
    }

    return cropInfo[cropType] as Map<String, dynamic>?;
  }

  /// Get item icon path for any item (unified method for seeds and crops)
  String getItemIcon(String itemId) {
    if (_inventorySchema == null) {
      throw Exception('Inventory schema not loaded. Call loadSchema() first.');
    }
    final icon = _inventorySchema!.getItemIcon(itemId);
    if (icon == null) {
      throw Exception('Item icon not found for: $itemId');
    }
    return icon;
  }

  /// Get growth duration in seconds for a crop type
  double getGrowthDuration(String cropType) {
    final info = getCropInfo(cropType);
    if (info == null) {
      throw Exception('Crop type not found: $cropType');
    }
    final duration = info['growth_duration'];
    if (duration is int) return duration.toDouble();
    return duration as double;
  }

  /// Get harvest quantity range for a crop type
  /// Returns a Map with 'min' and 'max' keys
  Map<String, int> getHarvestQuantity(String cropType) {
    final info = getCropInfo(cropType);
    if (info == null) {
      throw Exception('Crop type not found: $cropType');
    }
    final quantity = info['harvest_quantity'] as Map<String, dynamic>;
    return {
      'min': (quantity['min'] as num).toInt(),
      'max': (quantity['max'] as num).toInt(),
    };
  }

  /// Get a random harvest quantity for a crop type within its min-max range
  int getRandomHarvestQuantity(String cropType) {
    final quantity = getHarvestQuantity(cropType);
    final min = quantity['min']!;
    final max = quantity['max']!;
    if (min == max) return min;
    return min + Random().nextInt(max - min + 1);
  }

  /// Get crop stages map for a crop type
  /// Returns a Map<String, String> where keys are stage numbers and values are image paths
  Map<String, String> getCropStages(String cropType) {
    final info = getCropInfo(cropType);
    if (info == null) {
      throw Exception('Crop type not found: $cropType');
    }
    final stages = info['crop_stages'] as Map<String, dynamic>;
    return stages.map((key, value) => MapEntry(key, 'assets/${value as String}'));
  }

  /// Get the total number of stages for a crop type
  int getStageCount(String cropType) {
    return getCropStages(cropType).length;
  }

  /// Get the image path for a specific stage of a crop
  /// stageIndex is 1-based (1, 2, 3, ...)
  String getStageImage(String cropType, int stageIndex) {
    final stages = getCropStages(cropType);
    final key = stageIndex.toString();
    if (!stages.containsKey(key)) {
      throw Exception('Stage $stageIndex not found for crop type: $cropType');
    }
    return stages[key]!;
  }

  /// Calculate which stage a crop should be at based on elapsed time
  /// Returns a 1-based stage index
  /// 
  /// Example: if growthDuration is 10 seconds and there are 6 stages:
  /// - Stage 1: 0 seconds
  /// - Stage 2: 2 seconds  
  /// - Stage 3: 4 seconds
  /// - Stage 4: 6 seconds
  /// - Stage 5: 8 seconds
  /// - Stage 6: 10 seconds (fully grown)
  int calculateCurrentStage(String cropType, Duration elapsedTime) {
    final growthDuration = getGrowthDuration(cropType);
    final stageCount = getStageCount(cropType);
    
    final elapsedSeconds = elapsedTime.inMilliseconds / 1000.0;
    
    // If time exceeds growth duration, return final stage
    if (elapsedSeconds >= growthDuration) {
      return stageCount;
    }
    
    // Calculate stage based on elapsed time
    // Stage transitions are evenly distributed across the growth duration
    final stageProgress = elapsedSeconds / growthDuration;
    final stage = (stageProgress * (stageCount - 1)).floor() + 1;
    
    return stage.clamp(1, stageCount);
  }

  /// Get the duration in seconds for when a specific stage begins
  /// Returns the start time for a given stage (1-based index)
  double getStageStartTime(String cropType, int stageIndex) {
    final growthDuration = getGrowthDuration(cropType);
    final stageCount = getStageCount(cropType);
    
    if (stageIndex < 1 || stageIndex > stageCount) {
      throw Exception('Invalid stage index: $stageIndex for crop type: $cropType');
    }
    
    // Stage 1 always starts at 0
    if (stageIndex == 1) return 0.0;
    
    // Calculate evenly distributed stage times
    return growthDuration * (stageIndex - 1) / (stageCount - 1);
  }

  /// Check if a crop is fully grown based on elapsed time
  bool isFullyGrown(String cropType, Duration elapsedTime) {
    final growthDuration = getGrowthDuration(cropType);
    return elapsedTime.inMilliseconds / 1000.0 >= growthDuration;
  }

  /// Get drone work duration for a specific operation
  /// Returns duration in milliseconds, or null if not found
  int? getDroneWorkDuration(String operation) {
    if (_schemaData == null) {
      throw Exception('Farm data schema not loaded. Call loadSchema() first.');
    }

    final droneWorkDuration = _schemaData!['drone_work_duration'];
    if (droneWorkDuration == null || droneWorkDuration is! Map) {
      return null; // Schema doesn't have drone_work_duration section
    }

    final duration = droneWorkDuration[operation];
    if (duration is int) return duration;
    if (duration is double) return duration.toInt();
    return null;
  }

  /// Get all available crop types
  List<String> getAllCropTypes() {
    if (_schemaData == null) {
      throw Exception('Farm data schema not loaded. Call loadSchema() first.');
    }

    final cropInfo = _schemaData!['crop_info'];
    if (cropInfo == null || cropInfo is! Map) {
      throw Exception('Invalid farm data schema: missing crop_info');
    }

    return cropInfo.keys.cast<String>().toList();
  }

  /// Validate that all required fields exist for all crops
  bool validateSchema() {
    try {
      final cropTypes = getAllCropTypes();
      
      for (final cropType in cropTypes) {
        final info = getCropInfo(cropType);
        if (info == null) return false;
        
        // Check required fields (item_icon and seed_icon are now in inventory schema)
        if (!info.containsKey('growth_duration')) return false;
        if (!info.containsKey('harvest_quantity')) return false;
        if (!info.containsKey('crop_stages')) return false;
        
        // Validate harvest_quantity structure
        final quantity = info['harvest_quantity'];
        if (quantity is! Map) return false;
        if (!quantity.containsKey('min') || !quantity.containsKey('max')) return false;
        
        // Validate crop_stages structure
        final stages = info['crop_stages'];
        if (stages is! Map || stages.isEmpty) return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Set schema data directly for testing purposes
  /// This bypasses asset loading which doesn't work in unit tests
  /// Not intended for production use
  void setSchemaForTesting(Map<String, dynamic> data) {
    _schemaData = data;
  }
}
