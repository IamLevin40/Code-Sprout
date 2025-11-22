import 'package:flutter_test/flutter_test.dart';
import 'package:code_sprout/models/research_data.dart';

void main() {
  group('ResearchItem Base Tests', () {
    test('Test 1: ResearchItem should check prerequisites correctly - no predecessors', () {
      final item = CropResearchItem(
        id: 'test_crop',
        name: 'Test Crop',
        description: 'Test description',
        cropType: 'wheat',
        predecessorIds: [],
        requirements: {},
      );

      final completedIds = <String>{'other_research'};
      expect(item.arePredecessorsMet(completedIds), true);
    });

    test('Test 2: ResearchItem should check prerequisites correctly - with predecessors met', () {
      final item = CropResearchItem(
        id: 'test_crop',
        name: 'Test Crop',
        description: 'Test description',
        cropType: 'wheat',
        predecessorIds: ['req1', 'req2'],
        requirements: {},
      );

      final completedIds = <String>{'req1', 'req2', 'other'};
      expect(item.arePredecessorsMet(completedIds), true);
    });

    test('Test 3: ResearchItem should check prerequisites correctly - with predecessors not met', () {
      final item = CropResearchItem(
        id: 'test_crop',
        name: 'Test Crop',
        description: 'Test description',
        cropType: 'wheat',
        predecessorIds: ['req1', 'req2'],
        requirements: {},
      );

      final completedIds = <String>{'req1'}; // req2 is missing
      expect(item.arePredecessorsMet(completedIds), false);
    });

    test('Test 4: ResearchItem should check inventory requirements - sufficient items', () {
      final item = CropResearchItem(
        id: 'test_crop',
        name: 'Test Crop',
        description: 'Test description',
        cropType: 'wheat',
        predecessorIds: [],
        requirements: {
          'inventory.crops.wheat': 100,
          'inventory.crops.carrot': 50,
        },
      );

      final inventory = {
        'inventory': {
          'crops': {
            'wheat': 150,
            'carrot': 60,
          }
        }
      };

      expect(item.areRequirementsMet(inventory), true);
    });

    test('Test 5: ResearchItem should check inventory requirements - insufficient items', () {
      final item = CropResearchItem(
        id: 'test_crop',
        name: 'Test Crop',
        description: 'Test description',
        cropType: 'wheat',
        predecessorIds: [],
        requirements: {
          'inventory.crops.wheat': 100,
          'inventory.crops.carrot': 50,
        },
      );

      final inventory = {
        'inventory': {
          'crops': {
            'wheat': 150,
            'carrot': 30, // Not enough carrots
          }
        }
      };

      expect(item.areRequirementsMet(inventory), false);
    });

    test('Test 6: ResearchItem should check inventory requirements - missing items', () {
      final item = CropResearchItem(
        id: 'test_crop',
        name: 'Test Crop',
        description: 'Test description',
        cropType: 'wheat',
        predecessorIds: [],
        requirements: {
          'inventory.crops.wheat': 100,
        },
      );

      final inventory = {
        'inventory': {
          'crops': {
            'carrot': 200, // wheat is missing
          }
        }
      };

      expect(item.areRequirementsMet(inventory), false);
    });
  });

  group('ResearchState Tests', () {
    test('Test 7: ResearchState should track completed research', () {
      final state = ResearchState();
      
      expect(state.isCompleted('research1'), false);
      
      state.completeResearch('research1');
      expect(state.isCompleted('research1'), true);
      expect(state.completedResearchIds.contains('research1'), true);
    });

    test('Test 8: ResearchState should not duplicate completed research', () {
      final state = ResearchState();
      
      state.completeResearch('research1');
      state.completeResearch('research1');
      
      expect(state.completedResearchIds.length, 1);
      expect(state.completedResearchIds.first, 'research1');
    });

    test('Test 9: ResearchState should load completed research from list', () {
      final state = ResearchState();
      
      state.loadCompletedResearch(['res1', 'res2', 'res3']);
      
      expect(state.completedResearchIds.length, 3);
      expect(state.isCompleted('res1'), true);
      expect(state.isCompleted('res2'), true);
      expect(state.isCompleted('res3'), true);
    });

    test('Test 10: ResearchState should reset all research', () {
      final state = ResearchState();
      
      state.completeResearch('research1');
      state.completeResearch('research2');
      expect(state.completedResearchIds.length, 2);
      
      state.reset();
      expect(state.completedResearchIds.length, 0);
    });
  });

  group('Crop Research State Transitions', () {
    test('Test 11: Crop research should start as locked when prerequisites not met', () {
      final state = ResearchState();
      final item = CropResearchItem(
        id: 'crop_potato',
        name: 'Potato',
        description: 'Test',
        cropType: 'potato',
        predecessorIds: ['crop_wheat', 'crop_carrot'],
        requirements: {},
      );

      final currentState = state.getCropResearchState(item);
      expect(currentState, CropResearchState.locked);
    });

    test('Test 12: Crop research should transition to toBeResearched when prerequisites met', () {
      final state = ResearchState();
      state.completeResearch('crop_wheat');
      state.completeResearch('crop_carrot');
      
      final item = CropResearchItem(
        id: 'crop_potato',
        name: 'Potato',
        description: 'Test',
        cropType: 'potato',
        predecessorIds: ['crop_wheat', 'crop_carrot'],
        requirements: {},
      );

      final currentState = state.getCropResearchState(item);
      expect(currentState, CropResearchState.toBeResearched);
    });

    test('Test 13: Crop research should transition to purchase when completed', () {
      final state = ResearchState();
      state.completeResearch('crop_wheat');
      
      final item = CropResearchItem(
        id: 'crop_wheat',
        name: 'Wheat',
        description: 'Test',
        cropType: 'wheat',
        predecessorIds: [],
        requirements: {},
      );

      final currentState = state.getCropResearchState(item);
      expect(currentState, CropResearchState.purchase);
    });

    test('Test 14: Crop research with no prerequisites should start as toBeResearched', () {
      final state = ResearchState();
      
      final item = CropResearchItem(
        id: 'crop_wheat',
        name: 'Wheat',
        description: 'Test',
        cropType: 'wheat',
        predecessorIds: [],
        requirements: {},
      );

      final currentState = state.getCropResearchState(item);
      expect(currentState, CropResearchState.toBeResearched);
    });
  });

  group('Farm Research State Transitions', () {
    test('Test 15: Farm research should start as locked when prerequisites not met', () {
      final state = ResearchState();
      final item = FarmResearchItem(
        id: 'farm_expansion',
        name: 'Farm Expansion',
        description: 'Test',
        farmFeature: 'expansion',
        predecessorIds: ['farm_basic'],
        requirements: {},
      );

      final currentState = state.getFarmResearchState(item);
      expect(currentState, FarmResearchState.locked);
    });

    test('Test 16: Farm research should transition to toBeResearched when prerequisites met', () {
      final state = ResearchState();
      state.completeResearch('farm_basic');
      
      final item = FarmResearchItem(
        id: 'farm_expansion',
        name: 'Farm Expansion',
        description: 'Test',
        farmFeature: 'expansion',
        predecessorIds: ['farm_basic'],
        requirements: {},
      );

      final currentState = state.getFarmResearchState(item);
      expect(currentState, FarmResearchState.toBeResearched);
    });

    test('Test 17: Farm research should transition to unlocked when completed', () {
      final state = ResearchState();
      state.completeResearch('farm_expansion');
      
      final item = FarmResearchItem(
        id: 'farm_expansion',
        name: 'Farm Expansion',
        description: 'Test',
        farmFeature: 'expansion',
        predecessorIds: [],
        requirements: {},
      );

      final currentState = state.getFarmResearchState(item);
      expect(currentState, FarmResearchState.unlocked);
    });
  });

  group('Functions Research State Transitions', () {
    test('Test 18: Functions research should start as locked when prerequisites not met', () {
      final state = ResearchState();
      final item = FunctionsResearchItem(
        id: 'func_harvest',
        name: 'harvest()',
        description: 'Test',
        functionName: 'harvest',
        predecessorIds: ['func_plant'],
        requirements: {},
      );

      final currentState = state.getFunctionsResearchState(item);
      expect(currentState, FunctionsResearchState.locked);
    });

    test('Test 19: Functions research should transition to toBeResearched when prerequisites met', () {
      final state = ResearchState();
      state.completeResearch('func_plant');
      
      final item = FunctionsResearchItem(
        id: 'func_harvest',
        name: 'harvest()',
        description: 'Test',
        functionName: 'harvest',
        predecessorIds: ['func_plant'],
        requirements: {},
      );

      final currentState = state.getFunctionsResearchState(item);
      expect(currentState, FunctionsResearchState.toBeResearched);
    });

    test('Test 20: Functions research should transition to unlocked when completed', () {
      final state = ResearchState();
      state.completeResearch('func_harvest');
      
      final item = FunctionsResearchItem(
        id: 'func_harvest',
        name: 'harvest()',
        description: 'Test',
        functionName: 'harvest',
        predecessorIds: [],
        requirements: {},
      );

      final currentState = state.getFunctionsResearchState(item);
      expect(currentState, FunctionsResearchState.unlocked);
    });
  });

  group('Complex Predecessor Chains', () {
    test('Test 21: Research with multiple prerequisites should unlock in correct order', () {
      final state = ResearchState();
      
      // Define research chain: A -> B, A -> C, B + C -> D
      final itemA = CropResearchItem(
        id: 'A',
        name: 'A',
        description: 'Test',
        cropType: 'wheat',
        predecessorIds: [],
        requirements: {},
      );
      
      final itemB = CropResearchItem(
        id: 'B',
        name: 'B',
        description: 'Test',
        cropType: 'carrot',
        predecessorIds: ['A'],
        requirements: {},
      );
      
      final itemC = CropResearchItem(
        id: 'C',
        name: 'C',
        description: 'Test',
        cropType: 'potato',
        predecessorIds: ['A'],
        requirements: {},
      );
      
      final itemD = CropResearchItem(
        id: 'D',
        name: 'D',
        description: 'Test',
        cropType: 'beetroot',
        predecessorIds: ['B', 'C'],
        requirements: {},
      );

      // Initially, A is toBeResearched, others are locked
      expect(state.getCropResearchState(itemA), CropResearchState.toBeResearched);
      expect(state.getCropResearchState(itemB), CropResearchState.locked);
      expect(state.getCropResearchState(itemC), CropResearchState.locked);
      expect(state.getCropResearchState(itemD), CropResearchState.locked);

      // Complete A
      state.completeResearch('A');
      expect(state.getCropResearchState(itemA), CropResearchState.purchase);
      expect(state.getCropResearchState(itemB), CropResearchState.toBeResearched);
      expect(state.getCropResearchState(itemC), CropResearchState.toBeResearched);
      expect(state.getCropResearchState(itemD), CropResearchState.locked); // Still needs B and C

      // Complete B
      state.completeResearch('B');
      expect(state.getCropResearchState(itemD), CropResearchState.locked); // Still needs C

      // Complete C
      state.completeResearch('C');
      expect(state.getCropResearchState(itemD), CropResearchState.toBeResearched); // Now unlocked
    });

    test('Test 22: Research with partial prerequisites should remain locked', () {
      final state = ResearchState();
      state.completeResearch('req1');
      state.completeResearch('req2');
      // req3 is NOT completed
      
      final item = FarmResearchItem(
        id: 'advanced_farm',
        name: 'Advanced Farm',
        description: 'Test',
        farmFeature: 'advanced',
        predecessorIds: ['req1', 'req2', 'req3'],
        requirements: {},
      );

      final currentState = state.getFarmResearchState(item);
      expect(currentState, FarmResearchState.locked);
    });
  });

  group('Complex Inventory Requirements', () {
    test('Test 23: Research should check multiple inventory items correctly', () {
      final item = CropResearchItem(
        id: 'test',
        name: 'Test',
        description: 'Test',
        cropType: 'wheat',
        predecessorIds: [],
        requirements: {
          'inventory.crops.wheat': 100,
          'inventory.crops.carrot': 50,
          'inventory.crops.potato': 75,
        },
      );

      final inventory = {
        'inventory': {
          'crops': {
            'wheat': 100,
            'carrot': 50,
            'potato': 75,
          }
        }
      };

      expect(item.areRequirementsMet(inventory), true);
    });

    test('Test 24: Research should fail if any requirement is not met', () {
      final item = CropResearchItem(
        id: 'test',
        name: 'Test',
        description: 'Test',
        cropType: 'wheat',
        predecessorIds: [],
        requirements: {
          'inventory.crops.wheat': 100,
          'inventory.crops.carrot': 50,
          'inventory.crops.potato': 75,
        },
      );

      final inventory = {
        'inventory': {
          'crops': {
            'wheat': 100,
            'carrot': 50,
            'potato': 74, // One short!
          }
        }
      };

      expect(item.areRequirementsMet(inventory), false);
    });

    test('Test 25: Research with no requirements should always pass inventory check', () {
      final item = CropResearchItem(
        id: 'test',
        name: 'Test',
        description: 'Test',
        cropType: 'wheat',
        predecessorIds: [],
        requirements: {},
      );

      final emptyInventory = <String, dynamic>{};
      expect(item.areRequirementsMet(emptyInventory), true);
    });
  });

  group('Edge Cases', () {
    test('Test 26: Empty predecessorIds list should allow research', () {
      final state = ResearchState();
      final item = CropResearchItem(
        id: 'test',
        name: 'Test',
        description: 'Test',
        cropType: 'wheat',
        predecessorIds: [],
        requirements: {},
      );

      expect(item.arePredecessorsMet(state.completedResearchIds), true);
      expect(state.getCropResearchState(item), CropResearchState.toBeResearched);
    });

    test('Test 27: Nested inventory paths should be correctly parsed', () {
      final item = CropResearchItem(
        id: 'test',
        name: 'Test',
        description: 'Test',
        cropType: 'wheat',
        predecessorIds: [],
        requirements: {
          'inventory.items.special.rare_seed': 10,
        },
      );

      final inventory = {
        'inventory': {
          'items': {
            'special': {
              'rare_seed': 15,
            }
          }
        }
      };

      expect(item.areRequirementsMet(inventory), true);
    });

    test('Test 28: ResearchState should notify listeners on completion', () {
      final state = ResearchState();
      var notified = false;
      
      state.addListener(() {
        notified = true;
      });
      
      state.completeResearch('test_research');
      expect(notified, true);
    });

    test('Test 29: ResearchState should notify listeners on reset', () {
      final state = ResearchState();
      var notificationCount = 0;
      
      state.addListener(() {
        notificationCount++;
      });
      
      state.completeResearch('test1');
      state.completeResearch('test2');
      state.reset();
      
      expect(notificationCount, 3); // Once for each complete and once for reset
    });

    test('Test 30: ResearchState should notify listeners on loadCompletedResearch', () {
      final state = ResearchState();
      var notified = false;
      
      state.addListener(() {
        notified = true;
      });
      
      state.loadCompletedResearch(['res1', 'res2']);
      expect(notified, true);
    });
  });
}
