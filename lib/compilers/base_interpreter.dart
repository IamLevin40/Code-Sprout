import '../models/farm_data.dart';
import '../models/research_data.dart';
import '../models/research_items_schema.dart';

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
  final int? errorLine; // Line number where error occurred (1-based)

  ExecutionResult({
    required this.success,
    this.errorMessage,
    this.errorType,
    List<String>? executionLog,
    this.errorLine,
  }) : executionLog = executionLog ?? [];

  ExecutionResult.success({List<String>? log})
      : success = true,
        errorMessage = null,
        errorType = null,
        errorLine = null,
        executionLog = log ?? [];

  ExecutionResult.error(String message, {ErrorType? type, List<String>? log, this.errorLine})
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
  bool shouldStop = false; // Flag for stopping execution
  
  // Execution callbacks for line tracking and log updates
  Function(int?)? onLineExecuting; // Callback when executing a line (1-based, null = done)
  Function(int?, bool)? onLineError; // Callback when error on a line (line number, isError)
  Function(String)? onLogUpdate; // Callback when log is updated

  final ResearchState? researchState;

  FarmCodeInterpreter({
    required this.farmState,
    this.onCropHarvested,
    this.onLineExecuting,
    this.onLineError,
    this.onLogUpdate,
    this.researchState,
  });

  /// Parse and execute code
  Future<ExecutionResult> execute(String code);

  /// Log a message during execution
  void log(String message) {
    executionLog.add(message);
    onLogUpdate?.call(message); // Notify listener of new log entry
  }
  
  /// Stop execution gracefully (will finish current statement)
  void stop() {
    if (!shouldStop) {
      shouldStop = true;
      log('Stop requested - finishing current operation...');
    }
  }
  
  /// Pre-validate code for syntax/semantic errors before execution
  Future<ExecutionResult?> preValidate(String code);
  
  /// Notify line execution
  void notifyLineExecuting(int? lineNumber) {
    onLineExecuting?.call(lineNumber);
  }
  
  /// Notify line error
  void notifyLineError(int? lineNumber, bool isError) {
    onLineError?.call(lineNumber, isError);
  }

  /// Clear execution log and reset state
  void clearLog() {
    executionLog.clear();
    currentScope = VariableScope();
    shouldBreak = false;
    shouldContinue = false;
    shouldReturn = false;
  }

  /// Check if a function is unlocked by research
  bool _isFunctionUnlocked(String functionSignature) {
    if (researchState == null) {
      return false; // If no research state, disallow all functions
    }

    // Get all completed function research IDs
    final completedResearchIds = researchState!.completedFunctionsResearches;
    
    // Check if any completed research unlocks this function
    for (final researchId in completedResearchIds) {
      final schema = ResearchItemsSchema.instance.getFunctionsItem(researchId);
      if (schema != null && schema.functionsUnlocked.contains(functionSignature)) {
        return true;
      }
    }

    return false; // Function not unlocked
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
    
    // Strip outer parentheses if they wrap the entire expression
    while (expr.startsWith('(') && expr.endsWith(')')) {
      int depth = 0;
      bool isOuterParen = true;
      for (int i = 0; i < expr.length; i++) {
        if (expr[i] == '(') depth++;
        if (expr[i] == ')') depth--;
        // If depth becomes 0 before the end, outer parens don't wrap everything
        if (depth == 0 && i < expr.length - 1) {
          isOuterParen = false;
          break;
        }
      }
      if (isOuterParen) {
        expr = expr.substring(1, expr.length - 1).trim();
      } else {
        break;
      }
    }
    
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

    // Handle enum literals (e.g., PlotState::Normal, CropType::Wheat)
    // These are returned as string representations for comparison
    // Check this before function calls to avoid treating enums as functions
    if (!expr.contains('(') && (expr.contains('::') || 
        (expr.contains('.') && !expr.contains(' ')))) {
      return expr; // Return as-is for string comparison
    }

    // Handle function calls (must come before variable check)
    if (expr.contains('(') && expr.contains(')')) {
      final result = evaluateFunctionCall(expr);
      if (result != null) return result;
    }
    
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
        // Handle string equality for enum comparisons
        if (left is String && right is String) {
          return left == right;
        }
        return left == right;
      case '!=':
        // Handle string inequality for enum comparisons
        if (left is String && right is String) {
          return left != right;
        }
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
    if (!_isFunctionUnlocked('move(direction)')) {
      log('Error: Function not unlocked. Research the required functions to use move(direction)');
      return false;
    }
    final dirName = direction.toString().split('.').last;
    log('Moving drone $dirName...');
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
    if (!_isFunctionUnlocked('till()')) {
      log('Error: Function not unlocked. Research the required functions to use till()');
      return false;
    }
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
    if (!_isFunctionUnlocked('water()')) {
      log('Error: Function not unlocked. Research the required functions to use water()');
      return false;
    }
    log('Watering soil...');
    final success = farmState.waterCurrentPlot();
    if (success) {
      log('Soil watered successfully');
    } else {
      log('Error: Cannot water this plot');
    }
    return success;
  }

  /// Execute plant operation (now uses SeedType)
  bool executePlant(SeedType seed) {
    if (!_isFunctionUnlocked('plant(seedType)')) {
      log('Error: Function not unlocked. Research the required functions to use plant(seedType)');
      return false;
    }
    log('Planting ${seed.displayName}...');
    // `plantSeed` now returns the number of plots planted (int).
    final plantedCount = farmState.plantSeed(seed);
    if (plantedCount > 0) {
      log('${seed.displayName} planted successfully on $plantedCount plot${plantedCount > 1 ? 's' : ''}');
      return true;
    } else {
      log('Error: Cannot plant on this plot (check if you have seeds or plot is not tillable)');
      return false;
    }
  }

  /// Execute harvest operation
  Future<bool> executeHarvest() async {
    if (!_isFunctionUnlocked('harvest()')) {
      log('Error: Function not unlocked. Research the required functions to use harvest()');
      return false;
    }
    log('Harvesting crop...');
    final result = await farmState.harvestCurrentPlot();
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

  /// Execute sleep operation - pauses drone operation
  Future<void> executeSleep(num duration) async {
    if (!_isFunctionUnlocked('sleep(duration)')) {
      log('Error: Function not unlocked. Research the required functions to use sleep(duration)');
      return;
    }
    log('Sleeping for $duration seconds...');
    await Future.delayed(Duration(milliseconds: (duration * 1000).round()));
    log('Sleep completed');
  }

  /// Get current X position of drone
  int executeGetPositionX() {
    if (!_isFunctionUnlocked('getPositionX()')) {
      log('Error: Function not unlocked. Research the required functions to use getPositionX()');
      return -1;
    }
    return farmState.dronePosition.x;
  }

  /// Get current Y position of drone
  int executeGetPositionY() {
    if (!_isFunctionUnlocked('getPositionY()')) {
      log('Error: Function not unlocked. Research the required functions to use getPositionY()');
      return -1;
    }
    return farmState.dronePosition.y;
  }

  /// Get plot state at current position
  PlotState? executeGetPlotState() {
    if (!_isFunctionUnlocked('getPlotState()')) {
      log('Error: Function not unlocked. Research the required functions to use getPlotState()');
      return null;
    }
    final plot = farmState.getCurrentPlot();
    return plot?.state;
  }

  /// Get crop type at current position
  CropType? executeGetCropType() {
    if (!_isFunctionUnlocked('getCropType()')) {
      log('Error: Function not unlocked. Research the required functions to use getCropType()');
      return null;
    }
    final plot = farmState.getCurrentPlot();
    return plot?.crop?.cropType;
  }

  /// Check if crop at current position is fully grown
  bool executeIsCropGrown() {
    if (!_isFunctionUnlocked('isCropGrown()')) {
      log('Error: Function not unlocked. Research the required functions to use isCropGrown()');
      return false;
    }
    final plot = farmState.getCurrentPlot();
    return plot?.crop?.isGrown ?? false;
  }

  /// Check if current plot can be tilled
  bool executeCanTill() {
    if (!_isFunctionUnlocked('canTill()')) {
      log('Error: Function not unlocked. Research the required functions to use canTill()');
      return false;
    }
    final plot = farmState.getCurrentPlot();
    return plot?.canTill() ?? false;
  }

  /// Check if current plot can be watered
  bool executeCanWater() {
    if (!_isFunctionUnlocked('canWater()')) {
      log('Error: Function not unlocked. Research the required functions to use canWater()');
      return false;
    }
    final plot = farmState.getCurrentPlot();
    return plot?.canWater() ?? false;
  }

  /// Check if current plot can be planted
  bool executeCanPlant() {
    if (!_isFunctionUnlocked('canPlant()')) {
      log('Error: Function not unlocked. Research the required functions to use canPlant()');
      return false;
    }
    final plot = farmState.getCurrentPlot();
    return plot?.canPlant() ?? false;
  }

  /// Check if current plot can be harvested
  bool executeCanHarvest() {
    if (!_isFunctionUnlocked('canHarvest()')) {
      log('Error: Function not unlocked. Research the required functions to use canHarvest()');
      return false;
    }
    final plot = farmState.getCurrentPlot();
    return plot?.canHarvest() ?? false;
  }

  /// Get grid width (number of plots horizontally)
  int executeGetPlotGridX() {
    if (!_isFunctionUnlocked('getPlotGridX()')) {
      log('Error: Function not unlocked. Research the required functions to use getPlotGridX()');
      return -1;
    }
    return farmState.gridWidth;
  }

  /// Get grid height (number of plots vertically)
  int executeGetPlotGridY() {
    if (!_isFunctionUnlocked('getPlotGridY()')) {
      log('Error: Function not unlocked. Research the required functions to use getPlotGridY()');
      return -1;
    }
    return farmState.gridHeight;
  }

  /// Check if user has at least one seed of the specified type
  bool executeHasSeed(SeedType seedType) {
    if (!_isFunctionUnlocked('hasSeed(seedType)')) {
      log('Error: Function not unlocked. Research the required functions to use hasSeed(seedType)');
      return false;
    }
    return farmState.hasSeed(seedType);
  }

  /// Get the quantity of a specific seed type in inventory
  int executeGetSeedInventoryCount(SeedType seedType) {
    if (!_isFunctionUnlocked('getSeedInventoryCount(seedType)')) {
      log('Error: Function not unlocked. Research the required functions to use getSeedInventoryCount(seedType)');
      return -1;
    }
    return farmState.getSeedInventoryCount(seedType);
  }

  /// Get the quantity of a specific crop type in inventory
  int executeGetCropInventoryCount(CropType cropType) {
    if (!_isFunctionUnlocked('getCropInventoryCount(cropType)')) {
      log('Error: Function not unlocked. Research the required functions to use getCropInventoryCount(cropType)');
      return -1;
    }
    return farmState.getCropInventoryCount(cropType);
  }

  /// Evaluate function call that returns a value
  /// This method should be overridden by language-specific interpreters
  /// to handle their specific syntax (e.g., PlotState::Normal vs PlotState.Normal)
  dynamic evaluateFunctionCall(String expr) {
    // Base implementation - subclasses should override for language-specific syntax
    return null;
  }
}
