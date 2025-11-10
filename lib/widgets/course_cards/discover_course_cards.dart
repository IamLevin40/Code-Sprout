import 'package:flutter/material.dart';
import '../../models/styles_schema.dart';
import 'global_course_cards.dart';

/// Discover course card — compact variant used in Discover section on HomePage
class DiscoverCourseCard extends StatelessWidget {
  final String languageId;
  final String languageName;
  final String difficulty;
  final VoidCallback? onTap;

  const DiscoverCourseCard({
    super.key,
    required this.languageId,
    required this.languageName,
    required this.difficulty,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();
    final width = styles.getStyles('course_cards.discover_card.attribute.width') as double;
    final height = styles.getStyles('course_cards.discover_card.attribute.height') as double;
    final borderRadius = styles.getStyles('course_cards.discover_card.attribute.border_radius') as double;
    final borderWidth = styles.getStyles('course_cards.discover_card.attribute.border_width') as double;

    final marginLeftRight = styles.getStyles('course_cards.discover_card.attribute.margin.left-right') as double;
    final marginTopBottom = styles.getStyles('course_cards.discover_card.attribute.margin.top-bottom') as double;

    final bgGradient = styles.getStyles('course_cards.style_coding.$languageId.background_color') as LinearGradient;
    final strokeGradient = styles.getStyles('course_cards.style_coding.$languageId.stroke_color') as LinearGradient;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: strokeGradient,
        ),
        padding: EdgeInsets.all(borderWidth),
        child: Container(
          decoration: BoxDecoration(
            gradient: bgGradient,
            borderRadius: BorderRadius.circular(borderRadius - borderWidth),
          ),
          padding: EdgeInsets.only(
            left: marginLeftRight,
            right: marginLeftRight,
            top: marginTopBottom,
            bottom: marginTopBottom,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Language icon
              Center(child: GlobalCourseCards.buildLanguageIcon(styles, languageId)),

              // Language name
              Center(child: GlobalCourseCards.buildLanguageName(styles, languageName)),

              // Difficulty label
              Center(child: GlobalCourseCards.buildDifficultyLabel(styles, difficulty)),
              const SizedBox(height: 4),

              // Difficulty leaves
              Builder(builder: (ctx) {
                final leafSize = styles.getStyles('course_cards.general.leaves.width') as double;
                final leafPadding = styles.getStyles('course_cards.general.leaves.padding') as double;
                final leavesTotalWidth = (leafSize * 3) + (leafPadding * 2);
                return Center(
                  child: SizedBox(
                    width: leavesTotalWidth,
                    child: Center(child: GlobalCourseCards.buildDifficultyLeaves(styles, difficulty)),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
