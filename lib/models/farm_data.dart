import 'dart:async';
import 'package:flutter/foundation.dart';
import 'farm_data_schema.dart';

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

  FarmState({
    this.gridWidth = 3,
    this.gridHeight = 3,
    DronePosition? initialDronePosition,
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

  /// Plant a crop on the current plot
  bool plantCrop(CropType cropType) {
    final plot = getCurrentPlot();
    if (plot == null) return false;

    if (!plot.canPlant()) {
      debugPrint('Cannot plant on plot at (${plot.x}, ${plot.y})');
      return false;
    }

    // If planting on a watered plot, start growth immediately.
    if (plot.state == PlotState.watered) {
      plot.crop = PlantedCrop(cropType: cropType, growthStartedAt: DateTime.now());
    } else {
      // Planting on tilled plot: crop exists but growth hasn't started yet
      plot.crop = PlantedCrop(cropType: cropType, growthStartedAt: null);
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

  /// Set execution state
  void setExecuting(bool executing) {
    isExecuting = executing;
    notifyListeners();
  }
}
