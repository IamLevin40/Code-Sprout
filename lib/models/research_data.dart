import 'package:flutter/foundation.dart';
import 'research_items_schema.dart';

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
      final available = _getNestedValue(userData, inventoryPath) as int? ?? 0;
      
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

  /// Load completed research from user data
  void loadCompletedResearch(List<String> completedIds) {
    _completedResearchIds.clear();
    _completedResearchIds.addAll(completedIds);
    notifyListeners();
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
