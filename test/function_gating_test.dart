import 'package:flutter_test/flutter_test.dart';
import 'package:code_sprout/models/farm_data.dart';
import 'package:code_sprout/models/farm_data_schema.dart';
import 'package:code_sprout/models/research_data.dart';
import 'package:code_sprout/models/research_items_schema.dart';
import 'package:code_sprout/compilers/python_interpreter.dart';

void main() {
  group('Function Gating Tests', () {
    late FarmState farmState;
    late ResearchState researchState;
    late PythonInterpreter interpreter;

    setUp(() {
      // Clear and add test function research items
      ResearchItemsSchema.instance.clearForTesting();
      
      // Add function research items with functions_unlocked
      ResearchItemsSchema.instance.addFunctionsItemForTesting('func_move',
        FunctionsResearchItemSchema(
          id: 'func_move',
          icon: '',
          name: 'move(direction)',
          languageSpecificDescription: {},
          predecessorIds: [],
          requirements: {},
          functionsUnlocked: ['move(direction)'],
        ));
      
      ResearchItemsSchema.instance.addFunctionsItemForTesting('func_till',
        FunctionsResearchItemSchema(
          id: 'func_till',
          icon: '',
          name: 'till()',
          languageSpecificDescription: {},
          predecessorIds: [],
          requirements: {},
          functionsUnlocked: ['till()'],
        ));

      ResearchItemsSchema.instance.addFunctionsItemForTesting('func_water',
        FunctionsResearchItemSchema(
          id: 'func_water',
          icon: '',
          name: 'water()',
          languageSpecificDescription: {},
          predecessorIds: [],
          requirements: {},
          functionsUnlocked: ['water()'],
        ));

      ResearchItemsSchema.instance.addFunctionsItemForTesting('func_plant',
        FunctionsResearchItemSchema(
          id: 'func_plant',
          icon: '',
          name: 'plant(crop)',
          languageSpecificDescription: {},
          predecessorIds: [],
          requirements: {},
          functionsUnlocked: ['plant(seedType)'],
        ));

      ResearchItemsSchema.instance.addFunctionsItemForTesting('func_harvest',
        FunctionsResearchItemSchema(
          id: 'func_harvest',
          icon: '',
          name: 'harvest()',
          languageSpecificDescription: {},
          predecessorIds: [],
          requirements: {},
          functionsUnlocked: ['harvest()'],
        ));

      ResearchItemsSchema.instance.addFunctionsItemForTesting('func_sleep',
        FunctionsResearchItemSchema(
          id: 'func_sleep',
          icon: '',
          name: 'sleep(duration)',
          languageSpecificDescription: {},
          predecessorIds: [],
          requirements: {},
          functionsUnlocked: ['sleep(duration)'],
        ));

      ResearchItemsSchema.instance.addFunctionsItemForTesting('func_getters',
        FunctionsResearchItemSchema(
          id: 'func_getters',
          icon: '',
          name: 'Getter Functions',
          languageSpecificDescription: {},
          predecessorIds: [],
          requirements: {},
          functionsUnlocked: ['getPositionX()', 'getPositionY()', 'getPlotGridX()', 'getPlotGridY()'],
        ));

      ResearchItemsSchema.instance.addFunctionsItemForTesting('func_state_checkers',
        FunctionsResearchItemSchema(
          id: 'func_state_checkers',
          icon: '',
          name: 'State Checkers',
          languageSpecificDescription: {},
          predecessorIds: [],
          requirements: {},
          functionsUnlocked: ['getPlotState()', 'getCropType()', 'isCropGrown()'],
        ));

      ResearchItemsSchema.instance.addFunctionsItemForTesting('func_can_checkers',
        FunctionsResearchItemSchema(
          id: 'func_can_checkers',
          icon: '',
          name: 'Can Checkers',
          languageSpecificDescription: {},
          predecessorIds: [],
          requirements: {},
          functionsUnlocked: ['canTill()', 'canWater()', 'canPlant()', 'canHarvest()'],
        ));

      ResearchItemsSchema.instance.addFunctionsItemForTesting('func_inventory',
        FunctionsResearchItemSchema(
          id: 'func_inventory',
          icon: '',
          name: 'Inventory Functions',
          languageSpecificDescription: {},
          predecessorIds: [],
          requirements: {},
          functionsUnlocked: ['hasSeed(seedType)', 'getSeedInventoryCount(seedType)', 'getCropInventoryCount(cropType)'],
        ));

      // Create minimal farm schema for testing
      FarmDataSchema().setSchemaForTesting({
        'crop_info': {
          'wheat': {
            'growth_duration': 1,
            'harvest_quantity': {'min': 1, 'max': 1},
            'crop_stages': {'1': 'assets/images/crops/wheat_stage1.png'}
          }
        }
      });

      // Initialize farm state and research state
      farmState = FarmState();
      researchState = ResearchState();
    });

    group('Default Locked Functions', () {
      test('move() should be locked by default', () async {
        interpreter = PythonInterpreter(
          farmState: farmState,
          researchState: researchState,
        );

        const code = 'move(Direction.NORTH)';
        final result = await interpreter.execute(code);

        expect(result.success, isFalse);
        expect(result.executionLog.any((log) => 
          log.contains('not unlocked') && log.contains('move(direction)')), isTrue);
      });

      test('till() should be locked by default', () async {
        interpreter = PythonInterpreter(
          farmState: farmState,
          researchState: researchState,
        );

        const code = 'till()';
        final result = await interpreter.execute(code);

        expect(result.success, isFalse);
        expect(result.executionLog.any((log) => 
          log.contains('not unlocked') && log.contains('till()')), isTrue);
      });

      test('water() should be locked by default', () async {
        interpreter = PythonInterpreter(
          farmState: farmState,
          researchState: researchState,
        );

        const code = 'water()';
        final result = await interpreter.execute(code);

        expect(result.success, isFalse);
        expect(result.executionLog.any((log) => 
          log.contains('not unlocked') && log.contains('water()')), isTrue);
      });

      test('plant() should be locked by default', () async {
        interpreter = PythonInterpreter(
          farmState: farmState,
          researchState: researchState,
        );

        const code = 'plant(SeedType.WHEAT)';
        final result = await interpreter.execute(code);

        expect(result.success, isFalse);
        expect(result.executionLog.any((log) => 
          log.contains('not unlocked') && log.contains('plant(seedType)')), isTrue);
      });

      test('harvest() should be locked by default', () async {
        interpreter = PythonInterpreter(
          farmState: farmState,
          researchState: researchState,
        );

        const code = 'harvest()';
        final result = await interpreter.execute(code);

        expect(result.success, isFalse);
        expect(result.executionLog.any((log) => 
          log.contains('not unlocked') && log.contains('harvest()')), isTrue);
      });

      test('sleep() should be locked by default', () async {
        interpreter = PythonInterpreter(
          farmState: farmState,
          researchState: researchState,
        );

        const code = 'sleep(1)';
        final result = await interpreter.execute(code);

        expect(result.success, isFalse);
        expect(result.executionLog.any((log) => 
          log.contains('not unlocked') && log.contains('sleep(duration)')), isTrue);
      });

      test('getPositionX() should be locked by default', () async {
        interpreter = PythonInterpreter(
          farmState: farmState,
          researchState: researchState,
        );

        const code = 'x = get_position_x()';
        final result = await interpreter.execute(code);

        expect(result.success, isTrue); // Code executes but function returns error value
        expect(result.executionLog.any((log) => 
          log.contains('not unlocked') && log.contains('getPositionX()')), isTrue);
      });

      test('getPlotState() should be locked by default', () async {
        interpreter = PythonInterpreter(
          farmState: farmState,
          researchState: researchState,
        );

        const code = 'state = get_plot_state()';
        final result = await interpreter.execute(code);

        expect(result.success, isTrue);
        expect(result.executionLog.any((log) => 
          log.contains('not unlocked') && log.contains('getPlotState()')), isTrue);
      });

      test('canTill() should be locked by default', () async {
        interpreter = PythonInterpreter(
          farmState: farmState,
          researchState: researchState,
        );

        const code = 'can = can_till()';
        final result = await interpreter.execute(code);

        expect(result.success, isTrue);
        expect(result.executionLog.any((log) => 
          log.contains('not unlocked') && log.contains('canTill()')), isTrue);
      });

      test('hasSeed() should be locked by default', () async {
        interpreter = PythonInterpreter(
          farmState: farmState,
          researchState: researchState,
        );

        const code = 'has = has_seed(SeedType.WHEAT)';
        final result = await interpreter.execute(code);

        expect(result.success, isTrue);
        expect(result.executionLog.any((log) => 
          log.contains('not unlocked') && log.contains('hasSeed(seedType)')), isTrue);
      });
    });

    group('Unlocked Functions After Research', () {
      test('move() should be unlocked after researching func_move', () async {
        // Mock research completion
        researchState.completeResearch('func_move');
        
        interpreter = PythonInterpreter(
          farmState: farmState,
          researchState: researchState,
        );

        const code = 'move(Direction.NORTH)';
        final result = await interpreter.execute(code);

        expect(result.success, isTrue);
        expect(result.executionLog.any((log) => log.contains('not unlocked')), isFalse);
        expect(result.executionLog.any((log) => log.contains('Moving drone')), isTrue);
      });

      test('till() should be unlocked after researching func_till', () async {
        researchState.completeResearch('func_till');
        
        interpreter = PythonInterpreter(
          farmState: farmState,
          researchState: researchState,
        );

        const code = 'till()';
        final result = await interpreter.execute(code);

        expect(result.success, isTrue);
        expect(result.executionLog.any((log) => log.contains('not unlocked')), isFalse);
        expect(result.executionLog.any((log) => log.contains('Tilling soil')), isTrue);
      });

      test('water() should be unlocked after researching func_water', () async {
        researchState.completeResearch('func_till'); // Need till first
        researchState.completeResearch('func_water');
        
        interpreter = PythonInterpreter(
          farmState: farmState,
          researchState: researchState,
        );

        const code = '''
till()
water()
''';
        final result = await interpreter.execute(code);

        expect(result.success, isTrue);
        expect(result.executionLog.any((log) => 
          log.contains('not unlocked') && log.contains('water()')), isFalse);
        expect(result.executionLog.any((log) => log.contains('Watering soil')), isTrue);
      });

      test('plant() should be unlocked after researching func_plant', () async {
        researchState.completeResearch('func_till');
        researchState.completeResearch('func_water');
        researchState.completeResearch('func_plant');
        
        interpreter = PythonInterpreter(
          farmState: farmState,
          researchState: researchState,
        );

        const code = '''
till()
water()
plant(SeedType.WHEAT)
''';
        final result = await interpreter.execute(code);

        expect(result.success, isTrue);
        expect(result.executionLog.any((log) => 
          log.contains('not unlocked') && log.contains('plant(seedType)')), isFalse);
        expect(result.executionLog.any((log) => log.contains('Planting')), isTrue);
      });

      test('harvest() should be unlocked after researching func_harvest', () async {
        researchState.completeResearch('func_harvest');
        
        interpreter = PythonInterpreter(
          farmState: farmState,
          researchState: researchState,
        );

        const code = 'harvest()';
        final result = await interpreter.execute(code);

        // Will fail because no crop to harvest, but function is unlocked
        expect(result.executionLog.any((log) => 
          log.contains('not unlocked') && log.contains('harvest()')), isFalse);
        expect(result.executionLog.any((log) => log.contains('Harvesting crop')), isTrue);
      });

      test('getter functions should be unlocked after researching func_getters', () async {
        researchState.completeResearch('func_move');
        researchState.completeResearch('func_getters');
        
        interpreter = PythonInterpreter(
          farmState: farmState,
          researchState: researchState,
        );

        const code = '''
x = get_position_x()
y = get_position_y()
grid_x = get_plot_grid_x()
grid_y = get_plot_grid_y()
''';
        final result = await interpreter.execute(code);

        expect(result.success, isTrue);
        expect(result.executionLog.any((log) => 
          log.contains('not unlocked') && log.contains('getPositionX()')), isFalse);
        expect(result.executionLog.any((log) => 
          log.contains('not unlocked') && log.contains('getPositionY()')), isFalse);
      });

      test('state checker functions should be unlocked after researching func_state_checkers', () async {
        researchState.completeResearch('func_move');
        researchState.completeResearch('func_getters');
        researchState.completeResearch('func_state_checkers');
        
        interpreter = PythonInterpreter(
          farmState: farmState,
          researchState: researchState,
        );

        const code = '''
state = get_plot_state()
crop = get_crop_type()
grown = is_crop_grown()
''';
        final result = await interpreter.execute(code);

        expect(result.success, isTrue);
        expect(result.executionLog.any((log) => 
          log.contains('not unlocked') && log.contains('getPlotState()')), isFalse);
        expect(result.executionLog.any((log) => 
          log.contains('not unlocked') && log.contains('getCropType()')), isFalse);
      });

      test('can checker functions should be unlocked after researching func_can_checkers', () async {
        researchState.completeResearch('func_move');
        researchState.completeResearch('func_getters');
        researchState.completeResearch('func_state_checkers');
        researchState.completeResearch('func_can_checkers');
        
        interpreter = PythonInterpreter(
          farmState: farmState,
          researchState: researchState,
        );

        const code = '''
can_t = can_till()
can_w = can_water()
can_p = can_plant()
can_h = can_harvest()
''';
        final result = await interpreter.execute(code);

        expect(result.success, isTrue);
        expect(result.executionLog.any((log) => 
          log.contains('not unlocked') && log.contains('canTill()')), isFalse);
        expect(result.executionLog.any((log) => 
          log.contains('not unlocked') && log.contains('canWater()')), isFalse);
      });

      test('inventory functions should be unlocked after researching func_inventory', () async {
        researchState.completeResearch('func_move');
        researchState.completeResearch('func_plant');
        researchState.completeResearch('func_inventory');
        
        interpreter = PythonInterpreter(
          farmState: farmState,
          researchState: researchState,
        );

        const code = '''
has = has_seed(SeedType.WHEAT)
seed_count = get_seed_inventory_count(SeedType.WHEAT)
crop_count = get_crop_inventory_count(CropType.WHEAT)
''';
        final result = await interpreter.execute(code);

        expect(result.success, isTrue);
        expect(result.executionLog.any((log) => 
          log.contains('not unlocked') && log.contains('hasSeed(seedType)')), isFalse);
        expect(result.executionLog.any((log) => 
          log.contains('not unlocked') && log.contains('getSeedInventoryCount(seedType)')), isFalse);
      });
    });

    group('Mixed Scenarios', () {
      test('should allow unlocked functions and block locked functions in same code', () async {
        researchState.completeResearch('func_move');
        // func_till NOT completed
        
        interpreter = PythonInterpreter(
          farmState: farmState,
          researchState: researchState,
        );

        const code = '''
move(Direction.NORTH)
till()
''';
        final result = await interpreter.execute(code);

        expect(result.success, isFalse);
        expect(result.executionLog.any((log) => log.contains('Moving drone')), isTrue);
        expect(result.executionLog.any((log) => 
          log.contains('not unlocked') && log.contains('till()')), isTrue);
      });

      test('should work with all functions unlocked', () async {
        // Unlock all function research items
        researchState.completeResearch('func_move');
        researchState.completeResearch('func_till');
        researchState.completeResearch('func_water');
        researchState.completeResearch('func_plant');
        researchState.completeResearch('func_harvest');
        researchState.completeResearch('func_sleep');
        researchState.completeResearch('func_getters');
        researchState.completeResearch('func_state_checkers');
        researchState.completeResearch('func_can_checkers');
        researchState.completeResearch('func_inventory');
        
        interpreter = PythonInterpreter(
          farmState: farmState,
          researchState: researchState,
        );

        const code = '''
move(Direction.NORTH)
if can_till():
    till()
if can_water():
    water()
if can_plant():
    plant(SeedType.WHEAT)
x = get_position_x()
y = get_position_y()
has = has_seed(SeedType.WHEAT)
''';
        final result = await interpreter.execute(code);

        expect(result.success, isTrue);
        expect(result.executionLog.any((log) => log.contains('not unlocked')), isFalse);
      });

      test('should handle null researchState (all functions allowed)', () async {
        interpreter = PythonInterpreter(
          farmState: farmState,
          researchState: null, // No research state
        );

        const code = '''
move(Direction.NORTH)
till()
water()
plant(SeedType.WHEAT)
''';
        final result = await interpreter.execute(code);

        expect(result.success, isTrue);
        expect(result.executionLog.any((log) => log.contains('not unlocked')), isFalse);
      });
    });

    group('Error Messages', () {
      test('should show informative error message with function name', () async {
        interpreter = PythonInterpreter(
          farmState: farmState,
          researchState: researchState,
        );

        const code = 'move(Direction.NORTH)';
        final result = await interpreter.execute(code);

        expect(result.success, isFalse);
        final errorLog = result.executionLog.firstWhere(
          (log) => log.contains('not unlocked'),
        );
        expect(errorLog, contains('move(direction)'));
        expect(errorLog, contains('Research the required functions'));
      });

      test('should show parameter type in error message', () async {
        interpreter = PythonInterpreter(
          farmState: farmState,
          researchState: researchState,
        );

        const code = 'plant(SeedType.WHEAT)';
        final result = await interpreter.execute(code);

        expect(result.success, isFalse);
        final errorLog = result.executionLog.firstWhere(
          (log) => log.contains('not unlocked'),
        );
        expect(errorLog, contains('plant(seedType)'));
      });
    });
  });
}
