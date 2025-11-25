import 'package:flutter/material.dart';
import '../../models/styles_schema.dart';

/// Shows a confirmation dialog to delete a file with FadeTransition animation
///
/// `onConfirm` is called after the dialog is dismissed when the user confirms.
Future<void> showDeleteFileDialog(
  BuildContext context, {
  required String fileName,
  required VoidCallback onConfirm,
}) {
  final styles = AppStyles();
  final transitionMs = (styles.getStyles('farm_page.delete_file_dialog.transition_duration') as num).toInt();
  
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
      return _DeleteFileDialogContent(
        fileName: fileName,
        onConfirm: onConfirm,
      );
    },
  );
}

/// Internal dialog content widget
class _DeleteFileDialogContent extends StatelessWidget {
  final String fileName;
  final VoidCallback onConfirm;

  const _DeleteFileDialogContent({
    required this.fileName,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();
    
    final dialogWidth = styles.getStyles('farm_page.delete_file_dialog.width') as double;
    final bgColor = styles.getStyles('farm_page.delete_file_dialog.background_color') as Color;
    final borderRadius = styles.getStyles('farm_page.delete_file_dialog.border_radius') as double;
    
    final titleColor = styles.getStyles('farm_page.delete_file_dialog.title.color') as Color;
    final titleSize = styles.getStyles('farm_page.delete_file_dialog.title.font_size') as double;
    final titleWeight = styles.getStyles('farm_page.delete_file_dialog.title.font_weight') as FontWeight;
    
    final questionColor = styles.getStyles('farm_page.delete_file_dialog.question_text.color') as Color;
    final questionSize = styles.getStyles('farm_page.delete_file_dialog.question_text.font_size') as double;
    final questionWeight = styles.getStyles('farm_page.delete_file_dialog.question_text.font_weight') as FontWeight;
    
    final fileNameColor = styles.getStyles('farm_page.delete_file_dialog.file_name.color') as Color;
    final fileNameSize = styles.getStyles('farm_page.delete_file_dialog.file_name.font_size') as double;
    final fileNameWeight = styles.getStyles('farm_page.delete_file_dialog.file_name.font_weight') as FontWeight;
    
    final cancelWidth = styles.getStyles('farm_page.delete_file_dialog.cancel_button.width') as double;
    final cancelHeight = styles.getStyles('farm_page.delete_file_dialog.cancel_button.height') as double;
    final cancelBorderRadius = styles.getStyles('farm_page.delete_file_dialog.cancel_button.border_radius') as double;
    final cancelBorderWidth = styles.getStyles('farm_page.delete_file_dialog.cancel_button.border_width') as double;
    final cancelBgColor = styles.getStyles('farm_page.delete_file_dialog.cancel_button.background_color') as Color;
    final cancelStroke = styles.getStyles('farm_page.delete_file_dialog.cancel_button.stroke_color') as LinearGradient;
    final cancelTextColor = styles.getStyles('farm_page.delete_file_dialog.cancel_button.text.color') as Color;
    final cancelTextSize = styles.getStyles('farm_page.delete_file_dialog.cancel_button.text.font_size') as double;
    final cancelTextWeight = styles.getStyles('farm_page.delete_file_dialog.cancel_button.text.font_weight') as FontWeight;
    
    final deleteWidth = styles.getStyles('farm_page.delete_file_dialog.delete_button.width') as double;
    final deleteHeight = styles.getStyles('farm_page.delete_file_dialog.delete_button.height') as double;
    final deleteBorderRadius = styles.getStyles('farm_page.delete_file_dialog.delete_button.border_radius') as double;
    final deleteBorderWidth = styles.getStyles('farm_page.delete_file_dialog.delete_button.border_width') as double;
    final deleteBgGradient = styles.getStyles('farm_page.delete_file_dialog.delete_button.background_color') as LinearGradient;
    final deleteStroke = styles.getStyles('farm_page.delete_file_dialog.delete_button.stroke_color') as LinearGradient;
    final deleteTextColor = styles.getStyles('farm_page.delete_file_dialog.delete_button.text.color') as Color;
    final deleteTextSize = styles.getStyles('farm_page.delete_file_dialog.delete_button.text.font_size') as double;
    final deleteTextWeight = styles.getStyles('farm_page.delete_file_dialog.delete_button.text.font_weight') as FontWeight;

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
              'Delete File',
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
              'Are you sure you want to delete this file?',
              style: TextStyle(
                color: questionColor,
                fontSize: questionSize,
                fontWeight: questionWeight,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            // File name (centered)
            Text(
              fileName,
              style: TextStyle(
                color: fileNameColor,
                fontSize: fileNameSize,
                fontWeight: fileNameWeight,
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
                
                // Delete button
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    onConfirm();
                  },
                  child: Container(
                    width: deleteWidth,
                    height: deleteHeight,
                    decoration: BoxDecoration(
                      gradient: deleteStroke,
                      borderRadius: BorderRadius.circular(deleteBorderRadius),
                    ),
                    padding: EdgeInsets.all(deleteBorderWidth),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: deleteBgGradient,
                        borderRadius: BorderRadius.circular(deleteBorderRadius - deleteBorderWidth),
                      ),
                      child: Center(
                        child: Text(
                          'Delete',
                          style: TextStyle(
                            color: deleteTextColor,
                            fontSize: deleteTextSize,
                            fontWeight: deleteTextWeight,
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
