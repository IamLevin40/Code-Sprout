import 'package:flutter/material.dart';
import '../../models/farm_data.dart';
import '../../models/styles_schema.dart';
import '../../miscellaneous/handle_farm_progress.dart';
import 'notification_display.dart';

/// Shows a dialog to confirm clearing the farm with FadeTransition animation
Future<void> showClearFarmDialog({
  required BuildContext context,
  required FarmState farmState,
  required NotificationController notificationController,
}) {
  final styles = AppStyles();
  final transitionMs = (styles.getStyles('farm_page.clear_farm_dialog.transition_duration') as num).toInt();
  
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    transitionDuration: Duration(milliseconds: transitionMs),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        ),
        child: child,
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) {
      return _ClearFarmDialogContent(
        farmState: farmState,
        notificationController: notificationController,
      );
    },
  );
}

/// Internal dialog content widget
class _ClearFarmDialogContent extends StatelessWidget {
  final FarmState farmState;
  final NotificationController notificationController;

  const _ClearFarmDialogContent({
    required this.farmState,
    required this.notificationController,
  });

  void _clearFarm(BuildContext context) {
    Navigator.pop(context);
    
    farmState.clearFarmToSeeds();
    
    // Save farm progress after clearing
    FarmProgressHandler.saveFarmProgress(farmState: farmState);
    
    // Show success notification
    notificationController.showSuccess(
      'Farm cleared! Crops have been returned to inventory as seeds.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();
    
    final dialogWidth = styles.getStyles('farm_page.clear_farm_dialog.width') as double;
    final bgColor = styles.getStyles('farm_page.clear_farm_dialog.background_color') as Color;
    final borderRadius = styles.getStyles('farm_page.clear_farm_dialog.border_radius') as double;
    
    final titleColor = styles.getStyles('farm_page.clear_farm_dialog.title.color') as Color;
    final titleSize = styles.getStyles('farm_page.clear_farm_dialog.title.font_size') as double;
    final titleWeight = styles.getStyles('farm_page.clear_farm_dialog.title.font_weight') as FontWeight;
    
    final questionColor = styles.getStyles('farm_page.clear_farm_dialog.question_text.color') as Color;
    final questionSize = styles.getStyles('farm_page.clear_farm_dialog.question_text.font_size') as double;
    final questionWeight = styles.getStyles('farm_page.clear_farm_dialog.question_text.font_weight') as FontWeight;
    final plainTextColor = styles.getStyles('farm_page.clear_farm_dialog.plain_text.color') as Color;
    final plainTextSize = styles.getStyles('farm_page.clear_farm_dialog.plain_text.font_size') as double;
    final plainTextWeight = styles.getStyles('farm_page.clear_farm_dialog.plain_text.font_weight') as FontWeight;
    
    final cancelWidth = styles.getStyles('farm_page.clear_farm_dialog.cancel_button.width') as double;
    final cancelHeight = styles.getStyles('farm_page.clear_farm_dialog.cancel_button.height') as double;
    final cancelBorderRadius = styles.getStyles('farm_page.clear_farm_dialog.cancel_button.border_radius') as double;
    final cancelBorderWidth = styles.getStyles('farm_page.clear_farm_dialog.cancel_button.border_width') as double;
    final cancelBgColor = styles.getStyles('farm_page.clear_farm_dialog.cancel_button.background_color') as Color;
    final cancelStroke = styles.getStyles('farm_page.clear_farm_dialog.cancel_button.stroke_color') as LinearGradient;
    final cancelTextColor = styles.getStyles('farm_page.clear_farm_dialog.cancel_button.text.color') as Color;
    final cancelTextSize = styles.getStyles('farm_page.clear_farm_dialog.cancel_button.text.font_size') as double;
    final cancelTextWeight = styles.getStyles('farm_page.clear_farm_dialog.cancel_button.text.font_weight') as FontWeight;
    
    final clearWidth = styles.getStyles('farm_page.clear_farm_dialog.clear_button.width') as double;
    final clearHeight = styles.getStyles('farm_page.clear_farm_dialog.clear_button.height') as double;
    final clearBorderRadius = styles.getStyles('farm_page.clear_farm_dialog.clear_button.border_radius') as double;
    final clearBorderWidth = styles.getStyles('farm_page.clear_farm_dialog.clear_button.border_width') as double;
    final clearBgGradient = styles.getStyles('farm_page.clear_farm_dialog.clear_button.background_color') as LinearGradient;
    final clearStroke = styles.getStyles('farm_page.clear_farm_dialog.clear_button.stroke_color') as LinearGradient;
    final clearTextColor = styles.getStyles('farm_page.clear_farm_dialog.clear_button.text.color') as Color;
    final clearTextSize = styles.getStyles('farm_page.clear_farm_dialog.clear_button.text.font_size') as double;
    final clearTextWeight = styles.getStyles('farm_page.clear_farm_dialog.clear_button.text.font_weight') as FontWeight;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: dialogWidth,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title (centered)
            Text(
              'Clear Farm',
              style: TextStyle(
                color: titleColor,
                fontSize: titleSize,
                fontWeight: titleWeight,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            // Question text (centered)
            Text(
              'Are you sure you want to clear the entire farm?',
              style: TextStyle(
                color: questionColor,
                fontSize: questionSize,
                fontWeight: questionWeight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Plain text (centered)
            Text(
              'All plots will be reset to normal state and the drone will return to (0,0).\n\n'
              'Any crops on plots will be converted back to seeds and returned to your inventory.',
              style: TextStyle(
                color: plainTextColor,
                fontSize: plainTextSize,
                fontWeight: plainTextWeight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Buttons (centered)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Cancel button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: cancelWidth,
                    height: cancelHeight,
                    decoration: BoxDecoration(
                      gradient: cancelStroke,
                      borderRadius: BorderRadius.circular(cancelBorderRadius),
                    ),
                    padding: EdgeInsets.all(cancelBorderWidth),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cancelBgColor,
                        borderRadius: BorderRadius.circular(cancelBorderRadius - cancelBorderWidth),
                      ),
                      child: Center(
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: cancelTextColor,
                            fontSize: cancelTextSize,
                            fontWeight: cancelTextWeight,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Clear button
                GestureDetector(
                  onTap: () => _clearFarm(context),
                  child: Container(
                    width: clearWidth,
                    height: clearHeight,
                    decoration: BoxDecoration(
                      gradient: clearStroke,
                      borderRadius: BorderRadius.circular(clearBorderRadius),
                    ),
                    padding: EdgeInsets.all(clearBorderWidth),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: clearBgGradient,
                        borderRadius: BorderRadius.circular(clearBorderRadius - clearBorderWidth),
                      ),
                      child: Center(
                        child: Text(
                          'Clear',
                          style: TextStyle(
                            color: clearTextColor,
                            fontSize: clearTextSize,
                            fontWeight: clearTextWeight,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
