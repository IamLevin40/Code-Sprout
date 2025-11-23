import 'package:flutter_test/flutter_test.dart';
import 'package:code_sprout/models/research_data.dart';

/// Test suite for research progress auto-save/auto-load functionality
void main() {
  group('Research Progress Persistence Tests', () {
    test('Test 1: ResearchState exports to correct Firestore format', () {
      final state = ResearchState();
      state.completeResearch('crop_wheat');
      state.completeResearch('crop_carrot');
      state.completeResearch('farm_3x3');
      state.completeResearch('func_move');
      state.completeResearch('func_till');

      final exported = state.exportToFirestore();

      expect(exported['crop_researches'], ['crop_wheat', 'crop_carrot']);
      expect(exported['farm_researches'], ['farm_3x3']);
      expect(exported['functions_researches'], ['func_move', 'func_till']);
    });

    test('Test 2: ResearchState loads from Firestore format', () {
      final state = ResearchState();
      final firestoreData = {
        'crop_researches': ['crop_wheat', 'crop_carrot', 'crop_potato'],
        'farm_researches': ['farm_3x3', 'farm_4x4'],
        'functions_researches': ['func_move', 'func_till', 'func_water'],
      };

      state.loadFromFirestore(firestoreData);

      expect(state.isCompleted('crop_wheat'), true);
      expect(state.isCompleted('crop_carrot'), true);
      expect(state.isCompleted('crop_potato'), true);
      expect(state.isCompleted('farm_3x3'), true);
      expect(state.isCompleted('farm_4x4'), true);
      expect(state.isCompleted('func_move'), true);
      expect(state.isCompleted('func_till'), true);
      expect(state.isCompleted('func_water'), true);
      expect(state.completedResearchIds.length, 8);
    });

    test('Test 3: ResearchState completedCropResearches getter', () {
      final state = ResearchState();
      state.completeResearch('crop_wheat');
      state.completeResearch('farm_3x3');
      state.completeResearch('crop_carrot');
      state.completeResearch('func_move');

      final cropResearches = state.completedCropResearches;

      expect(cropResearches.length, 2);
      expect(cropResearches, contains('crop_wheat'));
      expect(cropResearches, contains('crop_carrot'));
    });

    test('Test 4: ResearchState completedFarmResearches getter', () {
      final state = ResearchState();
      state.completeResearch('crop_wheat');
      state.completeResearch('farm_3x3');
      state.completeResearch('farm_4x4');
      state.completeResearch('func_move');

      final farmResearches = state.completedFarmResearches;

      expect(farmResearches.length, 2);
      expect(farmResearches, contains('farm_3x3'));
      expect(farmResearches, contains('farm_4x4'));
    });

    test('Test 5: ResearchState completedFunctionsResearches getter', () {
      final state = ResearchState();
      state.completeResearch('crop_wheat');
      state.completeResearch('func_move');
      state.completeResearch('func_till');
      state.completeResearch('farm_3x3');
      state.completeResearch('func_water');

      final funcResearches = state.completedFunctionsResearches;

      expect(funcResearches.length, 3);
      expect(funcResearches, contains('func_move'));
      expect(funcResearches, contains('func_till'));
      expect(funcResearches, contains('func_water'));
    });

    test('Test 6: ResearchState handles empty Firestore data', () {
      final state = ResearchState();
      state.completeResearch('crop_wheat'); // Add some data first

      final firestoreData = {
        'crop_researches': <String>[],
        'farm_researches': <String>[],
        'functions_researches': <String>[],
      };

      state.loadFromFirestore(firestoreData);

      expect(state.completedResearchIds, isEmpty);
    });

    test('Test 7: ResearchState handles partial Firestore data', () {
      final state = ResearchState();
      final firestoreData = {
        'crop_researches': ['crop_wheat'],
        // Missing farm_researches
        'functions_researches': ['func_move'],
      };

      state.loadFromFirestore(firestoreData);

      expect(state.isCompleted('crop_wheat'), true);
      expect(state.isCompleted('func_move'), true);
      expect(state.completedResearchIds.length, 2);
    });

    test('Test 8: Export then load maintains data integrity', () {
      final state1 = ResearchState();
      state1.completeResearch('crop_wheat');
      state1.completeResearch('crop_carrot');
      state1.completeResearch('farm_3x3');
      state1.completeResearch('func_move');

      final exported = state1.exportToFirestore();

      final state2 = ResearchState();
      state2.loadFromFirestore({
        'crop_researches': exported['crop_researches']!,
        'farm_researches': exported['farm_researches']!,
        'functions_researches': exported['functions_researches']!,
      });

      expect(state2.completedResearchIds, state1.completedResearchIds);
      expect(state2.isCompleted('crop_wheat'), true);
      expect(state2.isCompleted('crop_carrot'), true);
      expect(state2.isCompleted('farm_3x3'), true);
      expect(state2.isCompleted('func_move'), true);
    });

    test('Test 9: ResearchState separates research types correctly', () {
      final state = ResearchState();
      state.completeResearch('crop_wheat');
      state.completeResearch('crop_carrot');
      state.completeResearch('crop_potato');
      state.completeResearch('farm_3x3');
      state.completeResearch('farm_4x4');
      state.completeResearch('func_move');
      state.completeResearch('func_till');
      state.completeResearch('func_water');
      state.completeResearch('func_plant');

      expect(state.completedCropResearches.length, 3);
      expect(state.completedFarmResearches.length, 2);
      expect(state.completedFunctionsResearches.length, 4);
      expect(state.completedResearchIds.length, 9);
    });

    test('Test 10: Multiple load operations clear previous data', () {
      final state = ResearchState();
      
      // First load
      state.loadFromFirestore({
        'crop_researches': ['crop_wheat', 'crop_carrot'],
        'farm_researches': ['farm_3x3'],
        'functions_researches': ['func_move'],
      });

      expect(state.completedResearchIds.length, 4);

      // Second load should clear previous data
      state.loadFromFirestore({
        'crop_researches': ['crop_potato'],
        'farm_researches': <String>[],
        'functions_researches': ['func_till'],
      });

      expect(state.completedResearchIds.length, 2);
      expect(state.isCompleted('crop_wheat'), false);
      expect(state.isCompleted('crop_carrot'), false);
      expect(state.isCompleted('crop_potato'), true);
      expect(state.isCompleted('func_till'), true);
    });
  });
}
