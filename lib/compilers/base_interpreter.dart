import '../models/farm_data.dart';

/// Error types for better error categorization
enum ErrorType {
  lexical,     // Invalid tokens/characters
  syntactical, // Invalid syntax/grammar
  semantical,  // Type errors, undefined variables
  logical,     // Runtime logic errors
  runtime,     // General runtime errors
}

/// Result of a code execution
class ExecutionResult {
  final bool success;
  final String? errorMessage;
  final ErrorType? errorType;
  final List<String> executionLog;

  ExecutionResult({
    required this.success,
    this.errorMessage,
    this.errorType,
    List<String>? executionLog,
  }) : executionLog = executionLog ?? [];

  ExecutionResult.success({List<String>? log})
      : success = true,
        errorMessage = null,
        errorType = null,
        executionLog = log ?? [];

  ExecutionResult.error(String message, {ErrorType? type, List<String>? log})
      : success = false,
        errorMessage = message,
        errorType = type,
        executionLog = log ?? [];
}

/// Variable scope for managing variable declarations
class VariableScope {
  final Map<String, dynamic> _variables = {};
  final VariableScope? parent;

  VariableScope({this.parent});

  void define(String name, dynamic value) {
    _variables[name] = value;
  }

  dynamic get(String name) {
    if (_variables.containsKey(name)) {
      return _variables[name];
    }
    if (parent != null) {
      return parent!.get(name);
    }
    return null;
  }

  bool has(String name) {
    return _variables.containsKey(name) || (parent?.has(name) ?? false);
  }

  void set(String name, dynamic value) {
    if (_variables.containsKey(name)) {
      _variables[name] = value;
    } else if (parent != null && parent!.has(name)) {
      parent!.set(name, value);
    } else {
      throw Exception('Undefined variable: $name');
    }
  }
}

/// Base class for all language compilers/interpreters
abstract class FarmCodeInterpreter {
  final FarmState farmState;
  final Function(CropType)? onCropHarvested;
  final List<String> executionLog = [];
  
  // Variable management
  VariableScope currentScope = VariableScope();
  
  // Control flow flags
  bool shouldBreak = false;
  bool shouldContinue = false;
  bool shouldReturn = false;

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

  /// Clear execution log and reset state
  void clearLog() {
    executionLog.clear();
    currentScope = VariableScope();
    shouldBreak = false;
    shouldContinue = false;
    shouldReturn = false;
  }
  
  /// Create a new scope (for blocks, loops, functions)
  void pushScope() {
    currentScope = VariableScope(parent: currentScope);
  }
  
  /// Exit current scope
  void popScope() {
    if (currentScope.parent != null) {
      currentScope = currentScope.parent!;
    }
  }
  
  /// Evaluate arithmetic/logical expressions
  dynamic evaluateExpression(String expr) {
    expr = expr.trim();
    
    // Handle literals
    if (expr == 'true') return true;
    if (expr == 'false') return false;
    
    // Handle string literals
    if ((expr.startsWith('"') && expr.endsWith('"')) ||
        (expr.startsWith("'") && expr.endsWith("'"))) {
      return expr.substring(1, expr.length - 1);
    }
    
    // Handle numbers
    final numVal = num.tryParse(expr);
    if (numVal != null) return numVal;
    
    // Handle variables
    if (RegExp(r'^[a-zA-Z_]\w*$').hasMatch(expr)) {
      if (currentScope.has(expr)) {
        return currentScope.get(expr);
      }
      throw Exception('Undefined variable: $expr');
    }
    
    // Handle binary operators (simplified)
    // Priority: ||, &&, ==, !=, <, >, <=, >=, +, -, *, /, %
    
    // Logical OR
    final orParts = _splitByOperator(expr, '||');
    if (orParts.length > 1) {
      for (final part in orParts) {
        final val = evaluateExpression(part);
        if (_toBool(val)) return true;
      }
      return false;
    }
    
    // Logical AND
    final andParts = _splitByOperator(expr, '&&');
    if (andParts.length > 1) {
      for (final part in andParts) {
        final val = evaluateExpression(part);
        if (!_toBool(val)) return false;
      }
      return true;
    }
    
    // Comparison operators
    for (final op in ['==', '!=', '<=', '>=', '<', '>']) {
      final parts = _splitByOperator(expr, op);
      if (parts.length == 2) {
        final left = evaluateExpression(parts[0]);
        final right = evaluateExpression(parts[1]);
        return _compareValues(left, right, op);
      }
    }
    
    // Arithmetic operators (special handling for string concatenation)
    for (final op in ['+', '-', '*', '/', '%']) {
      final parts = _splitByOperator(expr, op);
      if (parts.length >= 2) {
        // Handle multiple parts (e.g., a + b + c)
        dynamic result = evaluateExpression(parts[0]);
        for (int i = 1; i < parts.length; i++) {
          final right = evaluateExpression(parts[i]);
          result = _arithmeticOperation(result, right, op);
        }
        return result;
      }
    }
    
    return expr;
  }
  
  /// Split expression by operator (respects parentheses and quotes)
  List<String> _splitByOperator(String expr, String op) {
    int parenDepth = 0;
    int lastSplit = 0;
    List<String> parts = [];
    bool inString = false;
    String? stringChar;
    
    for (int i = 0; i <= expr.length - op.length; i++) {
      // Track string literals
      if ((expr[i] == '"' || expr[i] == "'") && (i == 0 || expr[i - 1] != '\\')) {
        if (!inString) {
          inString = true;
          stringChar = expr[i];
        } else if (expr[i] == stringChar) {
          inString = false;
          stringChar = null;
        }
      }
      
      if (!inString) {
        if (expr[i] == '(') parenDepth++;
        if (expr[i] == ')') parenDepth--;
        
        if (parenDepth == 0 && expr.substring(i, i + op.length) == op) {
          parts.add(expr.substring(lastSplit, i).trim());
          lastSplit = i + op.length;
        }
      }
    }
    
    if (parts.isNotEmpty) {
      parts.add(expr.substring(lastSplit).trim());
    }
    
    return parts.isEmpty ? [expr] : parts;
  }
  
  /// Convert value to boolean
  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.isNotEmpty;
    return false;
  }
  
  /// Compare two values
  bool _compareValues(dynamic left, dynamic right, String op) {
    switch (op) {
      case '==':
        return left == right;
      case '!=':
        return left != right;
      case '<':
        return (left as num) < (right as num);
      case '>':
        return (left as num) > (right as num);
      case '<=':
        return (left as num) <= (right as num);
      case '>=':
        return (left as num) >= (right as num);
      default:
        return false;
    }
  }
  
  /// Perform arithmetic operation
  dynamic _arithmeticOperation(dynamic left, dynamic right, String op) {
    if (op == '+' && (left is String || right is String)) {
      return left.toString() + right.toString();
    }
    
    final l = left is num ? left : num.tryParse(left.toString()) ?? 0;
    final r = right is num ? right : num.tryParse(right.toString()) ?? 0;
    
    switch (op) {
      case '+':
        return l + r;
      case '-':
        return l - r;
      case '*':
        return l * r;
      case '/':
        if (r == 0) throw Exception('Division by zero');
        return l / r;
      case '%':
        return l % r;
      default:
        return 0;
    }
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
    final result = farmState.harvestCurrentPlot();
    if (result != null) {
      final cropType = result['cropType'] as CropType;
      final quantity = result['quantity'] as int;
      log('Harvested $quantity ${cropType.displayName}${quantity > 1 ? 's' : ''}!');
      onCropHarvested?.call(cropType);
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
