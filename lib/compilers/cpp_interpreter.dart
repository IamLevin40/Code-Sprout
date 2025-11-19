import 'base_interpreter.dart';
import '../models/farm_data.dart';

/// Comprehensive C++ code interpreter for farm drone operations
/// Supports: variables, operators, if-else, switch-case, loops, break/continue, cout, try-catch
class CppInterpreter extends FarmCodeInterpreter {
  CppInterpreter({
    required super.farmState,
    super.onCropHarvested,
  });

  @override
  Future<ExecutionResult> execute(String code) async {
    clearLog();
    log('Starting C++ code execution...');

    try {
      // Remove comments
      code = _removeComments(code);

      // Extract main function body
      final mainBody = _extractMainBody(code);
      if (mainBody == null) {
        return ExecutionResult.error(
          'Syntactical Error: main() function not found',
          type: ErrorType.syntactical,
          log: executionLog,
        );
      }

      // Execute statements
      await _executeBlock(mainBody);

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

  /// Remove single-line and multi-line comments
  String _removeComments(String code) {
    code = code.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');
    code = code.replaceAll(RegExp(r'//.*?$', multiLine: true), '');
    return code;
  }

  /// Extract block content between braces with proper nesting
  String _extractBlock(String code, int startIndex) {
    int braceCount = 0;
    bool inString = false;
    String? stringChar;
    int blockStart = -1;

    for (int i = startIndex; i < code.length; i++) {
      final char = code[i];

      // Track string literals
      if ((char == '"' || char == "'") && (i == 0 || code[i - 1] != '\\')) {
        if (!inString) {
          inString = true;
          stringChar = char;
        } else if (char == stringChar) {
          inString = false;
          stringChar = null;
        }
      }

      if (!inString) {
        if (char == '{') {
          if (braceCount == 0) blockStart = i + 1;
          braceCount++;
        } else if (char == '}') {
          braceCount--;
          if (braceCount == 0) {
            return code.substring(blockStart, i);
          }
        }
      }
    }

    throw Exception('Syntactical Error: Unmatched braces');
  }

  /// Extract the body of main() function
  String? _extractMainBody(String code) {
    final mainPattern = RegExp(
      r'int\s+main\s*\([^)]*\)\s*\{',
      multiLine: true,
    );

    final match = mainPattern.firstMatch(code);
    if (match == null) return null;

    int braceCount = 1;
    int startIndex = match.end;
    int currentIndex = startIndex;

    while (currentIndex < code.length && braceCount > 0) {
      if (code[currentIndex] == '{') braceCount++;
      if (code[currentIndex] == '}') braceCount--;
      currentIndex++;
    }

    if (braceCount != 0) return null;
    return code.substring(startIndex, currentIndex - 1);
  }

  /// Execute a block of code
  Future<void> _executeBlock(String block) async {
    final statements = _parseStatements(block);

    for (final stmt in statements) {
      if (shouldBreak || shouldContinue || shouldReturn) break;

      final trimmed = stmt.trim();
      if (trimmed.isEmpty) continue;

      await delay(200);
      await _executeStatement(trimmed);
    }
  }

  /// Parse statements from code block
  List<String> _parseStatements(String code) {
    final List<String> statements = [];
    final buffer = StringBuffer();
    int braceDepth = 0;
    int parenDepth = 0;
    bool inString = false;
    String? stringChar;

    for (int i = 0; i < code.length; i++) {
      final char = code[i];

      // Handle strings
      if ((char == '"' || char == "'") && (i == 0 || code[i - 1] != '\\')) {
        if (!inString) {
          inString = true;
          stringChar = char;
        } else if (char == stringChar) {
          inString = false;
          stringChar = null;
        }
      }

      if (!inString) {
        if (char == '{') braceDepth++;
        if (char == '}') braceDepth--;
        if (char == '(') parenDepth++;
        if (char == ')') parenDepth--;
      }

      buffer.write(char);

      if (!inString && char == ';' && braceDepth == 0 && parenDepth == 0) {
        statements.add(buffer.toString().trim());
        buffer.clear();
      } else if (!inString && char == '}' && braceDepth == 0 && parenDepth == 0) {
        // Control structure or standalone block just closed - check if complete
        final current = buffer.toString().trim();
        if (current.startsWith(RegExp(r'(if|while|for|do|switch|try|\{)'))) {
          // For if statements, check if there's an 'else' following
          if (current.startsWith('if')) {
            int nextNonWhitespace = i + 1;
            while (nextNonWhitespace < code.length && code[nextNonWhitespace].trim().isEmpty) {
              nextNonWhitespace++;
            }
            if (nextNonWhitespace < code.length - 3 && 
                code.substring(nextNonWhitespace, nextNonWhitespace + 4) == 'else') {
              // Don't add yet - continue to capture else block
              continue;
            }
          }
          // For try statements, check if there's a 'catch' following
          if (current.startsWith('try')) {
            int nextNonWhitespace = i + 1;
            while (nextNonWhitespace < code.length && code[nextNonWhitespace].trim().isEmpty) {
              nextNonWhitespace++;
            }
            if (nextNonWhitespace < code.length - 4 && 
                code.substring(nextNonWhitespace, nextNonWhitespace + 5) == 'catch') {
              // Don't add yet - continue to capture catch block
              continue;
            }
          }
          // Complete statement - add it
          statements.add(current);
          buffer.clear();
        }
      }
    }

    // Add remaining content
    final remaining = buffer.toString().trim();
    if (remaining.isNotEmpty) {
      statements.add(remaining);
    }

    return statements;
  }

  /// Execute a single statement
  Future<void> _executeStatement(String stmt) async {
    stmt = stmt.trim();
    if (stmt.isEmpty) return;

    // Control flow checks FIRST (before assignment check)
    // If statement
    if (stmt.startsWith('if')) {
      await _handleIf(stmt);
      return;
    }

    // While loop
    if (stmt.startsWith('while')) {
      await _handleWhile(stmt);
      return;
    }

    // For loop
    if (stmt.startsWith('for')) {
      await _handleFor(stmt);
      return;
    }

    // Do-while loop
    if (stmt.startsWith('do')) {
      await _handleDoWhile(stmt);
      return;
    }

    // Switch statement
    if (stmt.startsWith('switch')) {
      await _handleSwitch(stmt);
      return;
    }

    // Try-catch
    if (stmt.startsWith('try')) {
      await _handleTryCatch(stmt);
      return;
    }

    // Standalone block (before variable/assignment checks)
    if (stmt.startsWith('{')) {
      final blockBody = _extractBlock(stmt, 0);
      pushScope();
      await _executeBlock(blockBody);
      popScope();
      return;
    }

    // Variable declaration
    if (_isVariableDeclaration(stmt)) {
      await _handleVariableDeclaration(stmt);
      return;
    }

    // Increment/decrement operators (++, --)
    if (stmt.contains('++') || stmt.contains('--')) {
      _handleIncrementDecrement(stmt);
      return;
    }

    // Assignment
    if (_isAssignment(stmt)) {
      await _handleAssignment(stmt);
      return;
    }

    // Break
    if (stmt.startsWith('break')) {
      shouldBreak = true;
      return;
    }

    // Continue
    if (stmt.startsWith('continue')) {
      shouldContinue = true;
      return;
    }

    // Return
    if (stmt.startsWith('return')) {
      shouldReturn = true;
      return;
    }

    // Try-catch
    if (stmt.startsWith('try')) {
      await _handleTryCatch(stmt);
      return;
    }

    // Cout (output)
    if (stmt.contains('cout')) {
      await _handleCout(stmt);
      return;
    }

    // Function call
    if (stmt.contains('(') && stmt.contains(')')) {
      await _handleFunctionCall(stmt);
      return;
    }

    throw Exception('Syntactical Error: Unrecognized statement: $stmt');
  }

  /// Check if statement is a variable declaration
  bool _isVariableDeclaration(String stmt) {
    final types = ['int', 'double', 'float', 'char', 'bool', 'string'];
    for (final type in types) {
      if (stmt.startsWith(type + ' ')) return true;
    }
    return false;
  }

  /// Handle variable declaration
  Future<void> _handleVariableDeclaration(String stmt) async {
    if (stmt.endsWith(';')) stmt = stmt.substring(0, stmt.length - 1);

    // Parse type and rest of declaration
    final spaceIndex = stmt.indexOf(' ');
    if (spaceIndex == -1) {
      throw Exception('Syntactical Error: Invalid variable declaration');
    }

    final type = stmt.substring(0, spaceIndex);
    final rest = stmt.substring(spaceIndex + 1).trim();

    // Handle assignment
    if (rest.contains('=')) {
      // Find the first = that's not part of ==, !=, >=, <=
      int assignIndex = -1;
      for (int i = 0; i < rest.length; i++) {
        if (rest[i] == '=' && 
            (i == 0 || (rest[i-1] != '!' && rest[i-1] != '=' && rest[i-1] != '>' && rest[i-1] != '<')) &&
            (i == rest.length - 1 || rest[i+1] != '=')) {
          assignIndex = i;
          break;
        }
      }
      
      if (assignIndex == -1) {
        throw Exception('Syntactical Error: Invalid variable assignment');
      }

      final varName = rest.substring(0, assignIndex).trim();
      final valueExpr = rest.substring(assignIndex + 1).trim();

      if (!RegExp(r'^[a-zA-Z_]\w*$').hasMatch(varName)) {
        throw Exception('Lexical Error: Invalid variable name: $varName');
      }

      final value = evaluateExpression(valueExpr);
      currentScope.define(varName, value);
      log('Variable $varName declared with value: $value');
    } else {
      // Declaration without initialization
      final varName = rest.trim();
      if (!RegExp(r'^[a-zA-Z_]\w*$').hasMatch(varName)) {
        throw Exception('Lexical Error: Invalid variable name: $varName');
      }
      currentScope.define(varName, _getDefaultValue(type));
      log('Variable $varName declared');
    }
  }

  /// Get default value for a type
  dynamic _getDefaultValue(String type) {
    switch (type) {
      case 'int':
      case 'float':
      case 'double':
        return 0;
      case 'bool':
        return false;
      case 'char':
        return '';
      case 'string':
        return '';
      default:
        return null;
    }
  }

  /// Check if statement is an assignment
  bool _isAssignment(String stmt) {
    return stmt.contains('=') && !stmt.contains('==') && !stmt.contains('!=') && !stmt.contains('<=') && !stmt.contains('>=');
  }

  /// Handle assignment
  Future<void> _handleAssignment(String stmt) async {
    if (stmt.endsWith(';')) stmt = stmt.substring(0, stmt.length - 1);

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

    if (!currentScope.has(varName)) {
      throw Exception('Semantical Error: Undefined variable: $varName');
    }

    final value = evaluateExpression(valueExpr);
    currentScope.set(varName, value);
    log('Variable $varName assigned value: $value');
  }

  /// Handle increment/decrement operators (++, --)
  void _handleIncrementDecrement(String stmt) {
    stmt = stmt.trim();
    if (stmt.endsWith(';')) stmt = stmt.substring(0, stmt.length - 1).trim();

    String varName;
    bool isIncrement;
    
    // Prefix: ++i or --i
    if (stmt.startsWith('++') || stmt.startsWith('--')) {
      isIncrement = stmt.startsWith('++');
      varName = stmt.substring(2).trim();
    }
    // Postfix: i++ or i--
    else if (stmt.endsWith('++') || stmt.endsWith('--')) {
      isIncrement = stmt.endsWith('++');
      varName = stmt.substring(0, stmt.length - 2).trim();
    }
    else {
      throw Exception('Syntactical Error: Invalid increment/decrement');
    }

    if (!currentScope.has(varName)) {
      throw Exception('Semantical Error: Undefined variable: $varName');
    }

    final currentValue = currentScope.get(varName);
    if (currentValue is! num) {
      throw Exception('Type Error: Cannot increment/decrement non-numeric variable');
    }

    final newValue = isIncrement ? currentValue + 1 : currentValue - 1;
    currentScope.set(varName, newValue);
    log('Variable $varName ${isIncrement ? "incremented" : "decremented"} to: $newValue');
  }

  /// Handle if statement
  Future<void> _handleIf(String stmt) async {
    // Extract condition
    final condStart = stmt.indexOf('(');
    final condEnd = _findMatchingParen(stmt, condStart);
    
    if (condStart == -1 || condEnd == -1) {
      throw Exception('Syntactical Error: Invalid if statement');
    }

    final condition = stmt.substring(condStart + 1, condEnd);
    
    // Extract if body
    final ifBody = _extractBlock(stmt, condEnd);
    
    // Check for else
    String? elseBody;
    final elseMatch = RegExp(r'\}\s*else\s*\{').firstMatch(stmt);
    if (elseMatch != null) {
      elseBody = _extractBlock(stmt, elseMatch.end - 1);
    }

    try {
      final condValue = evaluateExpression(condition);
      
      pushScope();
      if (_toBool(condValue)) {
        await _executeBlock(ifBody);
      } else if (elseBody != null) {
        await _executeBlock(elseBody);
      }
      popScope();
    } catch (e) {
      throw Exception('Logical Error in if condition: $e');
    }
  }

  /// Find matching closing parenthesis
  int _findMatchingParen(String code, int openIndex) {
    int depth = 0;
    bool inString = false;
    String? stringChar;

    for (int i = openIndex; i < code.length; i++) {
      final char = code[i];

      if ((char == '"' || char == "'") && (i == 0 || code[i - 1] != '\\')) {
        if (!inString) {
          inString = true;
          stringChar = char;
        } else if (char == stringChar) {
          inString = false;
          stringChar = null;
        }
      }

      if (!inString) {
        if (char == '(') depth++;
        if (char == ')') {
          depth--;
          if (depth == 0) return i;
        }
      }
    }
    return -1;
  }

  /// Handle while loop
  Future<void> _handleWhile(String stmt) async {
    final condStart = stmt.indexOf('(');
    final condEnd = _findMatchingParen(stmt, condStart);
    
    if (condStart == -1 || condEnd == -1) {
      throw Exception('Syntactical Error: Invalid while loop');
    }

    final condition = stmt.substring(condStart + 1, condEnd);
    final body = _extractBlock(stmt, condEnd);

    while (true) {
      try {
        final condValue = evaluateExpression(condition);
        if (!_toBool(condValue)) break;
      } catch (e) {
        throw Exception('Logical Error in while condition: $e');
      }

      pushScope();
      shouldBreak = false;
      shouldContinue = false;
      
      await _executeBlock(body);
      
      popScope();
      
      if (shouldBreak) {
        shouldBreak = false;
        break;
      }
      if (shouldReturn) break;
    }
  }

  /// Handle for loop
  Future<void> _handleFor(String stmt) async {
    final condStart = stmt.indexOf('(');
    final condEnd = _findMatchingParen(stmt, condStart);
    
    if (condStart == -1 || condEnd == -1) {
      throw Exception('Syntactical Error: Invalid for loop');
    }

    final forHeader = stmt.substring(condStart + 1, condEnd);
    
    // Split by semicolons (not inside strings or parens)
    final parts = _splitForHeader(forHeader);
    if (parts.length != 3) {
      throw Exception('Syntactical Error: Invalid for loop header');
    }

    final init = parts[0].trim();
    final condition = parts[1].trim();
    final update = parts[2].trim();
    final body = _extractBlock(stmt, condEnd);

    pushScope();
    
    // Initialize
    if (init.isNotEmpty) {
      await _executeStatement(init + ';');
    }

    // Loop
    while (true) {
      try {
        if (condition.isNotEmpty) {
          final condValue = evaluateExpression(condition);
          if (!_toBool(condValue)) break;
        }
      } catch (e) {
        throw Exception('Logical Error in for condition: $e');
      }

      shouldBreak = false;
      shouldContinue = false;
      
      await _executeBlock(body);
      
      if (shouldBreak) {
        shouldBreak = false;
        break;
      }
      
      if (shouldReturn) break;
      
      // Reset continue flag before update
      shouldContinue = false;
      
      if (!shouldReturn && update.isNotEmpty) {
        await _executeStatement(update + ';');
      }
    }

    popScope();
  }

  /// Split for loop header by semicolons (respecting strings and parens)
  List<String> _splitForHeader(String header) {
    final parts = <String>[];
    final buffer = StringBuffer();
    int parenDepth = 0;
    bool inString = false;
    String? stringChar;

    for (int i = 0; i < header.length; i++) {
      final char = header[i];

      if ((char == '"' || char == "'") && (i == 0 || header[i - 1] != '\\')) {
        if (!inString) {
          inString = true;
          stringChar = char;
        } else if (char == stringChar) {
          inString = false;
          stringChar = null;
        }
      }

      if (!inString) {
        if (char == '(') parenDepth++;
        if (char == ')') parenDepth--;

        if (char == ';' && parenDepth == 0) {
          parts.add(buffer.toString());
          buffer.clear();
          continue;
        }
      }

      buffer.write(char);
    }

    parts.add(buffer.toString());
    return parts;
  }

  /// Handle do-while loop
  Future<void> _handleDoWhile(String stmt) async {
    final match = RegExp(r'do\s*\{(.*?)\}\s*while\s*\((.*?)\)', dotAll: true).firstMatch(stmt);
    
    if (match == null) {
      throw Exception('Syntactical Error: Invalid do-while loop');
    }

    final body = match.group(1)!;
    final condition = match.group(2)!;

    do {
      pushScope();
      shouldBreak = false;
      shouldContinue = false;
      
      await _executeBlock(body);
      
      popScope();
      
      if (shouldBreak) {
        shouldBreak = false;
        break;
      }
      if (shouldReturn) break;

      try {
        final condValue = evaluateExpression(condition);
        if (!_toBool(condValue)) break;
      } catch (e) {
        throw Exception('Logical Error in do-while condition: $e');
      }
    } while (true);
  }

  /// Handle switch statement
  Future<void> _handleSwitch(String stmt) async {
    final match = RegExp(r'switch\s*\((.*?)\)\s*\{(.*?)\}', dotAll: true).firstMatch(stmt);
    
    if (match == null) {
      throw Exception('Syntactical Error: Invalid switch statement');
    }

    final expr = match.group(1)!;
    final body = match.group(2)!;

    try {
      final switchValue = evaluateExpression(expr);
      
      // Parse cases
      final casePattern = RegExp(r'case\s+(.*?):(.*?)(?=case|default|$)', dotAll: true);
      final defaultPattern = RegExp(r'default\s*:(.*?)$', dotAll: true);

      bool matched = false;
      
      for (final caseMatch in casePattern.allMatches(body)) {
        final caseValue = caseMatch.group(1)!.trim();
        final caseBody = caseMatch.group(2)!;
        
        final caseVal = evaluateExpression(caseValue);
        
        if (switchValue == caseVal) {
          matched = true;
          pushScope();
          await _executeBlock(caseBody);
          popScope();
          
          if (shouldBreak) {
            shouldBreak = false;
            break;
          }
        }
      }

      if (!matched) {
        final defaultMatch = defaultPattern.firstMatch(body);
        if (defaultMatch != null) {
          final defaultBody = defaultMatch.group(1)!;
          pushScope();
          await _executeBlock(defaultBody);
          popScope();
        }
      }
    } catch (e) {
      throw Exception('Logical Error in switch: $e');
    }
  }

  /// Handle try-catch
  Future<void> _handleTryCatch(String stmt) async {
    // Find try block
    final tryStart = stmt.indexOf('try');
    if (tryStart == -1) {
      throw Exception('Syntactical Error: Invalid try-catch - no try keyword');
    }
    
    final tryBlockStart = stmt.indexOf('{', tryStart);
    if (tryBlockStart == -1) {
      throw Exception('Syntactical Error: Invalid try-catch - no opening brace after try');
    }
    
    final tryBody = _extractBlock(stmt, tryBlockStart);
    
    // Find catch block
    final catchStart = stmt.indexOf('catch', tryBlockStart);
    if (catchStart == -1) {
      throw Exception('Syntactical Error: Invalid try-catch - no catch keyword');
    }
    
    final catchBlockStart = stmt.indexOf('{', catchStart);
    if (catchBlockStart == -1) {
      throw Exception('Syntactical Error: Invalid try-catch - no opening brace after catch');
    }
    
    final catchBody = _extractBlock(stmt, catchBlockStart);

    try {
      pushScope();
      await _executeBlock(tryBody);
      popScope();
    } catch (e) {
      pushScope();
      await _executeBlock(catchBody);
      popScope();
    }
  }

  /// Handle cout (output)
  Future<void> _handleCout(String stmt) async {
    if (stmt.endsWith(';')) stmt = stmt.substring(0, stmt.length - 1);

    // Extract content between << operators
    final parts = stmt.split('<<').skip(1); // Skip "cout"
    final outputs = <String>[];

    for (var part in parts) {
      part = part.trim();
      if (part == 'endl') {
        outputs.add('\n');
        continue;
      }

      try {
        final value = evaluateExpression(part);
        outputs.add(value.toString());
      } catch (e) {
        outputs.add(part);
      }
    }

    log('Output: ${outputs.join('')}');
  }

  /// Handle function call
  Future<void> _handleFunctionCall(String stmt) async {
    if (stmt.endsWith(';')) stmt = stmt.substring(0, stmt.length - 1);

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
      case 'sleep':
        await _handleSleep(argsString);
        break;
      case 'getPositionX':
        // Return value function - handled in expression evaluation
        break;
      case 'getPositionY':
        // Return value function - handled in expression evaluation
        break;
      case 'getPlotState':
        // Return value function - handled in expression evaluation
        break;
      case 'getCropType':
        // Return value function - handled in expression evaluation
        break;
      case 'isCropGrown':
        // Return value function - handled in expression evaluation
        break;
      case 'canTill':
        // Return value function - handled in expression evaluation
        break;
      case 'canWater':
        // Return value function - handled in expression evaluation
        break;
      case 'canPlant':
        // Return value function - handled in expression evaluation
        break;
      case 'canHarvest':
        // Return value function - handled in expression evaluation
        break;
      case 'getPlotGridX':
        // Return value function - handled in expression evaluation
        break;
      case 'getPlotGridY':
        // Return value function - handled in expression evaluation
        break;
      default:
        throw Exception('Semantical Error: Unknown function "$functionName"');
    }
  }

  /// Handle sleep() function
  Future<void> _handleSleep(String args) async {
    final duration = evaluateExpression(args);
    if (duration is! num) {
      throw Exception('Type Error: sleep() requires numeric argument');
    }
    await executeSleep(duration);
  }

  /// Handle move() function
  void _handleMove(String args) {
    final dirPattern = RegExp(r'Direction::(\w+)', caseSensitive: false);
    final match = dirPattern.firstMatch(args);

    if (match == null) {
      throw Exception('Semantical Error: Invalid direction format');
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
        throw Exception('Semantical Error: Invalid direction "$dirStr"');
    }

    executeMove(direction);
  }

  /// Handle plant() function
  void _handlePlant(String args) {
    final cropPattern = RegExp(r'CropType::(\w+)', caseSensitive: false);
    final match = cropPattern.firstMatch(args);

    if (match == null) {
      throw Exception('Semantical Error: Invalid crop format - use CropType::CropName');
    }

    final cropStr = match.group(1)!.toLowerCase();
    final crop = CropTypeExtension.fromString(cropStr);

    if (crop == null) {
      throw Exception('Semantical Error: Unknown crop type "$cropStr"');
    }

    executePlant(crop);
  }

  @override
  dynamic evaluateFunctionCall(String expr) {
    final functionPattern = RegExp(r'^(\w+)\s*\((.*?)\)\s*$');
    final match = functionPattern.firstMatch(expr);

    if (match == null) return null;

    final functionName = match.group(1)!;

    switch (functionName) {
      case 'getPositionX':
        return executeGetPositionX();
      case 'getPositionY':
        return executeGetPositionY();
      case 'getPlotState':
        final state = executeGetPlotState();
        return _plotStateToString(state);
      case 'getCropType':
        final crop = executeGetCropType();
        return _cropTypeToString(crop);
      case 'isCropGrown':
        return executeIsCropGrown();
      case 'canTill':
        return executeCanTill();
      case 'canWater':
        return executeCanWater();
      case 'canPlant':
        return executeCanPlant();
      case 'canHarvest':
        return executeCanHarvest();
      case 'getPlotGridX':
        return executeGetPlotGridX();
      case 'getPlotGridY':
        return executeGetPlotGridY();
      default:
        return null;
    }
  }

  /// Convert PlotState to C++ enum string format
  String _plotStateToString(PlotState? state) {
    if (state == null) return 'PlotState::Normal';
    switch (state) {
      case PlotState.normal:
        return 'PlotState::Normal';
      case PlotState.tilled:
        return 'PlotState::Tilled';
      case PlotState.watered:
        return 'PlotState::Watered';
    }
  }

  /// Convert CropType to C++ enum string format
  String _cropTypeToString(CropType? crop) {
    if (crop == null) return 'CropType::None';
    return 'CropType::${crop.displayName}';
  }

  /// Convert value to boolean (wrapper for base class method)
  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.isNotEmpty;
    return false;
  }
}
