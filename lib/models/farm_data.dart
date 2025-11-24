import 'dart:async';
import 'package:flutter/foundation.dart';
import 'farm_data_schema.dart';
import 'user_data.dart';
import 'research_items_schema.dart';
import 'rank_data.dart';
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

/// Enum representing drone operational states
enum DroneState {
  normal,   // Idle or moving
  tilling,  // Currently tilling soil
  watering, // Currently watering
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
  DroneState state;
  
  // Animated position for smooth transitions (used by UI)
  double animatedX;
  double animatedY;

  DronePosition({
    this.x = 0,
    this.y = 0,
    this.state = DroneState.normal,
  })  : animatedX = x.toDouble(),
        animatedY = y.toDouble();

  DronePosition copyWith({int? x, int? y, DroneState? state}) {
    return DronePosition(
      x: x ?? this.x,
      y: y ?? this.y,
      state: state ?? this.state,
    );
  }

  @override
  String toString() => 'DronePosition($x, $y, state: $state)';
}

/// Main farm state managing the grid and drone
class FarmState extends ChangeNotifier {
  int gridWidth;
  int gridHeight;
  List<List<FarmPlot>> _grid;
  DronePosition dronePosition;
  bool isExecuting = false;
  Timer? _growthUpdateTimer;
  final FarmDataSchema _schema = FarmDataSchema();
  
  /// User data for inventory management (seeds and crops)
  UserData? userData;
  
  /// Research state for checking planting and harvesting permissions
  /// This will be injected from farm_page to enable research-based restrictions
  dynamic researchState;
  
  /// Drone work durations from schema (in milliseconds)
  int get generalDuration => _schema.getDroneWorkDuration('general') ?? 200;
  int get moveDuration => _schema.getDroneWorkDuration('move(direction)') ?? 1000;
  int get tillDuration => _schema.getDroneWorkDuration('till()') ?? 600;
  int get waterDuration => _schema.getDroneWorkDuration('water()') ?? 1000;

  FarmState({
    this.gridWidth = 1,
    this.gridHeight = 1,
    DronePosition? initialDronePosition,
    this.userData,
    this.researchState,
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

  /// Calculate maximum grid size from completed farm researches
  /// Returns (maxX, maxY) based on farm_plot_grid conditions
  (int, int) _calculateMaxGridSize() {
    if (researchState == null) return (1, 1); // Default 1x1
    
    try {
      final completedResearches = (researchState as dynamic).completedFarmResearches as List<String>;
      int maxX = 1;
      int maxY = 1;
      
      for (final researchId in completedResearches) {
        final item = ResearchItemsSchema.instance.getFarmItem(researchId);
        if (item != null && item.conditionsUnlocked.containsKey('farm_plot_grid')) {
          final gridCondition = item.conditionsUnlocked['farm_plot_grid']!;
          final x = gridCondition['x'] ?? 1;
          final y = gridCondition['y'] ?? 1;
          if (x > maxX) maxX = x;
          if (y > maxY) maxY = y;
        }
      }
      
      return (maxX, maxY);
    } catch (e) {
      debugPrint('Error calculating max grid size: $e');
      return (1, 1);
    }
  }

  /// Calculate maximum water grid from completed farm researches
  /// Returns (maxX, maxY) based on water_grid conditions
  (int, int) _calculateMaxWaterGrid() {
    if (researchState == null) return (1, 1); // Default 1x1
    
    try {
      final completedResearches = (researchState as dynamic).completedFarmResearches as List<String>;
      int maxX = 1;
      int maxY = 1;
      
      for (final researchId in completedResearches) {
        final item = ResearchItemsSchema.instance.getFarmItem(researchId);
        if (item != null && item.conditionsUnlocked.containsKey('water_grid')) {
          final gridCondition = item.conditionsUnlocked['water_grid']!;
          final x = gridCondition['x'] ?? 1;
          final y = gridCondition['y'] ?? 1;
          if (x > maxX) maxX = x;
          if (y > maxY) maxY = y;
        }
      }
      
      return (maxX, maxY);
    } catch (e) {
      debugPrint('Error calculating max water grid: $e');
      return (1, 1);
    }
  }

  /// Calculate maximum till grid from completed farm researches
  /// Returns (maxX, maxY) based on till_grid conditions
  (int, int) _calculateMaxTillGrid() {
    if (researchState == null) return (1, 1); // Default 1x1
    
    try {
      final completedResearches = (researchState as dynamic).completedFarmResearches as List<String>;
      int maxX = 1;
      int maxY = 1;
      
      for (final researchId in completedResearches) {
        final item = ResearchItemsSchema.instance.getFarmItem(researchId);
        if (item != null && item.conditionsUnlocked.containsKey('till_grid')) {
          final gridCondition = item.conditionsUnlocked['till_grid']!;
          final x = gridCondition['x'] ?? 1;
          final y = gridCondition['y'] ?? 1;
          if (x > maxX) maxX = x;
          if (y > maxY) maxY = y;
        }
      }
      
      return (maxX, maxY);
    } catch (e) {
      debugPrint('Error calculating max till grid: $e');
      return (1, 1);
    }
  }

  /// Calculate maximum harvest grid from completed farm researches
  /// Returns (maxX, maxY) based on harvest_grid conditions
  (int, int) _calculateMaxHarvestGrid() {
    if (researchState == null) return (1, 1); // Default 1x1
    
    try {
      final completedResearches = (researchState as dynamic).completedFarmResearches as List<String>;
      int maxX = 1;
      int maxY = 1;
      
      for (final researchId in completedResearches) {
        final item = ResearchItemsSchema.instance.getFarmItem(researchId);
        if (item != null && item.conditionsUnlocked.containsKey('harvest_grid')) {
          final gridCondition = item.conditionsUnlocked['harvest_grid']!;
          final x = gridCondition['x'] ?? 1;
          final y = gridCondition['y'] ?? 1;
          if (x > maxX) maxX = x;
          if (y > maxY) maxY = y;
        }
      }
      
      return (maxX, maxY);
    } catch (e) {
      debugPrint('Error calculating max harvest grid: $e');
      return (1, 1);
    }
  }

  /// Calculate maximum plant grid from completed farm researches
  /// Returns (maxX, maxY) based on plant_grid conditions
  (int, int) _calculateMaxPlantGrid() {
    if (researchState == null) return (1, 1); // Default 1x1
    
    try {
      final completedResearches = (researchState as dynamic).completedFarmResearches as List<String>;
      int maxX = 1;
      int maxY = 1;
      
      for (final researchId in completedResearches) {
        final item = ResearchItemsSchema.instance.getFarmItem(researchId);
        if (item != null && item.conditionsUnlocked.containsKey('plant_grid')) {
          final gridCondition = item.conditionsUnlocked['plant_grid']!;
          final x = gridCondition['x'] ?? 1;
          final y = gridCondition['y'] ?? 1;
          if (x > maxX) maxX = x;
          if (y > maxY) maxY = y;
        }
      }
      
      return (maxX, maxY);
    } catch (e) {
      debugPrint('Error calculating max plant grid: $e');
      return (1, 1);
    }
  }

  /// Expand grid to new dimensions, preserving existing plots
  void expandGrid(int newWidth, int newHeight) {
    if (newWidth == gridWidth && newHeight == gridHeight) {
      return; // No change needed
    }
    
    // Create new grid
    final newGrid = List.generate(
      newHeight,
      (y) => List.generate(
        newWidth,
        (x) {
          // Preserve existing plots if within old bounds
          if (y < _grid.length && x < _grid[y].length) {
            return _grid[y][x];
          }
          // Create new plots for expanded areas
          return FarmPlot(x: x, y: y);
        },
      ),
    );
    
    _grid = newGrid;
    gridWidth = newWidth;
    gridHeight = newHeight;
    
    // Ensure drone is within new bounds
    if (dronePosition.x >= newWidth) dronePosition.x = newWidth - 1;
    if (dronePosition.y >= newHeight) dronePosition.y = newHeight - 1;
    
    notifyListeners();
  }

  /// Apply farm research conditions (grid expansion based on completed researches)
  void applyFarmResearchConditions() {
    final (maxX, maxY) = _calculateMaxGridSize();
    expandGrid(maxX, maxY);
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

  /// Move drone in a direction with animation support
  /// Returns true if move was successful, false if out of bounds
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

    // Update drone grid position
    dronePosition.x = newX;
    dronePosition.y = newY;
    dronePosition.state = DroneState.normal;
    notifyListeners();
    return true;
  }
  
  /// Animate drone movement with smooth transition (ease-in-out)
  /// This is called by the interpreter and includes the work duration delay
  Future<void> animateDroneMove(Direction direction) async {
    final startX = dronePosition.animatedX;
    final startY = dronePosition.animatedY;
    
    // Calculate target position based on direction
    int targetX = dronePosition.x;
    int targetY = dronePosition.y;
    
    switch (direction) {
      case Direction.north:
        targetY = dronePosition.y + 1;
        break;
      case Direction.south:
        targetY = dronePosition.y - 1;
        break;
      case Direction.east:
        targetX = dronePosition.x + 1;
        break;
      case Direction.west:
        targetX = dronePosition.x - 1;
        break;
    }
    
    // Check if target position is valid
    if (targetX < 0 || targetX >= gridWidth || targetY < 0 || targetY >= gridHeight) {
      return; // Move failed, don't animate
    }
    
    // Convert to double for animation
    final targetXDouble = targetX.toDouble();
    final targetYDouble = targetY.toDouble();
    
    // Animate over moveDuration milliseconds with ease-in-out
    final duration = moveDuration;
    const steps = 12;
    final stepDuration = duration ~/ steps;
    
    for (int i = 0; i <= steps; i++) {
      // Ease-in-out curve: t = t < 0.5 ? 2*t*t : -1 + (4 - 2*t)*t
      double t = i / steps;
      t = t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
      
      dronePosition.animatedX = startX + (targetXDouble - startX) * t;
      dronePosition.animatedY = startY + (targetYDouble - startY) * t;
      notifyListeners();
      
      if (i < steps) {
        await Future.delayed(Duration(milliseconds: stepDuration));
      }
    }
    
    // Update integer grid position only after animation completes
    dronePosition.x = targetX;
    dronePosition.y = targetY;
    dronePosition.animatedX = targetXDouble;
    dronePosition.animatedY = targetYDouble;
    dronePosition.state = DroneState.normal; // Reset state after move
    notifyListeners();
  }
  
  /// Set drone state and notify listeners
  void setDroneState(DroneState state) {
    if (dronePosition.state != state) {
      dronePosition.state = state;
      notifyListeners();
    }
  }

  /// Till the current plot (or area based on completed research)
  bool tillCurrentPlot() {
    final (tillWidth, tillHeight) = _calculateMaxTillGrid();
    
    // If till grid is 1x1, use simple single-plot logic
    if (tillWidth == 1 && tillHeight == 1) {
      var plot = getCurrentPlot();
      // If plot is null (drone positioned outside current grid), try to expand to include it
      if (plot == null) {
        final neededWidth = dronePosition.x + 1;
        final neededHeight = dronePosition.y + 1;
        final newWidth = neededWidth > gridWidth ? neededWidth : gridWidth;
        final newHeight = neededHeight > gridHeight ? neededHeight : gridHeight;
        if (newWidth != gridWidth || newHeight != gridHeight) {
          expandGrid(newWidth, newHeight);
        }
        plot = getCurrentPlot();
        if (plot == null) return false;
      }

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
    
    // Area tilling: center the area on drone position
    int tilledCount = 0;
    final centerX = dronePosition.x;
    final centerY = dronePosition.y;
    
    // Calculate area bounds (centered on drone)
    final halfWidth = tillWidth ~/ 2;
    final halfHeight = tillHeight ~/ 2;
    final startX = centerX - halfWidth;
    final startY = centerY - halfHeight;
    final endX = startX + tillWidth - 1;
    final endY = startY + tillHeight - 1;
    
    // Till all plots in the area
    for (int y = startY; y <= endY; y++) {
      for (int x = startX; x <= endX; x++) {
        final plot = getPlot(x, y);
        if (plot != null && plot.canTill()) {
          plot.state = PlotState.tilled;
          
          // If a crop exists on the plot, reset its growth
          if (plot.crop != null) {
            plot.crop!.growthStartedAt = null;
          }
          
          tilledCount++;
        }
      }
    }
    
    if (tilledCount > 0) {
      notifyListeners();
      return true;
    }
    
    debugPrint('No plots were tilled in the ${tillWidth}x$tillHeight area');
    return false;
  }

  /// Water the current plot (or area based on completed research)
  bool waterCurrentPlot() {
    final (waterWidth, waterHeight) = _calculateMaxWaterGrid();
    
    // If water grid is 1x1, use simple single-plot logic
    if (waterWidth == 1 && waterHeight == 1) {
      var plot = getCurrentPlot();
      // If the drone is outside grid, expand to include it so watering can proceed
      if (plot == null) {
        final neededWidth = dronePosition.x + 1;
        final neededHeight = dronePosition.y + 1;
        final newWidth = neededWidth > gridWidth ? neededWidth : gridWidth;
        final newHeight = neededHeight > gridHeight ? neededHeight : gridHeight;
        if (newWidth != gridWidth || newHeight != gridHeight) {
          expandGrid(newWidth, newHeight);
        }
        plot = getCurrentPlot();
        if (plot == null) return false;
      }

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
    
    // Area watering: center the area on drone position
    int wateredCount = 0;
    final centerX = dronePosition.x;
    final centerY = dronePosition.y;
    
    // Calculate area bounds (centered on drone)
    final halfWidth = waterWidth ~/ 2;
    final halfHeight = waterHeight ~/ 2;
    final startX = centerX - halfWidth;
    final startY = centerY - halfHeight;
    final endX = startX + waterWidth - 1;
    final endY = startY + waterHeight - 1;
    
    // Water all plots in the area
    for (int y = startY; y <= endY; y++) {
      for (int x = startX; x <= endX; x++) {
        final plot = getPlot(x, y);
        if (plot != null && plot.canWater()) {
          plot.state = PlotState.watered;
          
          // If there's a crop planted and growth hasn't started yet, start growth now
          if (plot.crop != null && plot.crop!.growthStartedAt == null) {
            plot.crop!.growthStartedAt = DateTime.now();
          }
          
          wateredCount++;
        }
      }
    }
    
    if (wateredCount > 0) {
      notifyListeners();
      return true;
    }
    
    debugPrint('No plots were watered in the ${waterWidth}x$waterHeight area');
    return false;
  }

  /// Check if seed type can be planted based on completed research
  bool _canPlantSeedType(String seedTypeId) {
    if (researchState == null) return true; // No restrictions if no research state
    
    try {
      // Check all completed crop researches for plant_enabled permissions
      final completedResearches = (researchState as dynamic).completedCropResearches as List<String>;
      
      // If no researches completed, deny planting
      if (completedResearches.isEmpty) {
        debugPrint('No crop researches completed, cannot plant $seedTypeId');
        return false;
      }
      
      // Try to use schema first, fall back to pattern matching if schema not loaded or returns null
      bool foundViaSchema = false;
      try {
        final schema = ResearchItemsSchema.instance;
        for (final researchId in completedResearches) {
          final cropResearch = schema.getCropItem(researchId);
          if (cropResearch != null) {
            if (cropResearch.plantEnabled.contains(seedTypeId)) {
              debugPrint('Seed $seedTypeId enabled by research $researchId via schema');
              return true; // Found a research that enables this seed type
            }
            foundViaSchema = true; // Schema returned data, don't use fallback
          }
        }
      } catch (e) {
        // Schema not loaded, will use fallback
        debugPrint('Schema error, using fallback pattern matching: $e');
      }
      
      // Fallback: derive expected seeds from research ID if schema returned null
      if (!foundViaSchema) {
        debugPrint('Schema returned null, using pattern matching for $seedTypeId');
        for (final researchId in completedResearches) {
          // crop_wheat -> enables wheat_seeds
          // crop_carrot -> enables carrot_seeds, etc.
          final cropName = researchId.replaceAll('crop_', '');
          final expectedSeedId = '${cropName}_seeds';
          if (seedTypeId == expectedSeedId) {
            debugPrint('Seed $seedTypeId enabled by research $researchId via pattern');
            return true;
          }
        }
      }
      
      debugPrint('Seed type $seedTypeId not enabled by any completed research');
      return false; // No research enables this seed type
    } catch (e) {
      debugPrint('Error checking plant permission: $e');
      return true; // On error, allow planting (fail-open)
    }
  }

  /// Generate priority-based planting positions: center → plus → cross → plus → cross ...
  List<(int, int)> _generatePlantingPriority(int centerX, int centerY, int areaWidth, int areaHeight) {
    final List<(int, int)> positions = [];
    
    final halfWidth = areaWidth ~/ 2;
    final halfHeight = areaHeight ~/ 2;
    
    // Add center position first
    positions.add((centerX, centerY));
    
    // Generate rings outward alternating between plus and cross patterns
    int ring = 1;
    bool usePlusPattern = true;
    
    while (ring <= halfWidth || ring <= halfHeight) {
      if (usePlusPattern) {
        // Plus pattern: cardinal directions (N, E, S, W)
        // North
        if (ring <= halfHeight) {
          for (int dx = -ring; dx <= ring; dx++) {
            if (dx == 0 || (ring <= halfWidth && dx.abs() <= halfWidth)) {
              positions.add((centerX + dx, centerY + ring));
            }
          }
        }
        // East
        if (ring <= halfWidth) {
          for (int dy = -ring + 1; dy < ring; dy++) {
            if (dy.abs() <= halfHeight) {
              positions.add((centerX + ring, centerY + dy));
            }
          }
        }
        // South
        if (ring <= halfHeight) {
          for (int dx = ring; dx >= -ring; dx--) {
            if (dx == 0 || (ring <= halfWidth && dx.abs() <= halfWidth)) {
              positions.add((centerX + dx, centerY - ring));
            }
          }
        }
        // West
        if (ring <= halfWidth) {
          for (int dy = -ring + 1; dy < ring; dy++) {
            if (dy.abs() <= halfHeight) {
              positions.add((centerX - ring, centerY + dy));
            }
          }
        }
      } else {
        // Cross pattern: intercardinal directions (NE, SE, SW, NW)
        if (ring <= halfWidth && ring <= halfHeight) {
          // NE diagonal
          positions.add((centerX + ring, centerY + ring));
          // SE diagonal
          positions.add((centerX + ring, centerY - ring));
          // SW diagonal
          positions.add((centerX - ring, centerY - ring));
          // NW diagonal
          positions.add((centerX - ring, centerY + ring));
        }
      }
      
      ring++;
      usePlusPattern = !usePlusPattern;
    }
    
    return positions;
  }

  /// Plant a seed on the current plot or area (requires seeds in inventory)
  /// Returns number of plots successfully planted
  int plantSeed(SeedType seedType) {
    final (plantWidth, plantHeight) = _calculateMaxPlantGrid();
    
    // Check if this seed type is enabled by research
    if (!_canPlantSeedType(seedType.id)) {
      debugPrint('Seed type ${seedType.id} not unlocked by research');
      return 0;
    }
    
    // Check available seeds
    int availableSeeds = 1 << 30; // Default to large number if no userData
    if (userData != null) {
      availableSeeds = userData!.get('sproutProgress.inventory.${seedType.id}.quantity') as int? ?? 0;
      if (availableSeeds <= 0) {
        debugPrint('No ${seedType.displayName} in inventory');
        return 0;
      }
    }
    
    // If plant grid is 1x1, use simple single-plot logic
    if (plantWidth == 1 && plantHeight == 1) {
      final plot = getCurrentPlot();
      if (plot == null) return 0;

      if (!plot.canPlant()) {
        debugPrint('Cannot plant on plot at (${plot.x}, ${plot.y})');
        return 0;
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
      return 1;
    }
    
    // Area planting with priority pattern
    final centerX = dronePosition.x;
    final centerY = dronePosition.y;
    
    // Generate priority-based positions
    final positions = _generatePlantingPriority(centerX, centerY, plantWidth, plantHeight);
    
    final cropType = seedType.cropType;
    int planted = 0;
    int seedsUsed = 0;
    
    // Plant in priority order until we run out of seeds or plantable plots
    for (final (x, y) in positions) {
      if (seedsUsed >= availableSeeds) break;
      
      final plot = getPlot(x, y);
      if (plot != null && plot.canPlant()) {
        // Plant the crop
        if (plot.state == PlotState.watered) {
          plot.crop = PlantedCrop(cropType: cropType, growthStartedAt: DateTime.now());
        } else {
          plot.crop = PlantedCrop(cropType: cropType, growthStartedAt: null);
        }
        
        planted++;
        seedsUsed++;
      }
    }
    
    if (planted == 0) {
      debugPrint('No plots planted in ${plantWidth}x$plantHeight area');
      return 0;
    }
    
    // Decrease seed quantity in inventory
    if (userData != null && seedsUsed > 0) {
      try {
        final base = Map<String, dynamic>.from(userData!.toJson());
        final parts = 'sproutProgress.inventory.${seedType.id}.quantity'.split('.');
        final currentQty = (userData!.get('sproutProgress.inventory.${seedType.id}.quantity') as int?) ?? 0;
        final newQty = (currentQty - seedsUsed).clamp(0, 1 << 30);
        _setNestedValue(base, parts, newQty);

        _saveUserDataJson(base);
        try {
          userData = UserData.fromJson(base);
          LocalStorageService.instance.userDataNotifier.value = userData!;
        } catch (_) {}
      } catch (e) {
        debugPrint('Failed to persist seed decrement: $e');
      }
    }
    
    notifyListeners();
    return planted;
  }

  /// Check if crop type can be harvested based on completed research
  bool _canHarvestCropType(String cropTypeId) {
    if (researchState == null) return true; // No restrictions if no research state
    
    try {
      // Check all completed crop researches for harvest_enabled permissions
      final completedCropResearches = (researchState as dynamic).completedCropResearches as List<String>;
      final completedFarmResearches = (researchState as dynamic).completedFarmResearches as List<String>;
      
      // If no researches at all completed, deny harvesting
      if (completedCropResearches.isEmpty && completedFarmResearches.isEmpty) {
        debugPrint('No researches completed, cannot harvest $cropTypeId');
        return false;
      }
      
      // Try to use schema first, fall back to pattern matching if schema not loaded or returns null
      bool foundViaSchema = false;
      try {
        final schema = ResearchItemsSchema.instance;
        // Check crop researches first
        for (final researchId in completedCropResearches) {
          final cropResearch = schema.getCropItem(researchId);
          if (cropResearch != null) {
            if (cropResearch.harvestEnabled.contains(cropTypeId)) {
              debugPrint('Crop $cropTypeId enabled by crop research $researchId via schema');
              return true; // Found a crop research that enables this crop type
            }
            foundViaSchema = true; // Schema returned data, don't use fallback for crop researches
          }
        }

        // If no crop-specific research allowed it but farm researches exist, allow harvesting
        if (completedFarmResearches.isNotEmpty) {
          debugPrint('Allowing harvest of $cropTypeId because farm research(s) completed: $completedFarmResearches');
          return true;
        }
      } catch (e) {
        // Schema not loaded, will use fallback
        debugPrint('Schema error, using fallback pattern matching: $e');
      }

      // Fallback: derive expected crop from completed crop research IDs if schema returned null
      if (!foundViaSchema && completedCropResearches.isNotEmpty) {
        debugPrint('Schema returned null, using pattern matching for $cropTypeId');
        for (final researchId in completedCropResearches) {
          // crop_wheat -> enables wheat
          final cropName = researchId.replaceAll('crop_', '');
          if (cropTypeId == cropName) {
            debugPrint('Crop $cropTypeId enabled by research $researchId via pattern');
            return true;
          }
        }
      }

      debugPrint('Crop type $cropTypeId not enabled by any completed research');
      return false; // No research enables this crop type
    } catch (e) {
      debugPrint('Error checking harvest permission: $e');
      return true; // On error, allow harvesting (fail-open)
    }
  }

  /// Harvest crop from current plot or area (based on harvest_grid research)
  /// Returns a map with 'cropType' and 'quantity' on success, null on failure
  Future<Map<String, dynamic>?> harvestCurrentPlot() async {
    final (harvestWidth, harvestHeight) = _calculateMaxHarvestGrid();
    
    // If harvest grid is 1x1, use simple single-plot logic
    if (harvestWidth == 1 && harvestHeight == 1) {
      final plot = getCurrentPlot();
      if (plot == null) return null;

      if (!plot.canHarvest()) {
        debugPrint('Cannot harvest plot at (${plot.x}, ${plot.y})');
        return null;
      }

      final cropType = plot.crop!.cropType;
      
      // Check if this crop type is enabled by research
      if (!_canHarvestCropType(cropType.id)) {
        debugPrint('Crop type ${cropType.id} not unlocked by research');
        return null;
      }
      
      final quantity = _schema.getRandomHarvestQuantity(cropType.id);
      
      plot.crop = null;
      plot.state = PlotState.normal; // Reset to normal after harvest
      notifyListeners();

      // Persist harvested crop quantity and award XP
      if (userData != null) {
        try {
          final base = Map<String, dynamic>.from(userData!.toJson());
          final parts = 'sproutProgress.inventory.${cropType.id}.quantity'.split('.');
          final currentQty = (userData!.get('sproutProgress.inventory.${cropType.id}.quantity') as int?) ?? 0;
          final newQty = currentQty + quantity;
          _setNestedValue(base, parts, newQty);

          // Award XP for harvesting this crop (per item harvested)
          try {
            final cropResearchId = 'crop_${cropType.id}';
            final cropResearch = ResearchItemsSchema.instance.getCropItem(cropResearchId);
            if (cropResearch != null && cropResearch.experienceGainPoints > 0) {
              final rankData = await RankData.load();
              final xpToAdd = cropResearch.experienceGainPoints * quantity;
              final updatedUserData = rankData.addExperiencePoints(base, xpToAdd);
              base.clear();
              base.addAll(updatedUserData);
            }
          } catch (e) {
            debugPrint('Failed to award XP for harvest: $e');
          }

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
    
    // Area harvesting: center on drone position
    final centerX = dronePosition.x;
    final centerY = dronePosition.y;
    
    final halfWidth = harvestWidth ~/ 2;
    final halfHeight = harvestHeight ~/ 2;
    final startX = centerX - halfWidth;
    final startY = centerY - halfHeight;
    final endX = startX + harvestWidth - 1;
    final endY = startY + harvestHeight - 1;
    
    // Harvest all harvestable crops in area
    final Map<String, int> harvestedCrops = {};
    int totalHarvested = 0;
    
    for (int y = startY; y <= endY; y++) {
      for (int x = startX; x <= endX; x++) {
        final plot = getPlot(x, y);
        if (plot != null && plot.canHarvest()) {
          final cropType = plot.crop!.cropType;
          
          // Check if this crop type is enabled by research
          if (_canHarvestCropType(cropType.id)) {
            final quantity = _schema.getRandomHarvestQuantity(cropType.id);
            
            // Accumulate harvested quantities by crop type
            harvestedCrops[cropType.id] = (harvestedCrops[cropType.id] ?? 0) + quantity;
            totalHarvested++;
            
            // Clear plot
            plot.crop = null;
            plot.state = PlotState.normal;
          }
        }
      }
    }
    
    if (totalHarvested == 0) {
      debugPrint('No crops harvested in ${harvestWidth}x$harvestHeight area');
      return null;
    }
    
    // Persist all harvested crops to userData and award XP
    if (userData != null) {
      try {
        final base = Map<String, dynamic>.from(userData!.toJson());
        
        int totalXP = 0;
        harvestedCrops.forEach((cropId, quantity) {
          final parts = 'sproutProgress.inventory.$cropId.quantity'.split('.');
          final currentQty = (userData!.get('sproutProgress.inventory.$cropId.quantity') as int?) ?? 0;
          final newQty = currentQty + quantity;
          _setNestedValue(base, parts, newQty);
          // Calculate XP for this crop type (XP per item harvested)
          try {
            final cropResearchId = 'crop_$cropId';
            final cropResearch = ResearchItemsSchema.instance.getCropItem(cropResearchId);
            if (cropResearch != null && cropResearch.experienceGainPoints > 0) {
              // Award XP per harvested item (multiply by quantity)
              totalXP += cropResearch.experienceGainPoints * quantity;
            }
          } catch (e) {
            debugPrint('Failed to calculate XP for $cropId: $e');
          }
        });

        // Award total XP
        if (totalXP > 0) {
          try {
            final rankData = await RankData.load();
            final updatedUserData = rankData.addExperiencePoints(base, totalXP);
            base.clear();
            base.addAll(updatedUserData);
          } catch (e) {
            debugPrint('Failed to award XP for area harvest: $e');
          }
        }

        _saveUserDataJson(base);
        try {
          userData = UserData.fromJson(base);
          LocalStorageService.instance.userDataNotifier.value = userData!;
        } catch (_) {}
      } catch (e) {
        debugPrint('Failed to persist harvest quantities: $e');
      }
    }
    
    notifyListeners();
    
    // Return summary (use first crop type for compatibility, include total quantity)
    final firstCropId = harvestedCrops.keys.first;
    final firstCropType = CropTypeExtension.fromString(firstCropId);
    return {
      'cropType': firstCropType,
      'quantity': harvestedCrops.values.reduce((a, b) => a + b),
      'harvestedCrops': harvestedCrops,
      'plotsHarvested': totalHarvested,
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
