import 'base_interpreter.dart';
import '../models/farm_data.dart';

/// Comprehensive JavaScript code interpreter for farm drone operations
/// Supports: variables (var/let/const), operators, if-else, switch-case, loops, break/continue, console.log, try-catch
class JavaScriptInterpreter extends FarmCodeInterpreter {
  String _originalCode = '';

  JavaScriptInterpreter({
    required super.farmState,
    super.onCropHarvested,
    super.onLineExecuting,
    super.onLineError,
    super.onLogUpdate,
  });

  @override
  Future<ExecutionResult?> preValidate(String code) async {
    clearLog();
    log('Validating JavaScript code...');

    try {
      // Remove comments for parsing
      code = _removeComments(code);

      // Parse statements and validate syntax
      try {
        final statements = _parseStatements(code);
        
        // Validate each statement for common syntax errors
        for (int i = 0; i < statements.length; i++) {
          final stmt = statements[i].trim();
          if (stmt.isEmpty) continue;
          
          // Check for missing semicolons (less strict in JS)
          final needsSemicolon = !stmt.endsWith('{') && 
                                  !stmt.endsWith('}') && 
                                  !stmt.startsWith('if') && 
                                  !stmt.startsWith('else') &&
                                  !stmt.startsWith('for') &&
                                  !stmt.startsWith('while') &&
                                  !stmt.startsWith('do') &&
                                  !stmt.startsWith('switch') &&
                                  !stmt.startsWith('case') &&
                                  !stmt.startsWith('default') &&
                                  !stmt.startsWith('try') &&
                                  !stmt.startsWith('catch') &&
                                  !stmt.startsWith('function') &&
                                  !stmt.contains('{');
          
          if (needsSemicolon && !stmt.endsWith(';')) {
            return ExecutionResult.error(
              'Syntactical Error: Missing semicolon on line ${i + 1}',
              type: ErrorType.syntactical,
              log: executionLog,
              errorLine: i + 1,
            );
          }
        }
      } catch (e) {
        return ExecutionResult.error(
          'Syntactical Error: ${e.toString()}',
          type: ErrorType.syntactical,
          log: executionLog,
          errorLine: 1,
        );
      }

      log('Validation passed!');
      return null; // null means validation passed
    } catch (e) {
      return ExecutionResult.error(
        'Validation Error: $e',
        type: ErrorType.syntactical,
        log: executionLog,
        errorLine: 1,
      );
    }
  }

  @override
  Future<ExecutionResult> execute(String code) async {
    clearLog();
    log('Starting JavaScript code execution...');

    try {
      // Store original code for line mapping
      _originalCode = code;
      
      // Remove comments
      final cleanedCode = _removeComments(code);

      // Execute statements
      await _executeBlock(cleanedCode);

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
    // Remove multi-line comments
    code = code.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');
    // Remove single-line comments
    code = code.replaceAll(RegExp(r'//.*?$', multiLine: true), '');
    return code;
  }

  /// Find the position of the assignment operator '=' (not '==', '!=', etc.)
  int _findAssignmentOperator(String expr) {
    bool inString = false;
    String? stringChar;
    int parenDepth = 0;

    for (int i = 0; i < expr.length; i++) {
      final char = expr[i];

      // Track string literals
      if ((char == '"' || char == "'" || char == '`') && (i == 0 || expr[i - 1] != '\\')) {
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

        // Found '=' that's not part of '==', '!=', '<=', '>='
        if (char == '=' && parenDepth == 0) {
          // Check it's not part of a comparison operator
          final isComparison = (i > 0 && (expr[i - 1] == '=' || expr[i - 1] == '!' || 
                                           expr[i - 1] == '<' || expr[i - 1] == '>')) ||
                               (i < expr.length - 1 && expr[i + 1] == '=');
          if (!isComparison) {
            return i;
          }
        }
      }
    }
    return -1;
  }

  /// Extract block content between braces with proper nesting
  String _extractBlock(String code, int startIndex) {
    int braceCount = 0;
    bool inString = false;
    String? stringChar;
    int blockStart = -1;

    for (int i = startIndex; i < code.length; i++) {
      final char = code[i];

      if ((char == '"' || char == "'" || char == '`') && (i == 0 || code[i - 1] != '\\')) {
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

  /// Find matching closing parenthesis
  int _findMatchingParen(String code, int openIndex) {
    int depth = 0;
    bool inString = false;
    String? stringChar;

    for (int i = openIndex; i < code.length; i++) {
      final char = code[i];

      if ((char == '"' || char == "'" || char == '`') && (i == 0 || code[i - 1] != '\\')) {
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

  /// Split for loop header by semicolons
  List<String> _splitForHeader(String header) {
    final parts = <String>[];
    final buffer = StringBuffer();
    int parenDepth = 0;
    bool inString = false;
    String? stringChar;

    for (int i = 0; i < header.length; i++) {
      final char = header[i];

      if ((char == '"' || char == "'" || char == '`') && (i == 0 || header[i - 1] != '\\')) {
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

  /// Execute a block of code
  Future<void> _executeBlock(String block) async {
    final statements = _parseStatements(block);

    for (int i = 0; i < statements.length; i++) {
      // Check stop flag
      if (shouldStop) {
        log('Execution stopped by user');
        notifyLineExecuting(null);
        return;
      }
      
      if (shouldBreak || shouldContinue || shouldReturn) break;

      final stmt = statements[i];
      final trimmed = stmt.trim();
      if (trimmed.isEmpty) continue;

      // Find actual line number in original source code
      final lineNum = _findStatementLine(stmt);
      notifyLineExecuting(lineNum);
      
      await delay(200);
      
      // Check stop flag again after delay (responsive stopping)
      if (shouldStop) {
        log('Execution stopped by user');
        notifyLineExecuting(null);
        return;
      }
      
      await _executeStatement(trimmed);
    }
    
    // Clear line highlighting when done
    notifyLineExecuting(null);
  }
  
  /// Map statement to its line number in original code
  int _findStatementLine(String statement) {
    final lines = _originalCode.split('\n');
    final stmtKey = statement.trim().replaceAll(RegExp(r'\s+'), ' ');
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim().replaceAll(RegExp(r'\s+'), ' ');
      if (line.isEmpty) continue;
      
      // Check if this line contains a significant part of the statement
      if (stmtKey.length > 5 && line.contains(stmtKey.substring(0, (stmtKey.length * 0.6).floor()))) {
        return i + 1; // Return 1-based line number
      }
    }
    return 1; // Default to line 1 if not found
  }

  /// Parse statements from code
  List<String> _parseStatements(String code) {
    final List<String> statements = [];
    final buffer = StringBuffer();
    int braceDepth = 0;
    int parenDepth = 0;
    bool inString = false;
    String? stringChar;

    for (int i = 0; i < code.length; i++) {
      final char = code[i];

      if ((char == '"' || char == "'" || char == '`') && (i == 0 || code[i - 1] != '\\')) {
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

      // Split on semicolon at depth 0
      if (!inString && char == ';' && braceDepth == 0 && parenDepth == 0) {
        statements.add(buffer.toString().trim());
        buffer.clear();
      } 
      // Also split when control structure closes at depth 0
      else if (!inString && char == '}' && braceDepth == 0 && parenDepth == 0) {
        final current = buffer.toString().trim();
        if (current.startsWith(RegExp(r'(if|while|for|do|switch|try)'))) {
          // Check for else following if
          if (current.startsWith('if')) {
            int nextNonWhitespace = i + 1;
            while (nextNonWhitespace < code.length && code[nextNonWhitespace].trim().isEmpty) {
              nextNonWhitespace++;
            }
            if (nextNonWhitespace < code.length - 3 && 
                code.substring(nextNonWhitespace, nextNonWhitespace + 4) == 'else') {
              continue; // Don't add yet - capture else block
            }
          }
          // Check for catch following try
          if (current.startsWith('try')) {
            int nextNonWhitespace = i + 1;
            while (nextNonWhitespace < code.length && code[nextNonWhitespace].trim().isEmpty) {
              nextNonWhitespace++;
            }
            if (nextNonWhitespace < code.length - 4 && 
                code.substring(nextNonWhitespace, nextNonWhitespace + 5) == 'catch') {
              continue; // Don't add yet - capture catch block
            }
          }
          // Complete control structure - add it
          statements.add(current);
          buffer.clear();
        }
      }
    }

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

    // Variable declaration (var, let, const)
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

    // console.log
    if (stmt.contains('console.log')) {
      await _handleConsoleLog(stmt);
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
    return stmt.startsWith('var ') || stmt.startsWith('let ') || stmt.startsWith('const ');
  }

  /// Handle variable declaration
  Future<void> _handleVariableDeclaration(String stmt) async {
    if (stmt.endsWith(';')) stmt = stmt.substring(0, stmt.length - 1);

    final spaceIndex = stmt.indexOf(' ');
    if (spaceIndex == -1) {
      throw Exception('Syntactical Error: Invalid variable declaration');
    }

    // Extract keyword (var/let/const) and rest of declaration
    final rest = stmt.substring(spaceIndex + 1).trim();

    // Find the first '=' that is not part of '==' or other comparison operators
    final assignIndex = _findAssignmentOperator(rest);
    if (assignIndex != -1) {
      final varName = rest.substring(0, assignIndex).trim();
      final valueExpr = rest.substring(assignIndex + 1).trim();

      if (!RegExp(r'^[a-zA-Z_$][\w$]*$').hasMatch(varName)) {
        throw Exception('Lexical Error: Invalid variable name: $varName');
      }

      final value = evaluateExpression(valueExpr);
      currentScope.define(varName, value);
      log('Variable $varName declared with value: $value');
    } else {
      final varName = rest.trim();
      if (!RegExp(r'^[a-zA-Z_$][\w$]*$').hasMatch(varName)) {
        throw Exception('Lexical Error: Invalid variable name: $varName');
      }
      currentScope.define(varName, null);
      log('Variable $varName declared');
    }
  }

  /// Check if statement is an assignment
  bool _isAssignment(String stmt) {
    return stmt.contains('=') && !stmt.contains('==') && !stmt.contains('!=') && !stmt.contains('<=') && !stmt.contains('>=') && !stmt.contains('var ') && !stmt.contains('let ') && !stmt.contains('const ');
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
    final condStart = stmt.indexOf('(');
    final condEnd = _findMatchingParen(stmt, condStart);
    
    if (condStart == -1 || condEnd == -1) {
      throw Exception('Syntactical Error: Invalid if statement');
    }

    final condition = stmt.substring(condStart + 1, condEnd);
    final ifBody = _extractBlock(stmt, condEnd);
    
    String? elseBody;
    final elseIdx = stmt.indexOf('} else', condEnd);
    if (elseIdx != -1) {
      final afterElse = elseIdx + 6; // Position after "} else"
      // Skip whitespace
      int pos = afterElse;
      while (pos < stmt.length && stmt[pos].trim().isEmpty) {
        pos++;
      }
      
      // Check if it's "else if" or just "else"
      if (pos < stmt.length && stmt.substring(pos).startsWith('if')) {
        // else if - extract the entire if statement
        elseBody = stmt.substring(pos);
      } else if (pos < stmt.length && stmt[pos] == '{') {
        // else { - extract just the block
        elseBody = _extractBlock(stmt, pos);
      }
    }

    try {
      final condValue = evaluateExpression(condition);
      
      pushScope();
      if (_toBool(condValue)) {
        await _executeBlock(ifBody);
      } else if (elseBody != null) {
        // If elseBody starts with "if", handle it as an if statement
        if (elseBody.trim().startsWith('if')) {
          await _handleIf(elseBody);
        } else {
          await _executeBlock(elseBody);
        }
      }
      popScope();
    } catch (e) {
      throw Exception('Logical Error in if condition: $e');
    }
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
    final parts = _splitForHeader(forHeader);
    
    if (parts.length != 3) {
      throw Exception('Syntactical Error: Invalid for loop header');
    }

    final init = parts[0].trim();
    final condition = parts[1].trim();
    final update = parts[2].trim();
    final body = _extractBlock(stmt, condEnd);

    pushScope();
    
    if (init.isNotEmpty) {
      await _executeStatement(init + ';');
    }

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
    final match = RegExp(r'try\s*\{(.*?)\}\s*catch\s*\([^)]*\)\s*\{(.*?)\}', dotAll: true).firstMatch(stmt);
    
    if (match == null) {
      throw Exception('Syntactical Error: Invalid try-catch');
    }

    final tryBody = match.group(1)!;
    final catchBody = match.group(2)!;

    try {
      pushScope();
      await _executeBlock(tryBody);
      popScope();
    } catch (e) {
      log('Exception caught: $e');
      pushScope();
      await _executeBlock(catchBody);
      popScope();
    }
  }

  /// Handle console.log
  Future<void> _handleConsoleLog(String stmt) async {
    if (stmt.endsWith(';')) stmt = stmt.substring(0, stmt.length - 1);

    final match = RegExp(r'console\.log\((.*?)\)$').firstMatch(stmt);
    if (match == null) {
      throw Exception('Syntactical Error: Invalid console.log statement');
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
      default:
        throw Exception('Semantical Error: Unknown function "$functionName"');
    }
  }

  Future<void> _handleSleep(String args) async {
    final duration = evaluateExpression(args);
    if (duration is! num) {
      throw Exception('Type Error: sleep() requires numeric argument');
    }
    await executeSleep(duration);
  }

  @override
  dynamic evaluateFunctionCall(String expr) {
    final functionPattern = RegExp(r'^(\w+)\s*\((.*?)\)\s*$');
    final match = functionPattern.firstMatch(expr);
    if (match == null) return null;
    final functionName = match.group(1)!;
    switch (functionName) {
      case 'getPositionX': return executeGetPositionX();
      case 'getPositionY': return executeGetPositionY();
      case 'getPlotState':
        final state = executeGetPlotState();
        return _plotStateToString(state);
      case 'getCropType':
        final crop = executeGetCropType();
        return _cropTypeToString(crop);
      case 'isCropGrown': return executeIsCropGrown();
      case 'canTill': return executeCanTill();
      case 'canWater': return executeCanWater();
      case 'canPlant': return executeCanPlant();
      case 'canHarvest': return executeCanHarvest();
      case 'getPlotGridX': return executeGetPlotGridX();
      case 'getPlotGridY': return executeGetPlotGridY();
      case 'hasSeed': return _handleHasSeed(match.group(2)!);
      case 'getSeedInventoryCount': return _handleGetSeedInventoryCount(match.group(2)!);
      case 'getCropInventoryCount': return _handleGetCropInventoryCount(match.group(2)!);
      default: return null;
    }
  }

  /// Handle hasSeed() function
  bool _handleHasSeed(String args) {
    args = args.replaceAll('"', '').replaceAll("'", '').replaceAll('`', '').trim();
    final seedPattern = RegExp(r'SeedType\.(\w+)', caseSensitive: false);
    final match = seedPattern.firstMatch(args);

    String seedStr;
    if (match != null) {
      seedStr = match.group(1)!;
    } else {
      seedStr = args;
    }

    final seed = SeedTypeExtension.fromString(seedStr);
    if (seed == null) {
      throw Exception('Semantical Error: Unknown seed type "$seedStr"');
    }

    return executeHasSeed(seed);
  }

  /// Handle getSeedInventoryCount() function
  int _handleGetSeedInventoryCount(String args) {
    args = args.replaceAll('"', '').replaceAll("'", '').replaceAll('`', '').trim();
    final seedPattern = RegExp(r'SeedType\.(\w+)', caseSensitive: false);
    final match = seedPattern.firstMatch(args);

    String seedStr;
    if (match != null) {
      seedStr = match.group(1)!;
    } else {
      seedStr = args;
    }

    final seed = SeedTypeExtension.fromString(seedStr);
    if (seed == null) {
      throw Exception('Semantical Error: Unknown seed type "$seedStr"');
    }

    return executeGetSeedInventoryCount(seed);
  }

  /// Handle getCropInventoryCount() function
  int _handleGetCropInventoryCount(String args) {
    args = args.replaceAll('"', '').replaceAll("'", '').replaceAll('`', '').trim();
    final cropPattern = RegExp(r'CropType\.(\w+)', caseSensitive: false);
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

    return executeGetCropInventoryCount(crop);
  }

  String _plotStateToString(PlotState? state) {
    if (state == null) return 'PlotState.Normal';
    switch (state) {
      case PlotState.normal: return 'PlotState.Normal';
      case PlotState.tilled: return 'PlotState.Tilled';
      case PlotState.watered: return 'PlotState.Watered';
    }
  }

  String _cropTypeToString(CropType? crop) {
    if (crop == null) return 'CropType.None';
    return 'CropType.${crop.displayName}';
  }

  /// Handle move() function
  void _handleMove(String args) {
    args = args.replaceAll('"', '').replaceAll("'", '').replaceAll('`', '').trim();

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

  /// Handle plant() function (now uses SeedType)
  void _handlePlant(String args) {
    args = args.replaceAll('"', '').replaceAll("'", '').replaceAll('`', '').trim();

    final seedPattern = RegExp(r'SeedType\.(\w+)', caseSensitive: false);
    final match = seedPattern.firstMatch(args);

    String seedStr;
    if (match != null) {
      seedStr = match.group(1)!;
    } else {
      seedStr = args;
    }

    final seed = SeedTypeExtension.fromString(seedStr);

    if (seed == null) {
      throw Exception('Semantical Error: Unknown seed type "$seedStr"');
    }

    executePlant(seed);
  }

  /// Convert value to boolean
  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.isNotEmpty;
    return value != null;
  }
}
