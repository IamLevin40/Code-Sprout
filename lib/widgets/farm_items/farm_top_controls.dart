import 'package:flutter/material.dart';
import '../../models/styles_schema.dart';
import '../../models/language_code_files.dart';

/// Top controls for farm page - includes Run button with file selector, Stop and Log buttons
class FarmTopControls extends StatelessWidget {
  final bool isExecuting;
  final LanguageCodeFiles codeFiles;
  final int selectedExecutionFileIndex;
  final VoidCallback onRunPressed;
  final VoidCallback onStopPressed;
  final VoidCallback onLogPressed;
  final VoidCallback onNextFile;
  final VoidCallback onPreviousFile;
  final VoidCallback onClearFarmPressed;

  const FarmTopControls({
    super.key,
    required this.isExecuting,
    required this.codeFiles,
    required this.selectedExecutionFileIndex,
    required this.onRunPressed,
    required this.onStopPressed,
    required this.onLogPressed,
    required this.onNextFile,
    required this.onPreviousFile,
    required this.onClearFarmPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (!isExecuting) {
      return _buildRunButtonWithFileSelector();
    } else {
      return _buildStopAndLogButtons();
    }
  }

  Widget _buildRunButtonWithFileSelector() {
    return Column(
      children: [
        // File selector for execution
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_left, color: Colors.black),
              onPressed: onPreviousFile,
              iconSize: 20,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 102, 87, 87).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                codeFiles.files[selectedExecutionFileIndex].fileName,
                style: const TextStyle(color: Colors.black, fontSize: 12),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_right, color: Colors.black),
              onPressed: onNextFile,
              iconSize: 20,
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Run and Clear Farm buttons side by side
        Row(
          children: [
            Expanded(child: _buildRunButton()),
            const SizedBox(width: 8),
            Expanded(child: _buildClearFarmButton()),
          ],
        ),
      ],
    );
  }

  Widget _buildRunButton() {
    final styles = AppStyles();
    final height = styles.getStyles('farm_page.control_buttons.start_button.height') as double;
    final borderRadius = styles.getStyles('farm_page.control_buttons.start_button.border_radius') as double;
    final borderWidth = styles.getStyles('farm_page.control_buttons.start_button.border_width') as double;
    final bgGradient = styles.getStyles('farm_page.control_buttons.start_button.background_color') as LinearGradient;
    final strokeGradient = styles.getStyles('farm_page.control_buttons.start_button.stroke_color') as LinearGradient;
    final textColor = styles.getStyles('farm_page.control_buttons.start_button.text.color') as Color;
    final fontSize = styles.getStyles('farm_page.control_buttons.start_button.text.font_size') as double;
    final fontWeight = styles.getStyles('farm_page.control_buttons.start_button.text.font_weight') as FontWeight;

    return GestureDetector(
      onTap: onRunPressed,
      child: Container(
        height: height,
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
          alignment: Alignment.center,
          child: Text(
            'Run',
            style: TextStyle(color: textColor, fontSize: fontSize, fontWeight: fontWeight),
          ),
        ),
      ),
    );
  }

  Widget _buildStopAndLogButtons() {
    return Row(
      children: [
        Expanded(child: _buildStopButton()),
        const SizedBox(width: 8),
        Expanded(child: _buildLogButton()),
      ],
    );
  }

  Widget _buildStopButton() {
    final styles = AppStyles();
    final height = styles.getStyles('farm_page.control_buttons.stop_button.height') as double;
    final borderRadius = styles.getStyles('farm_page.control_buttons.stop_button.border_radius') as double;
    final borderWidth = styles.getStyles('farm_page.control_buttons.stop_button.border_width') as double;
    final bgGradient = styles.getStyles('farm_page.control_buttons.stop_button.background_color') as LinearGradient;
    final strokeGradient = styles.getStyles('farm_page.control_buttons.stop_button.stroke_color') as LinearGradient;
    final textColor = styles.getStyles('farm_page.control_buttons.stop_button.text.color') as Color;
    final fontSize = styles.getStyles('farm_page.control_buttons.stop_button.text.font_size') as double;
    final fontWeight = styles.getStyles('farm_page.control_buttons.stop_button.text.font_weight') as FontWeight;

    return GestureDetector(
      onTap: onStopPressed,
      child: Container(
        height: height,
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
          alignment: Alignment.center,
          child: Text(
            'Stop',
            style: TextStyle(color: textColor, fontSize: fontSize, fontWeight: fontWeight),
          ),
        ),
      ),
    );
  }

  Widget _buildClearFarmButton() {
    final styles = AppStyles();
    final height = styles.getStyles('farm_page.control_buttons.start_button.height') as double;
    final borderRadius = styles.getStyles('farm_page.control_buttons.start_button.border_radius') as double;
    final borderWidth = styles.getStyles('farm_page.control_buttons.start_button.border_width') as double;
    
    // Use stop button colors for the Clear Farm button (reddish theme)
    final bgGradient = styles.getStyles('farm_page.control_buttons.stop_button.background_color') as LinearGradient;
    final strokeGradient = styles.getStyles('farm_page.control_buttons.stop_button.stroke_color') as LinearGradient;
    final textColor = styles.getStyles('farm_page.control_buttons.stop_button.text.color') as Color;
    final fontSize = styles.getStyles('farm_page.control_buttons.start_button.text.font_size') as double;
    final fontWeight = styles.getStyles('farm_page.control_buttons.start_button.text.font_weight') as FontWeight;

    return GestureDetector(
      onTap: onClearFarmPressed,
      child: Container(
        height: height,
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
          alignment: Alignment.center,
          child: Text(
            'Clear Farm',
            style: TextStyle(color: textColor, fontSize: fontSize, fontWeight: fontWeight),
          ),
        ),
      ),
    );
  }

  Widget _buildLogButton() {
    final styles = AppStyles();
    final height = styles.getStyles('farm_page.control_buttons.code_button.height') as double;
    final borderRadius = styles.getStyles('farm_page.control_buttons.code_button.border_radius') as double;
    final borderWidth = styles.getStyles('farm_page.control_buttons.code_button.border_width') as double;
    final bgGradient = styles.getStyles('farm_page.control_buttons.code_button.background_color') as LinearGradient;
    final strokeGradient = styles.getStyles('farm_page.control_buttons.code_button.stroke_color') as LinearGradient;
    final textColor = styles.getStyles('farm_page.control_buttons.code_button.text.color') as Color;
    final fontSize = styles.getStyles('farm_page.control_buttons.code_button.text.font_size') as double;
    final fontWeight = styles.getStyles('farm_page.control_buttons.code_button.text.font_weight') as FontWeight;

    return GestureDetector(
      onTap: onLogPressed,
      child: Container(
        height: height,
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
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long, color: textColor, size: fontSize * 1.5),
              const SizedBox(height: 4),
              Text(
                'Log',
                style: TextStyle(color: textColor, fontSize: fontSize * 0.8, fontWeight: fontWeight),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
