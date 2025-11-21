import 'package:flutter/material.dart';
import '../../models/styles_schema.dart';

/// Bottom controls for farm page - includes Code, Inventory, and Research buttons
class FarmBottomControls extends StatelessWidget {
  final VoidCallback onCodePressed;
  final VoidCallback onInventoryPressed;
  final VoidCallback onResearchPressed;

  const FarmBottomControls({
    super.key,
    required this.onCodePressed,
    required this.onInventoryPressed,
    required this.onResearchPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: _buildCodeButton()),
        const SizedBox(width: 8),
        Expanded(child: _buildInventoryButton()),
        const SizedBox(width: 8),
        Expanded(child: _buildResearchButton()),
      ],
    );
  }

  Widget _buildCodeButton() {
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
      onTap: onCodePressed,
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
              Icon(Icons.code, color: textColor, size: fontSize * 1.5),
              const SizedBox(height: 4),
              Text(
                'Drone Code',
                style: TextStyle(color: textColor, fontSize: fontSize * 0.8, fontWeight: fontWeight),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInventoryButton() {
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
      onTap: onInventoryPressed,
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
              Icon(Icons.inventory_2, color: textColor, size: fontSize * 1.5),
              const SizedBox(height: 4),
              Text(
                'Inventory',
                style: TextStyle(color: textColor, fontSize: fontSize * 0.8, fontWeight: fontWeight),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResearchButton() {
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
      onTap: onResearchPressed,
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
              Icon(Icons.menu_book, color: textColor, size: fontSize * 1.5),
              const SizedBox(height: 4),
              Text(
                'Research',
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

