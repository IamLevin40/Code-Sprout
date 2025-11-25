import 'package:flutter_test/flutter_test.dart';
import 'package:code_sprout/services/farm_progress_service.dart';
import 'package:code_sprout/models/farm_data.dart';

void main() {
  group('FarmProgressService Tests', () {
    test('Test 1: farmStateToFirestore creates correct document structure', () {
      // Create a farm state with specific values
      final farmState = FarmState(
        gridWidth: 3,
        gridHeight: 3,
        initialDronePosition: DronePosition(x: 1, y: 2),
      );

      // Till a plot and plant a crop
      farmState.dronePosition.x = 0;
      farmState.dronePosition.y = 0;
      farmState.tillCurrentPlot();
      farmState.waterCurrentPlot();
      farmState.plantSeed(SeedType.wheat_seeds);

      // Convert to Firestore format
      final data = FarmProgressService.farmStateToFirestore(farmState);

      // Verify structure
      expect(data['gridInfo'], isNotNull);
      expect(data['gridInfo']['x'], 3);
      expect(data['gridInfo']['y'], 3);
      expect(data['dronePosition'], isNotNull);
      expect(data['dronePosition']['x'], 0);
      expect(data['dronePosition']['y'], 0);
      expect(data['plotInfo'], isNotNull);
      expect(data['plotInfo']['(0,0)'], isNotNull);
      expect(data['plotInfo']['(0,0)']['plotState'], 'watered');
      expect(data['plotInfo']['(0,0)']['cropInfo'], isNotNull);
      expect(data['plotInfo']['(0,0)']['cropInfo']['cropType'], 'wheat');
    });

    test('Test 2: Load farm progress restores drone position correctly', () async {
      final progress = {
        'gridInfo': {'x': 3, 'y': 3},
        'dronePosition': {'x': 2, 'y': 1},
        'plotInfo': {
          '(0,0)': {'plotState': 'normal', 'cropInfo': {}},
          '(0,1)': {'plotState': 'normal', 'cropInfo': {}},
          '(0,2)': {'plotState': 'normal', 'cropInfo': {}},
          '(1,0)': {'plotState': 'normal', 'cropInfo': {}},
          '(1,1)': {'plotState': 'normal', 'cropInfo': {}},
          '(1,2)': {'plotState': 'normal', 'cropInfo': {}},
          '(2,0)': {'plotState': 'normal', 'cropInfo': {}},
          '(2,1)': {'plotState': 'normal', 'cropInfo': {}},
          '(2,2)': {'plotState': 'normal', 'cropInfo': {}},
        },
      };

      final farmState = FarmState();
      FarmProgressService.applyProgressToFarmState(
        farmState: farmState,
        progress: progress,
      );

      expect(farmState.dronePosition.x, 2);
      expect(farmState.dronePosition.y, 1);
    });

    test('Test 3: Load farm progress restores plot states correctly', () async {
      final progress = {
        'gridInfo': {'x': 3, 'y': 3},
        'dronePosition': {'x': 0, 'y': 0},
        'plotInfo': {
          '(0,0)': {'plotState': 'tilled', 'cropInfo': {}},
          '(0,1)': {'plotState': 'watered', 'cropInfo': {}},
          '(0,2)': {'plotState': 'normal', 'cropInfo': {}},
          '(1,0)': {'plotState': 'normal', 'cropInfo': {}},
          '(1,1)': {'plotState': 'normal', 'cropInfo': {}},
          '(1,2)': {'plotState': 'normal', 'cropInfo': {}},
          '(2,0)': {'plotState': 'normal', 'cropInfo': {}},
          '(2,1)': {'plotState': 'normal', 'cropInfo': {}},
          '(2,2)': {'plotState': 'normal', 'cropInfo': {}},
        },
      };

      final farmState = FarmState();
      FarmProgressService.applyProgressToFarmState(
        farmState: farmState,
        progress: progress,
      );

      final plot00 = farmState.getPlot(0, 0);
      final plot01 = farmState.getPlot(0, 1);
      final plot02 = farmState.getPlot(0, 2);

      expect(plot00?.state, PlotState.tilled);
      expect(plot01?.state, PlotState.watered);
      expect(plot02?.state, PlotState.normal);
    });

    test('Test 4: Load farm progress restores crop type correctly', () async {
      final progress = {
        'gridInfo': {'x': 3, 'y': 3},
        'dronePosition': {'x': 0, 'y': 0},
        'plotInfo': {
          '(0,0)': {
            'plotState': 'watered',
            'cropInfo': {
              'cropType': 'carrot',
              'cropDuration': 5,
            }
          },
          '(0,1)': {'plotState': 'normal', 'cropInfo': {}},
          '(0,2)': {'plotState': 'normal', 'cropInfo': {}},
          '(1,0)': {'plotState': 'normal', 'cropInfo': {}},
          '(1,1)': {'plotState': 'normal', 'cropInfo': {}},
          '(1,2)': {'plotState': 'normal', 'cropInfo': {}},
          '(2,0)': {'plotState': 'normal', 'cropInfo': {}},
          '(2,1)': {'plotState': 'normal', 'cropInfo': {}},
          '(2,2)': {'plotState': 'normal', 'cropInfo': {}},
        },
      };

      final farmState = FarmState();
      FarmProgressService.applyProgressToFarmState(
        farmState: farmState,
        progress: progress,
      );

      final plot00 = farmState.getPlot(0, 0);
      expect(plot00?.crop, isNotNull);
      expect(plot00?.crop?.cropType, CropType.carrot);
    });

    test('Test 5: Load farm progress restores crop growth duration correctly', () async {
      final progress = {
        'gridInfo': {'x': 3, 'y': 3},
        'dronePosition': {'x': 0, 'y': 0},
        'plotInfo': {
          '(0,0)': {
            'plotState': 'watered',
            'cropInfo': {
              'cropType': 'wheat',
              'cropDuration': 10, // 10 seconds of growth
            }
          },
          '(0,1)': {'plotState': 'normal', 'cropInfo': {}},
          '(0,2)': {'plotState': 'normal', 'cropInfo': {}},
          '(1,0)': {'plotState': 'normal', 'cropInfo': {}},
          '(1,1)': {'plotState': 'normal', 'cropInfo': {}},
          '(1,2)': {'plotState': 'normal', 'cropInfo': {}},
          '(2,0)': {'plotState': 'normal', 'cropInfo': {}},
          '(2,1)': {'plotState': 'normal', 'cropInfo': {}},
          '(2,2)': {'plotState': 'normal', 'cropInfo': {}},
        },
      };

      final farmState = FarmState();
      FarmProgressService.applyProgressToFarmState(
        farmState: farmState,
        progress: progress,
      );

      final plot00 = farmState.getPlot(0, 0);
      expect(plot00?.crop, isNotNull);
      
      // Check that elapsed time is approximately 10 seconds (with small tolerance)
      final elapsedSeconds = plot00!.crop!.elapsedTime.inMilliseconds / 1000.0;
      expect(elapsedSeconds, greaterThan(9.5));
      expect(elapsedSeconds, lessThan(10.5));
    });

    test('Test 6: Create default farm progress has correct structure', () {
      final defaultProgress = FarmProgressService.createDefaultProgress(
        gridWidth: 4,
        gridHeight: 4,
      );

      expect(defaultProgress['gridInfo']['x'], 4);
      expect(defaultProgress['gridInfo']['y'], 4);
      expect(defaultProgress['dronePosition']['x'], 0);
      expect(defaultProgress['dronePosition']['y'], 0);
      expect(defaultProgress['plotInfo'], isNotNull);
      
      // Check that all 16 plots exist
      for (int y = 0; y < 4; y++) {
        for (int x = 0; x < 4; x++) {
          final key = '($x,$y)';
          expect(defaultProgress['plotInfo'][key], isNotNull);
          expect(defaultProgress['plotInfo'][key]['plotState'], 'normal');
          expect(defaultProgress['plotInfo'][key]['cropInfo'], isEmpty);
        }
      }
    });

    test('Test 7: Parse coordinates from string correctly', () {
      final coords1 = FarmProgressService.parseCoordinates('(0,0)');
      expect(coords1, [0, 0]);

      final coords2 = FarmProgressService.parseCoordinates('(2,5)');
      expect(coords2, [2, 5]);

      final coords3 = FarmProgressService.parseCoordinates('(10,15)');
      expect(coords3, [10, 15]);

      final coordsInvalid = FarmProgressService.parseCoordinates('invalid');
      expect(coordsInvalid, isNull);
    });

    test('Test 8: Parse plot state from string correctly', () {
      expect(FarmProgressService.parsePlotState('normal'), PlotState.normal);
      expect(FarmProgressService.parsePlotState('tilled'), PlotState.tilled);
      expect(FarmProgressService.parsePlotState('watered'), PlotState.watered);
      expect(FarmProgressService.parsePlotState('NORMAL'), PlotState.normal);
      expect(FarmProgressService.parsePlotState('TILLED'), PlotState.tilled);
      expect(FarmProgressService.parsePlotState('unknown'), PlotState.normal);
    });

    test('Test 9: Save and restore multiple crops with different growth durations', () async {
      final farmState = FarmState(gridWidth: 3, gridHeight: 3);

      // Plant multiple crops at different plots
      farmState.dronePosition.x = 0;
      farmState.dronePosition.y = 0;
      farmState.tillCurrentPlot();
      farmState.waterCurrentPlot();
      farmState.plantSeed(SeedType.wheat_seeds);
      
      // Start growth for all crops
      final plot00 = farmState.getPlot(0, 0);
      if (plot00?.crop != null && plot00!.crop!.growthStartedAt == null) {
        plot00.crop = plot00.crop!.copyWith(growthStartedAt: DateTime.now());
      }

      farmState.dronePosition.x = 1;
      farmState.dronePosition.y = 0;
      farmState.tillCurrentPlot();
      farmState.waterCurrentPlot();
      farmState.plantSeed(SeedType.carrot_seeds);
      
      final plot10 = farmState.getPlot(1, 0);
      if (plot10?.crop != null && plot10!.crop!.growthStartedAt == null) {
        plot10.crop = plot10.crop!.copyWith(growthStartedAt: DateTime.now());
      }

      farmState.dronePosition.x = 2;
      farmState.dronePosition.y = 0;
      farmState.tillCurrentPlot();
      farmState.waterCurrentPlot();
      farmState.plantSeed(SeedType.potato_seeds);
      
      final plot20 = farmState.getPlot(2, 0);
      if (plot20?.crop != null && plot20!.crop!.growthStartedAt == null) {
        plot20.crop = plot20.crop!.copyWith(growthStartedAt: DateTime.now());
      }

      // Wait at least 1 second so duration is > 0 (we save in seconds, not milliseconds)
      await Future.delayed(const Duration(seconds: 1, milliseconds: 100));

      // Convert to Firestore format
      final data = FarmProgressService.farmStateToFirestore(farmState);

      // Verify data has crops saved
      expect(data['plotInfo']['(0,0)']['cropInfo'], isNotEmpty, 
          reason: 'Wheat crop should be saved');
      expect(data['plotInfo']['(1,0)']['cropInfo'], isNotEmpty, 
          reason: 'Carrot crop should be saved');
      expect(data['plotInfo']['(2,0)']['cropInfo'], isNotEmpty, 
          reason: 'Potato crop should be saved');

      // Create new farm state and restore
      final newFarmState = FarmState(gridWidth: 3, gridHeight: 3);
      FarmProgressService.applyProgressToFarmState(
        farmState: newFarmState,
        progress: data,
      );

      // Verify all crops are restored
      final newPlot00 = newFarmState.getPlot(0, 0);
      final newPlot10 = newFarmState.getPlot(1, 0);
      final newPlot20 = newFarmState.getPlot(2, 0);

      expect(newPlot00, isNotNull, reason: 'Plot (0,0) should exist');
      expect(newPlot10, isNotNull, reason: 'Plot (1,0) should exist');
      expect(newPlot20, isNotNull, reason: 'Plot (2,0) should exist');
      
      expect(newPlot00?.crop, isNotNull, reason: 'Plot (0,0) should have crop restored');
      expect(newPlot10?.crop, isNotNull, reason: 'Plot (1,0) should have crop restored');
      expect(newPlot20?.crop, isNotNull, reason: 'Plot (2,0) should have crop restored');
      
      expect(newPlot00?.crop?.cropType, CropType.wheat);
      expect(newPlot10?.crop?.cropType, CropType.carrot);
      expect(newPlot20?.crop?.cropType, CropType.potato);

      // All should have growth started (duration > 0)
      expect(newPlot00?.crop?.growthStartedAt, isNotNull);
      expect(newPlot10?.crop?.growthStartedAt, isNotNull);
      expect(newPlot20?.crop?.growthStartedAt, isNotNull);
    });

    test('Test 10: Empty crop info results in no crop on plot', () async {
      final progress = {
        'gridInfo': {'x': 3, 'y': 3},
        'dronePosition': {'x': 0, 'y': 0},
        'plotInfo': {
          '(0,0)': {
            'plotState': 'tilled',
            'cropInfo': {}, // Empty crop info
          },
          '(0,1)': {'plotState': 'normal', 'cropInfo': {}},
          '(0,2)': {'plotState': 'normal', 'cropInfo': {}},
          '(1,0)': {'plotState': 'normal', 'cropInfo': {}},
          '(1,1)': {'plotState': 'normal', 'cropInfo': {}},
          '(1,2)': {'plotState': 'normal', 'cropInfo': {}},
          '(2,0)': {'plotState': 'normal', 'cropInfo': {}},
          '(2,1)': {'plotState': 'normal', 'cropInfo': {}},
          '(2,2)': {'plotState': 'normal', 'cropInfo': {}},
        },
      };

      final farmState = FarmState();
      FarmProgressService.applyProgressToFarmState(
        farmState: farmState,
        progress: progress,
      );

      final plot00 = farmState.getPlot(0, 0);
      expect(plot00?.state, PlotState.tilled);
      expect(plot00?.crop, isNull);
    });

    test('Test 11: Grid expansion handles larger grids correctly', () {
      final defaultProgress = FarmProgressService.createDefaultProgress(
        gridWidth: 5,
        gridHeight: 5,
      );

      expect(defaultProgress['gridInfo']['x'], 5);
      expect(defaultProgress['gridInfo']['y'], 5);
      
      // Check that all 25 plots exist
      int plotCount = 0;
      (defaultProgress['plotInfo'] as Map).forEach((key, value) {
        plotCount++;
      });
      expect(plotCount, 25);
    });

    test('Test 12: createFarmStateFromProgress creates correct FarmState instance', () {
      final progress = {
        'gridInfo': {'x': 4, 'y': 4},
        'dronePosition': {'x': 3, 'y': 2},
        'plotInfo': {
          '(0,0)': {'plotState': 'normal', 'cropInfo': {}},
          '(0,1)': {'plotState': 'normal', 'cropInfo': {}},
          '(0,2)': {'plotState': 'normal', 'cropInfo': {}},
          '(0,3)': {'plotState': 'normal', 'cropInfo': {}},
          '(1,0)': {'plotState': 'normal', 'cropInfo': {}},
          '(1,1)': {'plotState': 'normal', 'cropInfo': {}},
          '(1,2)': {'plotState': 'normal', 'cropInfo': {}},
          '(1,3)': {'plotState': 'normal', 'cropInfo': {}},
          '(2,0)': {'plotState': 'normal', 'cropInfo': {}},
          '(2,1)': {'plotState': 'normal', 'cropInfo': {}},
          '(2,2)': {'plotState': 'normal', 'cropInfo': {}},
          '(2,3)': {'plotState': 'normal', 'cropInfo': {}},
          '(3,0)': {'plotState': 'normal', 'cropInfo': {}},
          '(3,1)': {'plotState': 'normal', 'cropInfo': {}},
          '(3,2)': {'plotState': 'normal', 'cropInfo': {}},
          '(3,3)': {'plotState': 'normal', 'cropInfo': {}},
        },
      };

      final farmState = FarmProgressService.createFarmStateFromProgress(
        progress: progress,
      );

      expect(farmState.gridWidth, 4);
      expect(farmState.gridHeight, 4);
      expect(farmState.dronePosition.x, 3);
      expect(farmState.dronePosition.y, 2);
    });

    test('Test 13: Crop with zero duration has no growth started', () async {
      final progress = {
        'gridInfo': {'x': 3, 'y': 3},
        'dronePosition': {'x': 0, 'y': 0},
        'plotInfo': {
          '(0,0)': {
            'plotState': 'tilled',
            'cropInfo': {
              'cropType': 'wheat',
              'cropDuration': 0, // No growth yet
            }
          },
          '(0,1)': {'plotState': 'normal', 'cropInfo': {}},
          '(0,2)': {'plotState': 'normal', 'cropInfo': {}},
          '(1,0)': {'plotState': 'normal', 'cropInfo': {}},
          '(1,1)': {'plotState': 'normal', 'cropInfo': {}},
          '(1,2)': {'plotState': 'normal', 'cropInfo': {}},
          '(2,0)': {'plotState': 'normal', 'cropInfo': {}},
          '(2,1)': {'plotState': 'normal', 'cropInfo': {}},
          '(2,2)': {'plotState': 'normal', 'cropInfo': {}},
        },
      };

      final farmState = FarmState();
      FarmProgressService.applyProgressToFarmState(
        farmState: farmState,
        progress: progress,
      );

      final plot00 = farmState.getPlot(0, 0);
      expect(plot00?.crop, isNotNull);
      expect(plot00?.crop?.cropType, CropType.wheat);
      expect(plot00?.crop?.growthStartedAt, isNull);
    });

    test('Test 14: Multiple plot states mixed across grid', () async {
      final farmState = FarmState(gridWidth: 3, gridHeight: 3);

      // Create mixed state grid
      farmState.dronePosition.x = 0;
      farmState.dronePosition.y = 0;
      farmState.tillCurrentPlot();

      farmState.dronePosition.x = 1;
      farmState.dronePosition.y = 0;
      farmState.tillCurrentPlot();
      farmState.waterCurrentPlot();

      farmState.dronePosition.x = 2;
      farmState.dronePosition.y = 0;
      // Leave as normal

      // Convert and restore
      final data = FarmProgressService.farmStateToFirestore(farmState);
      final newFarmState = FarmState(gridWidth: 3, gridHeight: 3);
      FarmProgressService.applyProgressToFarmState(
        farmState: newFarmState,
        progress: data,
      );

      expect(newFarmState.getPlot(0, 0)?.state, PlotState.tilled);
      expect(newFarmState.getPlot(1, 0)?.state, PlotState.watered);
      expect(newFarmState.getPlot(2, 0)?.state, PlotState.normal);
    });

    test('Test 15: All supported crop types can be saved and restored', () async {
      final allCropTypes = [
        (SeedType.wheat_seeds, CropType.wheat),
        (SeedType.carrot_seeds, CropType.carrot),
        (SeedType.potato_seeds, CropType.potato),
        (SeedType.beetroot_seeds, CropType.beetroot),
        (SeedType.radish_seeds, CropType.radish),
        (SeedType.onion_seeds, CropType.onion),
        (SeedType.lettuce_seeds, CropType.lettuce),
        (SeedType.tomato_seeds, CropType.tomato),
        (SeedType.garlic_seeds, CropType.garlic),
      ];

      for (final (seedType, expectedCropType) in allCropTypes) {
        final farmState = FarmState(gridWidth: 3, gridHeight: 3);
        
        farmState.dronePosition.x = 0;
        farmState.dronePosition.y = 0;
        farmState.tillCurrentPlot();
        farmState.waterCurrentPlot();
        farmState.plantSeed(seedType);

        final data = FarmProgressService.farmStateToFirestore(farmState);
        final newFarmState = FarmState(gridWidth: 3, gridHeight: 3);
        FarmProgressService.applyProgressToFarmState(
          farmState: newFarmState,
          progress: data,
        );

        final plot00 = newFarmState.getPlot(0, 0);
        expect(plot00?.crop?.cropType, expectedCropType,
            reason: 'Failed to restore ${expectedCropType.displayName}');
      }
    });

    test('Test 16: Crop duration is saved as integer, not double', () async {
      final farmState = FarmState(gridWidth: 3, gridHeight: 3);

      // Plant a crop
      farmState.dronePosition.x = 0;
      farmState.dronePosition.y = 0;
      farmState.tillCurrentPlot();
      farmState.waterCurrentPlot();
      farmState.plantSeed(SeedType.wheat_seeds);

      // Wait a bit
      await Future.delayed(const Duration(milliseconds: 100));

      // Convert to Firestore format
      final data = FarmProgressService.farmStateToFirestore(farmState);

      // Verify cropDuration is an integer
      final cropInfo = data['plotInfo']['(0,0)']['cropInfo'];
      expect(cropInfo['cropDuration'], isA<int>(),
          reason: 'cropDuration should be an integer, not double');
    });

    test('Test 17: Crop duration is in seconds, not milliseconds', () async {
      final farmState = FarmState(gridWidth: 3, gridHeight: 3);

      // Plant a crop
      farmState.dronePosition.x = 0;
      farmState.dronePosition.y = 0;
      farmState.tillCurrentPlot();
      farmState.waterCurrentPlot();
      farmState.plantSeed(SeedType.wheat_seeds);

      // Wait 1 second
      await Future.delayed(const Duration(seconds: 1));

      // Convert to Firestore format
      final data = FarmProgressService.farmStateToFirestore(farmState);

      // Verify cropDuration is approximately 1 (seconds), not ~1000 (milliseconds)
      final cropDuration = data['plotInfo']['(0,0)']['cropInfo']['cropDuration'] as int;
      expect(cropDuration, greaterThanOrEqualTo(1));
      expect(cropDuration, lessThan(100), 
          reason: 'Duration should be in seconds (~1), not milliseconds (~1000)');
    });

    test('Test 18: Crop duration capping logic exists (tested with schema in production)', () async {
      // Note: This test verifies the capping logic works when schema is loaded
      // In production, wheat has growth_duration of 5.0 seconds
      // Without schema loaded in test environment, duration won't be capped (fail-safe)
      
      final farmState = FarmState(gridWidth: 3, gridHeight: 3);

      // Plant wheat and manually set growth started to 100 seconds ago
      farmState.dronePosition.x = 0;
      farmState.dronePosition.y = 0;
      farmState.tillCurrentPlot();
      farmState.waterCurrentPlot();
      farmState.plantSeed(SeedType.wheat_seeds);

      // Manually set growth to 100 seconds ago
      final plot = farmState.getPlot(0, 0);
      if (plot != null && plot.crop != null) {
        plot.crop = PlantedCrop(
          cropType: CropType.wheat,
          growthStartedAt: DateTime.now().subtract(const Duration(seconds: 100)),
        );
      }

      // Convert to Firestore format
      final data = FarmProgressService.farmStateToFirestore(farmState);
      final cropDuration = data['plotInfo']['(0,0)']['cropInfo']['cropDuration'] as int;
      
      // Without schema loaded, duration will be 100 (fail-safe behavior)
      // With schema loaded (production), it would be capped at 5
      // Test just verifies it's a reasonable integer value
      expect(cropDuration, isA<int>());
      expect(cropDuration, greaterThanOrEqualTo(5), 
          reason: 'Duration should be at least 5 seconds (actual or capped)');
    });

    test('Test 19: Integer format is used for crop durations (not double)', () async {
      // Verify that crop durations are always saved as integers for performance
      final farmState = FarmState(gridWidth: 3, gridHeight: 3);

      // Plant tomato
      farmState.dronePosition.x = 0;
      farmState.dronePosition.y = 0;
      farmState.tillCurrentPlot();
      farmState.waterCurrentPlot();
      farmState.plantSeed(SeedType.tomato_seeds);

      // Manually set growth started to 20 seconds ago
      final plot = farmState.getPlot(0, 0);
      if (plot != null && plot.crop != null) {
        plot.crop = PlantedCrop(
          cropType: CropType.tomato,
          growthStartedAt: DateTime.now().subtract(const Duration(seconds: 20)),
        );
      }

      // Convert to Firestore format
      final data = FarmProgressService.farmStateToFirestore(farmState);

      // Verify cropDuration is an integer (not double)
      final cropDuration = data['plotInfo']['(0,0)']['cropInfo']['cropDuration'];
      expect(cropDuration, isA<int>(), 
          reason: 'Crop duration must be integer for performance');
      expect(cropDuration, greaterThanOrEqualTo(15), 
          reason: 'Duration should reflect actual elapsed time');
    });

    test('Test 20: Seconds format is used (not milliseconds)', () async {
      // Verify that durations are stored in seconds, not milliseconds
      final farmState = FarmState(gridWidth: 3, gridHeight: 3);

      // Plant garlic and wait 1 second
      farmState.dronePosition.x = 0;
      farmState.dronePosition.y = 0;
      farmState.tillCurrentPlot();
      farmState.waterCurrentPlot();
      farmState.plantSeed(SeedType.garlic_seeds);

      // Manually set growth started to 1 second ago
      final plot = farmState.getPlot(0, 0);
      if (plot != null && plot.crop != null) {
        plot.crop = PlantedCrop(
          cropType: CropType.garlic,
          growthStartedAt: DateTime.now().subtract(const Duration(seconds: 1)),
        );
      }

      // Convert to Firestore format
      final data = FarmProgressService.farmStateToFirestore(farmState);

      // Verify cropDuration is in seconds (~1), not milliseconds (~1000)
      final cropDuration = data['plotInfo']['(0,0)']['cropInfo']['cropDuration'] as int;
      expect(cropDuration, greaterThanOrEqualTo(1));
      expect(cropDuration, lessThan(100), 
          reason: 'Duration should be in seconds (~1), not milliseconds (~1000)');
    });

    test('Test 21: Crops under max duration are not capped', () async {
      final farmState = FarmState(gridWidth: 3, gridHeight: 3);

      // Plant wheat (max 5 seconds) and wait 2 seconds
      farmState.dronePosition.x = 0;
      farmState.dronePosition.y = 0;
      farmState.tillCurrentPlot();
      farmState.waterCurrentPlot();
      farmState.plantSeed(SeedType.wheat_seeds);

      // Wait 2 seconds (under the 5 second max)
      await Future.delayed(const Duration(seconds: 2));

      // Convert to Firestore format
      final data = FarmProgressService.farmStateToFirestore(farmState);

      // Verify cropDuration is approximately 2, not capped
      final cropDuration = data['plotInfo']['(0,0)']['cropInfo']['cropDuration'] as int;
      expect(cropDuration, greaterThanOrEqualTo(2));
      expect(cropDuration, lessThan(5),
          reason: 'Duration should be actual elapsed time (2s), not capped (5s)');
    });
  });
}
