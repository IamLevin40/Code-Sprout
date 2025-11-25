import 'package:flutter_test/flutter_test.dart';
import 'package:code_sprout/models/farm_data.dart';
import 'package:code_sprout/models/farm_data_schema.dart';

void main() {
  // Initialize Flutter test binding
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Drone State and Work Duration Tests', () {
    late FarmState farmState;
    late FarmDataSchema schema;

    setUp(() async {
      // Mock schema data for testing
      schema = FarmDataSchema();
      schema.setSchemaForTesting({
        'drone_work_duration': {
          'general': 200,
          'move(direction)': 1000,
          'till()': 600,
          'water()': 1000,
        },
        'crop_info': {},
      });
      
      farmState = FarmState(gridWidth: 3, gridHeight: 3);
    });

    test('Test 1: Drone starts with normal state', () {
      expect(farmState.dronePosition.state, DroneState.normal);
    });

    test('Test 2: Drone state changes to tilling during till operation', () async {
      farmState.dronePosition.x = 1;
      farmState.dronePosition.y = 1;

      // Start till (should change state to tilling)
      farmState.setDroneState(DroneState.tilling);
      expect(farmState.dronePosition.state, DroneState.tilling);

      // Reset to normal after operation
      farmState.setDroneState(DroneState.normal);
      expect(farmState.dronePosition.state, DroneState.normal);
    });

    test('Test 3: Drone state changes to watering during water operation', () async {
      farmState.dronePosition.x = 1;
      farmState.dronePosition.y = 1;
      farmState.tillCurrentPlot();

      // Start water (should change state to watering)
      farmState.setDroneState(DroneState.watering);
      expect(farmState.dronePosition.state, DroneState.watering);

      // Reset to normal after operation
      farmState.setDroneState(DroneState.normal);
      expect(farmState.dronePosition.state, DroneState.normal);
    });

    test('Test 4: Drone work duration for general is 200ms', () {
      expect(farmState.generalDuration, 200);
    });

    test('Test 5: Drone work duration for move is 1000ms', () {
      expect(farmState.moveDuration, 1000);
    });

    test('Test 6: Drone work duration for till is 600ms', () {
      expect(farmState.tillDuration, 600);
    });

    test('Test 7: Drone work duration for water is 1000ms', () {
      expect(farmState.waterDuration, 1000);
    });

    test('Test 8: Schema loads drone work durations correctly', () {
      expect(schema.getDroneWorkDuration('general'), 200);
      expect(schema.getDroneWorkDuration('move(direction)'), 1000);
      expect(schema.getDroneWorkDuration('till()'), 600);
      expect(schema.getDroneWorkDuration('water()'), 1000);
    });

    test('Test 9: Animated position initialized at construction', () {
      final testPos = DronePosition(x: 2, y: 1);

      expect(testPos.animatedX, 2.0);
      expect(testPos.animatedY, 1.0);
    });

    test('Test 10: Move animation updates animated position', () async {
      farmState.dronePosition.x = 1;
      farmState.dronePosition.y = 1;
      farmState.dronePosition.animatedX = 1.0;
      farmState.dronePosition.animatedY = 1.0;

      // Perform animated move
      await farmState.animateDroneMove(Direction.east);

      expect(farmState.dronePosition.x, 2);
      expect(farmState.dronePosition.y, 1);
      expect(farmState.dronePosition.animatedX, 2.0);
      expect(farmState.dronePosition.animatedY, 1.0);
    });

    test('Test 11: Animated move takes approximately moveDuration', () async {
      final startTime = DateTime.now();
      
      farmState.dronePosition.x = 0;
      farmState.dronePosition.y = 0;

      await farmState.animateDroneMove(Direction.east);

      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      
      // Should take approximately 1000ms (allow 100ms tolerance)
      expect(elapsed, greaterThan(900));
      expect(elapsed, lessThan(1200));
    });

    test('Test 12: Drone state persists across operations', () {
      farmState.setDroneState(DroneState.tilling);
      expect(farmState.dronePosition.state, DroneState.tilling);

      farmState.setDroneState(DroneState.watering);
      expect(farmState.dronePosition.state, DroneState.watering);

      farmState.setDroneState(DroneState.normal);
      expect(farmState.dronePosition.state, DroneState.normal);
    });

    test('Test 13: setDroneState notifies listeners', () {
      bool notified = false;
      farmState.addListener(() {
        notified = true;
      });

      farmState.setDroneState(DroneState.tilling);
      expect(notified, true);
    });

    test('Test 14: setDroneState only notifies if state changes', () {
      int notifyCount = 0;
      farmState.addListener(() {
        notifyCount++;
      });

      farmState.setDroneState(DroneState.normal); // Same as current
      expect(notifyCount, 0);

      farmState.setDroneState(DroneState.tilling); // Different
      expect(notifyCount, 1);
    });

    test('Test 15: Animated move handles boundary correctly', () async {
      farmState.dronePosition.x = 2;
      farmState.dronePosition.y = 2;

      // Try to move out of bounds
      await farmState.animateDroneMove(Direction.east);

      // Should still be at original position
      expect(farmState.dronePosition.x, 2);
      expect(farmState.dronePosition.y, 2);
    });

    test('Test 16: Animated move in all directions', () async {
      farmState.dronePosition.x = 1;
      farmState.dronePosition.y = 1;

      // Move north
      await farmState.animateDroneMove(Direction.north);
      expect(farmState.dronePosition.x, 1);
      expect(farmState.dronePosition.y, 2);

      // Move east
      await farmState.animateDroneMove(Direction.east);
      expect(farmState.dronePosition.x, 2);
      expect(farmState.dronePosition.y, 2);

      // Move south
      await farmState.animateDroneMove(Direction.south);
      expect(farmState.dronePosition.x, 2);
      expect(farmState.dronePosition.y, 1);

      // Move west
      await farmState.animateDroneMove(Direction.west);
      expect(farmState.dronePosition.x, 1);
      expect(farmState.dronePosition.y, 1);
    });

    test('Test 17: Multiple sequential moves maintain state', () async {
      farmState.dronePosition.x = 0;
      farmState.dronePosition.y = 0;

      await farmState.animateDroneMove(Direction.east);
      expect(farmState.dronePosition.state, DroneState.normal);

      await farmState.animateDroneMove(Direction.north);
      expect(farmState.dronePosition.state, DroneState.normal);

      expect(farmState.dronePosition.x, 1);
      expect(farmState.dronePosition.y, 1);
    });

    test('Test 18: DronePosition copyWith preserves state', () {
      final pos = DronePosition(x: 1, y: 2, state: DroneState.tilling);
      final copied = pos.copyWith(x: 3);

      expect(copied.x, 3);
      expect(copied.y, 2);
      expect(copied.state, DroneState.tilling);
    });

    test('Test 19: DronePosition copyWith can change state', () {
      final pos = DronePosition(x: 1, y: 2, state: DroneState.normal);
      final copied = pos.copyWith(state: DroneState.watering);

      expect(copied.x, 1);
      expect(copied.y, 2);
      expect(copied.state, DroneState.watering);
    });

    test('Test 20: DronePosition toString includes state', () {
      final pos = DronePosition(x: 5, y: 7, state: DroneState.tilling);
      final str = pos.toString();

      expect(str, contains('5'));
      expect(str, contains('7'));
      expect(str, contains('tilling'));
    });

    test('Test 21: Animated position interpolates smoothly', () async {
      farmState.dronePosition.x = 0;
      farmState.dronePosition.y = 0;
      farmState.dronePosition.animatedX = 0.0;
      farmState.dronePosition.animatedY = 0.0;

      // Start async move and check intermediate values
      final moveFuture = farmState.animateDroneMove(Direction.east);
      
      // Wait a bit and check if animation is in progress
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Animated position should be between start and end
      expect(farmState.dronePosition.animatedX, greaterThan(0.0));
      expect(farmState.dronePosition.animatedX, lessThan(1.0));
      
      await moveFuture;
      
      // Final position should be exact
      expect(farmState.dronePosition.animatedX, 1.0);
    });

    test('Test 22: Schema returns null for unknown drone operation', () {
      expect(schema.getDroneWorkDuration('unknown_operation'), null);
    });

    test('Test 23: Till operation changes plot state', () {
      farmState.dronePosition.x = 1;
      farmState.dronePosition.y = 1;

      final plot = farmState.getCurrentPlot();
      expect(plot?.state, PlotState.normal);

      farmState.tillCurrentPlot();

      expect(plot?.state, PlotState.tilled);
    });

    test('Test 24: Water operation changes plot state', () {
      farmState.dronePosition.x = 1;
      farmState.dronePosition.y = 1;
      farmState.tillCurrentPlot();

      final plot = farmState.getCurrentPlot();
      expect(plot?.state, PlotState.tilled);

      farmState.waterCurrentPlot();

      expect(plot?.state, PlotState.watered);
    });

    test('Test 25: Drone state enum has all expected values', () {
      expect(DroneState.values, hasLength(3));
      expect(DroneState.values, contains(DroneState.normal));
      expect(DroneState.values, contains(DroneState.tilling));
      expect(DroneState.values, contains(DroneState.watering));
    });
  });
}
