import '../models/farm_data.dart';

/// Result of a code execution
class ExecutionResult {
  final bool success;
  final String? errorMessage;
  final List<String> executionLog;

  ExecutionResult({
    required this.success,
    this.errorMessage,
    List<String>? executionLog,
  }) : executionLog = executionLog ?? [];

  ExecutionResult.success({List<String>? log})
      : success = true,
        errorMessage = null,
        executionLog = log ?? [];

  ExecutionResult.error(String message, {List<String>? log})
      : success = false,
        errorMessage = message,
        executionLog = log ?? [];
}

/// Base class for all language compilers/interpreters
abstract class FarmCodeInterpreter {
  final FarmState farmState;
  final Function(CropType)? onCropHarvested;
  final List<String> executionLog = [];

  FarmCodeInterpreter({
    required this.farmState,
    this.onCropHarvested,
  });

  /// Parse and execute code
  Future<ExecutionResult> execute(String code);

  /// Log a message during execution
  void log(String message) {
    executionLog.add(message);
  }

  /// Clear execution log
  void clearLog() {
    executionLog.clear();
  }

  /// Execute move operation
  bool executeMove(Direction direction) {
    final dirName = direction.toString().split('.').last;
    log('Moving drone ${dirName}...');
    final success = farmState.moveDrone(direction);
    if (success) {
      log('Drone moved to (${farmState.dronePosition.x}, ${farmState.dronePosition.y})');
    } else {
      log('Error: Cannot move out of bounds');
    }
    return success;
  }

  /// Execute till operation
  bool executeTill() {
    log('Tilling soil...');
    final success = farmState.tillCurrentPlot();
    if (success) {
      log('Soil tilled successfully');
    } else {
      log('Error: Cannot till this plot');
    }
    return success;
  }

  /// Execute water operation
  bool executeWater() {
    log('Watering soil...');
    final success = farmState.waterCurrentPlot();
    if (success) {
      log('Soil watered successfully');
    } else {
      log('Error: Cannot water this plot');
    }
    return success;
  }

  /// Execute plant operation
  bool executePlant(CropType crop) {
    log('Planting ${crop.displayName}...');
    final success = farmState.plantCrop(crop);
    if (success) {
      log('${crop.displayName} planted successfully');
    } else {
      log('Error: Cannot plant on this plot');
    }
    return success;
  }

  /// Execute harvest operation
  bool executeHarvest() {
    log('Harvesting crop...');
    final crop = farmState.harvestCurrentPlot();
    if (crop != null) {
      log('Harvested ${crop.displayName}!');
      onCropHarvested?.call(crop);
      return true;
    } else {
      log('Error: Nothing to harvest here');
      return false;
    }
  }

  /// Helper to add delay between operations for visualization
  Future<void> delay([int milliseconds = 300]) async {
    await Future.delayed(Duration(milliseconds: milliseconds));
  }
}
