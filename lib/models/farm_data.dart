import 'dart:async';
import 'package:flutter/foundation.dart';
import 'farm_data_schema.dart';
import 'user_data.dart';
import '../services/local_storage_service.dart';

/// Enum representing the state of a farm plot
enum PlotState {
  normal,   // Default untilled soil
  tilled,   // Tilled and ready for planting
  watered,  // Watered (either tilled or with crop)
}

/// Enum representing crop types that can be planted
enum CropType {
  wheat,
  carrot,
  potato,
  beetroot,
  radish,
  onion,
  lettuce,
  tomato,
  garlic,
}

/// Enum representing seed types that can be planted
// ignore: constant_identifier_names
enum SeedType {
  wheat_seeds,
  carrot_seeds,
  potato_seeds,
  beetroot_seeds,
  radish_seeds,
  onion_seeds,
  lettuce_seeds,
  tomato_seeds,
  garlic_seeds,
}

/// Enum representing cardinal directions for drone movement
enum Direction {
  north,
  south,
  east,
  west,
}

/// Extension to get string representation of crop type matching user data schema
extension CropTypeExtension on CropType {
  String get id {
    switch (this) {
      case CropType.wheat:
        return 'wheat';
      case CropType.carrot:
        return 'carrot';
      case CropType.potato:
        return 'potato';
      case CropType.beetroot:
        return 'beetroot';
      case CropType.radish:
        return 'radish';
      case CropType.onion:
        return 'onion';
      case CropType.lettuce:
        return 'lettuce';
      case CropType.tomato:
        return 'tomato';
      case CropType.garlic:
        return 'garlic';
    }
  }

  String get displayName {
    return id[0].toUpperCase() + id.substring(1);
  }

  static CropType? fromString(String value) {
    final lower = value.toLowerCase();
    for (final crop in CropType.values) {
      if (crop.id == lower) return crop;
    }
    return null;
  }
}

/// Extension to get string representation of seed type matching user data schema
extension SeedTypeExtension on SeedType {
  String get id {
    switch (this) {
      case SeedType.wheat_seeds:
        return 'wheat_seeds';
      case SeedType.carrot_seeds:
        return 'carrot_seeds';
      case SeedType.potato_seeds:
        return 'potato_seeds';
      case SeedType.beetroot_seeds:
        return 'beetroot_seeds';
      case SeedType.radish_seeds:
        return 'radish_seeds';
      case SeedType.onion_seeds:
        return 'onion_seeds';
      case SeedType.lettuce_seeds:
        return 'lettuce_seeds';
      case SeedType.tomato_seeds:
        return 'tomato_seeds';
      case SeedType.garlic_seeds:
        return 'garlic_seeds';
    }
  }

  String get displayName {
    // Convert snake_case to display name (e.g., wheat_seeds -> Wheat Seeds)
    final base = id.replaceAll('_seeds', '');
    return '${base[0].toUpperCase()}${base.substring(1)} Seeds';
  }

  /// Get the corresponding CropType for this seed
  CropType get cropType {
    switch (this) {
      case SeedType.wheat_seeds:
        return CropType.wheat;
      case SeedType.carrot_seeds:
        return CropType.carrot;
      case SeedType.potato_seeds:
        return CropType.potato;
      case SeedType.beetroot_seeds:
        return CropType.beetroot;
      case SeedType.radish_seeds:
        return CropType.radish;
      case SeedType.onion_seeds:
        return CropType.onion;
      case SeedType.lettuce_seeds:
        return CropType.lettuce;
      case SeedType.tomato_seeds:
        return CropType.tomato;
      case SeedType.garlic_seeds:
        return CropType.garlic;
    }
  }

  /// Get the crop id for referencing in farm_data_schema
  String get cropId {
    return cropType.id;
  }

  /// Get SeedType from string
  static SeedType? fromString(String value) {
    // Match exact ID with snake_case
    for (final seed in SeedType.values) {
      if (seed.id == value) return seed;
    }
    return null;
  }

  /// Get SeedType from CropType
  static SeedType? fromCropType(CropType cropType) {
    switch (cropType) {
      case CropType.wheat:
        return SeedType.wheat_seeds;
      case CropType.carrot:
        return SeedType.carrot_seeds;
      case CropType.potato:
        return SeedType.potato_seeds;
      case CropType.beetroot:
        return SeedType.beetroot_seeds;
      case CropType.radish:
        return SeedType.radish_seeds;
      case CropType.onion:
        return SeedType.onion_seeds;
      case CropType.lettuce:
        return SeedType.lettuce_seeds;
      case CropType.tomato:
        return SeedType.tomato_seeds;
      case CropType.garlic:
        return SeedType.garlic_seeds;
    }
  }
}

/// Represents a single crop planted on a farm plot with time-based growth
class PlantedCrop {
  final CropType cropType;
  final DateTime plantedAt;
  DateTime? growthStartedAt;
  final FarmDataSchema _schema = FarmDataSchema();

  PlantedCrop({
    required this.cropType,
    DateTime? plantedAt,
    this.growthStartedAt,
  }) : plantedAt = plantedAt ?? DateTime.now();

  /// Get elapsed time since growth started. If growth hasn't started yet,
  /// elapsed time is zero.
  Duration get elapsedTime {
    if (growthStartedAt == null) return Duration.zero;
    return DateTime.now().difference(growthStartedAt!);
  }

  /// Check if crop is fully grown and ready to harvest
  bool get isGrown {
    // Not grown if growth hasn't started
    if (growthStartedAt == null) return false;
    return _schema.isFullyGrown(cropType.id, elapsedTime);
  }

  /// Get current growth stage (1-based index)
  int get currentStage {
    // If growth hasn't started, show stage 1
    if (growthStartedAt == null) return 1;
    return _schema.calculateCurrentStage(cropType.id, elapsedTime);
  }

  /// Get total number of stages for this crop
  int get totalStages {
    return _schema.getStageCount(cropType.id);
  }

  /// Get image path for current growth stage
  String get currentStageImage {
    return _schema.getStageImage(cropType.id, currentStage);
  }

  /// Get growth progress as percentage (0.0 to 1.0)
  double get growthProgress {
    final duration = _schema.getGrowthDuration(cropType.id);
    final elapsed = elapsedTime.inMilliseconds / 1000.0;
    return (elapsed / duration).clamp(0.0, 1.0);
  }

  /// Get remaining time until fully grown
  Duration get remainingTime {
    final duration = _schema.getGrowthDuration(cropType.id);
    final elapsed = elapsedTime.inMilliseconds / 1000.0;
    final remaining = duration - elapsed;
    if (remaining <= 0) return Duration.zero;
    return Duration(milliseconds: (remaining * 1000).round());
  }

  PlantedCrop copyWith({
    CropType? cropType,
    DateTime? plantedAt,
    DateTime? growthStartedAt,
  }) {
    return PlantedCrop(
      cropType: cropType ?? this.cropType,
      plantedAt: plantedAt ?? this.plantedAt,
      growthStartedAt: growthStartedAt ?? this.growthStartedAt,
    );
  }
}

/// Represents a single farm plot in the grid
class FarmPlot {
  final int x;
  final int y;
  PlotState state;
  PlantedCrop? crop;

  FarmPlot({
    required this.x,
    required this.y,
    this.state = PlotState.normal,
    this.crop,
  });

  /// Check if plot can be tilled
  bool canTill() {
    return state == PlotState.normal && crop == null;
  }

  /// Check if plot can be watered
  bool canWater() {
    return state == PlotState.tilled || (crop != null && !crop!.isGrown);
  }

  /// Check if plot can be planted
  bool canPlant() {
    // Allow planting on both tilled and watered plots, but not on normal.
    return (state == PlotState.tilled || state == PlotState.watered) && crop == null;
  }

  /// Check if crop can be harvested
  bool canHarvest() {
    return crop != null && crop!.isGrown;
  }

  FarmPlot copyWith({
    PlotState? state,
    PlantedCrop? crop,
    bool clearCrop = false,
  }) {
    return FarmPlot(
      x: x,
      y: y,
      state: state ?? this.state,
      crop: clearCrop ? null : (crop ?? this.crop),
    );
  }
}

/// Represents the drone's position and state on the farm
class DronePosition {
  int x;
  int y;

  DronePosition({
    this.x = 0,
    this.y = 0,
  });

  DronePosition copyWith({int? x, int? y}) {
    return DronePosition(
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }

  @override
  String toString() => 'DronePosition($x, $y)';
}

/// Main farm state managing the grid and drone
class FarmState extends ChangeNotifier {
  final int gridWidth;
  final int gridHeight;
  final List<List<FarmPlot>> _grid;
  DronePosition dronePosition;
  bool isExecuting = false;
  Timer? _growthUpdateTimer;
  final FarmDataSchema _schema = FarmDataSchema();
  
  /// User data for inventory management (seeds and crops)
  UserData? userData;

  FarmState({
    this.gridWidth = 3,
    this.gridHeight = 3,
    DronePosition? initialDronePosition,
    this.userData,
  })  : _grid = List.generate(
          gridHeight,
          (y) => List.generate(
            gridWidth,
            (x) => FarmPlot(x: x, y: y),
          ),
        ),
        dronePosition = initialDronePosition ?? DronePosition(x: 0, y: 0) {
    // Start periodic growth update timer (updates every second)
    _startGrowthUpdateTimer();
  }

  /// Update user data reference
  void setUserData(UserData? data) {
    userData = data;
    try {
      if (data != null) LocalStorageService.instance.userDataNotifier.value = data;
    } catch (_) {}
    notifyListeners();
  }

  /// Start timer to periodically update crop growth states
  void _startGrowthUpdateTimer() {
    _growthUpdateTimer?.cancel();
    _growthUpdateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      // Check if any crops need visual update
      bool needsUpdate = false;
      for (final row in _grid) {
        for (final plot in row) {
          if (plot.crop != null) {
            needsUpdate = true;
            break;
          }
        }
        if (needsUpdate) break;
      }
      if (needsUpdate) {
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _growthUpdateTimer?.cancel();
    super.dispose();
  }

  /// Get plot at specific coordinates
  FarmPlot? getPlot(int x, int y) {
    if (x < 0 || x >= gridWidth || y < 0 || y >= gridHeight) {
      return null;
    }
    return _grid[y][x];
  }

  /// Get current plot where drone is positioned
  FarmPlot? getCurrentPlot() {
    return getPlot(dronePosition.x, dronePosition.y);
  }

  /// Get all plots as flat list
  List<FarmPlot> getAllPlots() {
    return _grid.expand((row) => row).toList();
  }

  /// Move drone in a direction
  bool moveDrone(Direction direction) {
    int newX = dronePosition.x;
    int newY = dronePosition.y;

    switch (direction) {
      case Direction.north:
        newY = dronePosition.y + 1;
        break;
      case Direction.south:
        newY = dronePosition.y - 1;
        break;
      case Direction.east:
        newX = dronePosition.x + 1;
        break;
      case Direction.west:
        newX = dronePosition.x - 1;
        break;
    }

    // Check if new position is valid
    if (newX < 0 || newX >= gridWidth || newY < 0 || newY >= gridHeight) {
      debugPrint('Cannot move drone out of bounds: ($newX, $newY)');
      return false;
    }

    dronePosition.x = newX;
    dronePosition.y = newY;
    notifyListeners();
    return true;
  }

  /// Till the current plot
  bool tillCurrentPlot() {
    final plot = getCurrentPlot();
    if (plot == null) return false;

    if (!plot.canTill()) {
      debugPrint('Cannot till plot at (${plot.x}, ${plot.y})');
      return false;
    }

    plot.state = PlotState.tilled;

    // If a crop exists on the plot, reset its growth (stage restarts to 1)
    if (plot.crop != null) {
      plot.crop!.growthStartedAt = null;
    }

    notifyListeners();
    return true;
  }

  /// Water the current plot
  bool waterCurrentPlot() {
    final plot = getCurrentPlot();
    if (plot == null) return false;

    if (!plot.canWater()) {
      debugPrint('Cannot water plot at (${plot.x}, ${plot.y})');
      return false;
    }

    plot.state = PlotState.watered;

    // If there's a crop planted and growth hasn't started yet, start growth now
    if (plot.crop != null && plot.crop!.growthStartedAt == null) {
      plot.crop!.growthStartedAt = DateTime.now();
    }

    notifyListeners();
    return true;
  }

  /// Plant a seed on the current plot (requires seed in inventory)
  bool plantSeed(SeedType seedType) {
    final plot = getCurrentPlot();
    if (plot == null) return false;

    if (!plot.canPlant()) {
      debugPrint('Cannot plant on plot at (${plot.x}, ${plot.y})');
      return false;
    }

    // Check if user has at least one seed in inventory
    if (userData != null) {
      final seedQty = userData!.get('sproutProgress.inventory.${seedType.id}.quantity') as int? ?? 0;
      if (seedQty <= 0) {
        debugPrint('No ${seedType.displayName} in inventory');
        return false;
      }
    }

    // Convert seed type to crop type
    final cropType = seedType.cropType;

    // If planting on a watered plot, start growth immediately.
    if (plot.state == PlotState.watered) {
      plot.crop = PlantedCrop(cropType: cropType, growthStartedAt: DateTime.now());
    } else {
      // Planting on tilled plot: crop exists but growth hasn't started yet
      plot.crop = PlantedCrop(cropType: cropType, growthStartedAt: null);
    }
    
    // Decrease seed quantity in inventory if userData is available
    if (userData != null) {
      try {
        final base = Map<String, dynamic>.from(userData!.toJson());
        final parts = 'sproutProgress.inventory.${seedType.id}.quantity'.split('.');
        final currentQty = (userData!.get('sproutProgress.inventory.${seedType.id}.quantity') as int?) ?? 0;
        final newQty = (currentQty - 1).clamp(0, 1 << 30);
        _setNestedValue(base, parts, newQty);

        // Persist locally and remotely (fire-and-forget)
        _saveUserDataJson(base);
        // Update in-memory reference immediately for reads
        try {
          userData = UserData.fromJson(base);
          LocalStorageService.instance.userDataNotifier.value = userData!;
        } catch (_) {}
      } catch (e) {
        debugPrint('Failed to persist seed decrement: $e');
      }
    }
    
    notifyListeners();
    return true;
  }

  /// Harvest crop from current plot
  /// Returns a map with 'cropType' and 'quantity' on success, null on failure
  Map<String, dynamic>? harvestCurrentPlot() {
    final plot = getCurrentPlot();
    if (plot == null) return null;

    if (!plot.canHarvest()) {
      debugPrint('Cannot harvest plot at (${plot.x}, ${plot.y})');
      return null;
    }

    final cropType = plot.crop!.cropType;
    final quantity = _schema.getRandomHarvestQuantity(cropType.id);
    
    plot.crop = null;
    plot.state = PlotState.normal; // Reset to normal after harvest
    notifyListeners();

    // Persist harvested crop quantity into userData (increment)
    if (userData != null) {
      try {
        final base = Map<String, dynamic>.from(userData!.toJson());
        final parts = 'sproutProgress.inventory.${cropType.id}.quantity'.split('.');
        final currentQty = (userData!.get('sproutProgress.inventory.${cropType.id}.quantity') as int?) ?? 0;
        final newQty = currentQty + quantity;
        _setNestedValue(base, parts, newQty);

        _saveUserDataJson(base);
        try {
          userData = UserData.fromJson(base);
          LocalStorageService.instance.userDataNotifier.value = userData!;
        } catch (_) {}
      } catch (e) {
        debugPrint('Failed to persist harvest quantity: $e');
      }
    }

    return {
      'cropType': cropType,
      'quantity': quantity,
    };
  }

  /// Reset the entire farm to initial state
  void resetFarm() {
    for (var y = 0; y < gridHeight; y++) {
      for (var x = 0; x < gridWidth; x++) {
        _grid[y][x] = FarmPlot(x: x, y: y);
      }
    }
    dronePosition = DronePosition(x: 0, y: 0);
    isExecuting = false;
    notifyListeners();
  }

  /// Clear the entire farm and return crops as seeds to inventory
  /// All plots reset to normal state, drone returns to (0,0)
  /// Each crop is converted back to 1 seed and added to user's inventory
  void clearFarmToSeeds() {
    if (userData == null) {
      // If no user data, just reset the farm
      resetFarm();
      return;
    }

    try {
      final base = Map<String, dynamic>.from(userData!.toJson());
      
      // Count crops on each plot and convert to seeds
      for (var y = 0; y < gridHeight; y++) {
        for (var x = 0; x < gridWidth; x++) {
          final plot = _grid[y][x];
          
          // If plot has a crop, convert it to seed
          if (plot.crop != null) {
            final cropType = plot.crop!.cropType;
            final seedType = SeedTypeExtension.fromCropType(cropType);
            
            if (seedType != null) {
              // Get current seed quantity
              final parts = 'sproutProgress.inventory.${seedType.id}.quantity'.split('.');
              final currentQty = (userData!.get('sproutProgress.inventory.${seedType.id}.quantity') as int?) ?? 0;
              
              // Add 1 seed per crop
              final newQty = currentQty + 1;
              _setNestedValue(base, parts, newQty);
            }
          }
          
          // Reset plot to normal state
          _grid[y][x] = FarmPlot(x: x, y: y);
        }
      }
      
      // Reset drone position
      dronePosition = DronePosition(x: 0, y: 0);
      isExecuting = false;
      
      // Persist user data changes
      _saveUserDataJson(base);
      try {
        userData = UserData.fromJson(base);
        LocalStorageService.instance.userDataNotifier.value = userData!;
      } catch (_) {}
      
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to clear farm and convert crops to seeds: $e');
      // Fallback to simple reset if error occurs
      resetFarm();
    }
  }

  /// Set execution state
  void setExecuting(bool executing) {
    isExecuting = executing;
    notifyListeners();
  }

  /// Check if user has at least one seed of the specified type
  bool hasSeed(SeedType seedType) {
    if (userData == null) return false;
    final seedQty = userData!.get('sproutProgress.inventory.${seedType.id}.quantity') as int? ?? 0;
    return seedQty > 0;
  }

  /// Get the quantity of a specific seed type in inventory
  int getSeedInventoryCount(SeedType seedType) {
    if (userData == null) return 0;
    return userData!.get('sproutProgress.inventory.${seedType.id}.quantity') as int? ?? 0;
  }

  /// Get the quantity of a specific crop type in inventory
  int getCropInventoryCount(CropType cropType) {
    if (userData == null) return 0;
    return userData!.get('sproutProgress.inventory.${cropType.id}.quantity') as int? ?? 0;
  }

  /// Helper: set a nested value inside a Map given dot-separated path parts
  void _setNestedValue(Map<String, dynamic> map, List<String> parts, dynamic value) {
    Map<String, dynamic> current = map;
    for (var i = 0; i < parts.length - 1; i++) {
      final key = parts[i];
      if (current[key] == null || current[key] is! Map) {
        current[key] = <String, dynamic>{};
      }
      current = current[key] as Map<String, dynamic>;
    }
    current[parts.last] = value;
  }

  /// Helper: persist a full user JSON map locally and remotely, update notifier
  void _saveUserDataJson(Map<String, dynamic> base) {
    try {
      final newUser = UserData.fromJson(base);
      try {
        LocalStorageService.instance.userDataNotifier.value = newUser;
      } catch (_) {}

      // Save to local storage (may be async)
      try {
        LocalStorageService.instance.saveUserData(newUser).catchError((e) => debugPrint('saveUserData error: $e'));
      } catch (e) {
        debugPrint('Failed to call saveUserData: $e');
      }

      // Persist to remote in background
      Future(() async {
        try {
          await newUser.save();
        } catch (e) {
          debugPrint('UserData.save error: $e');
        }
      });
    } catch (e) {
      debugPrint('Failed to persist user data json: $e');
    }
  }
}
