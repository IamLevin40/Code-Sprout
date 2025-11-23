import 'package:flutter/material.dart';
import '../../models/farm_data.dart';
import '../../miscellaneous/handle_farm_progress.dart';

/// Shows a dialog to confirm clearing the farm
void showClearFarmDialog({
  required BuildContext context,
  required FarmState farmState,
}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Clear Farm'),
      content: const Text(
        'Are you sure you want to clear the entire farm?\n\n'
        'All plots will be reset to normal state and the drone will return to (0,0).\n\n'
        'Any crops on plots will be converted back to seeds and returned to your inventory.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            clearFarm(context: context, farmState: farmState);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Clear Farm'),
        ),
      ],
    ),
  );
}

/// Clear the farm and convert crops back to seeds
void clearFarm({
  required BuildContext context,
  required FarmState farmState,
}) {
  farmState.clearFarmToSeeds();
  
  // Save farm progress after clearing
  FarmProgressHandler.saveFarmProgress(farmState: farmState);
  
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Farm cleared! Crops have been returned to inventory as seeds.'),
      duration: Duration(seconds: 2),
    ),
  );
}
