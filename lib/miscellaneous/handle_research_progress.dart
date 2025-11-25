import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/farm_data.dart';
import '../models/research_data.dart';
import '../services/farm_progress_service.dart';

/// Handles research progress loading and saving operations
class ResearchProgressHandler {
  /// Load research progress from Firestore
  static Future<void> loadResearchProgress({
    required ResearchState researchState,
    required FarmState farmState,
    required VoidCallback onResearchStateChanged,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // No user logged in, add listener and return
        researchState.addListener(onResearchStateChanged);
        return;
      }

      // Check if research progress exists first
      final exists = await FarmProgressService.researchProgressExists(userId: user.uid);
      
      if (exists) {
        // Load existing research progress
        final progress = await FarmProgressService.loadResearchProgress(userId: user.uid);
        
        if (progress != null) {
          // Apply progress to research state WITHOUT triggering auto-save
          researchState.loadFromFirestore(progress);
          
          // NOW add listener after progress is loaded
          researchState.addListener(onResearchStateChanged);
          
          // Ensure farm grid updates according to completed researches
          try {
            farmState.applyFarmResearchConditions();
          } catch (e) {
            debugPrint('Failed to apply farm research conditions on load: $e');
          }
        }
      } else {
        // No existing progress, use default and add listener
        // This will trigger auto-save to create the initial progress
        researchState.addListener(onResearchStateChanged);
      }
    } catch (e) {
      // Silent fail - don't interrupt user experience
      // Add listener even if loading fails
      researchState.addListener(onResearchStateChanged);
      debugPrint('Failed to load research progress: $e');
    }
  }

  /// Save research progress to Firestore
  static Future<void> saveResearchProgress({
    required ResearchState researchState,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final exportData = researchState.exportToFirestore();
      await FarmProgressService.saveResearchProgress(
        userId: user.uid,
        cropResearches: exportData['crop_researches']!,
        farmResearches: exportData['farm_researches']!,
        functionsResearches: exportData['functions_researches']!,
      );
    } catch (e) {
      // Silent fail - don't interrupt user experience
      debugPrint('Failed to save research progress: $e');
    }
  }
}
