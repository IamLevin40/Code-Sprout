import 'package:flutter/material.dart';
import '../../models/styles_schema.dart';
import '../../models/course_data_schema.dart';
import '../../models/course_data.dart';
import '../../models/user_data.dart';
import 'global_course_cards.dart';
import 'locked_overlay_course_card.dart';

/// Recommended course card variant
class RecommendedCourseCard extends StatelessWidget {
  final String languageId;
  final String languageName;
  final String difficulty;
  final UserData? userData;
  final VoidCallback? onTap;

  const RecommendedCourseCard({
    super.key,
    required this.languageId,
    required this.languageName,
    required this.difficulty,
    this.userData,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();

    return FutureBuilder<Map<String, dynamic>>(
      future: _loadCourseData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return GlobalCourseCards.buildLoadingCard(styles, 'recommended_card');
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return GlobalCourseCards.buildErrorCard(styles, 'recommended_card');
        }

        final data = snapshot.data!;
        return _buildCard(context, styles, data);
      },
    );
  }

  Future<Map<String, dynamic>> _loadCourseData() async {
    final courseSchema = CourseDataSchema();
    final moduleData = await courseSchema.loadModuleSchema(languageId);

    // Determine difficulty level block
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

    // Get user progress (use CourseDataSchema helpers)
    int currentChapter = 1;
    int currentModule = 1;
    double progressPercentage = 0.0;

    if (userData != null) {
      try {
        final userDataMap = userData!.toFirestore();
        final progress = CourseDataSchema().getCurrentProgress(
          userData: userDataMap,
          languageId: languageId,
          difficulty: difficulty.toLowerCase(),
        );
        currentChapter = progress['currentChapter'] ?? 1;
        currentModule = progress['currentModule'] ?? 1;

        progressPercentage = await CourseDataSchema().getProgressPercentage(
          userData: userDataMap,
          languageId: languageId,
          difficulty: difficulty.toLowerCase(),
        );
      } catch (e) {
        currentChapter = 1;
        currentModule = 1;
        progressPercentage = 0.0;
      }
    }

    // Determine locked state using centralized helper in CourseDataSchema
    final isLocked = await CourseDataSchema().isDifficultyLocked(
      userData: userData?.toFirestore(),
      languageId: languageId,
      difficulty: difficulty,
    );

    return {
      'totalChapters': totalChapters,
      'duration': duration,
      'currentChapter': currentChapter,
      'currentModule': currentModule,
      'progressPercentage': progressPercentage,
      'isLocked': isLocked,
    };
  }

  Widget _buildCard(BuildContext context, AppStyles styles, Map<String, dynamic> data) {
    final width = styles.getStyles('course_cards.recommended_card.attribute.width') as double;
    final height = styles.getStyles('course_cards.recommended_card.attribute.height') as double;
    final borderRadius = styles.getStyles('course_cards.recommended_card.attribute.border_radius') as double;

    final bgGradient = styles.getStyles('course_cards.style_coding.$languageId.background_color') as LinearGradient;
    final strokeGradient = styles.getStyles('course_cards.style_coding.$languageId.stroke_color') as LinearGradient;
    final borderWidth = styles.getStyles('course_cards.recommended_card.attribute.border_width') as double;

    final chapters = (data['totalChapters'] as num).toInt();
    final duration = data['duration'];

    return GestureDetector(
      onTap: data['isLocked'] == true ? null : onTap,
      child: Stack(
        children: [
          Container(
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
              child: Padding(
                padding: EdgeInsets.only(
                  left: styles.getStyles('course_cards.recommended_card.attribute.margin.left-right') as double,
                  right: styles.getStyles('course_cards.recommended_card.attribute.margin.left-right') as double,
                  top: styles.getStyles('course_cards.recommended_card.attribute.margin.top-bottom') as double,
                  bottom: styles.getStyles('course_cards.recommended_card.attribute.margin.top-bottom') as double,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left column: language name and difficulty
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Language name
                              GlobalCourseCards.buildLanguageName(styles, languageName),

                              // Difficulty with leaves
                              GlobalCourseCards.buildDifficultyLabel(styles, difficulty),
                              const SizedBox(height: 4),
                              GlobalCourseCards.buildDifficultyLeaves(styles, difficulty),
                            ],
                          ),
                        ),

                        // Right: language icon
                        GlobalCourseCards.buildLanguageIcon(styles, languageId),
                      ],
                    ),

                    const Spacer(),

                    // Bottom info
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: styles.getStyles('course_cards.recommended_card.bottom_info.background_color') as LinearGradient,
                        borderRadius: BorderRadius.circular(styles.getStyles('course_cards.recommended_card.bottom_info.border_radius') as double),
                      ),
                      padding: EdgeInsets.only(
                        left: styles.getStyles('course_cards.recommended_card.bottom_info.margin.left-right') as double,
                        right: styles.getStyles('course_cards.recommended_card.bottom_info.margin.left-right') as double,
                        top: styles.getStyles('course_cards.recommended_card.bottom_info.margin.top-bottom') as double,
                        bottom: styles.getStyles('course_cards.recommended_card.bottom_info.margin.top-bottom') as double,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Chapters info
                          GlobalCourseCards.buildInfoRow(styles, styles.getStyles('course_cards.general.info_row.dark.chapter_icon') as String, styles.getStyles('course_cards.general.info_row.dark.text_color') as Color, '$chapters Chapters'),
                          const SizedBox(height: 2),
                          
                          // Duration info
                          GlobalCourseCards.buildInfoRow(styles, styles.getStyles('course_cards.general.info_row.dark.duration_icon') as String, styles.getStyles('course_cards.general.info_row.dark.text_color') as Color, _formatDuration(duration)),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),

          if (data['isLocked'] == true)
            Positioned.fill(
              child: LockedOverlayCourseCard(
                styles: styles,
                languageName: languageName,
                difficulty: difficulty,
                borderRadius: (borderRadius - borderWidth).clamp(0.0, borderRadius),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDuration(dynamic duration) {
    if (duration is EstimatedDuration) {
      return '${duration.hours} Hours ${duration.minutes} Minutes';
    }
    return duration?.toString() ?? '0 Hours 0 Minutes';
  }
}
