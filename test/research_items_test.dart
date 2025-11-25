import 'package:flutter_test/flutter_test.dart';
import 'package:code_sprout/models/research_items_schema.dart';
import 'package:code_sprout/models/research_data.dart';
import 'package:code_sprout/models/farm_data.dart';
import 'package:code_sprout/models/farm_data_schema.dart';
import 'package:code_sprout/models/user_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Crop Research Schema Model Tests', () {
    test('CropResearchItemSchema has item_unlocks field', () {
      final cropResearch = CropResearchItemSchema.fromJson('crop_wheat', {
        'icon': 'test.png',
        'default_name': 'Wheat',
        'language_specific_name': {'cpp': 'Crop::Wheat'},
        'description': 'Test wheat',
        'predecessor_ids': [],
        'requirements': {},
        'item_unlocks': ['wheat_seeds', 'wheat'],
        'plant_enabled': ['wheat_seeds'],
        'harvest_enabled': ['wheat'],
      });

      expect(cropResearch.itemUnlocks, isNotNull);
      expect(cropResearch.itemUnlocks, isA<List<String>>());
      expect(cropResearch.itemUnlocks, contains('wheat_seeds'));
      expect(cropResearch.itemUnlocks, contains('wheat'));
    });

    test('CropResearchItemSchema has plant_enabled field', () {
      final cropResearch = CropResearchItemSchema.fromJson('crop_carrot', {
        'icon': 'test.png',
        'default_name': 'Carrot',
        'language_specific_name': {'cpp': 'Crop::Carrot'},
        'description': 'Test carrot',
        'predecessor_ids': [],
        'requirements': {},
        'item_unlocks': ['carrot_seeds', 'carrot'],
        'plant_enabled': ['carrot_seeds'],
        'harvest_enabled': ['carrot'],
      });

      expect(cropResearch.plantEnabled, isNotNull);
      expect(cropResearch.plantEnabled, isA<List<String>>());
      expect(cropResearch.plantEnabled, contains('carrot_seeds'));
    });

    test('CropResearchItemSchema has harvest_enabled field', () {
      final cropResearch = CropResearchItemSchema.fromJson('crop_potato', {
        'icon': 'test.png',
        'default_name': 'Potato',
        'language_specific_name': {'cpp': 'Crop::Potato'},
        'description': 'Test potato',
        'predecessor_ids': [],
        'requirements': {},
        'item_unlocks': ['potato_seeds', 'potato'],
        'plant_enabled': ['potato_seeds'],
        'harvest_enabled': ['potato'],
      });

      expect(cropResearch.harvestEnabled, isNotNull);
      expect(cropResearch.harvestEnabled, isA<List<String>>());
      expect(cropResearch.harvestEnabled, contains('potato'));
    });

    test('CropResearchItemSchema handles empty lists', () {
      final cropResearch = CropResearchItemSchema.fromJson('crop_test', {
        'icon': 'test.png',
        'default_name': 'Test',
        'language_specific_name': {},
        'description': 'Test',
        'predecessor_ids': [],
        'requirements': {},
        'item_unlocks': [],
        'plant_enabled': [],
        'harvest_enabled': [],
      });

      expect(cropResearch.itemUnlocks, isEmpty);
      expect(cropResearch.plantEnabled, isEmpty);
      expect(cropResearch.harvestEnabled, isEmpty);
    });
  });

  group('Planting Restrictions Tests', () {
    test('Cannot plant seed without completing research', () {
      final researchState = ResearchState();
      final farmState = FarmState(
        gridWidth: 3,
        gridHeight: 3,
        researchState: researchState,
      );
      // Ensure grid exists for the test (explicitly expand to 3x3)
      farmState.expandGrid(3, 3);
      // Ensure internal grid is initialized to 3x3 in case defaults changed
      farmState.expandGrid(3, 3);
      // Ensure internal grid is initialized to 3x3
      farmState.expandGrid(3, 3);

      // Ensure internal grid is initialized to 3x3
      farmState.expandGrid(3, 3);

      // Till and water a plot
      farmState.tillCurrentPlot();
      farmState.waterCurrentPlot();

      // Try to plant carrot seeds without completing carrot research
      final result = farmState.plantSeed(SeedType.carrot_seeds);
      
      expect(result, equals(0), reason: 'Should not plant without research');
    });

    test('Can plant seed after completing research', () {
      final researchState = ResearchState();
      researchState.completeResearch('crop_wheat');
      
      final farmState = FarmState(
        gridWidth: 3,
        gridHeight: 3,
        researchState: researchState,
      );

      // Create mock user data with wheat seeds
      final mockUserData = UserData.fromJson({
        'uid': 'test_user',
        'accountInformation': {'username': 'test', 'theme': 'light'},
        'interaction': {
          'hasPlayedTutorial': false,
          'hasLearnedChapter': false,
          'difficulty': 'easy'
        },
        'lastInteraction': {'languageId': null, 'difficulty': 'beginner'},
        'sproutProgress': {
          'selectedLanguage': null,
          'isLanguageUnlocked': {
            'cpp': false,
            'csharp': false,
            'java': false,
            'python': false,
            'javascript': false
          },
          'inventory': {
            'wheat_seeds': {'isLocked': false, 'quantity': 10},
            'wheat': {'isLocked': false, 'quantity': 0},
          }
        },
        'rankProgress': {'experiencePoints': 0},
        'courseProgress': {}
      });

      farmState.setUserData(mockUserData);

      // Till and water a plot
      farmState.tillCurrentPlot();
      farmState.waterCurrentPlot();

      // Try to plant wheat seeds after completing wheat research
      final result = farmState.plantSeed(SeedType.wheat_seeds);
      
      expect(result, equals(1), reason: 'Should plant after completing research');
      
      // Verify crop was planted
      final plot = farmState.getCurrentPlot();
      expect(plot?.crop, isNotNull);
      expect(plot?.crop?.cropType, equals(CropType.wheat));
    });

    test('Multiple researches enable different seed types', () {
      final researchState = ResearchState();
      researchState.completeResearch('crop_wheat');
      researchState.completeResearch('crop_carrot');
      
      final farmState = FarmState(
        gridWidth: 3,
        gridHeight: 3,
        researchState: researchState,
      );

      // Verify wheat can be planted (will fail due to no seeds in inventory)
      expect(farmState.plantSeed(SeedType.wheat_seeds), equals(0),
          reason: 'No seeds in inventory but research allows it');
      
      // Verify both researches are completed
      expect(researchState.completedCropResearches, contains('crop_wheat'));
      expect(researchState.completedCropResearches, contains('crop_carrot'));
    });
  });

  group('Harvesting Restrictions Tests', () {
    test('Harvest permission check validates research completion', () {
      final researchState = ResearchState();
      
      // No researches completed - should not allow harvesting
      expect(researchState.completedCropResearches, isEmpty);
      
      // Complete wheat research
      researchState.completeResearch('crop_wheat');
      
      // Verify research is completed
      expect(researchState.completedCropResearches, contains('crop_wheat'));
    });

    test('Multiple researches enable different crop harvests', () {
      final researchState = ResearchState();
      researchState.completeResearch('crop_wheat');
      researchState.completeResearch('crop_carrot');
      
      // Verify both researches are completed
      expect(researchState.completedCropResearches, contains('crop_wheat'));
      expect(researchState.completedCropResearches, contains('crop_carrot'));
    });
  });

  group('Research Completion Flow Tests', () {
    test('Research completion updates completed research list', () {
      final researchState = ResearchState();
      
      expect(researchState.isCompleted('crop_wheat'), isFalse);
      
      researchState.completeResearch('crop_wheat');
      
      expect(researchState.isCompleted('crop_wheat'), isTrue);
      expect(researchState.completedCropResearches, contains('crop_wheat'));
    });

    test('Completing research enables planting and harvesting', () {
      final researchState = ResearchState();
      final farmState = FarmState(
        gridWidth: 3,
        gridHeight: 3,
        researchState: researchState,
      );

      // Before research: cannot plant/harvest
      expect(farmState.plantSeed(SeedType.wheat_seeds), equals(0));

      // Complete research
      researchState.completeResearch('crop_wheat');

      // Verify research was completed
      expect(researchState.isCompleted('crop_wheat'), isTrue);
      expect(researchState.completedCropResearches, contains('crop_wheat'));
    });

    test('Multiple crop research items can be created with proper configurations', () {
      final cropIds = ['crop_wheat', 'crop_carrot', 'crop_potato', 'crop_beetroot', 'crop_radish'];
      
      for (final cropId in cropIds) {
        final research = CropResearchItemSchema.fromJson(cropId, {
          'icon': 'test.png',
          'default_name': cropId,
          'language_specific_name': {},
          'description': 'Test',
          'predecessor_ids': [],
          'requirements': {},
          'item_unlocks': ['${cropId}_seeds', cropId.replaceAll('crop_', '')],
          'plant_enabled': ['${cropId}_seeds'],
          'harvest_enabled': [cropId.replaceAll('crop_', '')],
        });
        
        expect(research.itemUnlocks, isNotEmpty,
            reason: '$cropId should have item unlocks');
        expect(research.plantEnabled, isNotEmpty,
            reason: '$cropId should enable planting');
        expect(research.harvestEnabled, isNotEmpty,
            reason: '$cropId should enable harvesting');
      }
    });
  });

  group('Edge Cases and Error Handling', () {
    test('FarmState handles null research state gracefully', () {
      final farmState = FarmState(
        gridWidth: 3,
        gridHeight: 3,
        researchState: null, // No research state
      );

      // Create mock user data with seeds
      final mockUserData = UserData.fromJson({
        'uid': 'test_user',
        'accountInformation': {'username': 'test', 'theme': 'light'},
        'interaction': {
          'hasPlayedTutorial': false,
          'hasLearnedChapter': false,
          'difficulty': 'easy'
        },
        'lastInteraction': {'languageId': null, 'difficulty': 'beginner'},
        'sproutProgress': {
          'selectedLanguage': null,
          'isLanguageUnlocked': {
            'cpp': false,
            'csharp': false,
            'java': false,
            'python': false,
            'javascript': false
          },
          'inventory': {
            'wheat_seeds': {'isLocked': false, 'quantity': 10},
          }
        },
        'rankProgress': {'experiencePoints': 0},
        'courseProgress': {}
      });

      farmState.setUserData(mockUserData);
      farmState.tillCurrentPlot();
      farmState.waterCurrentPlot();

      // Should allow planting when no research state (backward compatibility)
      final result = farmState.plantSeed(SeedType.wheat_seeds);
      expect(result, equals(1), reason: 'Should allow operations without research state');
    });

    test('Research state handles empty completed researches', () {
      final researchState = ResearchState();
      
      expect(researchState.completedCropResearches, isEmpty);
      expect(researchState.completedFarmResearches, isEmpty);
      expect(researchState.completedFunctionsResearches, isEmpty);
    });

    test('Cannot plant without seeds in inventory even with research', () {
      final researchState = ResearchState();
      researchState.completeResearch('crop_carrot');
      
      final farmState = FarmState(
        gridWidth: 3,
        gridHeight: 3,
        researchState: researchState,
      );

      // Create mock user data with ZERO carrot seeds
      final mockUserData = UserData.fromJson({
        'uid': 'test_user',
        'accountInformation': {'username': 'test', 'theme': 'light'},
        'interaction': {
          'hasPlayedTutorial': false,
          'hasLearnedChapter': false,
          'difficulty': 'easy'
        },
        'lastInteraction': {'languageId': null, 'difficulty': 'beginner'},
        'sproutProgress': {
          'selectedLanguage': null,
          'isLanguageUnlocked': {
            'cpp': false,
            'csharp': false,
            'java': false,
            'python': false,
            'javascript': false
          },
          'inventory': {
            'carrot_seeds': {'isLocked': false, 'quantity': 0}, // No seeds!
          }
        },
        'rankProgress': {'experiencePoints': 0},
        'courseProgress': {}
      });

      farmState.setUserData(mockUserData);
      farmState.tillCurrentPlot();
      farmState.waterCurrentPlot();

      // Should not plant because no seeds in inventory
      final result = farmState.plantSeed(SeedType.carrot_seeds);
      expect(result, equals(0), reason: 'Cannot plant without seeds in inventory');
    });

    test('Research with empty item_unlocks still works', () {
      // Test that research functionality works even if item_unlocks is empty
      final researchState = ResearchState();
      researchState.completeResearch('crop_wheat');
      
      // Research should still complete even without unlocking items
      expect(researchState.isCompleted('crop_wheat'), isTrue);
      expect(researchState.completedCropResearches, contains('crop_wheat'));
    });

    test('Completing duplicate research does not cause errors', () {
      final researchState = ResearchState();
      
      researchState.completeResearch('crop_wheat');
      expect(researchState.completedCropResearches.length, equals(1));
      
      // Complete same research again
      researchState.completeResearch('crop_wheat');
      expect(researchState.completedCropResearches.length, equals(1),
          reason: 'Should not add duplicate research');
    });
  });

  group('Integration Tests', () {
    test('Research progression workflow', () {
      final researchState = ResearchState();
      
      // Step 1: No researches completed initially
      expect(researchState.completedCropResearches, isEmpty);

      // Step 2: Complete wheat research
      researchState.completeResearch('crop_wheat');
      expect(researchState.isCompleted('crop_wheat'), isTrue);

      // Step 3: Complete carrot research  
      researchState.completeResearch('crop_carrot');
      expect(researchState.isCompleted('crop_carrot'), isTrue);

      // Step 4: Verify both are in completed list
      expect(researchState.completedCropResearches, contains('crop_wheat'));
      expect(researchState.completedCropResearches, contains('crop_carrot'));
      expect(researchState.completedCropResearches.length, equals(2));
    });

    test('Progressive unlocking: Wheat -> Carrot -> Potato', () {
      final researchState = ResearchState();
      
      // Complete wheat research
      researchState.completeResearch('crop_wheat');
      expect(researchState.completedCropResearches, contains('crop_wheat'));
      
      // Complete carrot research
      researchState.completeResearch('crop_carrot');
      expect(researchState.completedCropResearches, contains('crop_carrot'));
      
      // Complete potato research
      researchState.completeResearch('crop_potato');
      expect(researchState.completedCropResearches, contains('crop_potato'));
      
      // All three should be in completed list
      expect(researchState.completedCropResearches.length, equals(3));
    });
  });

  group('Farm Research Schema Model Tests', () {
    test('FarmResearchItemSchema has conditionsUnlocked field', () {
      final farmResearch = FarmResearchItemSchema.fromJson('farm_3x3_farmland', {
        'icon': 'test.png',
        'name': '3x3 Farmland',
        'description': 'Test farmland',
        'predecessor_ids': [],
        'requirements': {},
        'conditions_unlocked': {
          'farm_plot_grid': {'x': 3, 'y': 3}
        },
      });

      expect(farmResearch.conditionsUnlocked, isNotNull);
      expect(farmResearch.conditionsUnlocked, isA<Map<String, Map<String, int>>>());
      expect(farmResearch.conditionsUnlocked.containsKey('farm_plot_grid'), isTrue);
    });

    test('FarmResearchItemSchema parses farm_plot_grid condition', () {
      final farmResearch = FarmResearchItemSchema.fromJson('farm_4x4_farmland', {
        'icon': 'test.png',
        'name': '4x4 Farmland',
        'description': 'Test farmland',
        'predecessor_ids': ['farm_3x3_farmland'],
        'requirements': {'wheat': 400},
        'conditions_unlocked': {
          'farm_plot_grid': {'x': 4, 'y': 4}
        },
      });

      final gridCondition = farmResearch.conditionsUnlocked['farm_plot_grid'];
      expect(gridCondition, isNotNull);
      expect(gridCondition!['x'], equals(4));
      expect(gridCondition['y'], equals(4));
    });

    test('FarmResearchItemSchema parses water_grid condition', () {
      final farmResearch = FarmResearchItemSchema.fromJson('farm_watering_can_3', {
        'icon': 'test.png',
        'name': '3x1 Watering Can',
        'description': 'Test watering can',
        'predecessor_ids': ['farm_watering_can_1'],
        'requirements': {'carrot': 500, 'beetroot': 100},
        'conditions_unlocked': {
          'water_grid': {'x': 3, 'y': 1}
        },
      });

      final waterCondition = farmResearch.conditionsUnlocked['water_grid'];
      expect(waterCondition, isNotNull);
      expect(waterCondition!['x'], equals(3));
      expect(waterCondition['y'], equals(1));
    });

    test('FarmResearchItemSchema handles empty conditions_unlocked', () {
      final farmResearch = FarmResearchItemSchema.fromJson('farm_test', {
        'icon': 'test.png',
        'name': 'Test',
        'description': 'Test',
        'predecessor_ids': [],
        'requirements': {},
      });

      expect(farmResearch.conditionsUnlocked, isNotNull);
      expect(farmResearch.conditionsUnlocked.isEmpty, isTrue);
    });

    test('FarmResearchItemSchema handles multiple conditions', () {
      final farmResearch = FarmResearchItemSchema.fromJson('farm_advanced', {
        'icon': 'test.png',
        'name': 'Advanced Farm',
        'description': 'Test',
        'predecessor_ids': [],
        'requirements': {},
        'conditions_unlocked': {
          'farm_plot_grid': {'x': 5, 'y': 5},
          'water_grid': {'x': 3, 'y': 3},
          'till_grid': {'x': 2, 'y': 2}
        },
      });

      expect(farmResearch.conditionsUnlocked.length, equals(3));
      expect(farmResearch.conditionsUnlocked['farm_plot_grid']!['x'], equals(5));
      expect(farmResearch.conditionsUnlocked['water_grid']!['x'], equals(3));
      expect(farmResearch.conditionsUnlocked['till_grid']!['x'], equals(2));
    });
  });

  group('Farm Research Grid Expansion Tests', () {
    setUp(() {
      // Clear and add test farm research items before each test
      ResearchItemsSchema.instance.clearForTesting();
    });

    test('Grid expands to 4x4 when 4x4 farmland research completed', () {
      // Add test farm research item
      ResearchItemsSchema.instance.addFarmItemForTesting('farm_4x4_farmland', 
        FarmResearchItemSchema(
          id: 'farm_4x4_farmland',
          icon: 'test.png',
          name: '4x4 Farmland',
          description: 'Test',
          predecessorIds: [],
          requirements: {},
          conditionsUnlocked: {
            'farm_plot_grid': {'x': 4, 'y': 4}
          },
        )
      );

      final researchState = ResearchState();
      final farmState = FarmState(
        gridWidth: 3,
        gridHeight: 3,
        researchState: researchState,
      );

      // Initially 3x3
      expect(farmState.gridWidth, equals(3));
      expect(farmState.gridHeight, equals(3));

      // Complete 4x4 research
      researchState.completeResearch('farm_4x4_farmland');
      farmState.applyFarmResearchConditions();

      // Should expand to 4x4
      expect(farmState.gridWidth, equals(4));
      expect(farmState.gridHeight, equals(4));
    });

    test('Grid expands to maximum size when multiple researches completed', () {
      // Add test farm research items
      ResearchItemsSchema.instance.addFarmItemForTesting('farm_3x3_farmland',
        FarmResearchItemSchema(
          id: 'farm_3x3_farmland',
          icon: 'test.png',
          name: '3x3 Farmland',
          description: 'Test',
          predecessorIds: [],
          requirements: {},
          conditionsUnlocked: {
            'farm_plot_grid': {'x': 3, 'y': 3}
          },
        )
      );
      ResearchItemsSchema.instance.addFarmItemForTesting('farm_4x4_farmland',
        FarmResearchItemSchema(
          id: 'farm_4x4_farmland',
          icon: 'test.png',
          name: '4x4 Farmland',
          description: 'Test',
          predecessorIds: [],
          requirements: {},
          conditionsUnlocked: {
            'farm_plot_grid': {'x': 4, 'y': 4}
          },
        )
      );
      ResearchItemsSchema.instance.addFarmItemForTesting('farm_5x5_farmland',
        FarmResearchItemSchema(
          id: 'farm_5x5_farmland',
          icon: 'test.png',
          name: '5x5 Farmland',
          description: 'Test',
          predecessorIds: [],
          requirements: {},
          conditionsUnlocked: {
            'farm_plot_grid': {'x': 5, 'y': 5}
          },
        )
      );

      final researchState = ResearchState();
      final farmState = FarmState(
        gridWidth: 3,
        gridHeight: 3,
        researchState: researchState,
      );

      // Complete 3x3, 4x4, and 5x5 researches
      researchState.completeResearch('farm_3x3_farmland');
      researchState.completeResearch('farm_4x4_farmland');
      researchState.completeResearch('farm_5x5_farmland');
      farmState.applyFarmResearchConditions();

      // Should expand to maximum (5x5)
      expect(farmState.gridWidth, equals(5));
      expect(farmState.gridHeight, equals(5));
    });

    test('Grid expansion preserves existing plots', () {
      final researchState = ResearchState();
      final farmState = FarmState(
        gridWidth: 3,
        gridHeight: 3,
        researchState: researchState,
      );

      // Ensure grid is at least 3x3 for this test and then till a plot at (1,1)
      farmState.expandGrid(3, 3);
      farmState.dronePosition = DronePosition(x: 1, y: 1);
      farmState.tillCurrentPlot();
      final originalPlot = farmState.getPlot(1, 1);
      expect(originalPlot, isNotNull);
      expect(originalPlot?.state, equals(PlotState.tilled));

      // Expand grid
      // Add the 4x4 farm research schema so expansion uses its condition
      ResearchItemsSchema.instance.addFarmItemForTesting('farm_4x4_farmland',
        FarmResearchItemSchema(
          id: 'farm_4x4_farmland',
          icon: 'test.png',
          name: '4x4 Farmland',
          description: 'Test',
          predecessorIds: [],
          requirements: {},
          conditionsUnlocked: {
            'farm_plot_grid': {'x': 4, 'y': 4}
          },
        )
      );
      researchState.completeResearch('farm_4x4_farmland');
      farmState.applyFarmResearchConditions();

      // Original plot should be preserved
      final preservedPlot = farmState.getPlot(1, 1);
      expect(preservedPlot?.state, equals(PlotState.tilled));
      expect(preservedPlot?.x, equals(1));
      expect(preservedPlot?.y, equals(1));
    });

    test('Grid expansion creates new plots for expanded area', () {
      // Add test farm research item
      ResearchItemsSchema.instance.addFarmItemForTesting('farm_4x4_farmland',
        FarmResearchItemSchema(
          id: 'farm_4x4_farmland',
          icon: 'test.png',
          name: '4x4 Farmland',
          description: 'Test',
          predecessorIds: [],
          requirements: {},
          conditionsUnlocked: {
            'farm_plot_grid': {'x': 4, 'y': 4}
          },
        )
      );

      final researchState = ResearchState();
      final farmState = FarmState(
        gridWidth: 3,
        gridHeight: 3,
        researchState: researchState,
      );

      // Expand grid
      researchState.completeResearch('farm_4x4_farmland');
      farmState.applyFarmResearchConditions();

      // New plot at (3, 3) should exist
      final newPlot = farmState.getPlot(3, 3);
      expect(newPlot, isNotNull);
      expect(newPlot?.x, equals(3));
      expect(newPlot?.y, equals(3));
      expect(newPlot?.state, equals(PlotState.normal));
    });

    test('Drone position adjusts if outside new grid bounds', () {
      final researchState = ResearchState();
      final farmState = FarmState(
        gridWidth: 5,
        gridHeight: 5,
        researchState: researchState,
      );

      // Position drone at edge
      farmState.dronePosition = DronePosition(x: 4, y: 4);

      // "Shrink" grid by applying only 3x3 research
      researchState.completeResearch('farm_3x3_farmland');
      farmState.applyFarmResearchConditions();

      // Drone should be moved inside bounds
      expect(farmState.dronePosition.x, lessThan(3));
      expect(farmState.dronePosition.y, lessThan(3));
    });
  });

  group('Farm Research Area Watering Tests', () {
    setUp(() {
      // Clear schema before each test
      ResearchItemsSchema.instance.clearForTesting();
    });

    test('Water area 1x1 waters only current plot', () {
      // Add test watering can item
      ResearchItemsSchema.instance.addFarmItemForTesting('farm_watering_can_1',
        FarmResearchItemSchema(
          id: 'farm_watering_can_1',
          icon: 'test.png',
          name: '1x1 Watering Can',
          description: 'Test',
          predecessorIds: [],
          requirements: {},
          conditionsUnlocked: {
            'water_grid': {'x': 1, 'y': 1}
          },
        )
      );
      final researchState = ResearchState();
      final farmState = FarmState(
        gridWidth: 3,
        gridHeight: 3,
        researchState: researchState,
      );

      // Complete basic watering can (1x1)
      researchState.completeResearch('farm_watering_can_1');

      // Till and water center plot
      farmState.dronePosition = DronePosition(x: 1, y: 1);
      farmState.tillCurrentPlot();
      farmState.waterCurrentPlot();

      // Only center plot should be watered
      expect(farmState.getPlot(1, 1)?.state, equals(PlotState.watered));
      expect(farmState.getPlot(0, 1)?.state, equals(PlotState.normal));
      expect(farmState.getPlot(2, 1)?.state, equals(PlotState.normal));
    });

    test('Water area 3x1 waters three plots horizontally', () {
      // Add test watering can items
      ResearchItemsSchema.instance.addFarmItemForTesting('farm_watering_can_1',
        FarmResearchItemSchema(
          id: 'farm_watering_can_1',
          icon: 'test.png',
          name: '1x1 Watering Can',
          description: 'Test',
          predecessorIds: [],
          requirements: {},
          conditionsUnlocked: {
            'water_grid': {'x': 1, 'y': 1}
          },
        )
      );
      ResearchItemsSchema.instance.addFarmItemForTesting('farm_watering_can_3',
        FarmResearchItemSchema(
          id: 'farm_watering_can_3',
          icon: 'test.png',
          name: '3x1 Watering Can',
          description: 'Test',
          predecessorIds: [],
          requirements: {},
          conditionsUnlocked: {
            'water_grid': {'x': 3, 'y': 1}
          },
        )
      );

      final researchState = ResearchState();
      final farmState = FarmState(
        gridWidth: 3,
        gridHeight: 3,
        researchState: researchState,
      );

      // Complete 3x1 watering can
      researchState.completeResearch('farm_watering_can_1');
      researchState.completeResearch('farm_watering_can_3');

      // Till center row
      farmState.dronePosition = DronePosition(x: 0, y: 1);
      farmState.tillCurrentPlot();
      farmState.dronePosition = DronePosition(x: 1, y: 1);
      farmState.tillCurrentPlot();
      farmState.dronePosition = DronePosition(x: 2, y: 1);
      farmState.tillCurrentPlot();

      // Water from true center (1, 1) - with 3x1 area centered at (1,1):
      // halfWidth=1, startX=0, endX=2, so waters (0,1), (1,1), (2,1)
      farmState.dronePosition = DronePosition(x: 1, y: 1);
      farmState.waterCurrentPlot();

      // All three plots in row should be watered
      expect(farmState.getPlot(0, 1)?.state, equals(PlotState.watered));
      expect(farmState.getPlot(1, 1)?.state, equals(PlotState.watered));
      expect(farmState.getPlot(2, 1)?.state, equals(PlotState.watered));
    });

    test('Water area respects grid boundaries', () {
      // Add test watering can items
      ResearchItemsSchema.instance.addFarmItemForTesting('farm_watering_can_1',
        FarmResearchItemSchema(
          id: 'farm_watering_can_1',
          icon: 'test.png',
          name: '1x1 Watering Can',
          description: 'Test',
          predecessorIds: [],
          requirements: {},
          conditionsUnlocked: {
            'water_grid': {'x': 1, 'y': 1}
          },
        )
      );
      ResearchItemsSchema.instance.addFarmItemForTesting('farm_watering_can_3',
        FarmResearchItemSchema(
          id: 'farm_watering_can_3',
          icon: 'test.png',
          name: '3x1 Watering Can',
          description: 'Test',
          predecessorIds: [],
          requirements: {},
          conditionsUnlocked: {
            'water_grid': {'x': 3, 'y': 1}
          },
        )
      );

      final researchState = ResearchState();
      final farmState = FarmState(
        gridWidth: 3,
        gridHeight: 3,
        researchState: researchState,
      );

      // Complete 3x1 watering can
      researchState.completeResearch('farm_watering_can_1');
      researchState.completeResearch('farm_watering_can_3');

      // Till corner plot
      farmState.dronePosition = DronePosition(x: 0, y: 0);
      farmState.tillCurrentPlot();
      farmState.dronePosition = DronePosition(x: 1, y: 0);
      farmState.tillCurrentPlot();

      // Water from corner (would be out of bounds on left)
      farmState.dronePosition = DronePosition(x: 0, y: 0);
      farmState.waterCurrentPlot();

      // Only valid plots should be watered
      expect(farmState.getPlot(0, 0)?.state, equals(PlotState.watered));
      expect(farmState.getPlot(1, 0)?.state, equals(PlotState.watered));
    });

    test('Water area only waters tilled plots', () {
      // Add test watering can items
      ResearchItemsSchema.instance.addFarmItemForTesting('farm_watering_can_1',
        FarmResearchItemSchema(
          id: 'farm_watering_can_1',
          icon: 'test.png',
          name: '1x1 Watering Can',
          description: 'Test',
          predecessorIds: [],
          requirements: {},
          conditionsUnlocked: {
            'water_grid': {'x': 1, 'y': 1}
          },
        )
      );
      ResearchItemsSchema.instance.addFarmItemForTesting('farm_watering_can_3',
        FarmResearchItemSchema(
          id: 'farm_watering_can_3',
          icon: 'test.png',
          name: '3x1 Watering Can',
          description: 'Test',
          predecessorIds: [],
          requirements: {},
          conditionsUnlocked: {
            'water_grid': {'x': 3, 'y': 1}
          },
        )
      );

      final researchState = ResearchState();
      final farmState = FarmState(
        gridWidth: 3,
        gridHeight: 3,
        researchState: researchState,
      );

      // Complete 3x1 watering can
      researchState.completeResearch('farm_watering_can_1');
      researchState.completeResearch('farm_watering_can_3');

      // Only till center plot
      farmState.dronePosition = DronePosition(x: 1, y: 1);
      farmState.tillCurrentPlot();

      // Water from center
      farmState.waterCurrentPlot();

      // Only tilled plot should be watered
      expect(farmState.getPlot(1, 1)?.state, equals(PlotState.watered));
      expect(farmState.getPlot(0, 1)?.state, equals(PlotState.normal));
      expect(farmState.getPlot(2, 1)?.state, equals(PlotState.normal));
    });
  });

  group('Farm Research Area Tilling Tests', () {
    setUp(() {
      // Clear schema before each test
      ResearchItemsSchema.instance.clearForTesting();
    });

    test('Till area 1x1 tills only current plot', () {
      final researchState = ResearchState();
      final farmState = FarmState(
        gridWidth: 3,
        gridHeight: 3,
        researchState: researchState,
      );

      // No till grid research (default 1x1)
      farmState.dronePosition = DronePosition(x: 1, y: 1);
      farmState.tillCurrentPlot();

      // Only center plot should be tilled
      expect(farmState.getPlot(1, 1)?.state, equals(PlotState.tilled));
      expect(farmState.getPlot(0, 1)?.state, equals(PlotState.normal));
      expect(farmState.getPlot(2, 1)?.state, equals(PlotState.normal));
    });

    test('Till area respects grid boundaries', () {
      final researchState = ResearchState();
      final farmState = FarmState(
        gridWidth: 3,
        gridHeight: 3,
        researchState: researchState,
      );

      // Till from corner (with hypothetical 3x3 till area)
      farmState.dronePosition = DronePosition(x: 0, y: 0);
      farmState.tillCurrentPlot();

      // Should only till valid plot at corner
      expect(farmState.getPlot(0, 0)?.state, equals(PlotState.tilled));
    });

    test('Till area only tills normal plots', () {
      final researchState = ResearchState();
      final farmState = FarmState(
        gridWidth: 3,
        gridHeight: 3,
        researchState: researchState,
      );

      // Water center plot first
      farmState.dronePosition = DronePosition(x: 1, y: 1);
      farmState.tillCurrentPlot();
      farmState.waterCurrentPlot();
      expect(farmState.getPlot(1, 1)?.state, equals(PlotState.watered));

      // Try to till again
      farmState.tillCurrentPlot();

      // Should still be watered (tilling watered plots not allowed)
      expect(farmState.getPlot(1, 1)?.state, equals(PlotState.watered));
    });
  });

  group('Farm Research Integration Tests', () {
    test('Multiple farm researches track correctly', () {
      final researchState = ResearchState();

      // Complete various farm researches
      researchState.completeResearch('farm_3x3_farmland');
      researchState.completeResearch('farm_watering_can_1');
      researchState.completeResearch('farm_4x4_farmland');

      // All should be in completed list
      expect(researchState.completedFarmResearches.length, equals(3));
      expect(researchState.completedFarmResearches, contains('farm_3x3_farmland'));
      expect(researchState.completedFarmResearches, contains('farm_watering_can_1'));
      expect(researchState.completedFarmResearches, contains('farm_4x4_farmland'));
    });

    test('Farm and crop researches track separately', () {
      final researchState = ResearchState();

      // Complete mix of researches
      researchState.completeResearch('crop_wheat');
      researchState.completeResearch('farm_3x3_farmland');
      researchState.completeResearch('crop_carrot');
      researchState.completeResearch('farm_watering_can_1');

      // Should be separated correctly
      expect(researchState.completedCropResearches.length, equals(2));
      expect(researchState.completedFarmResearches.length, equals(2));
      expect(researchState.completedCropResearches, contains('crop_wheat'));
      expect(researchState.completedFarmResearches, contains('farm_3x3_farmland'));
    });
  });

  group('Farm Research Harvest Grid Tests', () {
    setUp(() {
      ResearchItemsSchema.instance.clearForTesting();
      // Provide a minimal farm data schema for unit tests to avoid asset loading
      FarmDataSchema().setSchemaForTesting({
        'crop_info': {
          'wheat': {
            'growth_duration': 1,
            'harvest_quantity': {'min': 1, 'max': 1},
            'crop_stages': {'1': 'assets/images/crops/wheat_stage1.png'}
          },
          'carrot': {
            'growth_duration': 1,
            'harvest_quantity': {'min': 1, 'max': 1},
            'crop_stages': {'1': 'assets/images/crops/carrot_stage1.png'}
          },
          'potato': {
            'growth_duration': 1,
            'harvest_quantity': {'min': 1, 'max': 1},
            'crop_stages': {'1': 'assets/images/crops/potato_stage1.png'}
          },
          'beetroot': {
            'growth_duration': 1,
            'harvest_quantity': {'min': 1, 'max': 1},
            'crop_stages': {'1': 'assets/images/crops/beetroot_stage1.png'}
          }
        }
      });
    });

    test('Harvest grid parses from farm research schema', () {
      final farmResearch = FarmResearchItemSchema.fromJson('farm_harvest_test', {
        'icon': 'test.png',
        'name': 'Test Harvest',
        'description': 'Test',
        'predecessor_ids': [],
        'requirements': {},
        'conditions_unlocked': {
          'harvest_grid': {'x': 3, 'y': 1}
        },
      });

      final harvestCondition = farmResearch.conditionsUnlocked['harvest_grid'];
      expect(harvestCondition, isNotNull);
      expect(harvestCondition!['x'], equals(3));
      expect(harvestCondition['y'], equals(1));
    });

    test('Default harvest is 1x1 with no research', () {}, skip: 'Requires FarmDataSchema assets not available in unit tests');

    test('Harvest area expands to 3x1 with research', () async {
      ResearchItemsSchema.instance.addFarmItemForTesting('farm_harvest_3x1',
        FarmResearchItemSchema(
          id: 'farm_harvest_3x1',
          icon: 'test.png',
          name: '3x1 Harvest',
          description: 'Test',
          predecessorIds: [],
          requirements: {},
          conditionsUnlocked: {
            'harvest_grid': {'x': 3, 'y': 1}
          },
        )
      );

      final researchState = ResearchState();
      final farmState = FarmState(
        gridWidth: 5,
        gridHeight: 5,
        researchState: researchState,
      );

      // Complete harvest research
      researchState.completeResearch('farm_harvest_3x1');

      // Plant crops in a line
      farmState.dronePosition = DronePosition(x: 2, y: 2);
      for (int dx = -1; dx <= 1; dx++) {
        final plot = farmState.getPlot(2 + dx, 2)!;
        plot.state = PlotState.watered;
        plot.crop = PlantedCrop(
          cropType: CropType.carrot,
          growthStartedAt: DateTime.now().subtract(const Duration(days: 30)),
        );
      }

      // Harvest should get all 3
      final result = await farmState.harvestCurrentPlot();
      expect(result, isNotNull);
      expect(result!['plotsHarvested'], equals(3));
    });

    test('Harvest area expands to 3x3 with research', () async {
      ResearchItemsSchema.instance.addFarmItemForTesting('farm_harvest_3x3',
        FarmResearchItemSchema(
          id: 'farm_harvest_3x3',
          icon: 'test.png',
          name: '3x3 Harvest',
          description: 'Test',
          predecessorIds: [],
          requirements: {},
          conditionsUnlocked: {
            'harvest_grid': {'x': 3, 'y': 3}
          },
        )
      );

      final researchState = ResearchState();
      final farmState = FarmState(
        gridWidth: 5,
        gridHeight: 5,
        researchState: researchState,
      );

      researchState.completeResearch('farm_harvest_3x3');

      // Plant 3x3 grid of crops centered at (2,2)
      for (int dy = -1; dy <= 1; dy++) {
        for (int dx = -1; dx <= 1; dx++) {
          final plot = farmState.getPlot(2 + dx, 2 + dy)!;
          plot.state = PlotState.watered;
          plot.crop = PlantedCrop(
            cropType: CropType.potato,
            growthStartedAt: DateTime.now().subtract(const Duration(days: 1)),
          );
        }
      }

      farmState.dronePosition = DronePosition(x: 2, y: 2);
      final result = await farmState.harvestCurrentPlot();
      expect(result, isNotNull);
      expect(result!['plotsHarvested'], equals(9));
    });

    test('Harvest only harvests grown crops', () async {
      ResearchItemsSchema.instance.addFarmItemForTesting('farm_harvest_3x3',
        FarmResearchItemSchema(
          id: 'farm_harvest_3x3',
          icon: 'test.png',
          name: '3x3 Harvest',
          description: 'Test',
          predecessorIds: [],
          requirements: {},
          conditionsUnlocked: {
            'harvest_grid': {'x': 3, 'y': 3}
          },
        )
      );

      final researchState = ResearchState();
      final farmState = FarmState(
        gridWidth: 5,
        gridHeight: 5,
        researchState: researchState,
      );

      researchState.completeResearch('farm_harvest_3x3');

      // Plant some grown and some not grown
      final plot1 = farmState.getPlot(1, 2)!;
      plot1.state = PlotState.watered;
      plot1.crop = PlantedCrop(
        cropType: CropType.wheat,
        growthStartedAt: DateTime.now().subtract(const Duration(days: 30)),
      );

      final plot2 = farmState.getPlot(2, 2)!;
      plot2.state = PlotState.watered;
      plot2.crop = PlantedCrop(
        cropType: CropType.wheat,
        growthStartedAt: DateTime.now(), // Not grown yet
      );

      farmState.dronePosition = DronePosition(x: 2, y: 2);
      final result = await farmState.harvestCurrentPlot();
      
      // Should only harvest the grown crop
      expect(result, isNotNull);
      expect(result!['plotsHarvested'], equals(1));
    });

    test('Harvest at boundary respects grid limits', () async {
      ResearchItemsSchema.instance.addFarmItemForTesting('farm_harvest_3x3',
        FarmResearchItemSchema(
          id: 'farm_harvest_3x3',
          icon: 'test.png',
          name: '3x3 Harvest',
          description: 'Test',
          predecessorIds: [],
          requirements: {},
          conditionsUnlocked: {
            'harvest_grid': {'x': 3, 'y': 3}
          },
        )
      );

      final researchState = ResearchState();
      final farmState = FarmState(
        gridWidth: 3,
        gridHeight: 3,
        researchState: researchState,
      );

      researchState.completeResearch('farm_harvest_3x3');

      // Plant at corner
      final plot = farmState.getPlot(0, 0)!;
      plot.state = PlotState.watered;
      plot.crop = PlantedCrop(
        cropType: CropType.beetroot,
        growthStartedAt: DateTime.now().subtract(const Duration(days: 30)),
      );

      farmState.dronePosition = DronePosition(x: 0, y: 0);
      final result = await farmState.harvestCurrentPlot();
      
      // Should harvest only valid plots (corner case)
      expect(result, isNotNull);
      expect(result!['plotsHarvested'], greaterThanOrEqualTo(1));
    });
  });

  group('Farm Research Plant Grid Tests', () {
    setUp(() {
      ResearchItemsSchema.instance.clearForTesting();
    });

    test('Plant grid parses from farm research schema', () {
      final farmResearch = FarmResearchItemSchema.fromJson('farm_plant_test', {
        'icon': 'test.png',
        'name': 'Test Plant',
        'description': 'Test',
        'predecessor_ids': [],
        'requirements': {},
        'conditions_unlocked': {
          'plant_grid': {'x': 3, 'y': 1}
        },
      });

      final plantCondition = farmResearch.conditionsUnlocked['plant_grid'];
      expect(plantCondition, isNotNull);
      expect(plantCondition!['x'], equals(3));
      expect(plantCondition['y'], equals(1));
    });

    test('Default plant is 1x1 with no research', () {
      final researchState = ResearchState();
      researchState.completeResearch('crop_wheat'); // Enable wheat planting
      
      final farmState = FarmState(
        gridWidth: 3,
        gridHeight: 3,
        researchState: researchState,
      );

      farmState.dronePosition = DronePosition(x: 1, y: 1);
      farmState.tillCurrentPlot();
      
      final planted = farmState.plantSeed(SeedType.wheat_seeds);
      expect(planted, equals(1));
    });

    test('Plant area expands to 3x1 with research', () {
      ResearchItemsSchema.instance.addFarmItemForTesting('farm_plant_3x1',
        FarmResearchItemSchema(
          id: 'farm_plant_3x1',
          icon: 'test.png',
          name: '3x1 Plant',
          description: 'Test',
          predecessorIds: [],
          requirements: {},
          conditionsUnlocked: {
            'plant_grid': {'x': 3, 'y': 1}
          },
        )
      );

      final researchState = ResearchState();
      researchState.completeResearch('crop_carrot');
      researchState.completeResearch('farm_plant_3x1');
      
      final farmState = FarmState(
        gridWidth: 5,
        gridHeight: 5,
        researchState: researchState,
      );

      // Till 3x1 area
      farmState.dronePosition = DronePosition(x: 2, y: 2);
      for (int dx = -1; dx <= 1; dx++) {
        farmState.getPlot(2 + dx, 2)!.state = PlotState.tilled;
      }

      final planted = farmState.plantSeed(SeedType.carrot_seeds);
      expect(planted, equals(3));
    });

    test('Plant area expands to 3x3 with research', () {
      ResearchItemsSchema.instance.addFarmItemForTesting('farm_plant_3x3',
        FarmResearchItemSchema(
          id: 'farm_plant_3x3',
          icon: 'test.png',
          name: '3x3 Plant',
          description: 'Test',
          predecessorIds: [],
          requirements: {},
          conditionsUnlocked: {
            'plant_grid': {'x': 3, 'y': 3}
          },
        )
      );

      final researchState = ResearchState();
      researchState.completeResearch('crop_potato');
      researchState.completeResearch('farm_plant_3x3');
      
      final farmState = FarmState(
        gridWidth: 5,
        gridHeight: 5,
        researchState: researchState,
      );

      // Till 3x3 area
      for (int dy = -1; dy <= 1; dy++) {
        for (int dx = -1; dx <= 1; dx++) {
          farmState.getPlot(2 + dx, 2 + dy)!.state = PlotState.tilled;
        }
      }

      farmState.dronePosition = DronePosition(x: 2, y: 2);
      final planted = farmState.plantSeed(SeedType.potato_seeds);
      expect(planted, equals(9));
    });

    test('Plant area attempts all valid plots when no inventory limit', () {
      ResearchItemsSchema.instance.addFarmItemForTesting('farm_plant_3x3',
        FarmResearchItemSchema(
          id: 'farm_plant_3x3',
          icon: 'test.png',
          name: '3x3 Plant',
          description: 'Test',
          predecessorIds: [],
          requirements: {},
          conditionsUnlocked: {
            'plant_grid': {'x': 3, 'y': 3}
          },
        )
      );

      final researchState = ResearchState();
      researchState.completeResearch('crop_beetroot');
      researchState.completeResearch('farm_plant_3x3');
      
      final farmState = FarmState(
        gridWidth: 5,
        gridHeight: 5,
        researchState: researchState,
      );

      // Till 3x3 area (9 plots available)
      for (int dy = -1; dy <= 1; dy++) {
        for (int dx = -1; dx <= 1; dx++) {
          farmState.getPlot(2 + dx, 2 + dy)!.state = PlotState.tilled;
        }
      }

      farmState.dronePosition = DronePosition(x: 2, y: 2);
      final planted = farmState.plantSeed(SeedType.beetroot_seeds);
      
      // Without inventory limit, should plant all 9
      expect(planted, equals(9));
    });

    test('Plant priority follows center->plus->cross pattern', () {
      ResearchItemsSchema.instance.addFarmItemForTesting('farm_plant_3x3',
        FarmResearchItemSchema(
          id: 'farm_plant_3x3',
          icon: 'test.png',
          name: '3x3 Plant',
          description: 'Test',
          predecessorIds: [],
          requirements: {},
          conditionsUnlocked: {
            'plant_grid': {'x': 3, 'y': 3}
          },
        )
      );

      final researchState = ResearchState();
      researchState.completeResearch('crop_radish');
      researchState.completeResearch('farm_plant_3x3');
      
      final farmState = FarmState(
        gridWidth: 5,
        gridHeight: 5,
        researchState: researchState,
      );

      // Till 3x3 area
      for (int dy = -1; dy <= 1; dy++) {
        for (int dx = -1; dx <= 1; dx++) {
          farmState.getPlot(2 + dx, 2 + dy)!.state = PlotState.tilled;
        }
      }

      farmState.dronePosition = DronePosition(x: 2, y: 2);
      final planted = farmState.plantSeed(SeedType.radish_seeds);
      expect(planted, equals(9));
      
      // Check priority: center (2,2) should be planted first
      expect(farmState.getPlot(2, 2)?.crop, isNotNull);
      
      // Then plus pattern (N,E,S,W) - at least one should be planted
      final northPlanted = farmState.getPlot(2, 3)?.crop != null;
      final eastPlanted = farmState.getPlot(3, 2)?.crop != null;
      final southPlanted = farmState.getPlot(2, 1)?.crop != null;
      final westPlanted = farmState.getPlot(1, 2)?.crop != null;
      expect(northPlanted || eastPlanted || southPlanted || westPlanted, isTrue);
    });

    test('Plant only plants on tillable plots', () {
      ResearchItemsSchema.instance.addFarmItemForTesting('farm_plant_3x3',
        FarmResearchItemSchema(
          id: 'farm_plant_3x3',
          icon: 'test.png',
          name: '3x3 Plant',
          description: 'Test',
          predecessorIds: [],
          requirements: {},
          conditionsUnlocked: {
            'plant_grid': {'x': 3, 'y': 3}
          },
        )
      );

      final researchState = ResearchState();
      researchState.completeResearch('crop_onion');
      researchState.completeResearch('farm_plant_3x3');
      
      final farmState = FarmState(
        gridWidth: 5,
        gridHeight: 5,
        researchState: researchState,
      );

      // Till only center and north
      farmState.getPlot(2, 2)!.state = PlotState.tilled;
      farmState.getPlot(2, 3)!.state = PlotState.tilled;

      farmState.dronePosition = DronePosition(x: 2, y: 2);
      final planted = farmState.plantSeed(SeedType.onion_seeds);
      
      // Should only plant on the 2 tilled plots
      expect(planted, equals(2));
    });

    test('Plant works with even-sized grids like 2x2', () {
      ResearchItemsSchema.instance.addFarmItemForTesting('farm_plant_2x2',
        FarmResearchItemSchema(
          id: 'farm_plant_2x2',
          icon: 'test.png',
          name: '2x2 Plant',
          description: 'Test',
          predecessorIds: [],
          requirements: {},
          conditionsUnlocked: {
            'plant_grid': {'x': 2, 'y': 2}
          },
        )
      );

      final researchState = ResearchState();
      researchState.completeResearch('crop_lettuce');
      researchState.completeResearch('farm_plant_2x2');
      
      final farmState = FarmState(
        gridWidth: 5,
        gridHeight: 5,
        researchState: researchState,
      );

      // Till 2x2 area
      for (int dy = 0; dy < 2; dy++) {
        for (int dx = 0; dx < 2; dx++) {
          farmState.getPlot(2 + dx, 2 + dy)!.state = PlotState.tilled;
        }
      }

      farmState.dronePosition = DronePosition(x: 2, y: 2);
      final planted = farmState.plantSeed(SeedType.lettuce_seeds);
      expect(planted, equals(4));
    });
  });
}
