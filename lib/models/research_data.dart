import 'package:flutter/foundation.dart';
import 'research_items_schema.dart';
import '../services/firestore_service.dart';

/// Enum representing the state of a crop research card
enum CropResearchState {
  purchase,        // Available for purchase/use
  toBeResearched,  // Prerequisites met, can be researched
  locked,          // Prerequisites not met yet
}

/// Enum representing the state of a farm research card
enum FarmResearchState {
  unlocked,        // Research completed and unlocked
  toBeResearched,  // Prerequisites met, can be researched
  locked,          // Prerequisites not met yet
}

/// Enum representing the state of a functions research card
enum FunctionsResearchState {
  unlocked,        // Research completed and unlocked
  toBeResearched,  // Prerequisites met, can be researched
  locked,          // Prerequisites not met yet
}

/// Helper class to check research requirements
class ResearchRequirements {
  /// Check if all predecessors are completed
  static bool arePredecessorsMet(
    List<String> predecessorIds,
    Set<String> completedResearchIds,
  ) {
    if (predecessorIds.isEmpty) return true;
    return predecessorIds.every((id) => completedResearchIds.contains(id));
  }

  /// Check if user has enough inventory items
  /// Requirements map uses simplified item IDs (e.g., "wheat", "carrot")
  static bool areRequirementsMet(
    Map<String, int> requirements,
    Map<String, dynamic> userData,
  ) {
    for (final entry in requirements.entries) {
      final itemId = entry.key;
      final required = entry.value;
      
      // Access inventory using the path: sproutProgress.inventory.{itemId}.quantity
      final inventoryPath = 'sproutProgress.inventory.$itemId.quantity';
      final available = (_getNestedValue(userData, inventoryPath) as num?)?.toInt() ?? 0;
      
      if (available < required) {
        return false;
      }
    }
    return true;
  }

  /// Helper to get nested value from map using dot notation
  static dynamic _getNestedValue(Map<String, dynamic> map, String path) {
    final keys = path.split('.');
    dynamic current = map;
    
    for (final key in keys) {
      if (current is Map) {
        current = current[key];
      } else {
        return null;
      }
    }
    
    return current;
  }
}

/// Research state manager that tracks completed research
class ResearchState extends ChangeNotifier {
  final Set<String> _completedResearchIds = {};
  
  /// Get all completed research IDs
  Set<String> get completedResearchIds => Set.unmodifiable(_completedResearchIds);

  /// Check if a research is completed
  bool isCompleted(String researchId) {
    return _completedResearchIds.contains(researchId);
  }

  /// Mark a research as completed
  void completeResearch(String researchId) {
    if (!_completedResearchIds.contains(researchId)) {
      _completedResearchIds.add(researchId);
      notifyListeners();
    }
  }

  /// Unlock inventory items for a completed crop research
  /// Returns list of unlocked item IDs
  static Future<List<String>> unlockInventoryItems({
    required String researchId,
    required List<String> itemIds,
    required String userId,
  }) async {
    final List<String> unlockedItems = [];
    
    try {
      // Get current user data
      final userData = await FirestoreService.getUserData(userId, forceRefresh: true);
      if (userData == null) {
        debugPrint('User data not found for unlocking items');
        return unlockedItems;
      }
      
      // Unlock each item in the list
      for (final itemId in itemIds) {
        final isLockedPath = 'sproutProgress.inventory.$itemId.isLocked';
        final currentLockState = userData.get(isLockedPath) as bool? ?? true;
        
        // Only unlock if currently locked
        if (currentLockState) {
          await userData.updateFields({isLockedPath: false});
          unlockedItems.add(itemId);
          debugPrint('Unlocked item: $itemId from research: $researchId');
        }
      }
      
      // Save to Firestore
      if (unlockedItems.isNotEmpty) {
        await FirestoreService.updateUserData(userData);
        debugPrint('Successfully unlocked ${unlockedItems.length} items for research $researchId');
      }
    } catch (e) {
      debugPrint('Error unlocking inventory items for research $researchId: $e');
    }
    
    return unlockedItems;
  }

  /// Load completed research from user data
  void loadCompletedResearch(List<String> completedIds) {
    _completedResearchIds.clear();
    _completedResearchIds.addAll(completedIds);
    notifyListeners();
  }

  /// Load research progress from Firestore format
  /// Expected format: {
  ///   "crop_researches": ["crop_wheat", ...],
  ///   "farm_researches": ["farm_3x3", ...],
  ///   "functions_researches": ["func_move", ...]
  /// }
  void loadFromFirestore(Map<String, dynamic> firestoreData) {
    _completedResearchIds.clear();
    
    // Load crop researches
    final cropResearches = firestoreData['crop_researches'] as List?;
    if (cropResearches != null) {
      _completedResearchIds.addAll(cropResearches.cast<String>());
    }
    
    // Load farm researches
    final farmResearches = firestoreData['farm_researches'] as List?;
    if (farmResearches != null) {
      _completedResearchIds.addAll(farmResearches.cast<String>());
    }
    
    // Load functions researches
    final functionsResearches = firestoreData['functions_researches'] as List?;
    if (functionsResearches != null) {
      _completedResearchIds.addAll(functionsResearches.cast<String>());
    }
    
    notifyListeners();
  }

  /// Export research progress to Firestore format with separate lists
  Map<String, List<String>> exportToFirestore() {
    final cropResearches = <String>[];
    final farmResearches = <String>[];
    final functionsResearches = <String>[];
    
    for (final id in _completedResearchIds) {
      if (id.startsWith('crop_')) {
        cropResearches.add(id);
      } else if (id.startsWith('farm_')) {
        farmResearches.add(id);
      } else if (id.startsWith('func_')) {
        functionsResearches.add(id);
      }
    }
    
    return {
      'crop_researches': cropResearches,
      'farm_researches': farmResearches,
      'functions_researches': functionsResearches,
    };
  }

  /// Get completed crop research IDs
  List<String> get completedCropResearches {
    return _completedResearchIds
        .where((id) => id.startsWith('crop_'))
        .toList();
  }

  /// Get completed farm research IDs
  List<String> get completedFarmResearches {
    return _completedResearchIds
        .where((id) => id.startsWith('farm_'))
        .toList();
  }

  /// Get completed functions research IDs
  List<String> get completedFunctionsResearches {
    return _completedResearchIds
        .where((id) => id.startsWith('func_'))
        .toList();
  }

  /// Get the current state of a crop research item
  CropResearchState getCropResearchState(CropResearchItemSchema item) {
    if (_completedResearchIds.contains(item.id)) {
      return CropResearchState.purchase;
    }
    
    if (ResearchRequirements.arePredecessorsMet(item.predecessorIds, _completedResearchIds)) {
      return CropResearchState.toBeResearched;
    }
    
    return CropResearchState.locked;
  }

  /// Get the current state of a farm research item
  FarmResearchState getFarmResearchState(FarmResearchItemSchema item) {
    if (_completedResearchIds.contains(item.id)) {
      return FarmResearchState.unlocked;
    }
    
    if (ResearchRequirements.arePredecessorsMet(item.predecessorIds, _completedResearchIds)) {
      return FarmResearchState.toBeResearched;
    }
    
    return FarmResearchState.locked;
  }

  /// Get the current state of a functions research item
  FunctionsResearchState getFunctionsResearchState(FunctionsResearchItemSchema item) {
    if (_completedResearchIds.contains(item.id)) {
      return FunctionsResearchState.unlocked;
    }
    
    if (ResearchRequirements.arePredecessorsMet(item.predecessorIds, _completedResearchIds)) {
      return FunctionsResearchState.toBeResearched;
    }
    
    return FunctionsResearchState.locked;
  }

  /// Reset all research (for testing)
  void reset() {
    _completedResearchIds.clear();
    notifyListeners();
  }
}
