import 'package:flutter/material.dart';
import '../../models/styles_schema.dart';

/// Locked overlay widget displayed on top of course cards when a difficulty is locked
class LockedOverlayCourseCard extends StatelessWidget {
  final AppStyles styles;
  final String languageName;
  final String difficulty;
  final double borderRadius;

  const LockedOverlayCourseCard({
    super.key,
    required this.styles,
    required this.languageName,
    required this.difficulty,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    const prefix = 'course_cards.general.locked_overlay';
    final bgColor = styles.getStyles('$prefix.background_color') as Color;
    final strokeThickness = styles.getStyles('$prefix.stroke_thickness') as double;
    final strokeGradient = styles.getStyles('$prefix.stroke_gradient') as LinearGradient;
    final contentPadLR = styles.getStyles('$prefix.margin.left-right') as double;
    final contentPadTB = styles.getStyles('$prefix.margin.top-bottom') as double;

    final iconPath = styles.getStyles('$prefix.icon.image') as String;
    final iconWidth = styles.getStyles('$prefix.icon.width') as double;
    final iconHeight = styles.getStyles('$prefix.icon.height') as double;

    final requiresFontSize = styles.getStyles('$prefix.requires_text.font_size') as double;
    final requiresFontWeight = styles.getStyles('$prefix.requires_text.font_weight') as FontWeight;
    final requiresColor = styles.getStyles('$prefix.requires_text.color') as Color;

    final languageFontSize = styles.getStyles('$prefix.language_name.font_size') as double;
    final languageFontWeight = styles.getStyles('$prefix.language_name.font_weight') as FontWeight;
    final languageColor = styles.getStyles('$prefix.language_name.color') as Color;

    List<Shadow> languageShadows = [];
    try {
      final lsColor = styles.getStyles('$prefix.language_name.shadow.color') as Color;
      final lsOpacityRaw = styles.getStyles('$prefix.language_name.shadow.opacity');
      final lsOpacity = (lsOpacityRaw is num) ? lsOpacityRaw.toDouble() / 100.0 : (lsOpacityRaw as double);
      final lsBlur = styles.getStyles('$prefix.language_name.shadow.blur_radius') as double;
      languageShadows = [Shadow(color: lsColor.withAlpha((lsOpacity * 255).round()), blurRadius: lsBlur)];
    } catch (_) {
      languageShadows = [];
    }

    final difficultyFontSize = styles.getStyles('$prefix.difficulty_label.font_size') as double;
    final difficultyFontWeight = styles.getStyles('$prefix.difficulty_label.font_weight') as FontWeight;
    final difficultyColor = styles.getStyles('$prefix.difficulty_label.color') as Color;

    return CustomPaint(
      painter: _LockedOverlayBackgroundPainter(
        bgColor: bgColor,
        strokeGradient: strokeGradient,
        strokeColor: null,
        borderRadius: borderRadius,
        strokeThickness: strokeThickness,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: contentPadLR + strokeThickness,
          vertical: contentPadTB + strokeThickness,
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Lock icon
              if (iconPath.isNotEmpty)
                Center(
                  child: Image.asset(
                    iconPath,
                    width: iconWidth,
                    height: iconHeight,
                  ),
                ),
              const SizedBox(height: 2),

              // "Requires"
              Text(
                'Requires',
                style: TextStyle(
                  fontSize: requiresFontSize,
                  fontWeight: requiresFontWeight,
                  color: requiresColor,
                ),
              ),
              const SizedBox(height: 6),

              // Language name
              Text(
                languageName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: languageFontSize,
                  fontWeight: languageFontWeight,
                  color: languageColor,
                  shadows: languageShadows,
                ),
              ),

              // Difficulty label
              Text(
                difficulty,
                style: TextStyle(
                  fontSize: difficultyFontSize,
                  fontWeight: difficultyFontWeight,
                  color: difficultyColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Painter that draws the locked overlay background and stroke in a single pass.
class _LockedOverlayBackgroundPainter extends CustomPainter {
  final Color bgColor;
  final LinearGradient? strokeGradient;
  final Color? strokeColor;
  final double borderRadius;
  final double strokeThickness;

  _LockedOverlayBackgroundPainter({
    required this.bgColor,
    this.strokeGradient,
    this.strokeColor,
    required this.borderRadius,
    required this.strokeThickness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;

    // Draw background (fill)
    final RRect bgRRect = RRect.fromRectAndRadius(rect.deflate(strokeThickness / 2), Radius.circular(borderRadius));
    final Paint bgPaint = Paint()..color = bgColor;
    canvas.drawRRect(bgRRect, bgPaint);

    // Draw stroke
    if (strokeGradient != null || strokeColor != null) {
      final Paint strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeThickness;
      if (strokeGradient != null) {
        strokePaint.shader = strokeGradient!.createShader(rect);
      } else if (strokeColor != null) {
        strokePaint.color = strokeColor!;
      }
      canvas.drawRRect(bgRRect, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LockedOverlayBackgroundPainter oldDelegate) {
    return oldDelegate.bgColor != bgColor || oldDelegate.strokeGradient != strokeGradient || oldDelegate.strokeColor != strokeColor || oldDelegate.borderRadius != borderRadius || oldDelegate.strokeThickness != strokeThickness;
  }
}
