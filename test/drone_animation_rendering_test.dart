import 'package:flutter_test/flutter_test.dart';
import 'package:code_sprout/models/farm_data.dart';
import 'package:code_sprout/models/farm_data_schema.dart';

void main() {
  // Initialize Flutter test binding
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Drone Animation Rendering Tests', () {
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
      
      // Create a 3x3 farm
      farmState = FarmState(gridWidth: 3, gridHeight: 3);
    });

    test('animateDroneMove updates grid position only at end', () async {
      // Initial position
      expect(farmState.dronePosition.x, 0);
      expect(farmState.dronePosition.y, 0);

      // Start animation
      final animationFuture = farmState.animateDroneMove(Direction.north);

      // Wait a short time during animation
      await Future.delayed(const Duration(milliseconds: 100));

      // Grid position should still be at start
      expect(farmState.dronePosition.x, 0);
      expect(farmState.dronePosition.y, 0);

      // Animated position should have moved partway
      expect(farmState.dronePosition.animatedY, greaterThan(0.0));
      expect(farmState.dronePosition.animatedY, lessThan(1.0));

      // Wait for animation to complete
      await animationFuture;

      // Now grid position should be updated
      expect(farmState.dronePosition.x, 0);
      expect(farmState.dronePosition.y, 1);
      expect(farmState.dronePosition.animatedX, 0.0);
      expect(farmState.dronePosition.animatedY, 1.0);
    });

    test('Drone does not animate out of bounds', () async {
      // Move drone to top-right corner
      farmState.dronePosition.x = 2;
      farmState.dronePosition.y = 2;
      farmState.dronePosition.animatedX = 2.0;
      farmState.dronePosition.animatedY = 2.0;

      // Try to move north (out of bounds)
      await farmState.animateDroneMove(Direction.north);

      // Position should remain unchanged
      expect(farmState.dronePosition.x, 2);
      expect(farmState.dronePosition.y, 2);
      expect(farmState.dronePosition.animatedX, 2.0);
      expect(farmState.dronePosition.animatedY, 2.0);
    });

    test('Multiple consecutive moves animate correctly', () async {
      // Move east
      await farmState.animateDroneMove(Direction.east);
      expect(farmState.dronePosition.x, 1);
      expect(farmState.dronePosition.animatedX, 1.0);

      // Move north
      await farmState.animateDroneMove(Direction.north);
      expect(farmState.dronePosition.x, 1);
      expect(farmState.dronePosition.y, 1);
      expect(farmState.dronePosition.animatedX, 1.0);
      expect(farmState.dronePosition.animatedY, 1.0);

      // Move west
      await farmState.animateDroneMove(Direction.west);
      expect(farmState.dronePosition.x, 0);
      expect(farmState.dronePosition.y, 1);
      expect(farmState.dronePosition.animatedX, 0.0);
      expect(farmState.dronePosition.animatedY, 1.0);
    });

    test('Drone state resets to normal after move animation', () async {
      // Set drone to tilling state
      farmState.setDroneState(DroneState.tilling);
      expect(farmState.dronePosition.state, DroneState.tilling);

      // Move east
      await farmState.animateDroneMove(Direction.east);

      // State should be reset to normal after move
      expect(farmState.dronePosition.state, DroneState.normal);
    });
  });
}
