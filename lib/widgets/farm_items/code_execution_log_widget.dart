import 'package:flutter/material.dart';
import '../../models/styles_schema.dart';

/// Widget that displays code execution logs with auto-scroll functionality
class CodeExecutionLogWidget extends StatelessWidget {
  final ValueNotifier<List<String>> logNotifier;
  final ScrollController scrollController;
  final bool autoScrollEnabled;
  final VoidCallback onClose;

  const CodeExecutionLogWidget({
    super.key,
    required this.logNotifier,
    required this.scrollController,
    required this.autoScrollEnabled,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();
    
    final bgGradient = styles.getStyles('farm_page.execution_log.background_color') as LinearGradient;
    final borderRadius = styles.getStyles('farm_page.execution_log.border_radius') as double;
    final borderWidth = styles.getStyles('farm_page.execution_log.border_width') as double;
    final strokeGradient = styles.getStyles('farm_page.execution_log.stroke_color') as LinearGradient;
    final textColor = styles.getStyles('farm_page.execution_log.text_color') as Color;
    final fontSize = styles.getStyles('farm_page.execution_log.font_size') as double;
    final fontWeight = styles.getStyles('farm_page.execution_log.font_weight') as FontWeight;
    
    // Get close button styles
    final closeIcon = styles.getStyles('sprout_page.language_selection.close_button.icon') as String;
    final closeW = styles.getStyles('sprout_page.language_selection.close_button.width') as double;
    final closeH = styles.getStyles('sprout_page.language_selection.close_button.height') as double;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: strokeGradient,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      padding: EdgeInsets.all(borderWidth),
      child: Container(
        decoration: BoxDecoration(
          gradient: bgGradient,
          borderRadius: BorderRadius.circular(borderRadius - borderWidth),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Execution Log',
                  style: TextStyle(
                    color: textColor,
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: onClose,
                  child: Image.asset(closeIcon, width: closeW, height: closeH),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ValueListenableBuilder<List<String>>(
                valueListenable: logNotifier,
                builder: (context, logs, _) {
                  // Auto-scroll to bottom when new logs arrive and auto-scroll is enabled
                  if (autoScrollEnabled && scrollController.hasClients) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (scrollController.hasClients && autoScrollEnabled) {
                        scrollController.animateTo(
                          scrollController.position.maxScrollExtent,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    });
                  }
                  
                  return SingleChildScrollView(
                    controller: scrollController,
                    child: Text(
                      logs.isEmpty ? 'No execution yet...' : logs.join('\n'),
                      style: TextStyle(
                        color: textColor,
                        fontSize: fontSize,
                        fontWeight: fontWeight,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
