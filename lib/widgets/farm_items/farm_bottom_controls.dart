import 'package:flutter/material.dart';
import '../../models/styles_schema.dart';

/// Bottom controls for farm page - Complete redesign with new layout structure
/// Features a HUD bar at the bottom with Code, Inventory, and Research buttons
/// Each button displays icon (left) + text (right) layout
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
    final styles = AppStyles();
    
    // Get HUD styling
    final hudHeight = styles.getStyles('farm_page.bottom_controls.hud.height') as double;
    final hudBorderRadius = styles.getStyles('farm_page.bottom_controls.hud.border_radius') as double;
    final hudBgColor = styles.getStyles('farm_page.bottom_controls.hud.background_color') as Color;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Control buttons row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildControlButton(styles, 'code', 'Code', onCodePressed),
            const SizedBox(width: 8),
            _buildControlButton(styles, 'inventory', 'Inventory', onInventoryPressed),
            const SizedBox(width: 8),
            _buildControlButton(styles, 'research', 'Research', onResearchPressed),
          ],
        ),
        // HUD bar at the bottom
        Container(
          width: double.infinity,
          height: hudHeight,
          decoration: BoxDecoration(
            color: hudBgColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(hudBorderRadius),
              topRight: Radius.circular(hudBorderRadius),
            ),
          ),
        ),
      ],
    );
  }

  /// Build a control button with icon (left) + text (right) layout
  Widget _buildControlButton(
    AppStyles styles,
    String buttonType,
    String label,
    VoidCallback onTap,
  ) {
    // Get button styling from farm_page.bottom_controls
    final width = styles.getStyles('farm_page.bottom_controls.control_buttons.width') as double;
    final height = styles.getStyles('farm_page.bottom_controls.control_buttons.height') as double;
    final borderRadius = styles.getStyles('farm_page.bottom_controls.control_buttons.border_radius') as double;
    final borderWidth = styles.getStyles('farm_page.bottom_controls.control_buttons.border_width') as double;
    final bgGradient = styles.getStyles('farm_page.bottom_controls.control_buttons.background_color') as LinearGradient;
    final strokeGradient = styles.getStyles('farm_page.bottom_controls.control_buttons.stroke_color') as LinearGradient;
    
    // Get text styling
    final textColor = styles.getStyles('farm_page.bottom_controls.control_buttons.text.color') as Color;
    final fontSize = styles.getStyles('farm_page.bottom_controls.control_buttons.text.font_size') as double;
    final fontWeight = styles.getStyles('farm_page.bottom_controls.control_buttons.text.font_weight') as FontWeight;
    
    // Get icon styling
    final iconWidth = styles.getStyles('farm_page.bottom_controls.control_buttons.icon.width') as double;
    final iconHeight = styles.getStyles('farm_page.bottom_controls.control_buttons.icon.height') as double;
    final iconPath = styles.getStyles('farm_page.bottom_controls.control_buttons.icon.images.$buttonType') as String;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: strokeGradient,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(borderRadius),
            topRight: Radius.circular(borderRadius),
          ),
        ),
        padding: EdgeInsets.all(borderWidth),
        child: Container(
          decoration: BoxDecoration(
            gradient: bgGradient,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(borderRadius - borderWidth),
              topRight: Radius.circular(borderRadius - borderWidth),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                iconPath,
                width: iconWidth,
                height: iconHeight,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 8),
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
    );
  }
}
