import 'package:flutter/material.dart';
import '../../models/styles_schema.dart';
import '../../models/course_data_schema.dart';
import '../../miscellaneous/glass_effect.dart';
import 'global_course_cards.dart';

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
    final bgColor = styles.getStyles('$prefix.background.color') as Color;
    final bgOpacity = styles.getStyles('$prefix.background.opacity') as double;
    final bgBlurSigma = styles.getStyles('$prefix.background.blur_sigma') as double;
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

    final difficultyFontSize = styles.getStyles('$prefix.difficulty_label.font_size') as double;
    final difficultyFontWeight = styles.getStyles('$prefix.difficulty_label.font_weight') as FontWeight;
    final difficultyColor = styles.getStyles('$prefix.difficulty_label.color') as Color;
    final prevDifficultyDisplay = CourseDataSchema().previousDifficultyDisplay(difficulty);

    return GlassEffect(
      background: bgColor,
      opacity: bgOpacity,
      blurSigma: bgBlurSigma,
      strokeGradient: strokeGradient,
      strokeThickness: strokeThickness,
      borderRadius: borderRadius,
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
            GlobalCourseCards.buildLanguageName(styles, languageName, stylePath: '$prefix.language_name'),

            // Difficulty label (show previous difficulty when locked)
            Text(
              prevDifficultyDisplay,
              style: TextStyle(
                fontSize: difficultyFontSize,
                fontWeight: difficultyFontWeight,
                color: difficultyColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
