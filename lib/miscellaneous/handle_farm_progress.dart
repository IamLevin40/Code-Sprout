import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/farm_data.dart';
import '../services/farm_progress_service.dart';

/// Handles farm progress loading and saving operations
class FarmProgressHandler {
  /// Load farm progress from Firestore and apply to farm state
  static Future<void> loadFarmProgress({
    required FarmState farmState,
    required VoidCallback onFarmStateChanged,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // No user logged in, add listener and return
        farmState.addListener(onFarmStateChanged);
        return;
      }

      // Check if farm progress exists first
      final exists = await FarmProgressService.farmProgressExists(userId: user.uid);
      
      if (exists) {
        // Load existing progress
        final progress = await FarmProgressService.loadFarmProgress(userId: user.uid);
        
        if (progress != null) {
          // Apply progress to existing farm state WITHOUT triggering auto-save
          FarmProgressService.applyProgressToFarmState(
            farmState: farmState,
            progress: progress,
          );
          
          // NOW add listener after progress is loaded
          farmState.addListener(onFarmStateChanged);
        }
      } else {
        // No existing progress, use default and add listener
        // This will trigger auto-save to create the initial progress
        farmState.addListener(onFarmStateChanged);
      }
    } catch (e) {
      // Silent fail - don't interrupt user experience
      // Add listener even if loading fails
      farmState.addListener(onFarmStateChanged);
      debugPrint('Failed to load farm progress: $e');
    }
  }

  /// Save farm progress to Firestore
  static Future<void> saveFarmProgress({
    required FarmState farmState,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FarmProgressService.saveFarmProgress(
        userId: user.uid,
        farmState: farmState,
      );
    } catch (e) {
      // Silent fail - don't interrupt user experience
      debugPrint('Failed to save farm progress: $e');
    }
  }
}
