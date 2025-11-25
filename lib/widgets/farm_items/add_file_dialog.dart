import 'package:flutter/material.dart';
import '../../models/language_code_files.dart';
import '../../models/styles_schema.dart';
import '../../miscellaneous/handle_code_files.dart';

/// Shows a dialog to add a new code file
Future<void> showAddFileDialog({
  required BuildContext context,
  required String languageId,
  required LanguageCodeFiles codeFiles,
  required TextEditingController codeController,
  required bool isExecuting,
  required VoidCallback onStateChanged,
}) {
  if (isExecuting) return Future.value();
  
  final styles = AppStyles();
  final transitionMs = styles.getStyles('farm_page.add_file_dialog.transition_duration') as int;
  
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
      return _AddFileDialogContent(
        languageId: languageId,
        codeFiles: codeFiles,
        codeController: codeController,
        onStateChanged: onStateChanged,
      );
    },
  );
}

/// Internal dialog content widget
class _AddFileDialogContent extends StatefulWidget {
  final String languageId;
  final LanguageCodeFiles codeFiles;
  final TextEditingController codeController;
  final VoidCallback onStateChanged;

  const _AddFileDialogContent({
    required this.languageId,
    required this.codeFiles,
    required this.codeController,
    required this.onStateChanged,
  });

  @override
  State<_AddFileDialogContent> createState() => _AddFileDialogContentState();
}

class _AddFileDialogContentState extends State<_AddFileDialogContent> {
  late TextEditingController _fileNameController;
  late String _extension;

  @override
  void initState() {
    super.initState();
    _fileNameController = TextEditingController();
    _extension = LanguageCodeFiles.getFileExtension(widget.languageId);
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    super.dispose();
  }

  void _createFile() {
    final fileName = _fileNameController.text + _extension;
    Navigator.pop(context);
    
    CodeFilesHandler.createFile(
      context: context,
      fileName: fileName,
      codeFiles: widget.codeFiles,
      codeController: widget.codeController,
      languageId: widget.languageId,
      onStateChanged: widget.onStateChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();
    
    final width = styles.getStyles('farm_page.add_file_dialog.width') as double;
    final bgColor = styles.getStyles('farm_page.add_file_dialog.background_color') as Color;
    final borderRadius = styles.getStyles('farm_page.add_file_dialog.border_radius') as double;
    
    final titleColor = styles.getStyles('farm_page.add_file_dialog.title.color') as Color;
    final titleSize = styles.getStyles('farm_page.add_file_dialog.title.font_size') as double;
    final titleWeight = styles.getStyles('farm_page.add_file_dialog.title.font_weight') as FontWeight;
    
    final textboxBorderRadius = styles.getStyles('farm_page.add_file_dialog.textbox.border_radius') as double;
    final textboxBorderWidth = styles.getStyles('farm_page.add_file_dialog.textbox.border_width') as double;
    final textboxBgColor = styles.getStyles('farm_page.add_file_dialog.textbox.background_color') as Color;
    final textboxStroke = styles.getStyles('farm_page.add_file_dialog.textbox.stroke_color') as LinearGradient;
    final placeholderColor = styles.getStyles('farm_page.add_file_dialog.textbox.placeholder_text.color') as Color;
    final placeholderSize = styles.getStyles('farm_page.add_file_dialog.textbox.placeholder_text.font_size') as double;
    final placeholderWeight = styles.getStyles('farm_page.add_file_dialog.textbox.placeholder_text.font_weight') as FontWeight;
    final typeTextColor = styles.getStyles('farm_page.add_file_dialog.textbox.type_text.color') as Color;
    final typeTextSize = styles.getStyles('farm_page.add_file_dialog.textbox.type_text.font_size') as double;
    final typeTextWeight = styles.getStyles('farm_page.add_file_dialog.textbox.type_text.font_weight') as FontWeight;
    
    final extColor = styles.getStyles('farm_page.add_file_dialog.file_extension_label.color') as Color;
    final extSize = styles.getStyles('farm_page.add_file_dialog.file_extension_label.font_size') as double;
    final extWeight = styles.getStyles('farm_page.add_file_dialog.file_extension_label.font_weight') as FontWeight;
    
    final cancelWidth = styles.getStyles('farm_page.add_file_dialog.cancel_button.width') as double;
    final cancelHeight = styles.getStyles('farm_page.add_file_dialog.cancel_button.height') as double;
    final cancelBorderRadius = styles.getStyles('farm_page.add_file_dialog.cancel_button.border_radius') as double;
    final cancelBorderWidth = styles.getStyles('farm_page.add_file_dialog.cancel_button.border_width') as double;
    final cancelBgColor = styles.getStyles('farm_page.add_file_dialog.cancel_button.background_color') as Color;
    final cancelStroke = styles.getStyles('farm_page.add_file_dialog.cancel_button.stroke_color') as LinearGradient;
    final cancelTextColor = styles.getStyles('farm_page.add_file_dialog.cancel_button.text.color') as Color;
    final cancelTextSize = styles.getStyles('farm_page.add_file_dialog.cancel_button.text.font_size') as double;
    final cancelTextWeight = styles.getStyles('farm_page.add_file_dialog.cancel_button.text.font_weight') as FontWeight;
    
    final createWidth = styles.getStyles('farm_page.add_file_dialog.create_button.width') as double;
    final createHeight = styles.getStyles('farm_page.add_file_dialog.create_button.height') as double;
    final createBorderRadius = styles.getStyles('farm_page.add_file_dialog.create_button.border_radius') as double;
    final createBorderWidth = styles.getStyles('farm_page.add_file_dialog.create_button.border_width') as double;
    final createBgGradient = styles.getStyles('farm_page.add_file_dialog.create_button.background_color') as LinearGradient;
    final createStroke = styles.getStyles('farm_page.add_file_dialog.create_button.stroke_color') as LinearGradient;
    final createTextColor = styles.getStyles('farm_page.add_file_dialog.create_button.text.color') as Color;
    final createTextSize = styles.getStyles('farm_page.add_file_dialog.create_button.text.font_size') as double;
    final createTextWeight = styles.getStyles('farm_page.add_file_dialog.create_button.text.font_weight') as FontWeight;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: width,
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
              'Create New File',
              style: TextStyle(
                color: titleColor,
                fontSize: titleSize,
                fontWeight: titleWeight,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            // Textbox with extension label
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: textboxStroke,
                      borderRadius: BorderRadius.circular(textboxBorderRadius),
                    ),
                    padding: EdgeInsets.all(textboxBorderWidth),
                    child: Container(
                      decoration: BoxDecoration(
                        color: textboxBgColor,
                        borderRadius: BorderRadius.circular(textboxBorderRadius - textboxBorderWidth),
                      ),
                      child: TextField(
                        controller: _fileNameController,
                        autofocus: true,
                        style: TextStyle(
                          color: typeTextColor,
                          fontSize: typeTextSize,
                          fontWeight: typeTextWeight,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter file name',
                          hintStyle: TextStyle(
                            color: placeholderColor,
                            fontSize: placeholderSize,
                            fontWeight: placeholderWeight,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onSubmitted: (_) => _createFile(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _extension,
                  style: TextStyle(
                    color: extColor,
                    fontSize: extSize,
                    fontWeight: extWeight,
                  ),
                ),
              ],
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
                
                // Create button
                GestureDetector(
                  onTap: _createFile,
                  child: Container(
                    width: createWidth,
                    height: createHeight,
                    decoration: BoxDecoration(
                      gradient: createStroke,
                      borderRadius: BorderRadius.circular(createBorderRadius),
                    ),
                    padding: EdgeInsets.all(createBorderWidth),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: createBgGradient,
                        borderRadius: BorderRadius.circular(createBorderRadius - createBorderWidth),
                      ),
                      child: Center(
                        child: Text(
                          'Create',
                          style: TextStyle(
                            color: createTextColor,
                            fontSize: createTextSize,
                            fontWeight: createTextWeight,
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
