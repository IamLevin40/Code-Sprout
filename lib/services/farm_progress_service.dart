import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/farm_data.dart';
import '../models/farm_data_schema.dart';

/// Service for managing farm grid progress in Firestore
/// Structure: users/[userId]/farmProgress/grid
class FarmProgressService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FarmDataSchema _schema = FarmDataSchema();

  /// Get farm progress document reference for a user
  static DocumentReference _getFarmProgressDoc(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('farmProgress')
        .doc('grid');
  }

  /// Save farm grid progress to Firestore
  /// Structure: {
  ///   "gridInfo": { "x": int, "y": int },
  ///   "dronePosition": { "x": int, "y": int },
  ///   "plotInfo": {
  ///     "(0,0)": { "plotState": "normal", "cropInfo": { "cropType": "wheat", "cropDuration": 6.5 } },
  ///     ...
  ///   }
  /// }
  static Future<void> saveFarmProgress({
    required String userId,
    required FarmState farmState,
  }) async {
    try {
      final docRef = _getFarmProgressDoc(userId);
      final data = farmStateToFirestore(farmState);
      await docRef.set(data);
    } catch (e) {
      throw Exception('Failed to save farm progress: $e');
    }
  }

  /// Load farm grid progress from Firestore
  /// Returns null if document doesn't exist
  static Future<Map<String, dynamic>?> loadFarmProgress({
    required String userId,
  }) async {
    try {
      final docRef = _getFarmProgressDoc(userId);
      final doc = await docRef.get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return doc.data() as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to load farm progress: $e');
    }
  }

  /// Load or create default farm progress
  static Future<Map<String, dynamic>> loadOrCreateFarmProgress({
    required String userId,
    int defaultGridWidth = 3,
    int defaultGridHeight = 3,
  }) async {
    try {
      final existing = await loadFarmProgress(userId: userId);

      if (existing != null) {
        return existing;
      }

      // Create default progress with empty grid
      final defaultProgress = createDefaultProgress(
        gridWidth: defaultGridWidth,
        gridHeight: defaultGridHeight,
      );

      // Save to Firestore
      final docRef = _getFarmProgressDoc(userId);
      await docRef.set(defaultProgress);

      return defaultProgress;
    } catch (e) {
      throw Exception('Failed to load or create farm progress: $e');
    }
  }

  /// Delete farm progress for a user
  static Future<void> deleteFarmProgress({
    required String userId,
  }) async {
    try {
      final docRef = _getFarmProgressDoc(userId);
      await docRef.delete();
    } catch (e) {
      throw Exception('Failed to delete farm progress: $e');
    }
  }

  /// Check if farm progress exists for a user
  static Future<bool> farmProgressExists({
    required String userId,
  }) async {
    try {
      final docRef = _getFarmProgressDoc(userId);
      final doc = await docRef.get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Convert FarmState to Firestore JSON format
  /// @visibleForTesting
  static Map<String, dynamic> farmStateToFirestore(FarmState farmState) {
    final plotInfo = <String, dynamic>{};

    // Build plotInfo map with coordinates as keys
    for (int y = 0; y < farmState.gridHeight; y++) {
      for (int x = 0; x < farmState.gridWidth; x++) {
        final plot = farmState.getPlot(x, y);
        if (plot != null) {
          final plotKey = '($x,$y)';
          plotInfo[plotKey] = plotToFirestore(plot);
        }
      }
    }

    return {
      'gridInfo': {
        'x': farmState.gridWidth,
        'y': farmState.gridHeight,
      },
      'dronePosition': {
        'x': farmState.dronePosition.x,
        'y': farmState.dronePosition.y,
      },
      'plotInfo': plotInfo,
    };
  }

  /// Convert a single FarmPlot to Firestore format
  /// @visibleForTesting
  static Map<String, dynamic> plotToFirestore(FarmPlot plot) {
    final result = <String, dynamic>{
      'plotState': plot.state.name,
    };

    // Add crop info if crop exists
    if (plot.crop != null) {
      final crop = plot.crop!;
      
      // Calculate crop duration in seconds (elapsed time since growth started)
      int cropDuration = 0;
      if (crop.growthStartedAt != null) {
        cropDuration = DateTime.now().difference(crop.growthStartedAt!).inSeconds;
        
        // Cap the duration at the maximum growth duration for optimization
        // No need to save duration beyond when the crop is fully grown
        cropDuration = _capCropDuration(crop.cropType.id, cropDuration);
      }

      result['cropInfo'] = {
        'cropType': crop.cropType.id,
        'cropDuration': cropDuration,
      };
    } else {
      // Empty cropInfo when no crop
      result['cropInfo'] = {};
    }

    return result;
  }

  /// Cap crop duration at the maximum growth duration from schema
  /// This improves performance by not saving durations beyond when crop is fully grown
  static int _capCropDuration(String cropTypeId, int duration) {
    try {
      // Try to get max duration from schema (may not be loaded yet in tests)
      final maxDuration = _schema.getGrowthDuration(cropTypeId);
      final maxDurationSeconds = maxDuration.ceil();
      
      if (duration > maxDurationSeconds) {
        return maxDurationSeconds;
      }
      return duration;
    } catch (e) {
      // If schema not loaded or fails, return uncapped duration (fail-safe)
      return duration;
    }
  }

  /// Create default farm progress structure
  /// @visibleForTesting
  static Map<String, dynamic> createDefaultProgress({
    required int gridWidth,
    required int gridHeight,
  }) {
    final plotInfo = <String, dynamic>{};

    // Create all plots in normal state with no crops
    for (int y = 0; y < gridHeight; y++) {
      for (int x = 0; x < gridWidth; x++) {
        final plotKey = '($x,$y)';
        plotInfo[plotKey] = {
          'plotState': PlotState.normal.name,
          'cropInfo': {},
        };
      }
    }

    return {
      'gridInfo': {
        'x': gridWidth,
        'y': gridHeight,
      },
      'dronePosition': {
        'x': 0,
        'y': 0,
      },
      'plotInfo': plotInfo,
    };
  }

  /// Apply loaded farm progress to a FarmState instance
  /// This restores grid size, drone position, plot states, and crop growth durations
  static void applyProgressToFarmState({
    required FarmState farmState,
    required Map<String, dynamic> progress,
  }) {
    try {
      // Extract grid info
      final gridInfo = progress['gridInfo'] as Map<String, dynamic>?;
      final dronePos = progress['dronePosition'] as Map<String, dynamic>?;
      final plotInfo = progress['plotInfo'] as Map<String, dynamic>?;

      if (gridInfo == null || dronePos == null || plotInfo == null) {
        throw Exception('Invalid farm progress structure');
      }

      // Restore drone position
      farmState.dronePosition.x = (dronePos['x'] as num?)?.toInt() ?? 0;
      farmState.dronePosition.y = (dronePos['y'] as num?)?.toInt() ?? 0;

      // Restore plot states and crops
      plotInfo.forEach((key, value) {
        final coords = parseCoordinates(key);
        if (coords == null) return;

        final x = coords[0];
        final y = coords[1];

        final plot = farmState.getPlot(x, y);
        if (plot == null) return;

        // Handle dynamic type from test data or Firestore
        final plotData = value is Map<String, dynamic> 
            ? value 
            : Map<String, dynamic>.from(value as Map);
        
        // Restore plot state
        final plotStateName = plotData['plotState'] as String?;
        if (plotStateName != null) {
          plot.state = parsePlotState(plotStateName);
        }

        // Restore crop if exists
        final cropInfoRaw = plotData['cropInfo'];
        final cropInfo = cropInfoRaw is Map<String, dynamic>
            ? cropInfoRaw
            : (cropInfoRaw != null ? Map<String, dynamic>.from(cropInfoRaw as Map) : null);
        if (cropInfo != null && cropInfo.isNotEmpty) {
          final cropTypeName = cropInfo['cropType'] as String?;
          final cropDuration = (cropInfo['cropDuration'] as num?)?.toInt() ?? 0;

          if (cropTypeName != null) {
            final cropType = CropTypeExtension.fromString(cropTypeName);
            if (cropType != null) {
              // Calculate when growth started based on saved duration (in seconds)
              DateTime? growthStartedAt;
              if (cropDuration > 0) {
                growthStartedAt = DateTime.now().subtract(
                  Duration(seconds: cropDuration),
                );
              }

              plot.crop = PlantedCrop(
                cropType: cropType,
                growthStartedAt: growthStartedAt,
              );
            }
          }
        }
      });
    } catch (e) {
      throw Exception('Failed to apply farm progress: $e');
    }
  }

  /// Parse coordinate string like "(0,1)" to [x, y]
  /// @visibleForTesting
  static List<int>? parseCoordinates(String coordStr) {
    try {
      // Remove parentheses and split by comma
      final cleaned = coordStr.replaceAll('(', '').replaceAll(')', '');
      final parts = cleaned.split(',');
      if (parts.length != 2) return null;

      final x = int.parse(parts[0].trim());
      final y = int.parse(parts[1].trim());
      return [x, y];
    } catch (e) {
      return null;
    }
  }

  /// Parse plot state from string to PlotState enum
  /// @visibleForTesting
  static PlotState parsePlotState(String stateName) {
    switch (stateName.toLowerCase()) {
      case 'tilled':
        return PlotState.tilled;
      case 'watered':
        return PlotState.watered;
      case 'normal':
      default:
        return PlotState.normal;
    }
  }

  /// Create a new FarmState instance from loaded progress
  /// Useful for initializing farm page with saved progress
  static FarmState createFarmStateFromProgress({
    required Map<String, dynamic> progress,
  }) {
    final gridInfo = progress['gridInfo'] as Map<String, dynamic>?;
    final dronePos = progress['dronePosition'] as Map<String, dynamic>?;

    final gridWidth = (gridInfo?['x'] as num?)?.toInt() ?? 3;
    final gridHeight = (gridInfo?['y'] as num?)?.toInt() ?? 3;
    final droneX = (dronePos?['x'] as num?)?.toInt() ?? 0;
    final droneY = (dronePos?['y'] as num?)?.toInt() ?? 0;

    // Create farm state with loaded dimensions
    final farmState = FarmState(
      gridWidth: gridWidth,
      gridHeight: gridHeight,
      initialDronePosition: DronePosition(x: droneX, y: droneY),
    );

    // Apply plot states and crops
    applyProgressToFarmState(farmState: farmState, progress: progress);

    return farmState;
  }
}
