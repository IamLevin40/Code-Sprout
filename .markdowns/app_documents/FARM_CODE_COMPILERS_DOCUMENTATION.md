# Code Sprout - Farm Code Compilers & Interpreters Documentation

## Table of Contents
1. [System Overview](#system-overview)
2. [Architecture Overview](#architecture-overview)
3. [Base Interpreter Framework](#base-interpreter-framework)
4. [Language-Specific Interpreters](#language-specific-interpreters)
5. [Code Execution Pipeline](#code-execution-pipeline)
6. [Research-Gated Function System](#research-gated-function-system)
7. [Expression Evaluation Engine](#expression-evaluation-engine)
8. [Error Detection & Handling](#error-detection--handling)
9. [Variable Scope Management](#variable-scope-management)
10. [Control Flow Implementation](#control-flow-implementation)
11. [Drone Operation Functions](#drone-operation-functions)
12. [Code Validation System](#code-validation-system)
13. [Execution Logging & Debugging](#execution-logging--debugging)
14. [Line Tracking & Visualization](#line-tracking--visualization)
15. [Workflow Diagrams](#workflow-diagrams)

---

## System Overview

The Code Sprout interpreter system is a **custom-built, multi-language code execution engine** designed specifically for educational farming simulations. It interprets user-written code in real programming languages (C++, C#, Java, JavaScript, Python) to control a virtual farming drone.

### Purpose
- **Educational**: Teach real programming syntax and semantics
- **Safe Execution**: Sandboxed environment without system-level access
- **Visual Feedback**: Real-time code execution visualization
- **Progressive Learning**: Function gating through research system

### Key Features
- ✅ **5 Programming Languages** (C++, C#, Java, JavaScript, Python)
- ✅ **Full Syntax Support** (variables, operators, control flow, functions)
- ✅ **Research-Gated Functions** (progressive unlock system)
- ✅ **Real-Time Line Tracking** (visual execution feedback)
- ✅ **Comprehensive Error Reporting** (lexical, syntactical, semantical, runtime)
- ✅ **Expression Evaluation** (arithmetic, logical, comparison operations)
- ✅ **Scope Management** (nested scopes for blocks, loops, functions)
- ✅ **Execution Control** (stop, pause, step-through capabilities)

---

## Architecture Overview

### Three-Layer Architecture

```
┌─────────────────────────────────────────────────────────┐
│              Language-Specific Layer                     │
│  (CppInterpreter, PythonInterpreter, JavaInterpreter,   │
│   CSharpInterpreter, JavaScriptInterpreter)             │
│  - Language syntax parsing                              │
│  - Statement extraction                                 │
│  - Language-specific function calls                     │
└───────────────────────────┬─────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────┐
│                 Base Interpreter Layer                   │
│              (FarmCodeInterpreter)                       │
│  - Expression evaluation                                │
│  - Drone operation execution                            │
│  - Variable scope management                            │
│  - Control flow primitives                              │
│  - Research function gating                             │
└───────────────────────────┬─────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────┐
│                   Farm State Layer                       │
│                 (FarmState, ResearchState)               │
│  - Grid manipulation                                    │
│  - Crop management                                      │
│  - Drone positioning                                    │
│  - Research validation                                  │
└─────────────────────────────────────────────────────────┘
```

### Design Patterns

1. **Template Method Pattern**: Base interpreter defines execution skeleton, subclasses implement language-specific parsing
2. **Factory Pattern**: `InterpreterFactory` creates appropriate interpreter based on language ID
3. **Strategy Pattern**: Different evaluation strategies for each language's syntax
4. **Observer Pattern**: Callbacks for line execution, errors, and log updates
5. **State Pattern**: Execution state management (running, stopped, break, continue, return)

---

## Base Interpreter Framework

### FarmCodeInterpreter (Abstract Base Class)

**Location**: `lib/compilers/base_interpreter.dart`

#### Core Responsibilities

1. **Expression Evaluation**: Unified arithmetic and logical expression engine
2. **Drone Operations**: Execute farming commands (move, till, water, plant, harvest)
3. **Variable Management**: Scope-based variable storage and retrieval
4. **Control Flow**: Break, continue, return flags
5. **Research Gating**: Function access control based on research completion
6. **Execution Control**: Stop mechanism for user interruption
7. **Logging**: Execution trace and debug output

#### Key Components

```dart
abstract class FarmCodeInterpreter {
  final FarmState farmState;              // Farm grid state
  final ResearchState? researchState;     // Research progress
  final List<String> executionLog;        // Execution trace
  
  VariableScope currentScope;             // Active variable scope
  
  // Control flow flags
  bool shouldBreak = false;
  bool shouldContinue = false;
  bool shouldReturn = false;
  bool shouldStop = false;
  
  // Callbacks for UI updates
  Function(int?)? onLineExecuting;
  Function(int?, bool)? onLineError;
  Function(String)? onLogUpdate;
  Function(CropType)? onCropHarvested;
  
  // Abstract methods for language-specific implementation
  Future<ExecutionResult> execute(String code);
  Future<ExecutionResult?> preValidate(String code);
  dynamic evaluateFunctionCall(String expr);
}
```

#### ExecutionResult Structure

```dart
class ExecutionResult {
  final bool success;
  final String? errorMessage;
  final ErrorType? errorType;
  final List<String> executionLog;
  final int? errorLine;  // 1-based line number
}

enum ErrorType {
  lexical,      // Invalid tokens/characters
  syntactical,  // Invalid syntax/grammar
  semantical,   // Type errors, undefined variables
  logical,      // Runtime logic errors
  runtime,      // General runtime errors
}
```

---

## Language-Specific Interpreters

### 1. C++ Interpreter (`CppInterpreter`)

**Syntax Features**:
- `int main()` entry point
- Type declarations: `int`, `double`, `float`, `char`, `bool`, `string`
- Control flow: `if-else`, `while`, `for`, `do-while`, `switch-case`
- Operators: `++`, `--`, arithmetic, logical, comparison
- Output: `cout << ... << endl`
- Error handling: `try-catch`
- Comments: `//` and `/* */`

**Enum Syntax**:
```cpp
Direction::North, Direction::South, Direction::East, Direction::West
SeedType::WheatSeeds, SeedType::CarrotSeeds
CropType::Wheat, CropType::Carrot
PlotState::Normal, PlotState::Tilled, PlotState::Watered
```

**Example Code**:
```cpp
int main() {
    int count = 0;
    while (count < 5) {
        move(Direction::North);
        till();
        count++;
    }
    return 0;
}
```

### 2. Python Interpreter (`PythonInterpreter`)

**Syntax Features**:
- No type declarations (dynamic typing)
- Indentation-based blocks
- Control flow: `if-elif-else`, `while`, `for`
- Output: `print()`
- Error handling: `try-except`
- Comments: `#`

**Enum Syntax**:
```python
Direction.NORTH, Direction.SOUTH, Direction.EAST, Direction.WEST
SeedType.WHEAT_SEEDS, SeedType.CARROT_SEEDS
CropType.WHEAT, CropType.CARROT
PlotState.NORMAL, PlotState.TILLED, PlotState.WATERED
```

**Example Code**:
```python
count = 0
while count < 5:
    move(Direction.NORTH)
    till()
    count = count + 1
```

### 3. Java Interpreter (`JavaInterpreter`)

**Syntax Features**:
- `class Main` with `public static void main(String[] args)`
- Type declarations (strongly typed)
- Control flow: `if-else`, `while`, `for`, `do-while`, `switch-case`
- Output: `System.out.println()`
- Error handling: `try-catch`
- Comments: `//` and `/* */`

**Enum Syntax**:
```java
Direction.NORTH, Direction.SOUTH, Direction.EAST, Direction.WEST
SeedType.WHEAT_SEEDS, SeedType.CARROT_SEEDS
CropType.WHEAT, CropType.CARROT
PlotState.NORMAL, PlotState.TILLED, PlotState.WATERED
```

### 4. C# Interpreter (`CSharpInterpreter`)

**Syntax Features**:
- `class Program` with `static void Main()`
- Type declarations with `var` support
- Control flow: `if-else`, `while`, `for`, `do-while`, `switch-case`
- Output: `Console.WriteLine()`
- Error handling: `try-catch`
- Comments: `//` and `/* */`

**Enum Syntax**:
```csharp
Direction.North, Direction.South, Direction.East, Direction.West
SeedType.WheatSeeds, SeedType.CarrotSeeds
CropType.Wheat, CropType.Carrot
PlotState.Normal, PlotState.Tilled, PlotState.Watered
```

### 5. JavaScript Interpreter (`JavaScriptInterpreter`)

**Syntax Features**:
- No main function requirement
- Variable declarations: `var`, `let`, `const`
- Control flow: `if-else`, `while`, `for`, `do-while`, `switch-case`
- Output: `console.log()`
- Error handling: `try-catch`
- Comments: `//` and `/* */`

**Enum Syntax**:
```javascript
Direction.NORTH, Direction.SOUTH, Direction.EAST, Direction.WEST
SeedType.WHEAT_SEEDS, SeedType.CARROT_SEEDS
CropType.WHEAT, CropType.CARROT
PlotState.NORMAL, PlotState.TILLED, PlotState.WATERED
```

---

## Code Execution Pipeline

### Execution Flow

```
1. User writes code in editor
   ↓
2. Code validation (preValidate)
   - Syntax checking
   - Structure validation
   - Basic error detection
   ↓
3. Code execution (execute)
   ↓
4. Comment removal
   ↓
5. Main function extraction (for applicable languages)
   ↓
6. Statement parsing
   - Tokenization
   - Block identification
   - Control structure recognition
   ↓
7. Statement-by-statement execution
   ↓
8. For each statement:
   - Line number mapping
   - UI notification (highlight line)
   - Delay for visualization
   - Statement execution
   - Stop flag check
   ↓
9. Return ExecutionResult
```

### Statement Parsing

**Challenge**: Respect string literals, parentheses, and braces while splitting statements.

**Algorithm**:
```dart
List<String> _parseStatements(String code) {
  List<String> statements = [];
  StringBuffer buffer = StringBuffer();
  int braceDepth = 0;
  int parenDepth = 0;
  bool inString = false;
  String? stringChar;
  
  for (char in code) {
    // Track string boundaries
    if (char is quote && !escaped) {
      inString = !inString;
      stringChar = char;
    }
    
    if (!inString) {
      // Track nesting depth
      if (char == '{') braceDepth++;
      if (char == '}') braceDepth--;
      if (char == '(') parenDepth++;
      if (char == ')') parenDepth--;
    }
    
    buffer.write(char);
    
    // Statement terminator
    if (!inString && char == ';' && braceDepth == 0 && parenDepth == 0) {
      statements.add(buffer.toString());
      buffer.clear();
    }
  }
  
  return statements;
}
```

### Line Number Mapping

**Challenge**: Map parsed statements back to original source line numbers for accurate highlighting.

**Solution**:
```dart
int _findStatementLine(String statement) {
  final lines = originalCode.split('\n');
  final stmtKey = statement.trim().replaceAll(RegExp(r'\s+'), ' ');
  
  for (int i = 0; i < lines.length; i++) {
    final line = lines[i].trim().replaceAll(RegExp(r'\s+'), ' ');
    
    // Check if line contains significant portion of statement
    if (stmtKey.length > 5 && 
        line.contains(stmtKey.substring(0, (stmtKey.length * 0.6).floor()))) {
      return i + 1; // Return 1-based line number
    }
  }
  
  return 1; // Default to line 1 if not found
}
```

---

## Research-Gated Function System

### Function Gating Mechanism

**Purpose**: Control access to drone operations based on research progression.

**Implementation**:
```dart
bool _isFunctionUnlocked(String functionSignature) {
  if (researchState == null) return false;
  
  // Get completed function researches
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
```

### Gated Functions

All drone operation functions are gated:

| Function | Signature | Research Required |
|----------|-----------|-------------------|
| Move | `move(direction)` | func_move |
| Till | `till()` | func_till |
| Water | `water()` | func_water |
| Plant | `plant(seedType)` | func_plant |
| Harvest | `harvest()` | func_harvest |
| Sleep | `sleep(duration)` | func_sleep |
| Get Position X | `getPositionX()` | func_get_position_x |
| Get Position Y | `getPositionY()` | func_get_position_y |
| Get Plot State | `getPlotState()` | func_get_plot_state |
| Get Crop Type | `getCropType()` | func_get_crop_type |
| Is Crop Grown | `isCropGrown()` | func_is_crop_grown |
| Can Till | `canTill()` | func_can_till |
| Can Water | `canWater()` | func_can_water |
| Can Plant | `canPlant()` | func_can_plant |
| Can Harvest | `canHarvest()` | func_can_harvest |
| Get Plot Grid X | `getPlotGridX()` | func_get_plot_grid_x |
| Get Plot Grid Y | `getPlotGridY()` | func_get_plot_grid_y |
| Has Seed | `hasSeed(seedType)` | func_has_seed |
| Get Seed Count | `getSeedInventoryCount(seedType)` | func_get_seed_inventory_count |
| Get Crop Count | `getCropInventoryCount(cropType)` | func_get_crop_inventory_count |

### Error Message on Locked Functions

```
Error: Function not unlocked. Research the required functions to use move(direction)
```

---

## Expression Evaluation Engine

### Unified Expression Evaluator

**Challenge**: Support multiple languages with different syntax in a single evaluation engine.

**Features**:
- Arithmetic operations: `+`, `-`, `*`, `/`, `%`
- Logical operations: `&&`, `||`, `!`
- Comparison operations: `==`, `!=`, `<`, `>`, `<=`, `>=`
- Parentheses grouping
- String concatenation
- Variable resolution
- Function call evaluation
- Enum literal handling

### Operator Precedence

```
1. Parentheses: ()
2. Function calls: func()
3. Unary: !, -, +
4. Multiplicative: *, /, %
5. Additive: +, -
6. Comparison: <, >, <=, >=
7. Equality: ==, !=
8. Logical AND: &&
9. Logical OR: ||
```

### Expression Splitting Algorithm

**Challenge**: Split by operator while respecting parentheses and strings.

```dart
List<String> _splitByOperator(String expr, String op) {
  List<String> parts = [];
  int parenDepth = 0;
  int lastSplit = 0;
  bool inString = false;
  String? stringChar;
  
  for (int i = 0; i <= expr.length - op.length; i++) {
    // Track string boundaries
    if (expr[i] is quote && !escaped) {
      inString = !inString;
      stringChar = expr[i];
    }
    
    if (!inString) {
      // Track parentheses depth
      if (expr[i] == '(') parenDepth++;
      if (expr[i] == ')') parenDepth--;
      
      // Split at operator if at top level
      if (parenDepth == 0 && expr.substring(i, i + op.length) == op) {
        parts.add(expr.substring(lastSplit, i).trim());
        lastSplit = i + op.length;
      }
    }
  }
  
  parts.add(expr.substring(lastSplit).trim());
  return parts;
}
```

### Evaluation Examples

```
Expression: "5 + 3 * 2"
Evaluation Order:
  1. Split by '+': ["5", "3 * 2"]
  2. Evaluate "3 * 2" = 6
  3. Evaluate "5 + 6" = 11
Result: 11

Expression: "(x > 5) && (y < 10)"
Evaluation Order:
  1. Split by '&&': ["(x > 5)", "(y < 10)"]
  2. Remove outer parens: ["x > 5", "y < 10"]
  3. Evaluate "x > 5" = true (if x = 7)
  4. Evaluate "y < 10" = true (if y = 3)
  5. Evaluate "true && true" = true
Result: true
```

---

## Error Detection & Handling

### Error Categorization

#### 1. Lexical Errors
Invalid tokens or characters.

**Examples**:
- Invalid variable names: `123abc`, `var-name`
- Invalid characters: `@`, `$` (in non-applicable contexts)

**Detection**:
```dart
if (!RegExp(r'^[a-zA-Z_]\w*$').hasMatch(varName)) {
  throw Exception('Lexical Error: Invalid variable name: $varName');
}
```

#### 2. Syntactical Errors
Grammar and structure violations.

**Examples**:
- Missing semicolons (C++, Java, C#, JavaScript)
- Unmatched braces or parentheses
- Missing colons (Python)
- Invalid control structure syntax

**Detection**:
```dart
// Semicolon check (C++, Java, C#, JavaScript)
if (needsSemicolon && !stmt.endsWith(';')) {
  return ExecutionResult.error(
    'Syntactical Error: Missing semicolon at line $lineNum',
    type: ErrorType.syntactical,
    errorLine: lineNum,
  );
}

// Brace matching
int braceCount = 0;
for (char in stmt) {
  if (char == '{') braceCount++;
  if (char == '}') braceCount--;
}
if (braceCount != 0) {
  return ExecutionResult.error(
    'Syntactical Error: Unmatched braces at line $lineNum',
    type: ErrorType.syntactical,
    errorLine: lineNum,
  );
}
```

#### 3. Semantical Errors
Type mismatches and undefined references.

**Examples**:
- Undefined variables
- Unknown functions
- Type mismatches (incrementing string, etc.)

**Detection**:
```dart
if (!currentScope.has(varName)) {
  throw Exception('Semantical Error: Undefined variable: $varName');
}

if (currentValue is! num) {
  throw Exception('Type Error: Cannot increment/decrement non-numeric variable');
}
```

#### 4. Logical Errors
Runtime condition evaluation failures.

**Examples**:
- Division by zero
- Invalid condition evaluation
- Type coercion failures

**Detection**:
```dart
try {
  final condValue = evaluateExpression(condition);
  if (!_toBool(condValue)) break;
} catch (e) {
  throw Exception('Logical Error in while condition: $e');
}
```

#### 5. Runtime Errors
General execution failures.

**Examples**:
- Drone out of bounds
- Invalid plot operations
- Insufficient inventory

**Detection**:
```dart
final success = farmState.tillCurrentPlot();
if (!success) {
  log('Error: Cannot till this plot');
}
```

### Error Reporting Format

```
ExecutionResult.error(
  message: "Syntactical Error: Missing semicolon at line 5",
  type: ErrorType.syntactical,
  log: ["Starting C++ code execution...", "Variable x declared with value: 5"],
  errorLine: 5
)
```

---

## Variable Scope Management

### Scope Hierarchy

```
Global Scope (main function)
  │
  ├─ If Block Scope
  │   └─ Nested If Scope
  │
  ├─ While Loop Scope
  │   ├─ If Block Scope (inside loop)
  │   └─ Nested While Scope
  │
  └─ For Loop Scope
      └─ For Body Scope
```

### VariableScope Class

```dart
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
    return _variables.containsKey(name) || 
           (parent?.has(name) ?? false);
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
```

### Scope Operations

**Push Scope** (entering block):
```dart
void pushScope() {
  currentScope = VariableScope(parent: currentScope);
}
```

**Pop Scope** (exiting block):
```dart
void popScope() {
  if (currentScope.parent != null) {
    currentScope = currentScope.parent!;
  }
}
```

**Usage Example**:
```dart
// If statement execution
pushScope();  // Create new scope
await _executeBlock(ifBody);
popScope();   // Restore parent scope
```

### Language-Specific Scoping

**C++, Java, C#, JavaScript**: Block-scoped (each `{}` creates new scope)

**Python**: Function-scoped (blocks don't create new scopes)

---

## Control Flow Implementation

### Control Flow Flags

```dart
bool shouldBreak = false;     // Exit current loop
bool shouldContinue = false;  // Skip to next iteration
bool shouldReturn = false;    // Exit function/main
bool shouldStop = false;      // User-initiated stop
```

### If-Else Statement

**C++ Example**:
```cpp
if (condition) {
  // true branch
} else {
  // false branch
}
```

**Implementation**:
```dart
Future<void> _handleIf(String stmt) async {
  // Extract condition
  final condition = extractCondition(stmt);
  
  // Extract bodies
  final ifBody = extractIfBody(stmt);
  final elseBody = extractElseBody(stmt);
  
  // Evaluate and execute
  final condValue = evaluateExpression(condition);
  
  pushScope();
  if (_toBool(condValue)) {
    await _executeBlock(ifBody);
  } else if (elseBody != null) {
    await _executeBlock(elseBody);
  }
  popScope();
}
```

### While Loop

**C++ Example**:
```cpp
while (count < 10) {
  // loop body
  count++;
}
```

**Implementation**:
```dart
Future<void> _handleWhile(String stmt) async {
  final condition = extractCondition(stmt);
  final body = extractBody(stmt);
  
  while (true) {
    // Check stop flag
    if (shouldStop) return;
    
    // Evaluate condition
    final condValue = evaluateExpression(condition);
    if (!_toBool(condValue)) break;
    
    // Execute body
    pushScope();
    shouldBreak = false;
    shouldContinue = false;
    await _executeBlock(body);
    popScope();
    
    // Handle break
    if (shouldBreak) {
      shouldBreak = false;
      break;
    }
    
    // Handle return
    if (shouldReturn) break;
  }
}
```

### For Loop

**C++ Example**:
```cpp
for (int i = 0; i < 10; i++) {
  // loop body
}
```

**Implementation**:
```dart
Future<void> _handleFor(String stmt) async {
  final parts = splitForHeader(stmt);  // [init, condition, update]
  final body = extractBody(stmt);
  
  pushScope();
  
  // Initialize
  if (parts[0].isNotEmpty) {
    await _executeStatement(parts[0] + ';');
  }
  
  // Loop
  while (true) {
    // Check stop flag
    if (shouldStop) break;
    
    // Evaluate condition
    if (parts[1].isNotEmpty) {
      final condValue = evaluateExpression(parts[1]);
      if (!_toBool(condValue)) break;
    }
    
    // Execute body
    shouldBreak = false;
    shouldContinue = false;
    await _executeBlock(body);
    
    // Handle break
    if (shouldBreak) {
      shouldBreak = false;
      break;
    }
    
    // Handle return
    if (shouldReturn) break;
    
    // Update
    if (parts[2].isNotEmpty) {
      await _executeStatement(parts[2] + ';');
    }
  }
  
  popScope();
}
```

### Switch Statement (C++, Java, C#, JavaScript)

**C++ Example**:
```cpp
switch (value) {
  case 1:
    // case 1 body
    break;
  case 2:
    // case 2 body
    break;
  default:
    // default body
}
```

**Implementation**:
```dart
Future<void> _handleSwitch(String stmt) async {
  final expr = extractSwitchExpression(stmt);
  final body = extractSwitchBody(stmt);
  final switchValue = evaluateExpression(expr);
  
  // Parse cases
  final cases = parseCases(body);
  bool matched = false;
  
  for (final caseItem in cases) {
    final caseValue = evaluateExpression(caseItem.value);
    
    if (switchValue == caseValue) {
      matched = true;
      pushScope();
      await _executeBlock(caseItem.body);
      popScope();
      
      if (shouldBreak) {
        shouldBreak = false;
        break;
      }
    }
  }
  
  // Default case
  if (!matched && defaultCase != null) {
    pushScope();
    await _executeBlock(defaultCase.body);
    popScope();
  }
}
```

### Try-Catch Error Handling

**C++ Example**:
```cpp
try {
  // risky code
} catch (...) {
  // error handling
}
```

**Implementation**:
```dart
Future<void> _handleTryCatch(String stmt) async {
  final tryBody = extractTryBody(stmt);
  final catchBody = extractCatchBody(stmt);
  
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
```

---

## Drone Operation Functions

### Move Operation

**Signature**: `move(Direction)`

**Behavior**:
1. Validates direction parameter
2. Checks if move is within grid bounds
3. Animates drone movement (smooth transition)
4. Updates drone position
5. Logs movement result

**Implementation**:
```dart
Future<bool> executeMove(Direction direction) async {
  if (!_isFunctionUnlocked('move(direction)')) {
    log('Error: Function not unlocked...');
    return false;
  }
  
  log('Moving drone ${direction.name}...');
  
  // Animate move (includes work duration)
  await farmState.animateDroneMove(direction);
  
  final success = farmState.dronePosition.x >= 0 && 
                  farmState.dronePosition.y >= 0;
  
  if (success) {
    log('Drone moved to (${farmState.dronePosition.x}, ${farmState.dronePosition.y})');
  } else {
    log('Error: Cannot move out of bounds');
  }
  
  return success;
}
```

### Till Operation

**Signature**: `till()`

**Behavior**:
1. Sets drone to tilling state (visual feedback)
2. Attempts to till current plot or area
3. Delays for work duration (visual animation)
4. Logs result
5. Resets drone to normal state

**Implementation**:
```dart
Future<bool> executeTill() async {
  if (!_isFunctionUnlocked('till()')) {
    log('Error: Function not unlocked...');
    return false;
  }
  
  log('Tilling soil...');
  farmState.setDroneState(DroneState.tilling);
  
  final success = farmState.tillCurrentPlot();
  
  if (success) {
    await Future.delayed(Duration(milliseconds: farmState.tillDuration));
    log('Soil tilled successfully');
  } else {
    log('Error: Cannot till this plot');
  }
  
  farmState.setDroneState(DroneState.normal);
  return success;
}
```

### Water Operation

**Signature**: `water()`

**Behavior**:
1. Sets drone to watering state
2. Waters current plot or area
3. Starts crop growth if planted
4. Logs result

**Implementation**: Similar to till

### Plant Operation

**Signature**: `plant(SeedType)`

**Behavior**:
1. Validates seed type parameter
2. Checks inventory for seeds
3. Checks research permission for seed type
4. Plants seed(s) on prepared plot(s)
5. Decrements seed inventory
6. Logs result

**Implementation**:
```dart
Future<bool> executePlant(SeedType seed) async {
  if (!_isFunctionUnlocked('plant(seedType)')) {
    log('Error: Function not unlocked...');
    return false;
  }
  
  log('Planting ${seed.displayName}...');
  farmState.setDroneState(DroneState.planting);
  
  final plantedCount = farmState.plantSeed(seed);
  
  if (plantedCount > 0) {
    await Future.delayed(Duration(milliseconds: farmState.plantDuration));
    log('${seed.displayName} planted on $plantedCount plot(s)');
    farmState.setDroneState(DroneState.normal);
    return true;
  } else {
    log('Error: Cannot plant (check seeds and plot state)');
    farmState.setDroneState(DroneState.normal);
    return false;
  }
}
```

### Harvest Operation

**Signature**: `harvest()`

**Behavior**:
1. Checks if crop is fully grown
2. Checks research permission for crop type
3. Generates random harvest quantity
4. Adds crops to inventory
5. Awards XP
6. Resets plot to normal
7. Calls harvest callback
8. Logs result

**Implementation**:
```dart
Future<bool> executeHarvest() async {
  if (!_isFunctionUnlocked('harvest()')) {
    log('Error: Function not unlocked...');
    return false;
  }
  
  log('Harvesting crop...');
  farmState.setDroneState(DroneState.harvesting);
  
  final result = await farmState.harvestCurrentPlot();
  
  if (result != null) {
    await Future.delayed(Duration(milliseconds: farmState.harvestDuration));
    
    final cropType = result['cropType'] as CropType;
    final quantity = result['quantity'] as int;
    
    log('Harvested $quantity ${cropType.displayName}!');
    onCropHarvested?.call(cropType);
    
    farmState.setDroneState(DroneState.normal);
    return true;
  } else {
    log('Error: Nothing to harvest');
    farmState.setDroneState(DroneState.normal);
    return false;
  }
}
```

### Query Functions (Getters)

**Position Queries**:
- `getPositionX()`: Returns drone's X coordinate
- `getPositionY()`: Returns drone's Y coordinate

**Plot State Queries**:
- `getPlotState()`: Returns PlotState enum at current position
- `getCropType()`: Returns CropType enum at current position
- `isCropGrown()`: Returns boolean if crop is fully mature

**Permission Queries**:
- `canTill()`: Check if current plot can be tilled
- `canWater()`: Check if current plot can be watered
- `canPlant()`: Check if current plot can be planted
- `canHarvest()`: Check if current plot can be harvested

**Grid Queries**:
- `getPlotGridX()`: Returns grid width
- `getPlotGridY()`: Returns grid height

**Inventory Queries**:
- `hasSeed(SeedType)`: Check if user has at least 1 seed
- `getSeedInventoryCount(SeedType)`: Get seed quantity
- `getCropInventoryCount(CropType)`: Get crop quantity

### Sleep Function

**Signature**: `sleep(duration)` (duration in seconds)

**Behavior**:
1. Pauses execution for specified duration
2. Useful for pacing operations
3. Logs start and completion

**Implementation**:
```dart
Future<void> executeSleep(num duration) async {
  if (!_isFunctionUnlocked('sleep(duration)')) {
    log('Error: Function not unlocked...');
    return;
  }
  
  log('Sleeping for $duration seconds...');
  await Future.delayed(Duration(milliseconds: (duration * 1000).round()));
  log('Sleep completed');
}
```

---

## Code Validation System

### Pre-Validation Phase

**Purpose**: Catch syntax errors before execution to provide immediate feedback.

**Validation Steps**:

1. **Comment Removal**: Clean code for parsing
2. **Structure Check**: Validate entry points (main function)
3. **Syntax Validation**: Check for common syntax errors
4. **Brace Matching**: Ensure all braces are balanced
5. **Semicolon Check**: Verify statement terminators (C-style languages)
6. **Indentation Check**: Validate indentation (Python)

**Implementation Example (C++)**:
```dart
Future<ExecutionResult?> preValidate(String code) async {
  clearLog();
  log('Validating C++ code...');
  
  try {
    code = _removeComments(code);
    
    // Check for main function
    final mainBody = _extractMainBody(code);
    if (mainBody == null) {
      return ExecutionResult.error(
        'Syntactical Error: main() function not found',
        type: ErrorType.syntactical,
        errorLine: 1,
      );
    }
    
    // Parse and validate statements
    final statements = _parseStatements(mainBody);
    
    for (final stmt in statements) {
      // Check semicolons
      if (needsSemicolon(stmt) && !stmt.endsWith(';')) {
        int lineNum = _findLineNumber(originalCode, stmt);
        return ExecutionResult.error(
          'Syntactical Error: Missing semicolon at line $lineNum',
          type: ErrorType.syntactical,
          errorLine: lineNum,
        );
      }
      
      // Check brace matching
      if (!bracesBalanced(stmt)) {
        int lineNum = _findLineNumber(originalCode, stmt);
        return ExecutionResult.error(
          'Syntactical Error: Unmatched braces at line $lineNum',
          type: ErrorType.syntactical,
          errorLine: lineNum,
        );
      }
    }
    
    log('Validation passed!');
    return null; // null = validation passed
  } catch (e) {
    return ExecutionResult.error(
      'Validation Error: $e',
      type: ErrorType.syntactical,
      errorLine: 1,
    );
  }
}
```

---

## Execution Logging & Debugging

### Logging System

**Purpose**: Provide visibility into code execution for debugging and learning.

**Log Categories**:
1. **Variable Operations**: Declarations, assignments, updates
2. **Control Flow**: Loop iterations, condition evaluations
3. **Drone Operations**: Movement, farming actions
4. **Errors**: All error types with context
5. **System Messages**: Start, stop, completion

**Log Methods**:
```dart
void log(String message) {
  executionLog.add(message);
  onLogUpdate?.call(message);  // Notify UI
}
```

**Example Log Output**:
```
Starting C++ code execution...
Variable count declared with value: 0
Moving drone north...
Drone moved to (0, 1)
Tilling soil...
Soil tilled successfully
Variable count incremented to: 1
Moving drone north...
Drone moved to (0, 2)
...
Code execution completed successfully!
```

### Auto-Scroll Behavior

**UI Feature**: Log automatically scrolls to bottom during execution unless user manually scrolls up.

**Implementation** (in UI layer):
```dart
ScrollController _logScrollController = ScrollController();
bool _autoScrollEnabled = true;

void _onLogScroll() {
  // Disable auto-scroll if user scrolls up
  if (_logScrollController.position.pixels < 
      _logScrollController.position.maxScrollExtent - 50) {
    setState(() => _autoScrollEnabled = false);
  } else {
    setState(() => _autoScrollEnabled = true);
  }
}

void _scrollToBottom() {
  if (_autoScrollEnabled && _logScrollController.hasClients) {
    _logScrollController.jumpTo(
      _logScrollController.position.maxScrollExtent
    );
  }
}
```

---

## Line Tracking & Visualization

### Real-Time Line Highlighting

**Purpose**: Show users which line of code is currently executing.

**Mechanism**:
1. Map parsed statement to original source line
2. Notify UI before executing statement
3. Highlight line in code editor
4. Clear highlight after execution or on error

**Callback System**:
```dart
// In interpreter
void notifyLineExecuting(int? lineNumber) {
  onLineExecuting?.call(lineNumber);
}

// In UI (farm_page.dart)
final ValueNotifier<int?> _executingLineNotifier = ValueNotifier<int?>(null);

FarmCodeInterpreter interpreter = getInterpreter(
  onLineExecuting: (line) => _executingLineNotifier.value = line,
  // ...
);

// In code editor widget
ValueListenableBuilder<int?>(
  valueListenable: executingLineNotifier,
  builder: (context, executingLine, _) {
    // Highlight line with background color
    if (executingLine == lineIndex + 1) {
      return Container(
        color: Colors.yellow.withOpacity(0.3),
        child: lineWidget,
      );
    }
    return lineWidget;
  },
)
```

### Error Line Highlighting

**Purpose**: Show users exactly where an error occurred.

**Mechanism**:
```dart
// In interpreter (on error)
notifyLineError(errorLine, true);

// In UI
final ValueNotifier<int?> _errorLineNotifier = ValueNotifier<int?>(null);

// In code editor widget
if (errorLine == lineIndex + 1) {
  return Container(
    color: Colors.red.withOpacity(0.3),
    child: lineWidget,
  );
}
```

### Execution Delay for Visualization

**Purpose**: Allow users to see execution progress (not instant).

**Implementation**:
```dart
Future<void> delay([int? milliseconds]) async {
  final duration = milliseconds ?? farmState.generalDuration;
  await Future.delayed(Duration(milliseconds: duration));
}

// Usage in statement execution loop
for (final stmt in statements) {
  notifyLineExecuting(lineNum);
  await delay(generalDuration);  // Visual pause
  await _executeStatement(stmt);
}
```

### Stop Mechanism

**Purpose**: Allow users to interrupt long-running code.

**Implementation**:
```dart
// In interpreter
bool shouldStop = false;

void stop() {
  if (!shouldStop) {
    shouldStop = true;
    log('Stop requested - finishing current operation...');
  }
}

// Check in execution loop
for (final stmt in statements) {
  if (shouldStop) {
    log('Execution stopped by user');
    notifyLineExecuting(null);
    return;
  }
  
  await _executeStatement(stmt);
}
```

---

## Workflow Diagrams

### 1. Code Execution Workflow

```
┌──────────────────────┐
│  User clicks "Run"   │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│  Get code from       │
│  editor              │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│  Create interpreter  │
│  (Factory pattern)   │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│  Pre-validate code   │
└──────────┬───────────┘
           │
    ┌──────┴──────┐
    │  Valid?     │
    └──────┬──────┘
           │ Yes
           ▼
┌──────────────────────┐
│  Execute code        │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│  Remove comments     │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│  Extract main body   │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│  Parse statements    │
└──────────┬───────────┘
           │
           ▼
┌────────────────────────────┐
│  For each statement:       │
│  1. Map to line number     │
│  2. Highlight line         │
│  3. Delay (visualization)  │
│  4. Execute statement      │
│  5. Check stop flag        │
└────────────┬───────────────┘
             │
             ▼
    ┌────────────────┐
    │  Stop flag?    │
    └────────┬───────┘
             │ No
             ▼
┌──────────────────────┐
│  All statements done │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│  Clear line highlight│
│  Show completion msg │
└──────────────────────┘
```

### 2. Statement Execution Flow

```
┌──────────────────────┐
│  Receive statement   │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────────────┐
│  Check statement type:       │
│  - Control flow (if, while)? │
│  - Variable declaration?     │
│  - Assignment?               │
│  - Function call?            │
│  - Expression?               │
└──────────┬───────────────────┘
           │
    ┌──────┴──────────┐
    │  Control flow?  │
    └──────┬──────────┘
           │ Yes
           ▼
┌──────────────────────┐
│  Extract condition   │
│  Extract body        │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│  Evaluate condition  │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│  Push scope          │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│  Execute body        │
│  (recursive)         │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│  Pop scope           │
└──────────────────────┘
```

### 3. Expression Evaluation Flow

```
┌──────────────────────┐
│  Receive expression  │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│  Strip outer parens  │
└──────────┬───────────┘
           │
           ▼
    ┌──────┴──────────┐
    │  Literal?       │
    │  (number, bool, │
    │   string)       │
    └──────┬──────────┘
           │ No
           ▼
    ┌──────────────────┐
    │  Variable?       │
    └──────┬───────────┘
           │ No
           ▼
    ┌──────────────────┐
    │  Function call?  │
    └──────┬───────────┘
           │ No
           ▼
┌──────────────────────────┐
│  Split by operator:      │
│  1. ||                   │
│  2. &&                   │
│  3. ==, !=, <, >, <=, >= │
│  4. +, -, *, /, %        │
└──────────┬───────────────┘
           │
           ▼
┌──────────────────────┐
│  Evaluate left side  │
│  (recursive)         │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│  Evaluate right side │
│  (recursive)         │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│  Apply operator      │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│  Return result       │
└──────────────────────┘
```

### 4. Function Gating Flow

```
┌──────────────────────┐
│  User calls function │
│  (e.g., move())      │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────────┐
│  Check if unlocked:      │
│  _isFunctionUnlocked()   │
└──────────┬───────────────┘
           │
    ┌──────┴──────────┐
    │  Unlocked?      │
    └──────┬──────────┘
           │ Yes
           ▼
┌──────────────────────┐
│  Execute function    │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│  Interact with       │
│  FarmState           │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│  Log result          │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│  Return success      │
└──────────────────────┘

    (If unlocked = No)
           │
           ▼
┌──────────────────────┐
│  Log error message   │
│  "Function not       │
│   unlocked"          │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│  Return false/null   │
└──────────────────────┘
```

### 5. Research Integration Flow

```
┌──────────────────────┐
│  User completes      │
│  function research   │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────────┐
│  ResearchState updated   │
│  (add to completed set)  │
└──────────┬───────────────┘
           │
           ▼
┌──────────────────────┐
│  User writes code    │
│  using new function  │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│  Code executes       │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────────────┐
│  Function call encountered   │
└──────────┬─────────────────────┘
           │
           ▼
┌──────────────────────────────┐
│  Check research state:       │
│  1. Get completed research   │
│  2. Load research schema     │
│  3. Check functionsUnlocked  │
└──────────┬─────────────────────┘
           │
    ┌──────┴──────────┐
    │  Function in    │
    │  unlocked list? │
    └──────┬──────────┘
           │ Yes
           ▼
┌──────────────────────┐
│  Allow execution     │
└──────────────────────┘
```

---

## Key Technical Achievements

### 1. **Multi-Language Support**
Single codebase supports 5 distinct programming languages with proper syntax handling.

### 2. **Safe Execution**
No `eval()` or code injection - fully custom interpreter with controlled execution environment.

### 3. **Progressive Learning**
Research-gated functions ensure users learn concepts in proper sequence.

### 4. **Real-Time Visualization**
Line-by-line execution tracking provides immediate visual feedback.

### 5. **Comprehensive Error Handling**
5 error categories with precise line numbers and helpful messages.

### 6. **Expression Engine**
Unified expression evaluator handles complex arithmetic and logical operations.

### 7. **Scope Management**
Proper variable scoping with nested scope support for all control structures.

### 8. **Execution Control**
User can stop long-running code gracefully without app crashes.

### 9. **Farm Integration**
Direct manipulation of farm state, crops, and drone operations.

### 10. **Educational Focus**
Logging, debugging, and visualization features optimized for learning.

---

## Performance Considerations

### Optimizations

1. **Delayed Parsing**: Code only parsed when executed, not on every keystroke
2. **Efficient Statement Splitting**: Single-pass parsing with state tracking
3. **Scope Caching**: Variable lookups traverse parent chain only when needed
4. **Expression Short-Circuiting**: Logical operators stop evaluating when result determined
5. **Minimal State Updates**: FarmState only notified on actual changes

### Execution Speed

**Typical Execution Times**:
- Simple statement: ~200ms (includes visualization delay)
- Function call: ~300-1000ms (depends on operation)
- Loop iteration: Varies based on body complexity
- Expression evaluation: <1ms (no delay)

**Configurable Delays**:
- General duration: 200ms (between statements)
- Move duration: 400ms
- Till/Water/Plant/Harvest: 300-500ms

---

## Future Enhancements

### Potential Features

1. **Debugging Tools**:
   - Breakpoints
   - Step-through execution
   - Variable inspection
   - Watch expressions

2. **Performance Improvements**:
   - Just-in-time compilation
   - Expression caching
   - Parallel execution (multiple drones)

3. **Language Extensions**:
   - More languages (Rust, Go, Swift)
   - Custom functions/procedures
   - Arrays and data structures
   - Advanced loop constructs

4. **Error Recovery**:
   - Continue execution after non-critical errors
   - Error suggestions and fixes
   - Syntax highlighting in editor

5. **Advanced Features**:
   - Recursive functions
   - File I/O simulation
   - Multi-drone coordination
   - Event-driven programming

---

## Conclusion

The Code Sprout interpreter system represents a **sophisticated educational tool** that bridges the gap between visual programming and real-world coding. By supporting actual programming language syntax within a safe, controlled environment, it provides an authentic learning experience while maintaining the engagement of a game-based interface.

**Key Strengths**:
- ✅ **Authentic Syntax**: Real programming languages, not pseudo-code
- ✅ **Safe Environment**: No system access, controlled execution
- ✅ **Visual Feedback**: Line tracking, drone animation, execution log
- ✅ **Progressive Complexity**: Research-gated features ensure proper learning sequence
- ✅ **Comprehensive Coverage**: Variables, operators, control flow, functions
- ✅ **Error Guidance**: Detailed error messages with line numbers
- ✅ **Extensible Architecture**: Easy to add new languages or features
- ✅ **Performance Optimized**: Smooth execution with configurable delays

**Educational Impact**:
- Teaches real programming concepts with immediate visual feedback
- Builds muscle memory for actual language syntax
- Provides safe environment for experimentation and learning from errors
- Scales from beginner (simple move commands) to advanced (complex algorithms)

---

**Document Version**: 1.0  
**Last Updated**: November 27, 2025  
**Maintained By**: Code Sprout Development Team
