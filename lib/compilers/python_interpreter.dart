import 'base_interpreter.dart';
import '../models/farm_data.dart';

/// Python code interpreter for farm drone operations
class PythonInterpreter extends FarmCodeInterpreter {
  PythonInterpreter({
    required super.farmState,
    super.onCropHarvested,
  });

  @override
  Future<ExecutionResult> execute(String code) async {
    clearLog();
    log('Starting Python code execution...');

    try {
      // Remove comments
      code = _removeComments(code);

      // Parse statements
      final statements = _parseStatements(code);

      for (final stmt in statements) {
        final trimmed = stmt.trim();
        if (trimmed.isEmpty) continue;

        await delay();

        if (!await _executeStatement(trimmed)) {
          return ExecutionResult.error('Execution stopped due to error', log: executionLog);
        }
      }

      log('Code execution completed successfully!');
      return ExecutionResult.success(log: executionLog);
    } catch (e) {
      return ExecutionResult.error('Runtime error: $e', log: executionLog);
    }
  }

  /// Remove comments
  String _removeComments(String code) {
    // Remove single-line comments
    code = code.replaceAll(RegExp(r'#.*?$', multiLine: true), '');
    return code;
  }

  /// Parse statements from code
  List<String> _parseStatements(String code) {
    return code.split('\n').where((line) => line.trim().isNotEmpty).toList();
  }

  /// Execute a single statement
  Future<bool> _executeStatement(String stmt) async {
    // Parse function calls - Python style: function_name(args)
    final functionPattern = RegExp(r'^(\w+)\s*\((.*?)\)\s*$');
    final match = functionPattern.firstMatch(stmt);

    if (match != null) {
      final functionName = match.group(1)!;
      final argsString = match.group(2)?.trim() ?? '';

      switch (functionName) {
        case 'move':
          return _handleMove(argsString);
        case 'till':
          return executeTill();
        case 'water':
          return executeWater();
        case 'plant':
          return _handlePlant(argsString);
        case 'harvest':
          return executeHarvest();
        default:
          log('Error: Unknown function "$functionName"');
          return false;
      }
    }

    log('Error: Invalid statement syntax');
    return false;
  }

  /// Handle move() function
  bool _handleMove(String args) {
    // Parse Direction.North or "north" or 'north'
    args = args.replaceAll('"', '').replaceAll("'", '').trim();
    
    final dirPattern = RegExp(r'Direction\.(\w+)', caseSensitive: false);
    final match = dirPattern.firstMatch(args);

    String dirStr;
    if (match != null) {
      dirStr = match.group(1)!.toLowerCase();
    } else {
      dirStr = args.toLowerCase();
    }

    Direction? direction;

    switch (dirStr) {
      case 'north':
        direction = Direction.north;
        break;
      case 'south':
        direction = Direction.south;
        break;
      case 'east':
        direction = Direction.east;
        break;
      case 'west':
        direction = Direction.west;
        break;
      default:
        log('Error: Invalid direction "$dirStr"');
        return false;
    }

    return executeMove(direction);
  }

  /// Handle plant() function
  bool _handlePlant(String args) {
    // Parse Crop.Wheat or "wheat" or 'wheat'
    args = args.replaceAll('"', '').replaceAll("'", '').trim();
    
    final cropPattern = RegExp(r'Crop\.(\w+)', caseSensitive: false);
    final match = cropPattern.firstMatch(args);

    String cropStr;
    if (match != null) {
      cropStr = match.group(1)!.toLowerCase();
    } else {
      cropStr = args.toLowerCase();
    }

    final crop = CropTypeExtension.fromString(cropStr);

    if (crop == null) {
      log('Error: Unknown crop type "$cropStr"');
      return false;
    }

    return executePlant(crop);
  }
}
