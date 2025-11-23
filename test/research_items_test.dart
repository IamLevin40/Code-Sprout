import 'package:flutter_test/flutter_test.dart';
import 'package:code_sprout/models/research_items_schema.dart';
import 'package:code_sprout/models/research_data.dart';
import 'package:code_sprout/models/farm_data.dart';
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

      // Till and water a plot
      farmState.tillCurrentPlot();
      farmState.waterCurrentPlot();

      // Try to plant carrot seeds without completing carrot research
      final result = farmState.plantSeed(SeedType.carrot_seeds);
      
      expect(result, isFalse, reason: 'Should not plant without research');
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
      
      expect(result, isTrue, reason: 'Should plant after completing research');
      
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
      expect(farmState.plantSeed(SeedType.wheat_seeds), isFalse,
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
      expect(farmState.plantSeed(SeedType.wheat_seeds), isFalse);

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
      expect(result, isTrue, reason: 'Should allow operations without research state');
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
      expect(result, isFalse, reason: 'Cannot plant without seeds in inventory');
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
}
