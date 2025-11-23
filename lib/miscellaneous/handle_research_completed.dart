import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/research_data.dart';
import '../models/research_items_schema.dart';
import '../models/farm_data.dart';
import '../services/local_storage_service.dart';
import '../services/firestore_service.dart';

/// Handles research completion operations
class ResearchCompletionHandler {
  /// Handle research completion: deduct items from inventory and mark as completed
  /// Requirements use simplified item IDs (e.g., "wheat", "carrot")
  static Future<void> handleResearchCompleted({
    required BuildContext context,
    required String researchId,
    required Map<String, int> requirements,
    required ResearchState researchState,
    required FarmState farmState,
  }) async {
    try {
      final userData = LocalStorageService.instance.userDataNotifier.value;
      if (userData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User data not available')),
        );
        return;
      }
      
      // Deduct items from inventory using simplified paths
      for (final entry in requirements.entries) {
        final itemId = entry.key; // Simplified ID like "wheat", "carrot"
        final required = entry.value;
        final itemPath = 'sproutProgress.inventory.$itemId.quantity';
        final currentValue = userData.get(itemPath) as int? ?? 0;
        final newValue = currentValue - required;
        
        if (newValue < 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Insufficient items in inventory')),
          );
          return;
        }
        
        userData.set(itemPath, newValue);
      }
      
      // Mark research as completed
      researchState.completeResearch(researchId);
      await FirestoreService.updateUserData(userData);
      
      // Unlock inventory items if this is a crop research
      if (researchId.startsWith('crop_')) {
        final researchSchema = ResearchItemsSchema.instance.getCropItem(researchId);
        if (researchSchema != null && researchSchema.itemUnlocks.isNotEmpty) {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            await ResearchState.unlockInventoryItems(
              researchId: researchId,
              itemIds: researchSchema.itemUnlocks,
              userId: user.uid,
            );
          }
        }
      }
      
      // Apply farm research conditions if this is a farm research
      if (researchId.startsWith('farm_')) {
        farmState.applyFarmResearchConditions();
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Research completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to complete research: $e')),
        );
      }
    }
  }
}
