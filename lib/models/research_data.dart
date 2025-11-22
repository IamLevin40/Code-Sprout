import 'package:flutter/foundation.dart';

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

/// Base class for research items with common properties
abstract class ResearchItem {
  final String id;
  final String name;
  final String description;
  final String? imagePath;
  final List<String> predecessorIds; // IDs of research items that must be completed first
  final Map<String, int> requirements; // Required items from inventory (itemPath: quantity)

  ResearchItem({
    required this.id,
    required this.name,
    required this.description,
    this.imagePath,
    required this.predecessorIds,
    required this.requirements,
  });

  /// Check if all predecessors are completed
  bool arePredecessorsMet(Set<String> completedResearchIds) {
    if (predecessorIds.isEmpty) return true;
    return predecessorIds.every((id) => completedResearchIds.contains(id));
  }

  /// Check if user has enough inventory items
  bool areRequirementsMet(Map<String, dynamic> userInventory) {
    for (final entry in requirements.entries) {
      final itemPath = entry.key;
      final required = entry.value;
      final available = _getNestedValue(userInventory, itemPath) as int? ?? 0;
      
      if (available < required) {
        return false;
      }
    }
    return true;
  }

  /// Helper to get nested value from map using dot notation
  dynamic _getNestedValue(Map<String, dynamic> map, String path) {
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

/// Crop research item
class CropResearchItem extends ResearchItem {
  final String cropType; // e.g., "wheat", "carrot"

  CropResearchItem({
    required super.id,
    required super.name,
    required super.description,
    super.imagePath,
    required super.predecessorIds,
    required super.requirements,
    required this.cropType,
  });
}

/// Farm research item
class FarmResearchItem extends ResearchItem {
  final String farmFeature; // e.g., "plot_expansion", "irrigation"

  FarmResearchItem({
    required super.id,
    required super.name,
    required super.description,
    super.imagePath,
    required super.predecessorIds,
    required super.requirements,
    required this.farmFeature,
  });
}

/// Functions research item
class FunctionsResearchItem extends ResearchItem {
  final String functionName; // e.g., "plant", "harvest"

  FunctionsResearchItem({
    required super.id,
    required super.name,
    required super.description,
    super.imagePath,
    required super.predecessorIds,
    required super.requirements,
    required this.functionName,
  });
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
  CropResearchState getCropResearchState(CropResearchItem item) {
    if (_completedResearchIds.contains(item.id)) {
      return CropResearchState.purchase;
    }
    
    if (item.arePredecessorsMet(_completedResearchIds)) {
      return CropResearchState.toBeResearched;
    }
    
    return CropResearchState.locked;
  }

  /// Get the current state of a farm research item
  FarmResearchState getFarmResearchState(FarmResearchItem item) {
    if (_completedResearchIds.contains(item.id)) {
      return FarmResearchState.unlocked;
    }
    
    if (item.arePredecessorsMet(_completedResearchIds)) {
      return FarmResearchState.toBeResearched;
    }
    
    return FarmResearchState.locked;
  }

  /// Get the current state of a functions research item
  FunctionsResearchState getFunctionsResearchState(FunctionsResearchItem item) {
    if (_completedResearchIds.contains(item.id)) {
      return FunctionsResearchState.unlocked;
    }
    
    if (item.arePredecessorsMet(_completedResearchIds)) {
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
