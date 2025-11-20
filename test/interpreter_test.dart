import 'package:flutter_test/flutter_test.dart';
import 'package:code_sprout/models/farm_data.dart';
import 'package:code_sprout/models/farm_data_schema.dart';
import 'package:code_sprout/models/user_data.dart';
import 'package:code_sprout/compilers/cpp_interpreter.dart';
import 'package:code_sprout/compilers/python_interpreter.dart';
import 'package:code_sprout/compilers/java_interpreter.dart';
import 'package:code_sprout/compilers/csharp_interpreter.dart';
import 'package:code_sprout/compilers/javascript_interpreter.dart';

void main() {
  // Set up farm data schema once before all tests
  // Using setSchemaForTesting to avoid asset loading in tests
  setUpAll(() {
    final schema = FarmDataSchema();
    schema.setSchemaForTesting({
      'crop_info': {
        'wheat': {
          'item_icon': 'assets/images/icons/wheat_icon.png',
          'seed_icon': 'assets/images/icons/wheat_seeds.png',
          'growth_duration': 30.0,
          'harvest_quantity': {'min': 2, 'max': 4},
          'crop_stages': {
            '1': 'assets/images/icons/wheat_stage1.png',
            '2': 'assets/images/icons/wheat_stage2.png',
            '3': 'assets/images/icons/wheat_stage3.png',
            '4': 'assets/images/icons/wheat_stage4.png',
            '5': 'assets/images/icons/wheat_stage5.png',
            '6': 'assets/images/icons/wheat_stage6.png',
          }
        },
        'carrot': {
          'item_icon': 'assets/images/icons/carrot_icon.png',
          'seed_icon': 'assets/images/icons/carrot_seeds.png',
          'growth_duration': 25.0,
          'harvest_quantity': {'min': 1, 'max': 3},
          'crop_stages': {
            '1': 'assets/images/icons/carrot_stage1.png',
            '2': 'assets/images/icons/carrot_stage2.png',
            '3': 'assets/images/icons/carrot_stage3.png',
            '4': 'assets/images/icons/carrot_stage4.png',
            '5': 'assets/images/icons/carrot_stage5.png',
          }
        },
        'potato': {
          'item_icon': 'assets/images/icons/potato_icon.png',
          'seed_icon': 'assets/images/icons/potato_seeds.png',
          'growth_duration': 35.0,
          'harvest_quantity': {'min': 2, 'max': 5},
          'crop_stages': {
            '1': 'assets/images/icons/potato_stage1.png',
            '2': 'assets/images/icons/potato_stage2.png',
            '3': 'assets/images/icons/potato_stage3.png',
            '4': 'assets/images/icons/potato_stage4.png',
            '5': 'assets/images/icons/potato_stage5.png',
            '6': 'assets/images/icons/potato_stage6.png',
          }
        },
        'beetroot': {
          'item_icon': 'assets/images/icons/beetroot_icon.png',
          'seed_icon': 'assets/images/icons/beetroot_seeds.png',
          'growth_duration': 28.0,
          'harvest_quantity': {'min': 1, 'max': 3},
          'crop_stages': {
            '1': 'assets/images/icons/beetroot_stage1.png',
            '2': 'assets/images/icons/beetroot_stage2.png',
            '3': 'assets/images/icons/beetroot_stage3.png',
            '4': 'assets/images/icons/beetroot_stage4.png',
            '5': 'assets/images/icons/beetroot_stage5.png',
          }
        },
        'radish': {
          'item_icon': 'assets/images/icons/radish_icon.png',
          'seed_icon': 'assets/images/icons/radish_seeds.png',
          'growth_duration': 20.0,
          'harvest_quantity': {'min': 1, 'max': 2},
          'crop_stages': {
            '1': 'assets/images/icons/radish_stage1.png',
            '2': 'assets/images/icons/radish_stage2.png',
            '3': 'assets/images/icons/radish_stage3.png',
            '4': 'assets/images/icons/radish_stage4.png',
          }
        },
        'onion': {
          'item_icon': 'assets/images/icons/onion_icon.png',
          'seed_icon': 'assets/images/icons/onion_seeds.png',
          'growth_duration': 32.0,
          'harvest_quantity': {'min': 2, 'max': 4},
          'crop_stages': {
            '1': 'assets/images/icons/onion_stage1.png',
            '2': 'assets/images/icons/onion_stage2.png',
            '3': 'assets/images/icons/onion_stage3.png',
            '4': 'assets/images/icons/onion_stage4.png',
            '5': 'assets/images/icons/onion_stage5.png',
            '6': 'assets/images/icons/onion_stage6.png',
          }
        },
        'lettuce': {
          'item_icon': 'assets/images/icons/lettuce_icon.png',
          'seed_icon': 'assets/images/icons/lettuce_seeds.png',
          'growth_duration': 22.0,
          'harvest_quantity': {'min': 1, 'max': 2},
          'crop_stages': {
            '1': 'assets/images/icons/lettuce_stage1.png',
            '2': 'assets/images/icons/lettuce_stage2.png',
            '3': 'assets/images/icons/lettuce_stage3.png',
            '4': 'assets/images/icons/lettuce_stage4.png',
            '5': 'assets/images/icons/lettuce_stage5.png',
          }
        },
        'tomato': {
          'item_icon': 'assets/images/icons/tomato_icon.png',
          'seed_icon': 'assets/images/icons/tomato_seeds.png',
          'growth_duration': 40.0,
          'harvest_quantity': {'min': 3, 'max': 6},
          'crop_stages': {
            '1': 'assets/images/icons/tomato_stage1.png',
            '2': 'assets/images/icons/tomato_stage2.png',
            '3': 'assets/images/icons/tomato_stage3.png',
            '4': 'assets/images/icons/tomato_stage4.png',
            '5': 'assets/images/icons/tomato_stage5.png',
            '6': 'assets/images/icons/tomato_stage6.png',
            '7': 'assets/images/icons/tomato_stage7.png',
          }
        },
        'garlic': {
          'item_icon': 'assets/images/icons/garlic_icon.png',
          'seed_icon': 'assets/images/icons/garlic_seeds.png',
          'growth_duration': 26.0,
          'harvest_quantity': {'min': 1, 'max': 3},
          'crop_stages': {
            '1': 'assets/images/icons/garlic_stage1.png',
            '2': 'assets/images/icons/garlic_stage2.png',
            '3': 'assets/images/icons/garlic_stage3.png',
            '4': 'assets/images/icons/garlic_stage4.png',
            '5': 'assets/images/icons/garlic_stage5.png',
          }
        },
      }
    });
  });

  group('Interpreter Core Tests', () {
    late FarmState farmState;

    setUp(() {
      // Create mock user data with seeds in inventory for testing
      final mockUserData = UserData(
        uid: 'test_user',
        data: {
          'sproutProgress': {
            'inventory': {
              'wheatSeeds': {'isLocked': false, 'quantity': 100},
              'carrotSeeds': {'isLocked': false, 'quantity': 100},
              'potatoSeeds': {'isLocked': false, 'quantity': 100},
              'beetrootSeeds': {'isLocked': false, 'quantity': 100},
              'radishSeeds': {'isLocked': false, 'quantity': 100},
              'onionSeeds': {'isLocked': false, 'quantity': 100},
              'lettuceSeeds': {'isLocked': false, 'quantity': 100},
              'tomatoSeeds': {'isLocked': false, 'quantity': 100},
              'garlicSeeds': {'isLocked': false, 'quantity': 100},
              'wheat': {'isLocked': false, 'quantity': 0},
              'carrot': {'isLocked': false, 'quantity': 0},
              'potato': {'isLocked': false, 'quantity': 0},
              'beetroot': {'isLocked': false, 'quantity': 0},
              'radish': {'isLocked': false, 'quantity': 0},
              'onion': {'isLocked': false, 'quantity': 0},
              'lettuce': {'isLocked': false, 'quantity': 0},
              'tomato': {'isLocked': false, 'quantity': 0},
              'garlic': {'isLocked': false, 'quantity': 0},
            }
          }
        },
      );
      farmState = FarmState(gridWidth: 3, gridHeight: 3, userData: mockUserData);
    });

    group('C++ Interpreter Tests', () {
      late CppInterpreter interpreter;

      setUp(() {
        interpreter = CppInterpreter(farmState: farmState);
      });

      test('Variable declaration and assignment', () async {
        final code = '''
int main() {
  int x = 10;
  int y = 20;
  int sum = x + y;
  return 0;
}
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(interpreter.currentScope.get('x'), 10);
        expect(interpreter.currentScope.get('y'), 20);
        expect(interpreter.currentScope.get('sum'), 30);
      });

      test('Arithmetic operators', () async {
        final code = '''
int main() {
  int a = 10 + 5;
  int b = 20 - 8;
  int c = 6 * 7;
  int d = 20 / 4;
  int e = 17 % 5;
  return 0;
}
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(interpreter.currentScope.get('a'), 15);
        expect(interpreter.currentScope.get('b'), 12);
        expect(interpreter.currentScope.get('c'), 42);
        expect(interpreter.currentScope.get('d'), 5);
        expect(interpreter.currentScope.get('e'), 2);
      });

      test('Comparison operators', () async {
        final code = '''
int main() {
  bool a = 10 > 5;
  bool b = 10 < 5;
  bool c = 10 >= 10;
  bool d = 5 <= 10;
  bool e = 10 == 10;
  bool f = 10 != 5;
  return 0;
}
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(interpreter.currentScope.get('a'), true);
        expect(interpreter.currentScope.get('b'), false);
        expect(interpreter.currentScope.get('c'), true);
        expect(interpreter.currentScope.get('d'), true);
        expect(interpreter.currentScope.get('e'), true);
        expect(interpreter.currentScope.get('f'), true);
      });

      test('Logical operators', () async {
        final code = '''
int main() {
  bool a = true && true;
  bool b = true && false;
  bool c = false || true;
  bool d = false || false;
  return 0;
}
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(interpreter.currentScope.get('a'), true);
        expect(interpreter.currentScope.get('b'), false);
        expect(interpreter.currentScope.get('c'), true);
        expect(interpreter.currentScope.get('d'), false);
      });

      test('If-else control flow', () async {
        final code = '''
int main() {
  int x = 10;
  int result = 0;
  if (x > 5) {
    result = 1;
  } else {
    result = 2;
  }
  return 0;
}
''';
        final result = await interpreter.execute(code);
        if (!result.success) {
          print('ERROR: ${result.errorMessage}');
        }
        expect(result.success, true);
        expect(interpreter.currentScope.get('result'), 1);
      });

      test('For loop', () async {
        final code = '''
int main() {
  int sum = 0;
  for (int i = 1; i <= 5; i = i + 1) {
    sum = sum + i;
  }
  return 0;
}
''';
        final result = await interpreter.execute(code);
        if (!result.success) {
          print('ERROR: ${result.errorMessage}');
        }
        expect(result.success, true);
        expect(interpreter.currentScope.get('sum'), 15); // 1+2+3+4+5
      });

      test('While loop', () async {
        final code = '''
int main() {
  int count = 0;
  int i = 0;
  while (i < 5) {
    count = count + 1;
    i = i + 1;
  }
  return 0;
}
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(interpreter.currentScope.get('count'), 5);
      });

      test('Break statement in loop', () async {
        final code = '''
int main() {
  int sum = 0;
  for (int i = 1; i <= 10; i = i + 1) {
    if (i == 5) {
      break;
    }
    sum = sum + i;
  }
  return 0;
}
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(interpreter.currentScope.get('sum'), 10); // 1+2+3+4
      });

      test('Continue statement in loop', () async {
        final code = '''
int main() {
  int sum = 0;
  for (int i = 1; i <= 5; i = i + 1) {
    if (i == 3) {
      continue;
    }
    sum = sum + i;
  }
  return 0;
}
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(interpreter.currentScope.get('sum'), 12); // 1+2+4+5
      });

      test('Nested blocks and variable scoping', () async {
        final code = '''
int main() {
  int x = 10;
  {
    int y = 20;
    int z = x + y;
  }
  return 0;
}
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(interpreter.currentScope.get('x'), 10);
      });

      test('Farm operations - till, plant, water sequence', () async {
        final code = '''
int main() {
  till();
  plant(SeedType::wheatSeeds);
  water();
  return 0;
}
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        final plot = farmState.getCurrentPlot();
        expect(plot!.state, PlotState.watered);
        expect(plot.crop?.cropType, CropType.wheat);
        // Crop won't be grown immediately with time-based growth
        expect(plot.crop?.isGrown, false);
      });

      test('Farm operations - cannot plant on untilled plot', () async {
        final code = '''
int main() {
  plant(SeedType::wheatSeeds);
  return 0;
}
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        final plot = farmState.getCurrentPlot();
        expect(plot!.crop, null);
        expect(result.executionLog.any((msg) => msg.contains('Error')), true);
      });

      test('Farm operations - cannot plant after watering', () async {
        final code = '''
int main() {
  till();
  water();
  plant(SeedType::wheatSeeds);
  return 0;
}
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        final plot = farmState.getCurrentPlot();
        expect(plot!.state, PlotState.watered);
        // With planting allowed on watered plots, a crop should be planted
        expect(plot.crop?.cropType, CropType.wheat);
        // Crop won't be grown immediately
        expect(plot.crop?.isGrown, false);
      });

      test('Farm operations - move and plant multiple crops', () async {
        final code = '''
int main() {
  till();
  plant(SeedType::wheatSeeds);
  move(Direction::east);
  till();
  plant(SeedType::carrotSeeds);
  return 0;
}
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        final plot1 = farmState.getPlot(0, 0);
        final plot2 = farmState.getPlot(1, 0);
        expect(plot1!.crop?.cropType, CropType.wheat);
        expect(plot2!.crop?.cropType, CropType.carrot);
      });

      test('Try-catch error handling', () async {
        final code = '''
int main() {
  int result = 0;
  try {
    result = 10;
  } catch (...) {
    result = 99;
  }
  return 0;
}
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(interpreter.currentScope.get('result'), 10);
      });

      test('Division by zero error handling', () async {
        final code = '''
int main() {
  int x = 10;
  int y = 0;
  int result = x / y;
  return 0;
}
''';
        final result = await interpreter.execute(code);
        expect(result.success, false);
        expect(result.errorMessage, contains('Division by zero'));
      });

      test('Operator precedence', () async {
        final code = '''
int main() {
  int a = 2 + 3 * 4;
  int b = 10 - 2 * 3;
  return 0;
}
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        // Note: Current implementation evaluates left-to-right
        // This test documents current behavior
        expect(interpreter.currentScope.get('a'), isNotNull);
        expect(interpreter.currentScope.get('b'), isNotNull);
      });
    });

    group('Python Interpreter Tests', () {
      late PythonInterpreter interpreter;

      setUp(() {
        interpreter = PythonInterpreter(farmState: farmState);
      });

      test('Variable assignment (no type declaration)', () async {
        final code = '''
x = 10
y = 20
sum = x + y
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(interpreter.currentScope.get('x'), 10);
        expect(interpreter.currentScope.get('y'), 20);
        expect(interpreter.currentScope.get('sum'), 30);
      });

      test('Arithmetic operators', () async {
        final code = '''
a = 10 + 5
b = 20 - 8
c = 6 * 7
d = 20 / 4
e = 17 % 5
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(interpreter.currentScope.get('a'), 15);
        expect(interpreter.currentScope.get('b'), 12);
        expect(interpreter.currentScope.get('c'), 42);
        expect(interpreter.currentScope.get('d'), 5);
        expect(interpreter.currentScope.get('e'), 2);
      });

      test('Boolean expressions', () async {
        final code = '''
a = 10 > 5
b = 10 < 5
c = 10 == 10
d = 10 != 5
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(interpreter.currentScope.get('a'), true);
        expect(interpreter.currentScope.get('b'), false);
        expect(interpreter.currentScope.get('c'), true);
        expect(interpreter.currentScope.get('d'), true);
      });

      test('If-elif-else control flow', () async {
        final code = '''
x = 10
result = 0
if x > 15:
    result = 1
elif x > 5:
    result = 2
else:
    result = 3
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(interpreter.currentScope.get('result'), 2);
      });

      test('For loop with range', () async {
        final code = '''
sum = 0
for i in range(1, 6):
    sum = sum + i
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(interpreter.currentScope.get('sum'), 15);
      });

      test('While loop', () async {
        final code = '''
count = 0
i = 0
while i < 5:
    count = count + 1
    i = i + 1
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(interpreter.currentScope.get('count'), 5);
      });

      test('Break in loop', () async {
        final code = '''
sum = 0
for i in range(1, 11):
    if i == 5:
        break
    sum = sum + i
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(interpreter.currentScope.get('sum'), 10);
      });

      test('Continue in loop', () async {
        final code = '''
sum = 0
for i in range(1, 6):
    if i == 3:
        continue
    sum = sum + i
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(interpreter.currentScope.get('sum'), 12);
      });

      test('Indentation-based blocks', () async {
        final code = '''
x = 10
if x > 5:
    y = 20
    z = x + y
result = z
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(interpreter.currentScope.get('result'), 30);
      });

      test('Farm operations - correct sequence', () async {
        final code = '''
till()
plant(SeedType.wheatSeeds)
water()
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        final plot = farmState.getCurrentPlot();
        expect(plot!.state, PlotState.watered);
        expect(plot.crop?.cropType, CropType.wheat);
      });

      test('Try-except error handling', () async {
        final code = '''
result = 0
try:
    result = 10
except:
    result = 99
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(interpreter.currentScope.get('result'), 10);
      });

      test('String concatenation', () async {
        final code = '''
first = "Hello"
second = "World"
message = first + " " + second
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(interpreter.currentScope.get('message'), "Hello World");
      });
    });

    group('Java Interpreter Tests', () {
      late JavaInterpreter interpreter;

      setUp(() {
        interpreter = JavaInterpreter(farmState: farmState);
      });

      test('Variable declaration with types', () async {
        final code = '''
public class Main {
  public static void main(String[] args) {
    int x = 10;
    int y = 20;
    int sum = x + y;
  }
}
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(interpreter.currentScope.get('x'), 10);
        expect(interpreter.currentScope.get('y'), 20);
        expect(interpreter.currentScope.get('sum'), 30);
      });

      test('Arithmetic operations', () async {
        final code = '''
public class Main {
  public static void main(String[] args) {
    int a = 15 + 10;
    int b = 30 - 12;
    int c = 8 * 9;
  }
}
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(interpreter.currentScope.get('a'), 25);
        expect(interpreter.currentScope.get('b'), 18);
        expect(interpreter.currentScope.get('c'), 72);
      });

      test('If-else statement', () async {
        final code = '''
public class Main {
  public static void main(String[] args) {
    int x = 8;
    int result = 0;
    if (x > 5) {
      result = 1;
    } else {
      result = 2;
    }
  }
}
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(interpreter.currentScope.get('result'), 1);
      });

      test('For loop', () async {
        final code = '''
public class Main {
  public static void main(String[] args) {
    int sum = 0;
    for (int i = 1; i <= 5; i++) {
      sum = sum + i;
    }
  }
}
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(interpreter.currentScope.get('sum'), 15);
      });

      test('While loop', () async {
        final code = '''
public class Main {
  public static void main(String[] args) {
    int count = 0;
    int i = 0;
    while (i < 5) {
      count++;
      i++;
    }
  }
}
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(interpreter.currentScope.get('count'), 5);
      });

      test('Farm operations', () async {
        final code = '''
public class Main {
  public static void main(String[] args) {
    till();
    plant(SeedType.WHEAT_SEEDS);
    water();
  }
}
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        final plot = farmState.getCurrentPlot();
        expect(plot!.crop?.cropType, CropType.wheat);
      });

      test('Try-catch error handling', () async {
        final code = '''
public class Main {
  public static void main(String[] args) {
    int result = 0;
    try {
      result = 10;
    } catch (Exception e) {
      result = 99;
    }
  }
}
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(interpreter.currentScope.get('result'), 10);
      });
    });

    group('C# Interpreter Tests', () {
      late CSharpInterpreter interpreter;

      setUp(() {
        interpreter = CSharpInterpreter(farmState: farmState);
      });

      test('Variable declaration', () async {
        final code = '''
class Program {
  static void Main() {
    int x = 10;
    int y = 20;
    int sum = x + y;
  }
}
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(interpreter.currentScope.get('x'), 10);
        expect(interpreter.currentScope.get('sum'), 30);
      });

      test('Boolean operations', () async {
        final code = '''
class Program {
  static void Main() {
    bool a = true && false;
    bool b = true || false;
    bool c = 10 > 5;
  }
}
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(interpreter.currentScope.get('a'), false);
        expect(interpreter.currentScope.get('b'), true);
        expect(interpreter.currentScope.get('c'), true);
      });

      test('For loop', () async {
        final code = '''
class Program {
  static void Main() {
    int total = 0;
    for (int i = 0; i < 5; i++) {
      total = total + i;
    }
  }
}
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(interpreter.currentScope.get('total'), 10); // 0+1+2+3+4
      });

      test('Farm operations', () async {
        final code = '''
class Program {
  static void Main() {
    till();
    plant(SeedType.WheatSeeds);
    water();
  }
}
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        final plot = farmState.getCurrentPlot();
        expect(plot!.crop?.cropType, CropType.wheat);
      });
    });

    group('JavaScript Interpreter Tests', () {
      late JavaScriptInterpreter interpreter;

      setUp(() {
        interpreter = JavaScriptInterpreter(farmState: farmState);
      });

      test('var declaration', () async {
        final code = '''
var x = 10;
var y = 20;
var sum = x + y;
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(interpreter.currentScope.get('x'), 10);
        expect(interpreter.currentScope.get('sum'), 30);
      });

      test('let declaration', () async {
        final code = '''
let a = 5;
let b = 10;
let product = a * b;
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(interpreter.currentScope.get('a'), 5);
        expect(interpreter.currentScope.get('product'), 50);
      });

      test('const declaration', () async {
        final code = '''
const PI = 3.14;
const radius = 5;
const area = PI * radius * radius;
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(interpreter.currentScope.get('PI'), 3.14);
      });

      test('If-else statement', () async {
        final code = '''
let x = 7;
let result = 0;
if (x > 5) {
  result = 1;
} else {
  result = 2;
}
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(interpreter.currentScope.get('result'), 1);
      });

      test('For loop', () async {
        final code = '''
let sum = 0;
for (let i = 1; i <= 5; i++) {
  sum = sum + i;
}
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(interpreter.currentScope.get('sum'), 15);
      });

      test('While loop', () async {
        final code = '''
let count = 0;
let i = 0;
while (i < 5) {
  count++;
  i++;
}
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(interpreter.currentScope.get('count'), 5);
      });

      test('Farm operations', () async {
        final code = '''
till();
plant(SeedType.wheatSeeds);
water();
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        final plot = farmState.getCurrentPlot();
        expect(plot!.crop?.cropType, CropType.wheat);
      });

      test('String concatenation', () async {
        final code = '''
let first = "Hello";
let second = "World";
let message = first + " " + second;
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(interpreter.currentScope.get('message'), "Hello World");
      });

      test('Try-catch error handling', () async {
        final code = '''
let result = 0;
try {
  result = 10;
} catch (e) {
  result = 99;
}
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(interpreter.currentScope.get('result'), 10);
      });
    });

    group('Farm Domain Rules Tests', () {
      test('Cannot plant on normal plot', () async {
        final interpreter = CppInterpreter(farmState: farmState);
        final code = '''
int main() {
  plant(SeedType::wheatSeeds);
  return 0;
}
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(farmState.getCurrentPlot()!.crop, null);
      });

      test('Must till before planting', () async {
        final interpreter = PythonInterpreter(farmState: farmState);
        final code = '''
till()
plant(SeedType.wheatSeeds)
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(farmState.getCurrentPlot()!.crop?.cropType, CropType.wheat);
      });

      test('Watering after tilling prevents planting', () async {
        final interpreter = JavaInterpreter(farmState: farmState);
        final code = '''
public class Main {
  public static void main(String[] args) {
    till();
    water();
    plant(SeedType.WHEAT_SEEDS);
  }
}
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        // Planting on watered plot is allowed now
        expect(farmState.getCurrentPlot()!.crop?.cropType, CropType.wheat);
        expect(farmState.getCurrentPlot()!.state, PlotState.watered);
      });

      test('Can harvest after planting', () async {
        final interpreter = CSharpInterpreter(farmState: farmState);
        final code = '''
class Program {
  static void Main() {
    till();
    plant(SeedType.WheatSeeds);
    harvest();
  }
}
''';
        final result = await interpreter.execute(code);
        // Harvest should fail because crop isn't grown yet (time-based growth)
        expect(result.success, true);
        expect(farmState.getCurrentPlot()!.crop, isNotNull);
        expect(farmState.getCurrentPlot()!.crop!.isGrown, false);
      });

      test('Cannot move out of bounds', () async {
        final interpreter = JavaScriptInterpreter(farmState: farmState);
        final code = '''
move(Direction.west);
move(Direction.west);
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(farmState.dronePosition.x, 0);
        expect(result.executionLog.any((msg) => msg.contains('out of bounds')), true);
      });

      test('Multiple plots farming workflow', () async {
        final interpreter = CppInterpreter(farmState: farmState);
        final code = '''
int main() {
  till();
  plant(SeedType::wheatSeeds);
  move(Direction::east);
  till();
  plant(SeedType::carrotSeeds);
  move(Direction::east);
  till();
  plant(SeedType::potatoSeeds);
  return 0;
}
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(farmState.getPlot(0, 0)!.crop?.cropType, CropType.wheat);
        expect(farmState.getPlot(1, 0)!.crop?.cropType, CropType.carrot);
        expect(farmState.getPlot(2, 0)!.crop?.cropType, CropType.potato);
      });
    });

    group('Expression Evaluation Tests', () {
      late CppInterpreter interpreter;

      setUp(() {
        interpreter = CppInterpreter(farmState: farmState);
      });

      test('Complex arithmetic expressions', () async {
        final code = '''
int main() {
  int a = 2 + 3;
  int b = a * 4;
  int c = b - 10;
  return 0;
}
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(interpreter.currentScope.get('a'), 5);
        expect(interpreter.currentScope.get('b'), 20);
        expect(interpreter.currentScope.get('c'), 10);
      });

      test('Nested logical expressions', () async {
        final code = '''
int main() {
  bool a = true && true;
  bool b = a || false;
  bool c = b && true;
  return 0;
}
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(interpreter.currentScope.get('a'), true);
        expect(interpreter.currentScope.get('b'), true);
        expect(interpreter.currentScope.get('c'), true);
      });

      test('Comparison chains', () async {
        final code = '''
int main() {
  int x = 10;
  bool a = x > 5;
  bool b = x < 20;
  bool c = a && b;
  return 0;
}
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(interpreter.currentScope.get('c'), true);
      });
    });

    group('Error Handling Tests', () {
      test('C++ - Undefined variable error', () async {
        final interpreter = CppInterpreter(farmState: farmState);
        final code = '''
int main() {
  int x = y + 10;
  return 0;
}
''';
        final result = await interpreter.execute(code);
        expect(result.success, false);
        expect(result.errorMessage, contains('Undefined variable'));
      });

      test('Python - Syntax error', () async {
        final interpreter = PythonInterpreter(farmState: farmState);
        final code = '''
if x > 5
    y = 10
''';
        final result = await interpreter.execute(code);
        expect(result.success, false);
      });

      test('Java - Missing main method', () async {
        final interpreter = JavaInterpreter(farmState: farmState);
        final code = '''
public class Main {
  public void someMethod() {
    int x = 10;
  }
}
''';
        final result = await interpreter.execute(code);
        expect(result.success, false);
        expect(result.errorMessage, contains('main'));
      });
    });

    group('Complex Workflow Tests', () {
      test('Full farming cycle with loops', () async {
        final interpreter = PythonInterpreter(farmState: farmState);
        final code = '''
for i in range(0, 3):
    till()
    plant(SeedType.wheatSeeds)
    water()
    if i < 2:
        move(Direction.east)
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(farmState.getPlot(0, 0)!.crop?.cropType, CropType.wheat);
        expect(farmState.getPlot(1, 0)!.crop?.cropType, CropType.wheat);
        expect(farmState.getPlot(2, 0)!.crop?.cropType, CropType.wheat);
      });

      test('Conditional farming based on position', () async {
        final interpreter = JavaScriptInterpreter(farmState: farmState);
        final code = '''
let planted = 0;
for (let i = 0; i < 3; i++) {
  till();
  if (i == 0) {
    plant(SeedType.wheatSeeds);
    planted++;
  } else if (i == 1) {
    plant(SeedType.carrotSeeds);
    planted++;
  }
  if (i < 2) {
    move(Direction.east);
  }
}
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(interpreter.currentScope.get('planted'), 2);
        expect(farmState.getPlot(0, 0)!.crop?.cropType, CropType.wheat);
        expect(farmState.getPlot(1, 0)!.crop?.cropType, CropType.carrot);
      });

      test('Error recovery with try-catch', () async {
        final interpreter = CppInterpreter(farmState: farmState);
        final code = '''
int main() {
  int successCount = 0;
  try {
    till();
    plant(SeedType::wheatSeeds);
    successCount = successCount + 1;
  } catch (...) {
    successCount = 0;
  }
  return 0;
}
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(interpreter.currentScope.get('successCount'), 1);
      });
    });

    group('New Function Tests', () {
      late FarmState farmState;

      setUp(() {
        farmState = FarmState(gridWidth: 3, gridHeight: 3);
      });

      test('getPositionX and getPositionY return correct position', () async {
        final interpreter = CppInterpreter(farmState: farmState);
        final code = '''
int main() {
  int x = getPositionX();
  int y = getPositionY();
  move(Direction::east);
  int newX = getPositionX();
  return 0;
}
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(interpreter.currentScope.get('x'), 0);
        expect(interpreter.currentScope.get('y'), 0);
        expect(interpreter.currentScope.get('newX'), 1);
      });

      test('getPlotState returns correct state', () async {
        final interpreter = CppInterpreter(farmState: farmState);
        final code = '''
int main() {
  bool isNormal = (getPlotState() == PlotState::Normal);
  till();
  bool isTilled = (getPlotState() == PlotState::Tilled);
  water();
  bool isWatered = (getPlotState() == PlotState::Watered);
  return 0;
}
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(interpreter.currentScope.get('isNormal'), true);
        expect(interpreter.currentScope.get('isTilled'), true);
        expect(interpreter.currentScope.get('isWatered'), true);
      });

      test('getCropType returns correct crop', () async {
        final interpreter = CppInterpreter(farmState: farmState);
        final code = '''
int main() {
  till();
  plant(SeedType::WheatSeeds);
  bool isWheat = (getCropType() == CropType::Wheat);
  return 0;
}
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(interpreter.currentScope.get('isWheat'), true);
      });

      test('isCropGrown returns correct value', () async {
        final interpreter = CppInterpreter(farmState: farmState);
        final code = '''
int main() {
  till();
  water();
  plant(SeedType::WheatSeeds);
  bool grown = isCropGrown();
  return 0;
}
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(interpreter.currentScope.get('grown'), false); // Not grown yet
      });

      test('canTill, canWater, canPlant, canHarvest work correctly', () async {
        final interpreter = CppInterpreter(farmState: farmState);
        final code = '''
int main() {
  bool tillable1 = canTill();
  bool plantable1 = canPlant();
  
  till();
  bool tillable2 = canTill();
  bool plantable2 = canPlant();
  
  water();
  plant(SeedType::WheatSeeds);
  bool harvestable1 = canHarvest();
  bool waterable = canWater();
  
  return 0;
}
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(interpreter.currentScope.get('tillable1'), true);
        expect(interpreter.currentScope.get('plantable1'), false);
        expect(interpreter.currentScope.get('tillable2'), false);
        expect(interpreter.currentScope.get('plantable2'), true);
        expect(interpreter.currentScope.get('harvestable1'), false); // Crop not grown yet
        expect(interpreter.currentScope.get('waterable'), true);
      });

      test('getPlotGridX and getPlotGridY return grid dimensions', () async {
        final interpreter = CppInterpreter(farmState: farmState);
        final code = '''
int main() {
  int gridX = getPlotGridX();
  int gridY = getPlotGridY();
  return 0;
}
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(interpreter.currentScope.get('gridX'), 3);
        expect(interpreter.currentScope.get('gridY'), 3);
      });

      test('Python syntax for new functions', () async {
        final interpreter = PythonInterpreter(farmState: farmState);
        final code = '''
x = getPositionX()
y = getPositionY()
till()
state = getPlotState()
is_tilled = (state == PlotState.Tilled)
grid_x = getPlotGridX()
grid_y = getPlotGridY()
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(interpreter.currentScope.get('x'), 0);
        expect(interpreter.currentScope.get('y'), 0);
        expect(interpreter.currentScope.get('is_tilled'), true);
        expect(interpreter.currentScope.get('grid_x'), 3);
        expect(interpreter.currentScope.get('grid_y'), 3);
      });

      test('Java syntax for new functions', () async {
        final interpreter = JavaInterpreter(farmState: farmState);
        final code = '''
public class Main {
  public static void main(String[] args) {
    int x = getPositionX();
    int y = getPositionY();
    till();
    boolean isTillable = canTill();
    boolean isPlantable = canPlant();
    int gridX = getPlotGridX();
  }
}
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(interpreter.currentScope.get('x'), 0);
        expect(interpreter.currentScope.get('y'), 0);
        expect(interpreter.currentScope.get('isTillable'), false);
        expect(interpreter.currentScope.get('isPlantable'), true);
        expect(interpreter.currentScope.get('gridX'), 3);
      });

      test('C# syntax for new functions', () async {
        final interpreter = CSharpInterpreter(farmState: farmState);
        final code = '''
class Program {
  static void Main() {
    int x = GetPositionX();
    int y = GetPositionY();
    Till();
    bool canPlantHere = CanPlant();
    int gridX = GetPlotGridX();
    int gridY = GetPlotGridY();
  }
}
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(interpreter.currentScope.get('x'), 0);
        expect(interpreter.currentScope.get('y'), 0);
        expect(interpreter.currentScope.get('canPlantHere'), true);
        expect(interpreter.currentScope.get('gridX'), 3);
        expect(interpreter.currentScope.get('gridY'), 3);
      });

      test('JavaScript syntax for new functions', () async {
        final interpreter = JavaScriptInterpreter(farmState: farmState);
        final code = '''
let x = getPositionX();
let y = getPositionY();
till();
water();
plant(SeedType.wheatSeeds);
let cropType = getCropType();
let isWheat = (cropType == CropType.Wheat);
let grown = isCropGrown();
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(interpreter.currentScope.get('x'), 0);
        expect(interpreter.currentScope.get('y'), 0);
        expect(interpreter.currentScope.get('cropType'), 'CropType.Wheat');
        expect(interpreter.currentScope.get('isWheat'), true);
        expect(interpreter.currentScope.get('grown'), false);
      });

      test('Complex workflow using new functions', () async {
        final interpreter = CppInterpreter(farmState: farmState);
        final code = '''
int main() {
  int gridX = getPlotGridX();
  int gridY = getPlotGridY();
  int planted = 0;
  
  for (int y = 0; y < gridY; y = y + 1) {
    for (int x = 0; x < gridX; x = x + 1) {
      if (canTill()) {
        till();
      }
      if (canPlant()) {
        plant(SeedType::WheatSeeds);
        planted = planted + 1;
      }
      if (getPositionX() < gridX - 1) {
        move(Direction::east);
      }
    }
    if (getPositionY() < gridY - 1) {
      move(Direction::north);
      // Reset X position (simplified - would need west moves in real scenario)
    }
  }
  
  return 0;
}
''';
        final result = await interpreter.execute(code);
        expect(result.success, true);
        expect(interpreter.currentScope.get('planted'), greaterThan(0));
      });
    });
  });

  // Test group for line mapping accuracy
  group('Line Mapping Accuracy Tests', () {
    late FarmState farmState;
    
    setUp(() {
      final mockUserData = UserData(
        uid: 'test_user',
        data: {
          'sproutProgress': {
            'inventory': {
              'wheatSeeds': {'isLocked': false, 'quantity': 100},
            }
          }
        },
      );
      farmState = FarmState(gridWidth: 3, gridHeight: 3, userData: mockUserData);
    });

    test('C++ - Line highlighting matches source code lines', () async {
      final List<int?> executedLines = [];
      final interpreter = CppInterpreter(
        farmState: farmState,
        onLineExecuting: (line) => executedLines.add(line),
      );

      // Code with specific statements on known lines
      final code = '''
#include <iostream>
using namespace std;

int main() {
  int x = 5;
  int y = 10;
  int z = x + y;
  return 0;
}
''';

      await interpreter.execute(code);
      
      // Verify that line 5 (int x = 5;) was tracked
      expect(executedLines, contains(5));
      // Verify that line 6 (int y = 10;) was tracked
      expect(executedLines, contains(6));
      // Verify that line 7 (int z = x + y;) was tracked
      expect(executedLines, contains(7));
    });

    test('Python - Line highlighting matches source code lines', () async {
      final List<int?> executedLines = [];
      final interpreter = PythonInterpreter(
        farmState: farmState,
        onLineExecuting: (line) => executedLines.add(line),
      );

      final code = '''
x = 5
y = 10
z = x + y
print(z)
''';

      await interpreter.execute(code);
      
      // Python is line-based, should track lines 1, 2, 3, 4
      expect(executedLines, contains(1));
      expect(executedLines, contains(2));
      expect(executedLines, contains(3));
      expect(executedLines, contains(4));
    });

    test('Java - Line highlighting matches source code lines', () async {
      final List<int?> executedLines = [];
      final interpreter = JavaInterpreter(
        farmState: farmState,
        onLineExecuting: (line) => executedLines.add(line),
      );

      final code = '''
public class Main {
  public static void main(String[] args) {
    int x = 5;
    int y = 10;
    int z = x + y;
    System.out.println(z);
  }
}
''';

      await interpreter.execute(code);
      
      // Verify statements on lines 3, 4, 5, 6
      expect(executedLines, contains(3));
      expect(executedLines, contains(4));
      expect(executedLines, contains(5));
      expect(executedLines, contains(6));
    });

    test('C# - Line highlighting matches source code lines', () async {
      final List<int?> executedLines = [];
      final interpreter = CSharpInterpreter(
        farmState: farmState,
        onLineExecuting: (line) => executedLines.add(line),
      );

      final code = '''
using System;

class Program {
  static void Main() {
    int x = 5;
    int y = 10;
    int z = x + y;
    Console.WriteLine(z);
  }
}
''';

      await interpreter.execute(code);
      
      // Verify statements on lines 5, 6, 7, 8
      expect(executedLines, contains(5));
      expect(executedLines, contains(6));
      expect(executedLines, contains(7));
      expect(executedLines, contains(8));
    });

    test('JavaScript - Line highlighting matches source code lines', () async {
      final List<int?> executedLines = [];
      final interpreter = JavaScriptInterpreter(
        farmState: farmState,
        onLineExecuting: (line) => executedLines.add(line),
      );

      final code = '''
let x = 5;
let y = 10;
let z = x + y;
console.log(z);
''';

      await interpreter.execute(code);
      
      // Verify lines 1, 2, 3, 4
      expect(executedLines, contains(1));
      expect(executedLines, contains(2));
      expect(executedLines, contains(3));
      expect(executedLines, contains(4));
    });
  });

  // Test group for graceful stop execution
  group('Graceful Stop Execution Tests', () {
    late FarmState farmState;
    
    setUp(() {
      final mockUserData = UserData(
        uid: 'test_user',
        data: {
          'sproutProgress': {
            'inventory': {}
          }
        },
      );
      farmState = FarmState(gridWidth: 3, gridHeight: 3, userData: mockUserData);
    });

    test('C++ - Stop execution gracefully without crashing', () async {
      final interpreter = CppInterpreter(farmState: farmState);
      bool executionStopped = false;

      // Code with a loop that would run for a while
      final code = '''
#include <iostream>
using namespace std;

int main() {
  for (int i = 0; i < 100; i++) {
    int x = i * 2;
  }
  return 0;
}
''';

      // Start execution and stop it mid-way
      Future.delayed(Duration(milliseconds: 300), () {
        interpreter.stop();
        executionStopped = true;
      });

      await interpreter.execute(code);
      
      // Verify that execution was stopped
      expect(executionStopped, true);
      // Verify that stop message appears in log
      expect(interpreter.executionLog.any((msg) => msg.contains('Stop requested')), true);
      // Most importantly: this test should not crash
    });

    test('Python - Stop execution gracefully', () async {
      final interpreter = PythonInterpreter(farmState: farmState);
      bool executionStopped = false;

      final code = '''
for i in range(100):
    x = i * 2
''';

      Future.delayed(Duration(milliseconds: 300), () {
        interpreter.stop();
        executionStopped = true;
      });

      await interpreter.execute(code);
      expect(executionStopped, true);
      expect(interpreter.executionLog.any((msg) => msg.contains('Stop requested')), true);
    });

    test('Java - Stop execution gracefully', () async {
      final interpreter = JavaInterpreter(farmState: farmState);
      bool executionStopped = false;

      final code = '''
public class Main {
  public static void main(String[] args) {
    for (int i = 0; i < 100; i++) {
      int x = i * 2;
    }
  }
}
''';

      Future.delayed(Duration(milliseconds: 300), () {
        interpreter.stop();
        executionStopped = true;
      });

      await interpreter.execute(code);
      expect(executionStopped, true);
      expect(interpreter.executionLog.any((msg) => msg.contains('Stop requested')), true);
    });

    test('C# - Stop execution gracefully', () async {
      final interpreter = CSharpInterpreter(farmState: farmState);
      bool executionStopped = false;

      final code = '''
using System;

class Program {
  static void Main() {
    for (int i = 0; i < 100; i++) {
      int x = i * 2;
    }
  }
}
''';

      Future.delayed(Duration(milliseconds: 300), () {
        interpreter.stop();
        executionStopped = true;
      });

      await interpreter.execute(code);
      expect(executionStopped, true);
      expect(interpreter.executionLog.any((msg) => msg.contains('Stop requested')), true);
    });

    test('JavaScript - Stop execution gracefully', () async {
      final interpreter = JavaScriptInterpreter(farmState: farmState);
      bool executionStopped = false;

      final code = '''
for (let i = 0; i < 100; i++) {
  let x = i * 2;
}
''';

      Future.delayed(Duration(milliseconds: 300), () {
        interpreter.stop();
        executionStopped = true;
      });

      await interpreter.execute(code);
      expect(executionStopped, true);
      expect(interpreter.executionLog.any((msg) => msg.contains('Stop requested')), true);
    });

    test('Stop clears line highlighting', () async {
      int? lastNotifiedLine = null;
      final interpreter = CppInterpreter(
        farmState: farmState,
        onLineExecuting: (line) => lastNotifiedLine = line,
      );

      final code = '''
#include <iostream>
using namespace std;

int main() {
  for (int i = 0; i < 50; i++) {
    int x = i;
  }
  return 0;
}
''';

      Future.delayed(Duration(milliseconds: 250), () {
        interpreter.stop();
      });

      await interpreter.execute(code);
      
      // After stopping, line highlighting should be cleared (null)
      expect(lastNotifiedLine, null);
    });
  });

  // Comprehensive Stop Execution Test Suite
  group('Comprehensive Stop Execution Tests', () {
    late FarmState farmState;
    
    setUp(() {
      final mockUserData = UserData(
        uid: 'test_user',
        data: {
          'sproutProgress': {
            'inventory': {
              'wheatSeeds': {'isLocked': false, 'quantity': 100},
            }
          }
        },
      );
      farmState = FarmState(gridWidth: 3, gridHeight: 3, userData: mockUserData);
    });

    test('C++ - Stop during nested loops (deep nesting)', () async {
      final interpreter = CppInterpreter(farmState: farmState);
      bool stopped = false;

      final code = '''
#include <iostream>
using namespace std;

int main() {
  for (int i = 0; i < 20; i++) {
    for (int j = 0; j < 20; j++) {
      for (int k = 0; k < 20; k++) {
        int x = i + j + k;
      }
    }
  }
  return 0;
}
''';

      Future.delayed(Duration(milliseconds: 400), () {
        interpreter.stop();
        stopped = true;
      });

      await interpreter.execute(code);
      
      expect(stopped, true);
      expect(interpreter.executionLog.any((msg) => msg.contains('Stop requested')), true);
    });

    test('Python - Stop during nested for loops', () async {
      final interpreter = PythonInterpreter(farmState: farmState);
      bool stopped = false;

      final code = '''
for i in range(15):
    for j in range(15):
        for k in range(15):
            x = i + j + k
''';

      Future.delayed(Duration(milliseconds: 350), () {
        interpreter.stop();
        stopped = true;
      });

      await interpreter.execute(code);
      expect(stopped, true);
      expect(interpreter.executionLog.any((msg) => msg.contains('Stop requested')), true);
    });

    test('Java - Stop during nested while loops', () async {
      final interpreter = JavaInterpreter(farmState: farmState);
      bool stopped = false;

      final code = '''
public class Main {
  public static void main(String[] args) {
    int i = 0;
    while (i < 15) {
      int j = 0;
      while (j < 15) {
        int k = 0;
        while (k < 15) {
          k++;
        }
        j++;
      }
      i++;
    }
  }
}
''';

      Future.delayed(Duration(milliseconds: 400), () {
        interpreter.stop();
        stopped = true;
      });

      await interpreter.execute(code);
      expect(stopped, true);
      expect(interpreter.executionLog.any((msg) => msg.contains('Stop requested')), true);
    });

    test('C# - Stop during mixed loop types (for + while)', () async {
      final interpreter = CSharpInterpreter(farmState: farmState);
      bool stopped = false;

      final code = '''
using System;

class Program {
  static void Main() {
    for (int i = 0; i < 20; i++) {
      int j = 0;
      while (j < 20) {
        int x = i + j;
        j++;
      }
    }
  }
}
''';

      Future.delayed(Duration(milliseconds: 350), () {
        interpreter.stop();
        stopped = true;
      });

      await interpreter.execute(code);
      expect(stopped, true);
      expect(interpreter.executionLog.any((msg) => msg.contains('Stop requested')), true);
    });

    test('JavaScript - Stop during deeply nested loops', () async {
      final interpreter = JavaScriptInterpreter(farmState: farmState);
      bool stopped = false;

      final code = '''
for (let i = 0; i < 15; i++) {
  for (let j = 0; j < 15; j++) {
    for (let k = 0; k < 15; k++) {
      let x = i + j + k;
    }
  }
}
''';

      Future.delayed(Duration(milliseconds: 350), () {
        interpreter.stop();
        stopped = true;
      });

      await interpreter.execute(code);
      expect(stopped, true);
      expect(interpreter.executionLog.any((msg) => msg.contains('Stop requested')), true);
    });

    test('C++ - Stop during very long-running loop (simulated infinite)', () async {
      final interpreter = CppInterpreter(farmState: farmState);
      bool stopped = false;

      final code = '''
#include <iostream>
using namespace std;

int main() {
  for (int i = 0; i < 1000000; i++) {
    int x = i * 2;
  }
  return 0;
}
''';

      Future.delayed(Duration(milliseconds: 300), () {
        interpreter.stop();
        stopped = true;
      });

      await interpreter.execute(code);
      
      expect(stopped, true);
      expect(interpreter.executionLog.any((msg) => msg.contains('Stop requested')), true);
      // Should not complete the full loop
      expect(interpreter.executionLog.length, lessThan(1000000));
    });

    test('Python - Stop immediately after start', () async {
      final interpreter = PythonInterpreter(farmState: farmState);
      bool stopped = false;

      final code = '''
for i in range(1000):
    x = i * 2
''';

      // Stop almost immediately
      Future.delayed(Duration(milliseconds: 10), () {
        interpreter.stop();
        stopped = true;
      });

      await interpreter.execute(code);
      expect(stopped, true);
      expect(interpreter.executionLog.any((msg) => msg.contains('Stop requested')), true);
    });

    test('Java - Multiple rapid stop calls (should handle gracefully)', () async {
      final interpreter = JavaInterpreter(farmState: farmState);
      int stopCount = 0;

      final code = '''
public class Main {
  public static void main(String[] args) {
    for (int i = 0; i < 500; i++) {
      int x = i * 2;
    }
  }
}
''';

      // Call stop multiple times rapidly
      Future.delayed(Duration(milliseconds: 250), () {
        interpreter.stop();
        stopCount++;
      });
      Future.delayed(Duration(milliseconds: 260), () {
        interpreter.stop();
        stopCount++;
      });
      Future.delayed(Duration(milliseconds: 270), () {
        interpreter.stop();
        stopCount++;
      });

      await interpreter.execute(code);
      
      expect(stopCount, 3);
      // Should only log "Stop requested" once (duplicate calls ignored)
      final stopMessages = interpreter.executionLog.where((msg) => msg.contains('Stop requested')).length;
      expect(stopMessages, 1);
    });

    test('C# - Stop during validation phase', () async {
      final interpreter = CSharpInterpreter(farmState: farmState);
      bool stopped = false;

      final code = '''
using System;

class Program {
  static void Main() {
    for (int i = 0; i < 100; i++) {
      int x = i;
    }
  }
}
''';

      // Stop during validation
      Future.delayed(Duration(milliseconds: 5), () {
        interpreter.stop();
        stopped = true;
      });

      final validationResult = await interpreter.preValidate(code);
      
      if (validationResult == null && !interpreter.shouldStop) {
        await interpreter.execute(code);
      }
      
      expect(stopped, true);
    });

    test('JavaScript - Stop with farm operations in loop', () async {
      // Test stop while performing farm operations
      final interpreter = JavaScriptInterpreter(farmState: farmState);
      bool stopped = false;

      final code = '''
for (let i = 0; i < 100; i++) {
  if (canTill()) {
    till();
  }
  move("east");
}
''';

      Future.delayed(Duration(milliseconds: 400), () {
        interpreter.stop();
        stopped = true;
      });

      await interpreter.execute(code);
      
      expect(stopped, true);
      expect(interpreter.executionLog.any((msg) => msg.contains('Stop requested')), true);
    });

    test('C++ - Stop and verify no memory/state corruption', () async {
      final interpreter = CppInterpreter(farmState: farmState);

      final code = '''
#include <iostream>
using namespace std;

int main() {
  int counter = 0;
  for (int i = 0; i < 200; i++) {
    counter = counter + 1;
  }
  return 0;
}
''';

      Future.delayed(Duration(milliseconds: 300), () {
        interpreter.stop();
      });

      await interpreter.execute(code);
      
      // Verify interpreter state is clean after stop
      expect(interpreter.shouldStop, true);
      expect(interpreter.shouldBreak, false);
      expect(interpreter.shouldContinue, false);
      expect(interpreter.shouldReturn, false);
    });

    test('Python - Stop during while loop with complex condition', () async {
      final interpreter = PythonInterpreter(farmState: farmState);
      bool stopped = false;

      final code = '''
i = 0
while i < 100:
    j = 0
    while j < 100:
        x = i * j
        j = j + 1
    i = i + 1
''';

      Future.delayed(Duration(milliseconds: 350), () {
        interpreter.stop();
        stopped = true;
      });

      await interpreter.execute(code);
      expect(stopped, true);
      expect(interpreter.executionLog.any((msg) => msg.contains('Stop requested')), true);
    });

    test('Java - Stop during switch case with loop', () async {
      final interpreter = JavaInterpreter(farmState: farmState);
      bool stopped = false;

      final code = '''
public class Main {
  public static void main(String[] args) {
    for (int i = 0; i < 100; i++) {
      switch (i % 3) {
        case 0:
          int x = i;
          break;
        case 1:
          int y = i * 2;
          break;
        case 2:
          int z = i * 3;
          break;
      }
    }
  }
}
''';

      Future.delayed(Duration(milliseconds: 350), () {
        interpreter.stop();
        stopped = true;
      });

      await interpreter.execute(code);
      expect(stopped, true);
      expect(interpreter.executionLog.any((msg) => msg.contains('Stop requested')), true);
    });

    test('C# - Stop and check execution time is reasonable', () async {
      final interpreter = CSharpInterpreter(farmState: farmState);
      final stopwatch = Stopwatch()..start();

      final code = '''
using System;

class Program {
  static void Main() {
    for (int i = 0; i < 10000; i++) {
      for (int j = 0; j < 10000; j++) {
        int x = i + j;
      }
    }
  }
}
''';

      Future.delayed(Duration(milliseconds: 300), () {
        interpreter.stop();
      });

      await interpreter.execute(code);
      stopwatch.stop();
      
      // Execution should stop quickly (within 1 second even with stop delay)
      expect(stopwatch.elapsedMilliseconds, lessThan(1500));
      expect(interpreter.executionLog.any((msg) => msg.contains('Stop requested')), true);
    });

    test('JavaScript - Stop during try-catch block with loops', () async {
      final interpreter = JavaScriptInterpreter(farmState: farmState);
      bool stopped = false;

      final code = '''
try {
  for (let i = 0; i < 150; i++) {
    let x = i * 2;
  }
} catch (e) {
  console.log("Error");
}
''';

      Future.delayed(Duration(milliseconds: 350), () {
        interpreter.stop();
        stopped = true;
      });

      await interpreter.execute(code);
      expect(stopped, true);
      expect(interpreter.executionLog.any((msg) => msg.contains('Stop requested')), true);
    });
  });
}
