import 'package:flutter/material.dart';
import '../../models/styles_schema.dart';
import '../../models/language_code_files.dart';

/// Top controls for farm page - Complete redesign with new layout structure
/// Background container -> "Drone Tab" title -> File selector with navigation -> Control buttons
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
    final styles = AppStyles();
    
    // Get all style tokens from farm_page.top_controls
    final width = styles.getStyles('farm_page.top_controls.width') as double;
    final height = styles.getStyles('farm_page.top_controls.height') as double;
    final borderRadius = styles.getStyles('farm_page.top_controls.border_radius') as double;
    final bgColor = styles.getStyles('farm_page.top_controls.background_color') as Color;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTitle(styles),
          _buildFileSelector(styles),
          const SizedBox(height: 8),
          _buildControlButtons(styles),
        ],
      ),
    );
  }

  // Build the "Drone Tab" title
  Widget _buildTitle(AppStyles styles) {
    final titleColor = styles.getStyles('farm_page.top_controls.title.color') as Color;
    final titleFontSize = styles.getStyles('farm_page.top_controls.title.font_size') as double;
    final titleFontWeight = styles.getStyles('farm_page.top_controls.title.font_weight') as FontWeight;

    return Text(
      'Drone Tab',
      style: TextStyle(
        color: titleColor,
        fontSize: titleFontSize,
        fontWeight: titleFontWeight,
      ),
    );
  }

  // Build file selector with previous/next buttons
  Widget _buildFileSelector(AppStyles styles) {
    final fileNameColor = styles.getStyles('farm_page.top_controls.file_name.color') as Color;
    final fileNameFontSize = styles.getStyles('farm_page.top_controls.file_name.font_size') as double;
    final fileNameFontWeight = styles.getStyles('farm_page.top_controls.file_name.font_weight') as FontWeight;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTabButton(
          styles,
          'farm_page.top_controls.tab_buttons.icons.previous',
          onPreviousFile,
        ),
        const SizedBox(width: 8),
        Container(
          constraints: const BoxConstraints(maxWidth: 180),
          child: Text(
            codeFiles.files.isNotEmpty 
                ? codeFiles.files[selectedExecutionFileIndex].fileName
                : 'No file selected',
            style: TextStyle(
              color: fileNameColor,
              fontSize: fileNameFontSize,
              fontWeight: fileNameFontWeight,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        _buildTabButton(
          styles,
          'farm_page.top_controls.tab_buttons.icons.next',
          onNextFile,
        ),
      ],
    );
  }

  // Build control buttons row based on execution state
  Widget _buildControlButtons(AppStyles styles) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Log button (always visible)
        _buildControlButton(
          styles,
          'log_button',
          'Log',
          onLogPressed,
        ),
        const SizedBox(width: 8),
        if (!isExecuting) ...[
          // Run button
          _buildControlButton(
            styles,
            'run_button',
            'Run',
            onRunPressed,
          ),
          const SizedBox(width: 8),
          // Clear button
          _buildControlButton(
            styles,
            'clear_button',
            'Clear',
            onClearFarmPressed,
          ),
        ] else ...[
          // Stop button
          _buildControlButton(
            styles,
            'stop_button',
            'Stop',
            onStopPressed,
          ),
        ],
      ],
    );
  }

  // Build a tab button (previous/next) with icon
  Widget _buildTabButton(AppStyles styles, String iconPath, VoidCallback? onTap) {
    final width = styles.getStyles('farm_page.top_controls.tab_buttons.width') as double;
    final height = styles.getStyles('farm_page.top_controls.tab_buttons.height') as double;
    final borderRadius = styles.getStyles('farm_page.top_controls.tab_buttons.border_radius') as double;
    final bgColor = styles.getStyles('farm_page.top_controls.tab_buttons.background_color') as Color;
    final icon = styles.getStyles(iconPath) as String;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Center(
          child: Image.asset(
            icon,
            width: 16,
            height: 16,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  // Build a control button (Run, Log, Clear, Stop) with icon + text
  Widget _buildControlButton(
    AppStyles styles,
    String buttonType,
    String label,
    VoidCallback? onTap,
  ) {
    // Get general styles
    final width = styles.getStyles('farm_page.top_controls.control_buttons.general.width') as double;
    final height = styles.getStyles('farm_page.top_controls.control_buttons.general.height') as double;
    final borderRadius = styles.getStyles('farm_page.top_controls.control_buttons.general.border_radius') as double;
    final borderWidth = styles.getStyles('farm_page.top_controls.control_buttons.general.border_width') as double;
    final iconWidth = styles.getStyles('farm_page.top_controls.control_buttons.general.icon.width') as double;
    final iconHeight = styles.getStyles('farm_page.top_controls.control_buttons.general.icon.height') as double;
    final textColor = styles.getStyles('farm_page.top_controls.control_buttons.general.text.color') as Color;
    final fontSize = styles.getStyles('farm_page.top_controls.control_buttons.general.text.font_size') as double;
    final fontWeight = styles.getStyles('farm_page.top_controls.control_buttons.general.text.font_weight') as FontWeight;

    // Get button-specific styles
    final icon = styles.getStyles('farm_page.top_controls.control_buttons.$buttonType.icon') as String;
    final bgGradient = styles.getStyles('farm_page.top_controls.control_buttons.$buttonType.background_color') as LinearGradient;
    final strokeGradient = styles.getStyles('farm_page.top_controls.control_buttons.$buttonType.stroke_color') as LinearGradient;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  icon,
                  width: iconWidth,
                  height: iconHeight,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: fontSize,
                    fontWeight: fontWeight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
