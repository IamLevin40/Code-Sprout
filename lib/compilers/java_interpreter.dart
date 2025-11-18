import 'base_interpreter.dart';
import '../models/farm_data.dart';

/// Java code interpreter for farm drone operations
class JavaInterpreter extends FarmCodeInterpreter {
  JavaInterpreter({
    required super.farmState,
    super.onCropHarvested,
  });

  @override
  Future<ExecutionResult> execute(String code) async {
    clearLog();
    log('Starting Java code execution...');

    try {
      // Remove comments
      code = _removeComments(code);

      // Extract main method body
      final mainBody = _extractMainBody(code);
      if (mainBody == null) {
        return ExecutionResult.error('Error: main() method not found', log: executionLog);
      }

      // Parse and execute statements
      final statements = _parseStatements(mainBody);

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

  /// Remove single-line and multi-line comments
  String _removeComments(String code) {
    // Remove multi-line comments
    code = code.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');
    // Remove single-line comments
    code = code.replaceAll(RegExp(r'//.*?$', multiLine: true), '');
    return code;
  }

  /// Extract the body of main() method
  String? _extractMainBody(String code) {
    final mainPattern = RegExp(
      r'public\s+static\s+void\s+main\s*\([^)]*\)\s*\{',
      multiLine: true,
    );

    final match = mainPattern.firstMatch(code);
    if (match == null) return null;

    int braceCount = 1;
    int startIndex = match.end;
    int currentIndex = startIndex;

    while (currentIndex < code.length && braceCount > 0) {
      if (code[currentIndex] == '{') {
        braceCount++;
      } else if (code[currentIndex] == '}') {
        braceCount--;
      }
      currentIndex++;
    }

    if (braceCount != 0) return null;

    return code.substring(startIndex, currentIndex - 1);
  }

  /// Parse statements from code block
  List<String> _parseStatements(String code) {
    final List<String> statements = [];
    final buffer = StringBuffer();
    int braceDepth = 0;
    int parenDepth = 0;

    for (int i = 0; i < code.length; i++) {
      final char = code[i];

      if (char == '{') braceDepth++;
      if (char == '}') braceDepth--;
      if (char == '(') parenDepth++;
      if (char == ')') parenDepth--;

      buffer.write(char);

      if (char == ';' && braceDepth == 0 && parenDepth == 0) {
        statements.add(buffer.toString().trim());
        buffer.clear();
      }
    }

    return statements;
  }

  /// Execute a single statement
  Future<bool> _executeStatement(String stmt) async {
    // Remove trailing semicolon
    if (stmt.endsWith(';')) {
      stmt = stmt.substring(0, stmt.length - 1).trim();
    }

    // Parse function calls
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
    // Parse Direction.NORTH, Direction.SOUTH, etc.
    final dirPattern = RegExp(r'Direction\.(\w+)', caseSensitive: false);
    final match = dirPattern.firstMatch(args);

    if (match == null) {
      log('Error: Invalid direction format. Use Direction.NORTH, Direction.SOUTH, Direction.EAST, or Direction.WEST');
      return false;
    }

    final dirStr = match.group(1)!.toLowerCase();
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
    // Parse Crop.WHEAT, Crop.CARROT, etc.
    final cropPattern = RegExp(r'Crop\.(\w+)', caseSensitive: false);
    final match = cropPattern.firstMatch(args);

    if (match == null) {
      log('Error: Invalid crop format. Use Crop.WHEAT, Crop.CARROT, etc.');
      return false;
    }

    final cropStr = match.group(1)!.toLowerCase();
    final crop = CropTypeExtension.fromString(cropStr);

    if (crop == null) {
      log('Error: Unknown crop type "$cropStr"');
      return false;
    }

    return executePlant(crop);
  }
}
