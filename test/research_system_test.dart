import 'package:flutter_test/flutter_test.dart';
import 'package:code_sprout/models/research_items_schema.dart';
import 'package:code_sprout/models/research_data.dart';

/// Comprehensive test suite for the research system
/// Tests schema models, requirements checking, and state management (without asset loading)
void main() {
  group('Schema Model Tests', () {
    test('Test 1: CropResearchItemSchema parses JSON correctly', () {
      final json = {
        'icon': 'test_icon.png',
        'default_name': 'Test Crop',
        'language_specific_name': {
          'cpp': 'Crop::Test',
          'python': 'Crop.TEST',
        },
        'description': 'Test description',
        'predecessor_ids': ['crop_wheat'],
        'requirements': {'wheat': 100},
      };

      final schema = CropResearchItemSchema.fromJson('crop_test', json);

      expect(schema.id, 'crop_test');
      expect(schema.icon, 'test_icon.png');
      expect(schema.defaultName, 'Test Crop');
      expect(schema.description, 'Test description');
      expect(schema.predecessorIds, ['crop_wheat']);
      expect(schema.requirements, {'wheat': 100});
    });

    test('Test 2: CropResearchItemSchema returns correct language-specific name', () {
      final json = {
        'icon': 'test_icon.png',
        'default_name': 'Test Crop',
        'language_specific_name': {
          'cpp': 'Crop::Test',
          'python': 'Crop.TEST',
          'java': 'Crop.TEST',
        },
        'description': 'Test description',
        'predecessor_ids': <String>[],
        'requirements': <String, int>{},
      };

      final schema = CropResearchItemSchema.fromJson('crop_test', json);

      expect(schema.getNameForLanguage('cpp'), 'Crop::Test');
      expect(schema.getNameForLanguage('python'), 'Crop.TEST');
      expect(schema.getNameForLanguage('java'), 'Crop.TEST');
      expect(schema.getNameForLanguage('nonexistent'), 'Test Crop'); // Falls back to default
    });

    test('Test 3: FarmResearchItemSchema parses JSON correctly', () {
      final json = {
        'icon': 'farm_icon.png',
        'name': '3x3 Farmland',
        'description': 'Expand farm to 3x3',
        'predecessor_ids': <String>[],
        'requirements': {'wheat': 500},
      };

      final schema = FarmResearchItemSchema.fromJson('farm_3x3', json);

      expect(schema.id, 'farm_3x3');
      expect(schema.icon, 'farm_icon.png');
      expect(schema.name, '3x3 Farmland');
      expect(schema.description, 'Expand farm to 3x3');
      expect(schema.predecessorIds, isEmpty);
      expect(schema.requirements, {'wheat': 500});
    });

    test('Test 4: FunctionsResearchItemSchema parses JSON correctly', () {
      final json = {
        'icon': 'func_icon.png',
        'name': 'move()',
        'language_specific_description': {
          'cpp': 'Move forward in C++',
          'python': 'Move forward in Python',
        },
        'predecessor_ids': <String>[],
        'requirements': <String, int>{},
      };

      final schema = FunctionsResearchItemSchema.fromJson('func_move', json);

      expect(schema.id, 'func_move');
      expect(schema.icon, 'func_icon.png');
      expect(schema.name, 'move()');
      expect(schema.predecessorIds, isEmpty);
      expect(schema.requirements, isEmpty);
    });

    test('Test 5: FunctionsResearchItemSchema returns correct language-specific description', () {
      final json = {
        'icon': 'func_icon.png',
        'name': 'till()',
        'language_specific_description': {
          'cpp': 'Till the soil in C++',
          'python': 'Till the soil in Python',
          'java': 'Till the soil in Java',
        },
        'predecessor_ids': <String>[],
        'requirements': <String, int>{},
      };

      final schema = FunctionsResearchItemSchema.fromJson('func_till', json);

      expect(schema.getDescriptionForLanguage('cpp'), 'Till the soil in C++');
      expect(schema.getDescriptionForLanguage('python'), 'Till the soil in Python');
      expect(schema.getDescriptionForLanguage('java'), 'Till the soil in Java');
      expect(schema.getDescriptionForLanguage('nonexistent'), 'Till the soil in C++'); // Falls back to first value
    });

    test('Test 6: Schema handles empty predecessor list', () {
      final json = {
        'icon': 'test_icon.png',
        'default_name': 'Test',
        'language_specific_name': <String, String>{},
        'description': 'Test',
        'predecessor_ids': <String>[],
        'requirements': <String, int>{},
      };

      final schema = CropResearchItemSchema.fromJson('test_id', json);
      expect(schema.predecessorIds, isEmpty);
    });

    test('Test 7: Schema handles multiple predecessors', () {
      final json = {
        'icon': 'test_icon.png',
        'default_name': 'Test',
        'language_specific_name': <String, String>{},
        'description': 'Test',
        'predecessor_ids': ['crop_wheat', 'crop_carrot', 'crop_potato'],
        'requirements': <String, int>{},
      };

      final schema = CropResearchItemSchema.fromJson('test_id', json);
      expect(schema.predecessorIds.length, 3);
      expect(schema.predecessorIds, contains('crop_wheat'));
      expect(schema.predecessorIds, contains('crop_carrot'));
      expect(schema.predecessorIds, contains('crop_potato'));
    });

    test('Test 8: Schema handles empty requirements', () {
      final json = {
        'icon': 'test_icon.png',
        'default_name': 'Test',
        'language_specific_name': <String, String>{},
        'description': 'Test',
        'predecessor_ids': <String>[],
        'requirements': <String, int>{},
      };

      final schema = CropResearchItemSchema.fromJson('test_id', json);
      expect(schema.requirements, isEmpty);
    });

    test('Test 9: Schema handles multiple requirements', () {
      final json = {
        'icon': 'test_icon.png',
        'default_name': 'Test',
        'language_specific_name': <String, String>{},
        'description': 'Test',
        'predecessor_ids': <String>[],
        'requirements': {
          'wheat': 100,
          'carrot': 200,
          'potato': 300,
        },
      };

      final schema = CropResearchItemSchema.fromJson('test_id', json);
      expect(schema.requirements.length, 3);
      expect(schema.requirements['wheat'], 100);
      expect(schema.requirements['carrot'], 200);
      expect(schema.requirements['potato'], 300);
    });

    test('Test 10: Schema handles missing optional fields gracefully', () {
      final json = {
        'icon': 'test_icon.png',
        'name': 'Test',
        'description': 'Test desc',
        'predecessor_ids': <String>[],
        'requirements': <String, int>{},
      };

      final farmSchema = FarmResearchItemSchema.fromJson('test_id', json);
      expect(farmSchema.id, 'test_id');
      expect(farmSchema.name, 'Test');
    });
  });

  group('Research Requirements Helper Tests', () {
    test('Test 11: areRequirementsMet returns true for empty requirements', () {
      final inventory = {
        'sproutProgress': {
          'inventory': {
            'items': {
              'wheat': {'quantity': 100},
            },
          },
        },
      };

      final result = ResearchRequirements.areRequirementsMet({}, inventory);
      expect(result, true);
    });

    test('Test 12: areRequirementsMet returns true when all requirements are met', () {
      final inventory = {
        'sproutProgress': {
          'inventory': {
            'items': {
              'wheat': {'quantity': 100},
              'carrot': {'quantity': 50},
            },
          },
        },
      };

      final requirements = {
        'wheat': 50,
        'carrot': 25,
      };

      final result = ResearchRequirements.areRequirementsMet(requirements, inventory);
      expect(result, true);
    });

    test('Test 13: areRequirementsMet returns false when one requirement is not met', () {
      final inventory = {
        'sproutProgress': {
          'inventory': {
            'items': {
              'wheat': {'quantity': 100},
              'carrot': {'quantity': 10},
            },
          },
        },
      };

      final requirements = {
        'wheat': 50,
        'carrot': 25,
      };

      final result = ResearchRequirements.areRequirementsMet(requirements, inventory);
      expect(result, false);
    });

    test('Test 14: areRequirementsMet returns false when item is missing from inventory', () {
      final inventory = {
        'sproutProgress': {
          'inventory': {
            'items': {
              'wheat': {'quantity': 100},
            },
          },
        },
      };

      final requirements = {
        'wheat': 50,
        'carrot': 25,
      };

      final result = ResearchRequirements.areRequirementsMet(requirements, inventory);
      expect(result, false);
    });

    test('Test 15: areRequirementsMet handles exact quantity match', () {
      final inventory = {
        'sproutProgress': {
          'inventory': {
            'items': {
              'wheat': {'quantity': 100},
            },
          },
        },
      };

      final requirements = {'wheat': 100};

      final result = ResearchRequirements.areRequirementsMet(requirements, inventory);
      expect(result, true);
    });

    test('Test 16: areRequirementsMet handles malformed inventory structure', () {
      final inventory = {
        'sproutProgress': {
          'inventory': {},
        },
      };

      final requirements = {'wheat': 50};

      final result = ResearchRequirements.areRequirementsMet(requirements, inventory);
      expect(result, false);
    });

    test('Test 17: areRequirementsMet handles null inventory gracefully', () {
      final requirements = {'wheat': 50};

      final result = ResearchRequirements.areRequirementsMet(requirements, {});
      expect(result, false);
    });

    test('Test 18: areRequirementsMet handles zero quantity requirement', () {
      final inventory = {
        'sproutProgress': {
          'inventory': {
            'items': {
              'wheat': {'quantity': 0},
            },
          },
        },
      };

      final requirements = {'wheat': 0};

      final result = ResearchRequirements.areRequirementsMet(requirements, inventory);
      expect(result, true);
    });

    test('Test 19: areRequirementsMet handles multiple items with mixed results', () {
      final inventory = {
        'sproutProgress': {
          'inventory': {
            'items': {
              'wheat': {'quantity': 100},
              'carrot': {'quantity': 50},
              'potato': {'quantity': 10},
            },
          },
        },
      };

      final requirements = {
        'wheat': 50,
        'carrot': 40,
        'potato': 20, // This one fails
      };

      final result = ResearchRequirements.areRequirementsMet(requirements, inventory);
      expect(result, false);
    });

    test('Test 20: arePredecessorsMet returns true for empty predecessors', () {
      final unlockedItems = {'crop_wheat', 'crop_carrot'};

      final result = ResearchRequirements.arePredecessorsMet([], unlockedItems);
      expect(result, true);
    });
  });

  group('Research Prerequisites Tests', () {
    test('Test 21: arePredecessorsMet returns true when all predecessors are unlocked', () {
      final predecessors = ['crop_wheat', 'crop_carrot'];
      final unlockedItems = {'crop_wheat', 'crop_carrot', 'crop_potato'};

      final result = ResearchRequirements.arePredecessorsMet(predecessors, unlockedItems);
      expect(result, true);
    });

    test('Test 22: arePredecessorsMet returns false when one predecessor is missing', () {
      final predecessors = ['crop_wheat', 'crop_carrot'];
      final unlockedItems = {'crop_wheat'};

      final result = ResearchRequirements.arePredecessorsMet(predecessors, unlockedItems);
      expect(result, false);
    });

    test('Test 23: arePredecessorsMet returns false when all predecessors are missing', () {
      final predecessors = ['crop_wheat', 'crop_carrot'];
      final unlockedItems = <String>{};

      final result = ResearchRequirements.arePredecessorsMet(predecessors, unlockedItems);
      expect(result, false);
    });

    test('Test 24: arePredecessorsMet handles single predecessor', () {
      final predecessors = ['crop_wheat'];
      final unlockedItems = {'crop_wheat', 'crop_carrot'};

      final result = ResearchRequirements.arePredecessorsMet(predecessors, unlockedItems);
      expect(result, true);
    });

    test('Test 25: arePredecessorsMet is case-sensitive', () {
      final predecessors = ['crop_wheat'];
      final unlockedItems = {'CROP_WHEAT'};

      final result = ResearchRequirements.arePredecessorsMet(predecessors, unlockedItems);
      expect(result, false);
    });

    test('Test 26: arePredecessorsMet handles large predecessor list', () {
      final predecessors = List.generate(100, (i) => 'item_$i');
      final unlockedItems = List.generate(100, (i) => 'item_$i').toSet();

      final result = ResearchRequirements.arePredecessorsMet(predecessors, unlockedItems);
      expect(result, true);
    });

    test('Test 27: arePredecessorsMet returns false with partial match in large list', () {
      final predecessors = List.generate(100, (i) => 'item_$i');
      final unlockedItems = List.generate(99, (i) => 'item_$i').toSet(); // Missing item_99

      final result = ResearchRequirements.arePredecessorsMet(predecessors, unlockedItems);
      expect(result, false);
    });

    test('Test 28: arePredecessorsMet handles duplicate predecessors', () {
      final predecessors = ['crop_wheat', 'crop_wheat', 'crop_wheat'];
      final unlockedItems = {'crop_wheat'};

      final result = ResearchRequirements.arePredecessorsMet(predecessors, unlockedItems);
      expect(result, true);
    });

    test('Test 29: arePredecessorsMet handles empty unlocked list with non-empty predecessors', () {
      final predecessors = ['crop_wheat'];
      final unlockedItems = <String>{};

      final result = ResearchRequirements.arePredecessorsMet(predecessors, unlockedItems);
      expect(result, false);
    });

    test('Test 30: arePredecessorsMet handles unlocked list with extra items', () {
      final predecessors = ['crop_wheat'];
      final unlockedItems = {'crop_wheat', 'crop_carrot', 'crop_potato', 'farm_3x3'};

      final result = ResearchRequirements.arePredecessorsMet(predecessors, unlockedItems);
      expect(result, true);
    });
  });

  group('Research State Tests', () {
    test('Test 31: ResearchState initializes with empty completed items', () {
      final state = ResearchState();

      expect(state.completedResearchIds, isEmpty);
    });

    test('Test 32: ResearchState loads completed items from list', () {
      final state = ResearchState();
      state.loadCompletedResearch(['crop_wheat', 'farm_3x3', 'func_move']);

      expect(state.completedResearchIds, contains('crop_wheat'));
      expect(state.completedResearchIds, contains('farm_3x3'));
      expect(state.completedResearchIds, contains('func_move'));
      expect(state.completedResearchIds.length, 3);
    });

    test('Test 33: isCompleted returns true for completed item', () {
      final state = ResearchState();
      state.completeResearch('crop_wheat');

      expect(state.isCompleted('crop_wheat'), true);
    });

    test('Test 34: isCompleted returns false for non-completed item', () {
      final state = ResearchState();

      expect(state.isCompleted('crop_wheat'), false);
    });

    test('Test 35: completeResearch adds item to completed set', () {
      final state = ResearchState();
      state.completeResearch('crop_wheat');

      expect(state.completedResearchIds, contains('crop_wheat'));
      expect(state.completedResearchIds.length, 1);
    });

    test('Test 36: completeResearch handles duplicate completion', () {
      final state = ResearchState();
      state.completeResearch('crop_wheat');
      state.completeResearch('crop_wheat');

      expect(state.completedResearchIds.length, 1); // Should still be 1
    });

    test('Test 37: reset clears all completed items', () {
      final state = ResearchState();
      state.loadCompletedResearch(['crop_wheat', 'crop_carrot', 'farm_3x3']);
      
      expect(state.completedResearchIds.length, 3);
      
      state.reset();
      
      expect(state.completedResearchIds, isEmpty);
    });

    test('Test 38: getCropResearchState returns purchase for completed item', () {
      final state = ResearchState();
      state.completeResearch('crop_wheat');
      
      final itemJson = {
        'icon': 'icon.png',
        'default_name': 'Wheat',
        'language_specific_name': <String, String>{},
        'description': 'Test',
        'predecessor_ids': <String>[],
        'requirements': <String, int>{},
      };
      final item = CropResearchItemSchema.fromJson('crop_wheat', itemJson);
      
      final itemState = state.getCropResearchState(item);
      expect(itemState, CropResearchState.purchase);
    });

    test('Test 39: getCropResearchState returns locked for item with unmet predecessors', () {
      final state = ResearchState();
      
      final itemJson = {
        'icon': 'icon.png',
        'default_name': 'Carrot',
        'language_specific_name': <String, String>{},
        'description': 'Test',
        'predecessor_ids': ['crop_wheat'],
        'requirements': <String, int>{},
      };
      final item = CropResearchItemSchema.fromJson('crop_carrot', itemJson);
      
      final itemState = state.getCropResearchState(item);
      expect(itemState, CropResearchState.locked);
    });

    test('Test 40: getCropResearchState returns toBeResearched for item with met predecessors', () {
      final state = ResearchState();
      state.completeResearch('crop_wheat');
      
      final itemJson = {
        'icon': 'icon.png',
        'default_name': 'Carrot',
        'language_specific_name': <String, String>{},
        'description': 'Test',
        'predecessor_ids': ['crop_wheat'],
        'requirements': <String, int>{},
      };
      final item = CropResearchItemSchema.fromJson('crop_carrot', itemJson);
      
      final itemState = state.getCropResearchState(item);
      expect(itemState, CropResearchState.toBeResearched);
    });
  });

  group('Research Integration Tests', () {
    test('Test 41: Complete research flow - prerequisites and requirements', () {
      final state = ResearchState();
      final inventory = {
        'sproutProgress': {
          'inventory': {
            'items': {
              'wheat': {'quantity': 300},
            },
          },
        },
      };

      // Create wheat research item (no prerequisites)
      final wheatJson = {
        'icon': 'icon.png',
        'default_name': 'Wheat',
        'language_specific_name': <String, String>{},
        'description': 'Test',
        'predecessor_ids': <String>[],
        'requirements': {'wheat': 250},
      };
      final wheatItem = CropResearchItemSchema.fromJson('crop_wheat', wheatJson);

      // Initially not completed
      expect(state.isCompleted('crop_wheat'), false);

      // Check state - should be toBeResearched (no predecessors)
      expect(state.getCropResearchState(wheatItem), CropResearchState.toBeResearched);

      // Check requirements are met
      final canUnlock = ResearchRequirements.areRequirementsMet(wheatItem.requirements, inventory);
      expect(canUnlock, true);

      // Complete the research
      state.completeResearch('crop_wheat');
      expect(state.isCompleted('crop_wheat'), true);
      expect(state.getCropResearchState(wheatItem), CropResearchState.purchase);
    });

    test('Test 42: Research flow with insufficient items', () {
      final inventory = {
        'sproutProgress': {
          'inventory': {
            'items': {
              'wheat': {'quantity': 100},
            },
          },
        },
      };

      final requirements = {'wheat': 250};
      final canUnlock = ResearchRequirements.areRequirementsMet(requirements, inventory);

      expect(canUnlock, false);
    });

    test('Test 43: Research flow with missing prerequisites', () {
      final state = ResearchState();
      
      final itemJson = {
        'icon': 'icon.png',
        'default_name': 'Carrot',
        'language_specific_name': <String, String>{},
        'description': 'Test',
        'predecessor_ids': ['crop_wheat'],
        'requirements': <String, int>{},
      };
      final item = CropResearchItemSchema.fromJson('crop_carrot', itemJson);

      // Wheat not unlocked, so carrot should be locked
      expect(state.getCropResearchState(item), CropResearchState.locked);
    });

    test('Test 44: Research flow with met prerequisites and requirements', () {
      final state = ResearchState();
      state.completeResearch('crop_wheat');
      
      final inventory = {
        'sproutProgress': {
          'inventory': {
            'items': {
              'carrot': {'quantity': 350},
            },
          },
        },
      };

      final carrotJson = {
        'icon': 'icon.png',
        'default_name': 'Carrot',
        'language_specific_name': <String, String>{},
        'description': 'Test',
        'predecessor_ids': ['crop_wheat'],
        'requirements': {'carrot': 300},
      };
      final carrotItem = CropResearchItemSchema.fromJson('crop_carrot', carrotJson);

      // Prerequisites met (wheat completed)
      expect(state.getCropResearchState(carrotItem), CropResearchState.toBeResearched);

      // Requirements met (enough carrots)
      final requirementsMet = ResearchRequirements.areRequirementsMet(carrotItem.requirements, inventory);
      expect(requirementsMet, true);
    });

    test('Test 45: Multiple research items can be completed in sequence', () {
      final state = ResearchState();

      state.completeResearch('crop_wheat');
      expect(state.completedResearchIds.length, 1);

      state.completeResearch('crop_carrot');
      expect(state.completedResearchIds.length, 2);

      state.completeResearch('crop_potato');
      expect(state.completedResearchIds.length, 3);

      expect(state.isCompleted('crop_wheat'), true);
      expect(state.isCompleted('crop_carrot'), true);
      expect(state.isCompleted('crop_potato'), true);
    });

    test('Test 46: Research across different categories works independently', () {
      final state = ResearchState();

      state.completeResearch('crop_wheat');
      state.completeResearch('farm_3x3');
      state.completeResearch('func_move');

      expect(state.completedResearchIds.length, 3);
      expect(state.isCompleted('crop_wheat'), true);
      expect(state.isCompleted('farm_3x3'), true);
      expect(state.isCompleted('func_move'), true);
    });

    test('Test 47: Duplicate completion attempts are handled correctly', () {
      final state = ResearchState();

      state.completeResearch('crop_wheat');
      expect(state.completedResearchIds.length, 1);

      state.completeResearch('crop_wheat');
      expect(state.completedResearchIds.length, 1); // Should still be 1
    });

    test('Test 48: Language-specific name fallback works correctly', () {
      final json = {
        'icon': 'test_icon.png',
        'default_name': 'Default Name',
        'language_specific_name': {
          'cpp': 'Crop::Test',
        },
        'description': 'Test',
        'predecessor_ids': <String>[],
        'requirements': <String, int>{},
      };

      final schema = CropResearchItemSchema.fromJson('test', json);

      // Has cpp translation
      expect(schema.getNameForLanguage('cpp'), 'Crop::Test');

      // No python translation, should fall back to default
      expect(schema.getNameForLanguage('python'), 'Default Name');

      // No java translation, should fall back to default
      expect(schema.getNameForLanguage('java'), 'Default Name');
    });

    test('Test 49: Language-specific description fallback works correctly', () {
      final json = {
        'icon': 'test_icon.png',
        'name': 'test()',
        'language_specific_description': {
          'cpp': 'C++ description',
        },
        'predecessor_ids': <String>[],
        'requirements': <String, int>{},
      };

      final schema = FunctionsResearchItemSchema.fromJson('test', json);

      // Has cpp translation
      expect(schema.getDescriptionForLanguage('cpp'), 'C++ description');

      // No python translation, should fall back to first value (cpp)
      expect(schema.getDescriptionForLanguage('python'), 'C++ description');
    });

    test('Test 50: Complex research chain validation', () {
      // Simulate a chain: wheat -> carrot -> potato
      final state = ResearchState();
      state.loadCompletedResearch(['crop_wheat', 'crop_carrot']);

      final inventory = {
        'sproutProgress': {
          'inventory': {
            'items': {
              'wheat': {'quantity': 500},
              'carrot': {'quantity': 400},
              'potato': {'quantity': 100},
            },
          },
        },
      };

      // Wheat is completed
      expect(state.isCompleted('crop_wheat'), true);

      // Carrot is completed (requires wheat)
      expect(state.isCompleted('crop_carrot'), true);

      // Potato not completed yet, but prerequisites met (requires carrot which is completed)
      final potatoJson = {
        'icon': 'icon.png',
        'default_name': 'Potato',
        'language_specific_name': <String, String>{},
        'description': 'Test',
        'predecessor_ids': ['crop_carrot'],
        'requirements': {'potato': 50},
      };
      final potatoItem = CropResearchItemSchema.fromJson('crop_potato', potatoJson);

      expect(state.getCropResearchState(potatoItem), CropResearchState.toBeResearched);

      // Potato requirements met (enough items)
      final potatoReqsMet = ResearchRequirements.areRequirementsMet(potatoItem.requirements, inventory);
      expect(potatoReqsMet, true);
    });
  });
}
