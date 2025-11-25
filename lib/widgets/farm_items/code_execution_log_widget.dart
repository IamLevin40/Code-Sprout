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
    
    final bgColor = styles.getStyles('farm_page.execution_log.background_color') as Color;
    final borderRadius = styles.getStyles('farm_page.execution_log.border_radius') as double;
    final borderWidth = styles.getStyles('farm_page.execution_log.border_width') as double;
    final strokeGradient = styles.getStyles('farm_page.execution_log.stroke_color') as LinearGradient;
    
    // Get title styles
    final titleColor = styles.getStyles('farm_page.execution_log.title.color') as Color;
    final titleSize = styles.getStyles('farm_page.execution_log.title.font_size') as double;
    final titleWeight = styles.getStyles('farm_page.execution_log.title.font_weight') as FontWeight;
    
    // Get message log styles
    final messageColor = styles.getStyles('farm_page.execution_log.message_logs.color') as Color;
    final messageSize = styles.getStyles('farm_page.execution_log.message_logs.font_size') as double;
    final messageWeight = styles.getStyles('farm_page.execution_log.message_logs.font_weight') as FontWeight;
    
    // Get close button styles
    final closeIcon = styles.getStyles('farm_page.execution_log.close_button.icon') as String;
    final closeW = styles.getStyles('farm_page.execution_log.close_button.width') as double;
    final closeH = styles.getStyles('farm_page.execution_log.close_button.height') as double;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: strokeGradient,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      padding: EdgeInsets.all(borderWidth),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
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
                    color: titleColor,
                    fontSize: titleSize,
                    fontWeight: titleWeight,
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
                        color: messageColor,
                        fontSize: messageSize,
                        fontWeight: messageWeight,
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
