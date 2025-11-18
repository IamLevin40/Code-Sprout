import 'package:flutter/foundation.dart';

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

/// Represents a single crop planted on a farm plot
class PlantedCrop {
  final CropType cropType;
  final bool isGrown; // True when ready to harvest
  final DateTime plantedAt;

  PlantedCrop({
    required this.cropType,
    this.isGrown = false,
    DateTime? plantedAt,
  }) : plantedAt = plantedAt ?? DateTime.now();

  PlantedCrop copyWith({
    CropType? cropType,
    bool? isGrown,
    DateTime? plantedAt,
  }) {
    return PlantedCrop(
      cropType: cropType ?? this.cropType,
      isGrown: isGrown ?? this.isGrown,
      plantedAt: plantedAt ?? this.plantedAt,
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
    return state == PlotState.tilled && crop == null;
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
        dronePosition = initialDronePosition ?? DronePosition(x: 0, y: 0);

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

    plot.crop = PlantedCrop(cropType: cropType);
    // Simulate instant growth for now (can be changed to time-based later)
    plot.crop = plot.crop!.copyWith(isGrown: true);
    notifyListeners();
    return true;
  }

  /// Harvest crop from current plot
  CropType? harvestCurrentPlot() {
    final plot = getCurrentPlot();
    if (plot == null) return null;

    if (!plot.canHarvest()) {
      debugPrint('Cannot harvest plot at (${plot.x}, ${plot.y})');
      return null;
    }

    final cropType = plot.crop!.cropType;
    plot.crop = null;
    plot.state = PlotState.normal; // Reset to normal after harvest
    notifyListeners();
    return cropType;
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
