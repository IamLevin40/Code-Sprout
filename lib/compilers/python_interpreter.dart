import 'base_interpreter.dart';
import '../models/farm_data.dart';

/// Comprehensive Python code interpreter for farm drone operations
/// Supports: variables, operators, if-elif-else, for/while loops, break/continue, print(), try-except
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

      // Execute the code
      await _executeBlock(code, 0);

      if (!shouldReturn) {
        log('Code execution completed successfully!');
      }
      return ExecutionResult.success(log: executionLog);
    } on Exception catch (e) {
      return ExecutionResult.error(
        'Runtime Error: ${e.toString()}',
        type: ErrorType.runtime,
        log: executionLog,
      );
    } catch (e) {
      return ExecutionResult.error(
        'Unknown Error: $e',
        type: ErrorType.runtime,
        log: executionLog,
      );
    }
  }

  /// Remove comments
  String _removeComments(String code) {
    code = code.replaceAll(RegExp(r'#.*?$', multiLine: true), '');
    return code;
  }

  /// Get indentation level
  int _getIndentLevel(String line) {
    int spaces = 0;
    for (int i = 0; i < line.length; i++) {
      if (line[i] == ' ') {
        spaces++;
      } else if (line[i] == '\t') {
        spaces += 4;
      } else {
        break;
      }
    }
    return spaces ~/ 4;
  }

  /// Execute a block of code with specific indentation level
  Future<void> _executeBlock(String code, int baseIndent) async {
    final lines = code.split('\n');
    int i = 0;

    while (i < lines.length) {
      if (shouldBreak || shouldContinue || shouldReturn) break;

      final line = lines[i];
      final trimmed = line.trim();
      
      if (trimmed.isEmpty) {
        i++;
        continue;
      }

      final indent = _getIndentLevel(line);
      if (indent < baseIndent) break;
      if (indent > baseIndent) {
        i++;
        continue;
      }

      await delay(200);

      // If-elif-else
      if (trimmed.startsWith('if ')) {
        i = await _handleIf(lines, i, baseIndent);
        continue;
      }

      // While loop
      if (trimmed.startsWith('while ')) {
        i = await _handleWhile(lines, i, baseIndent);
        continue;
      }

      // For loop
      if (trimmed.startsWith('for ')) {
        i = await _handleFor(lines, i, baseIndent);
        continue;
      }

      // Try-except
      if (trimmed.startsWith('try:')) {
        i = await _handleTryExcept(lines, i, baseIndent);
        continue;
      }

      // Break
      if (trimmed == 'break') {
        shouldBreak = true;
        break;
      }

      // Continue
      if (trimmed == 'continue') {
        shouldContinue = true;
        break;
      }

      // Return
      if (trimmed.startsWith('return')) {
        shouldReturn = true;
        break;
      }

      // Execute single statement
      await _executeStatement(trimmed);
      i++;
    }
  }

  /// Execute a single statement
  Future<void> _executeStatement(String stmt) async {
    stmt = stmt.trim();
    if (stmt.isEmpty) return;

    // Variable assignment (no type declaration in Python)
    if (_isAssignment(stmt)) {
      await _handleAssignment(stmt);
      return;
    }

    // Print function
    if (stmt.startsWith('print(')) {
      await _handlePrint(stmt);
      return;
    }

    // Function call
    if (stmt.contains('(') && stmt.contains(')')) {
      await _handleFunctionCall(stmt);
      return;
    }

    throw Exception('Syntactical Error: Unrecognized statement: $stmt');
  }

  /// Check if statement is an assignment
  bool _isAssignment(String stmt) {
    // Check if there's a standalone = (not part of ==, !=, >=, <=)
    for (int i = 0; i < stmt.length; i++) {
      if (stmt[i] == '=' && 
          (i == 0 || (stmt[i-1] != '!' && stmt[i-1] != '=' && stmt[i-1] != '>' && stmt[i-1] != '<')) &&
          (i == stmt.length - 1 || stmt[i+1] != '=')) {
        return true;
      }
    }
    return false;
  }

  /// Handle assignment
  Future<void> _handleAssignment(String stmt) async {
    // Find the first = that's not part of ==, !=, >=, <=
    int assignIndex = -1;
    for (int i = 0; i < stmt.length; i++) {
      if (stmt[i] == '=' && 
          (i == 0 || (stmt[i-1] != '!' && stmt[i-1] != '=' && stmt[i-1] != '>' && stmt[i-1] != '<')) &&
          (i == stmt.length - 1 || stmt[i+1] != '=')) {
        assignIndex = i;
        break;
      }
    }
    
    if (assignIndex == -1) {
      throw Exception('Syntactical Error: Invalid assignment');
    }

    final varName = stmt.substring(0, assignIndex).trim();
    final valueExpr = stmt.substring(assignIndex + 1).trim();

    if (!RegExp(r'^[a-zA-Z_]\w*$').hasMatch(varName)) {
      throw Exception('Lexical Error: Invalid variable name: $varName');
    }

    try {
      final value = evaluateExpression(valueExpr);
      if (currentScope.has(varName)) {
        currentScope.set(varName, value);
        log('Variable $varName updated to: $value');
      } else {
        currentScope.define(varName, value);
        log('Variable $varName assigned value: $value');
      }
    } catch (e) {
      throw Exception('Semantical Error: Cannot evaluate expression: $valueExpr');
    }
  }

  /// Handle if-elif-else statement
  Future<int> _handleIf(List<String> lines, int startIndex, int baseIndent) async {
    int i = startIndex;
    final conditions = <String>[];
    final bodies = <String>[];
    String? elseBody;

    // Parse if
    final ifLine = lines[i].trim();
    if (!ifLine.endsWith(':')) {
      throw Exception('Syntactical Error: Missing colon after if');
    }

    final ifCondition = ifLine.substring(3, ifLine.length - 1).trim();
    conditions.add(ifCondition);
    
    i++;
    final ifBodyLines = <String>[];
    while (i < lines.length && _getIndentLevel(lines[i]) > baseIndent) {
      ifBodyLines.add(lines[i]);
      i++;
    }
    bodies.add(ifBodyLines.join('\n'));

    // Parse elif and else
    while (i < lines.length && _getIndentLevel(lines[i]) == baseIndent) {
      final line = lines[i].trim();
      
      if (line.startsWith('elif ')) {
        if (!line.endsWith(':')) {
          throw Exception('Syntactical Error: Missing colon after elif');
        }
        
        final elifCondition = line.substring(5, line.length - 1).trim();
        conditions.add(elifCondition);
        
        i++;
        final elifBodyLines = <String>[];
        while (i < lines.length && _getIndentLevel(lines[i]) > baseIndent) {
          elifBodyLines.add(lines[i]);
          i++;
        }
        bodies.add(elifBodyLines.join('\n'));
      } else if (line == 'else:') {
        i++;
        final elseBodyLines = <String>[];
        while (i < lines.length && _getIndentLevel(lines[i]) > baseIndent) {
          elseBodyLines.add(lines[i]);
          i++;
        }
        elseBody = elseBodyLines.join('\n');
        break;
      } else {
        break;
      }
    }

    // Execute (Python doesn't have block scope - no push/popScope)
    bool executed = false;
    for (int j = 0; j < conditions.length; j++) {
      try {
        final condValue = evaluateExpression(conditions[j]);
        if (_toBool(condValue)) {
          await _executeBlock(bodies[j], baseIndent + 1);
          executed = true;
          break;
        }
      } catch (e) {
        throw Exception('Logical Error in if/elif condition: $e');
      }
    }

    if (!executed && elseBody != null) {
      await _executeBlock(elseBody, baseIndent + 1);
    }

    return i;
  }

  /// Handle while loop
  Future<int> _handleWhile(List<String> lines, int startIndex, int baseIndent) async {
    final whileLine = lines[startIndex].trim();
    if (!whileLine.endsWith(':')) {
      throw Exception('Syntactical Error: Missing colon after while');
    }

    final condition = whileLine.substring(6, whileLine.length - 1).trim();
    
    // Get body
    int i = startIndex + 1;
    final bodyLines = <String>[];
    while (i < lines.length && _getIndentLevel(lines[i]) > baseIndent) {
      bodyLines.add(lines[i]);
      i++;
    }
    final body = bodyLines.join('\n');

    // Execute loop (Python doesn't have block scope)
    while (true) {
      try {
        final condValue = evaluateExpression(condition);
        if (!_toBool(condValue)) break;
      } catch (e) {
        throw Exception('Logical Error in while condition: $e');
      }

      shouldBreak = false;
      shouldContinue = false;
      
      await _executeBlock(body, baseIndent + 1);
      
      if (shouldBreak) {
        shouldBreak = false;
        break;
      }
      if (shouldReturn) break;
    }

    return i;
  }

  /// Handle for loop
  Future<int> _handleFor(List<String> lines, int startIndex, int baseIndent) async {
    final forLine = lines[startIndex].trim();
    if (!forLine.endsWith(':')) {
      throw Exception('Syntactical Error: Missing colon after for');
    }

    // Parse: for var in range(start, end) or for var in range(end)
    final forMatch = RegExp(r'for\s+(\w+)\s+in\s+range\((.*?)\)').firstMatch(forLine);
    if (forMatch == null) {
      throw Exception('Syntactical Error: Invalid for loop syntax');
    }

    final varName = forMatch.group(1)!;
    final rangeArgs = forMatch.group(2)!.split(',').map((s) => s.trim()).toList();

    int start = 0;
    int end;
    
    if (rangeArgs.length == 1) {
      end = (evaluateExpression(rangeArgs[0]) as num).toInt();
    } else if (rangeArgs.length == 2) {
      start = (evaluateExpression(rangeArgs[0]) as num).toInt();
      end = (evaluateExpression(rangeArgs[1]) as num).toInt();
    } else {
      throw Exception('Syntactical Error: Invalid range arguments');
    }

    // Get body
    int i = startIndex + 1;
    final bodyLines = <String>[];
    while (i < lines.length && _getIndentLevel(lines[i]) > baseIndent) {
      bodyLines.add(lines[i]);
      i++;
    }
    final body = bodyLines.join('\n');

    // Execute loop (Python doesn't have block scope)
    for (int val = start; val < end; val++) {
      if (currentScope.has(varName)) {
        currentScope.set(varName, val);
      } else {
        currentScope.define(varName, val);
      }
      
      shouldBreak = false;
      shouldContinue = false;
      
      await _executeBlock(body, baseIndent + 1);
      
      if (shouldBreak) {
        shouldBreak = false;
        break;
      }
      if (shouldReturn) break;
    }

    return i;
  }

  /// Handle try-except
  Future<int> _handleTryExcept(List<String> lines, int startIndex, int baseIndent) async {
    int i = startIndex + 1;
    
    // Get try body
    final tryBodyLines = <String>[];
    while (i < lines.length && _getIndentLevel(lines[i]) > baseIndent) {
      tryBodyLines.add(lines[i]);
      i++;
    }
    final tryBody = tryBodyLines.join('\n');

    // Get except body
    String? exceptBody;
    if (i < lines.length && lines[i].trim().startsWith('except')) {
      i++;
      final exceptBodyLines = <String>[];
      while (i < lines.length && _getIndentLevel(lines[i]) > baseIndent) {
        exceptBodyLines.add(lines[i]);
        i++;
      }
      exceptBody = exceptBodyLines.join('\n');
    }

    // Execute
    try {
      pushScope();
      await _executeBlock(tryBody, baseIndent + 1);
      popScope();
    } catch (e) {
      log('Exception caught: $e');
      if (exceptBody != null) {
        pushScope();
        await _executeBlock(exceptBody, baseIndent + 1);
        popScope();
      }
    }

    return i;
  }

  /// Handle print function
  Future<void> _handlePrint(String stmt) async {
    final match = RegExp(r'print\((.*?)\)$').firstMatch(stmt);
    if (match == null) {
      throw Exception('Syntactical Error: Invalid print statement');
    }

    final content = match.group(1)!;
    
    try {
      final value = evaluateExpression(content);
      log('Output: $value');
    } catch (e) {
      log('Output: $content');
    }
  }

  /// Handle function call
  Future<void> _handleFunctionCall(String stmt) async {
    final functionPattern = RegExp(r'^(\w+)\s*\((.*?)\)\s*$');
    final match = functionPattern.firstMatch(stmt);

    if (match == null) {
      throw Exception('Syntactical Error: Invalid function call');
    }

    final functionName = match.group(1)!;
    final argsString = match.group(2)?.trim() ?? '';

    switch (functionName) {
      case 'move':
        _handleMove(argsString);
        break;
      case 'till':
        executeTill();
        break;
      case 'water':
        executeWater();
        break;
      case 'plant':
        _handlePlant(argsString);
        break;
      case 'harvest':
        executeHarvest();
        break;
      default:
        throw Exception('Semantical Error: Unknown function "$functionName"');
    }
  }

  /// Handle move() function
  void _handleMove(String args) {
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
        throw Exception('Semantical Error: Invalid direction "$dirStr"');
    }

    executeMove(direction);
  }

  /// Handle plant() function
  void _handlePlant(String args) {
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
      throw Exception('Semantical Error: Unknown crop type "$cropStr"');
    }

    executePlant(crop);
  }

  /// Convert value to boolean
  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.isNotEmpty;
    return false;
  }
}
