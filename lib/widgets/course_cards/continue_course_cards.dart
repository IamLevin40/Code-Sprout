import 'package:flutter/material.dart';
import '../../models/styles_schema.dart';
import '../../models/course_data_schema.dart';
import '../../models/course_data.dart';
import '../../models/user_data.dart';
import 'global_course_cards.dart';
import '../../miscellaneous/single_pass_painters.dart';

/// Continue course card variant shown on Home page when the user has a
/// lastInteraction record for a language/difficulty and the difficulty is
/// available to continue
class ContinueCourseCard extends StatelessWidget {
  final UserData? userData;
  final VoidCallback? onTap;

  const ContinueCourseCard({
    super.key,
    this.userData,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();

    return FutureBuilder<Map<String, dynamic>>(
      future: _loadFromLastInteraction(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        if (snapshot.hasError || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!;
        if (data['visible'] != true) return const SizedBox.shrink();

        return _buildCard(context, styles, data);
      },
    );
  }

  Future<Map<String, dynamic>> _loadFromLastInteraction() async {
    if (userData == null) return {'visible': false};

    final userMap = userData!.toFirestore();
    final courseSchema = CourseDataSchema();

    final last = courseSchema.getLastInteraction(userData: userMap);
    final String? languageId = last['languageId'] as String?;
    final String? difficulty = last['difficulty'] as String?;

    if (languageId == null || difficulty == null) {
      return {'visible': false};
    }

    // Check lock state: only show if not locked
    final isLocked = await courseSchema.isDifficultyLocked(
      userData: userMap,
      languageId: languageId,
      difficulty: difficulty,
    );

    if (isLocked) return {'visible': false};

    // Load module schema to get display name and duration/chapters
    final moduleData = await courseSchema.loadModuleSchema(languageId);

    DifficultyLevel difficultyLevel;
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        difficultyLevel = moduleData.beginner;
        break;
      case 'intermediate':
        difficultyLevel = moduleData.intermediate;
        break;
      case 'advanced':
        difficultyLevel = moduleData.advanced;
        break;
      default:
        difficultyLevel = moduleData.beginner;
    }

    final totalChapters = difficultyLevel.chapters.length;
    final duration = difficultyLevel.estimatedDuration;

    final progress = await courseSchema.getProgressPercentage(
      userData: userMap,
      languageId: languageId,
      difficulty: difficulty.toLowerCase(),
    );

    final current = courseSchema.getCurrentProgress(
      userData: userMap,
      languageId: languageId,
      difficulty: difficulty.toLowerCase(),
    );

    return {
      'visible': true,
      'languageId': languageId,
      'languageName': moduleData.programmingLanguage,
      'difficulty': difficulty,
      'totalChapters': totalChapters,
      'duration': duration,
      'progressPercentage': progress,
      'currentChapter': current['currentChapter'],
      'currentModule': current['currentModule'],
      'isLocked': isLocked,
    };
  }

  Widget _buildCard(BuildContext context, AppStyles styles, Map<String, dynamic> data) {
    final height = styles.getStyles('course_cards.continue_card.attribute.height') as double;
    final borderRadius = styles.getStyles('course_cards.continue_card.attribute.border_radius') as double;
    final borderWidth = styles.getStyles('course_cards.continue_card.attribute.border_width') as double;
    final paddingLR = styles.getStyles('course_cards.continue_card.attribute.margin.left-right') as double;
    final paddingTB = styles.getStyles('course_cards.continue_card.attribute.margin.top-bottom') as double;

    final bgGradient = styles.getStyles('course_cards.style_coding.${data['languageId']}.background_color') as LinearGradient;
    final strokeGradient = styles.getStyles('course_cards.style_coding.${data['languageId']}.stroke_color') as LinearGradient;

    return GestureDetector(
      onTap: data['isLocked'] == true ? null : onTap,
      child: Container(
        width: double.infinity,
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
            left: paddingLR,
            right: paddingLR,
            top: paddingTB,
            bottom: paddingTB,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: left -> languageName + difficulty + info rows; right -> leaves + icon
              Expanded(
                child: Row(
                  children: [
                    // Left side
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Language name
                          GlobalCourseCards.buildLanguageName(styles, data['languageName'] as String),
                          const SizedBox(height: 4),

                          // Difficulty label
                          GlobalCourseCards.buildDifficultyLabel(styles, data['difficulty'] as String),
                          const SizedBox(height: 8),
                          
                          // Chapter info
                          GlobalCourseCards.buildInfoRow(
                            styles,
                            styles.getStyles('course_cards.general.info_row.light.chapter_icon') as String,
                            styles.getStyles('course_cards.general.info_row.light.text_color') as Color,
                            '${data['totalChapters']} Chapters',
                          ),
                          const SizedBox(height: 2),
                          
                          // Duration info
                          GlobalCourseCards.buildInfoRow(
                            styles,
                            styles.getStyles('course_cards.general.info_row.light.duration_icon') as String,
                            styles.getStyles('course_cards.general.info_row.light.text_color') as Color,
                            _formatDuration(data['duration']),
                          ),
                        ],
                      ),
                    ),

                    // Right side: top-right aligned group (leaves left, language icon right)
                    Align(
                      alignment: Alignment.topRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Difficulty leaves (left)
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: GlobalCourseCards.buildDifficultyLeaves(styles, data['difficulty'] as String),
                          ),
                          const SizedBox(width: 12),

                          // Language icon (right)
                          GlobalCourseCards.buildLanguageIcon(styles, data['languageId'] as String),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Progress text
              GlobalCourseCards.buildProgressText(styles, data),
              const SizedBox(height: 2),

              // Progress bar
              _buildProgressBar(styles, data['progressPercentage'] as double),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(dynamic duration) {
    if (duration is EstimatedDuration) {
      return '${duration.hours} Hours ${duration.minutes} Minutes';
    }
    return '0 Hours 0 Minutes';
  }

  Widget _buildProgressBar(AppStyles styles, double progress) {
    final barHeight = styles.getStyles('course_cards.continue_card.progress_bar.height') as double;
    final barBorderRadius = styles.getStyles('course_cards.continue_card.progress_bar.border_radius') as double;
    final barBgColor = styles.getStyles('course_cards.continue_card.progress_bar.background_color') as LinearGradient;
    final barFillColor = styles.getStyles('course_cards.continue_card.progress_bar.fill_color') as Color;
    final fillBorderRadius = styles.getStyles('course_cards.continue_card.progress_bar.fill_border_radius') as double;
    final strokeThickness = styles.getStyles('course_cards.continue_card.progress_bar.stroke_thickness') as double;
    final strokeGradient = styles.getStyles('course_cards.continue_card.progress_bar.stroke_gradient') as LinearGradient;
    final dynamic strokeBg = strokeGradient;

    return SizedBox(
      height: barHeight + strokeThickness,
      child: CustomPaint(
        painter: SinglePassBackgroundPainter(
          background: barBgColor,
          strokeGradient: strokeBg is LinearGradient ? strokeBg : null,
          strokeColor: strokeBg is Color ? strokeBg : null,
          borderRadius: barBorderRadius,
          strokeThickness: strokeThickness,
        ),
        child: Padding(
          padding: const EdgeInsets.all(0),
          child: Stack(
            children: [
              Builder(builder: (context) {
                double innerPadding = styles.getStyles('course_cards.continue_card.progress_bar.inner_padding') as double;
                final double pct = progress.clamp(0.0, 1.0);
                final BorderRadius fillRadius = pct >= 1.0
                    ? BorderRadius.circular(fillBorderRadius)
                    : BorderRadius.only(
                        topLeft: Radius.circular(fillBorderRadius),
                        bottomLeft: Radius.circular(fillBorderRadius),
                      );

                return Positioned(
                  left: innerPadding + strokeThickness / 2,
                  right: innerPadding + strokeThickness / 2,
                  top: innerPadding + strokeThickness / 2,
                  bottom: innerPadding + strokeThickness / 2,
                  child: ClipRRect(
                    borderRadius: fillRadius,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: pct,
                      child: Container(
                        decoration: BoxDecoration(
                          color: barFillColor,
                          borderRadius: fillRadius,
                        ),
                      ),
                    ),
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
