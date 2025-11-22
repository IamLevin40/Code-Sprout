import 'package:flutter_test/flutter_test.dart';
import 'package:code_sprout/models/farm_data.dart';

void main() {
  // Initialize Flutter binding for tests that use UserData
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('Clear Farm Tests', () {
    test('Test 1: Clear farm without crops returns to initial state', () {
      final farmState = FarmState(gridWidth: 3, gridHeight: 3);

      // Till some plots but don't plant anything
      farmState.dronePosition.x = 0;
      farmState.dronePosition.y = 0;
      farmState.tillCurrentPlot();

      farmState.dronePosition.x = 1;
      farmState.dronePosition.y = 1;
      farmState.tillCurrentPlot();
      farmState.waterCurrentPlot();

      // Move drone to a different position
      farmState.dronePosition.x = 2;
      farmState.dronePosition.y = 2;

      // Clear the farm
      farmState.clearFarmToSeeds();

      // Verify all plots are back to normal
      for (int y = 0; y < 3; y++) {
        for (int x = 0; x < 3; x++) {
          final plot = farmState.getPlot(x, y);
          expect(plot?.state, PlotState.normal);
          expect(plot?.crop, isNull);
        }
      }

      // Verify drone is at (0,0)
      expect(farmState.dronePosition.x, 0);
      expect(farmState.dronePosition.y, 0);
    });

    test('Test 2: Clear farm with crops removes all crops from plots', () {
      final farmState = FarmState(gridWidth: 3, gridHeight: 3);

      // Manually add crops to plots (simulating planted crops)
      farmState.dronePosition.x = 0;
      farmState.dronePosition.y = 0;
      final plot00 = farmState.getCurrentPlot();
      if (plot00 != null) {
        plot00.state = PlotState.watered;
        plot00.crop = PlantedCrop(
          cropType: CropType.wheat,
          growthStartedAt: DateTime.now(),
        );
      }

      farmState.dronePosition.x = 1;
      farmState.dronePosition.y = 0;
      final plot10 = farmState.getCurrentPlot();
      if (plot10 != null) {
        plot10.state = PlotState.watered;
        plot10.crop = PlantedCrop(
          cropType: CropType.carrot,
          growthStartedAt: DateTime.now(),
        );
      }

      farmState.dronePosition.x = 0;
      farmState.dronePosition.y = 1;
      final plot01 = farmState.getCurrentPlot();
      if (plot01 != null) {
        plot01.state = PlotState.watered;
        plot01.crop = PlantedCrop(
          cropType: CropType.potato,
          growthStartedAt: DateTime.now(),
        );
      }

      // Verify crops exist before clearing
      expect(plot00?.crop, isNotNull);
      expect(plot10?.crop, isNotNull);
      expect(plot01?.crop, isNotNull);

      // Clear the farm
      farmState.clearFarmToSeeds();

      // Verify all plots are cleared
      for (int y = 0; y < 3; y++) {
        for (int x = 0; x < 3; x++) {
          final plot = farmState.getPlot(x, y);
          expect(plot?.state, PlotState.normal);
          expect(plot?.crop, isNull);
        }
      }
    });

    test('Test 3: Clear farm with multiple crops clears all plots', () {
      final farmState = FarmState(gridWidth: 3, gridHeight: 3);

      // Manually add 3 wheat crops
      for (int i = 0; i < 3; i++) {
        farmState.dronePosition.x = i;
        farmState.dronePosition.y = 0;
        final plot = farmState.getCurrentPlot();
        if (plot != null) {
          plot.state = PlotState.watered;
          plot.crop = PlantedCrop(
            cropType: CropType.wheat,
            growthStartedAt: DateTime.now(),
          );
        }
      }

      // Verify all 3 plots have wheat
      for (int i = 0; i < 3; i++) {
        final plot = farmState.getPlot(i, 0);
        expect(plot?.crop?.cropType, CropType.wheat);
      }

      // Clear the farm
      farmState.clearFarmToSeeds();

      // Verify all plots are cleared
      for (int i = 0; i < 3; i++) {
        final plot = farmState.getPlot(i, 0);
        expect(plot?.state, PlotState.normal);
        expect(plot?.crop, isNull);
      }
    });

    test('Test 4: Clear farm resets drone position to (0,0)', () {
      final farmState = FarmState(gridWidth: 5, gridHeight: 5);

      // Move drone to far corner
      farmState.dronePosition.x = 4;
      farmState.dronePosition.y = 4;

      expect(farmState.dronePosition.x, 4);
      expect(farmState.dronePosition.y, 4);

      // Clear the farm
      farmState.clearFarmToSeeds();

      // Verify drone is back at (0,0)
      expect(farmState.dronePosition.x, 0);
      expect(farmState.dronePosition.y, 0);
    });

    test('Test 5: Clear farm with mixed plot states resets all to normal', () {
      final farmState = FarmState(gridWidth: 3, gridHeight: 3);

      // Create mixed states manually
      final plot00 = farmState.getPlot(0, 0);
      if (plot00 != null) plot00.state = PlotState.normal;

      final plot10 = farmState.getPlot(1, 0);
      if (plot10 != null) plot10.state = PlotState.tilled;

      final plot20 = farmState.getPlot(2, 0);
      if (plot20 != null) plot20.state = PlotState.watered;

      final plot01 = farmState.getPlot(0, 1);
      if (plot01 != null) {
        plot01.state = PlotState.watered;
        plot01.crop = PlantedCrop(
          cropType: CropType.wheat,
          growthStartedAt: DateTime.now(),
        );
      }

      // Verify mixed states exist
      expect(farmState.getPlot(0, 0)?.state, PlotState.normal);
      expect(farmState.getPlot(1, 0)?.state, PlotState.tilled);
      expect(farmState.getPlot(2, 0)?.state, PlotState.watered);
      expect(farmState.getPlot(0, 1)?.state, PlotState.watered);
      expect(farmState.getPlot(0, 1)?.crop, isNotNull);

      // Clear the farm
      farmState.clearFarmToSeeds();

      // Verify all are normal
      for (int y = 0; y < 3; y++) {
        for (int x = 0; x < 3; x++) {
          final plot = farmState.getPlot(x, y);
          expect(plot?.state, PlotState.normal, 
              reason: 'Plot ($x,$y) should be normal');
          expect(plot?.crop, isNull, 
              reason: 'Plot ($x,$y) should have no crop');
        }
      }
    });

    test('Test 6: Clear farm without user data works without errors', () {
      // Create farm state without user data
      final farmState = FarmState(gridWidth: 3, gridHeight: 3);

      // Try to clear (should not crash)
      expect(() => farmState.clearFarmToSeeds(), returnsNormally);

      // Verify farm is cleared
      expect(farmState.dronePosition.x, 0);
      expect(farmState.dronePosition.y, 0);
      
      for (int y = 0; y < 3; y++) {
        for (int x = 0; x < 3; x++) {
          final plot = farmState.getPlot(x, y);
          expect(plot?.state, PlotState.normal);
          expect(plot?.crop, isNull);
        }
      }
    });

    test('Test 7: Clear farm with all 9 crop types clears all plots', () {
      final farmState = FarmState(gridWidth: 3, gridHeight: 3);
      
      // All crop types
      final allCropTypes = [
        CropType.wheat,
        CropType.carrot,
        CropType.potato,
        CropType.beetroot,
        CropType.radish,
        CropType.onion,
        CropType.lettuce,
        CropType.tomato,
        CropType.garlic,
      ];

      // Manually add all 9 crop types
      for (int i = 0; i < 9 && i < allCropTypes.length; i++) {
        final x = i % 3;
        final y = i ~/ 3;
        final plot = farmState.getPlot(x, y);
        if (plot != null) {
          plot.state = PlotState.watered;
          plot.crop = PlantedCrop(
            cropType: allCropTypes[i],
            growthStartedAt: DateTime.now(),
          );
        }
      }

      // Verify all 9 crops exist
      for (int i = 0; i < 9; i++) {
        final x = i % 3;
        final y = i ~/ 3;
        expect(farmState.getPlot(x, y)?.crop, isNotNull);
      }

      // Clear the farm
      farmState.clearFarmToSeeds();

      // Verify all plots are cleared
      for (int y = 0; y < 3; y++) {
        for (int x = 0; x < 3; x++) {
          final plot = farmState.getPlot(x, y);
          expect(plot?.state, PlotState.normal);
          expect(plot?.crop, isNull);
        }
      }
    });
  });
}
