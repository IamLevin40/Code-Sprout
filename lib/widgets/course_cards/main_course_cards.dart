import 'package:flutter/material.dart';
import '../../models/styles_schema.dart';
import '../../models/course_data_schema.dart';
import '../../models/course_data.dart';
import '../../models/user_data.dart';
import 'global_course_cards.dart';
import 'locked_overlay_course_card.dart';
import '../../miscellaneous/single_pass_painters.dart';

/// Main course card widget that displays course information
/// Shows: language icon, difficulty with leaves, progress, chapters count, duration
class MainCourseCard extends StatelessWidget {
  final String languageId;
  final String languageName;
  final String difficulty;
  final double? cardWidth;
  final UserData? userData;
  final VoidCallback? onTap;

  const MainCourseCard({
    super.key,
    required this.languageId,
    required this.languageName,
    required this.difficulty,
    this.cardWidth,
    this.userData,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();

    return FutureBuilder<Map<String, dynamic>>(
      future: _loadCourseData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return GlobalCourseCards.buildLoadingCard(styles, 'main_card', cardWidth: cardWidth);
        }

        if (snapshot.hasError) {
          return GlobalCourseCards.buildErrorCard(styles, 'main_card', cardWidth: cardWidth);
        }

        final data = snapshot.data!;
        return _buildCard(context, styles, data);
      },
    );
  }

  /// Load all course data from schemas
  Future<Map<String, dynamic>> _loadCourseData() async {
    final courseSchema = CourseDataSchema();
    
    // Load module data for this language
    final moduleData = await courseSchema.loadModuleSchema(languageId);
    
    // Get difficulty level
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

    // Calculate total chapters
    final totalChapters = difficultyLevel.chapters.length;

    // Get estimated duration
    final duration = difficultyLevel.estimatedDuration;

    // Get user progress
    int currentChapter = 1;
    int currentModule = 1;
    double progressPercentage = 0.0;

    if (userData != null) {
      try {
        final userDataMap = userData!.toFirestore();
        final progress = courseSchema.getCurrentProgress(
          userData: userDataMap,
          languageId: languageId,
          difficulty: difficulty.toLowerCase(),
        );
        currentChapter = progress['currentChapter'] ?? 1;
        currentModule = progress['currentModule'] ?? 1;

        // Calculate progress percentage
        progressPercentage = await courseSchema.getProgressPercentage(
          userData: userDataMap,
          languageId: languageId,
          difficulty: difficulty.toLowerCase(),
        );
      } catch (e) {
        // If error, use defaults
        currentChapter = 1;
        currentModule = 1;
        progressPercentage = 0.0;
      }
    }

    // Determine locked state using centralized helper in CourseDataSchema
    final isLocked = await courseSchema.isDifficultyLocked(
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

  /// Build the main course card with all information
  Widget _buildCard(BuildContext context, AppStyles styles, Map<String, dynamic> data) {
    final fixedCardWidth = styles.getStyles('course_cards.main_card.attribute.width') as double;
    final maxWidth = styles.getStyles('course_cards.main_card.attribute.max_width') as double;
    final cardHeight = styles.getStyles('course_cards.main_card.attribute.max_height') as double;
    final borderRadius = styles.getStyles('course_cards.main_card.attribute.border_radius') as double;
    final borderWidth = styles.getStyles('course_cards.main_card.attribute.border_width') as double;
    final effectiveWidth = cardWidth ?? fixedCardWidth;

    // Get color coding from styles schema
    final bgGradient = styles.getStyles('course_cards.style_coding.$languageId.background_color') as LinearGradient;
    final strokeGradient = styles.getStyles('course_cards.style_coding.$languageId.stroke_color') as LinearGradient;

    return GestureDetector(
      onTap: data['isLocked'] == true ? null : onTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: cardHeight,
          maxWidth: maxWidth,
        ),
        child: Stack(
          children: [
            // The card itself
            Container(
              width: effectiveWidth,
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
                  left: styles.getStyles('course_cards.main_card.attribute.margin.left-right') as double,
                  right: styles.getStyles('course_cards.main_card.attribute.margin.left-right') as double,
                  top: styles.getStyles('course_cards.main_card.attribute.margin.top-bottom') as double,
                  bottom: styles.getStyles('course_cards.main_card.attribute.margin.top-bottom') as double,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Language icon
                    Align(
                      alignment: Alignment.center,
                      child: GlobalCourseCards.buildLanguageIcon(styles, languageId),
                    ),

                    // Language name
                    Center(child: GlobalCourseCards.buildLanguageName(styles, languageName)),
                    
                    // Difficulty with leaves
                    GlobalCourseCards.buildDifficultyRowCombined(styles, difficulty),
                    const SizedBox(height: 4),

                    // Chapters info
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
                    const SizedBox(height: 8),

                    // Current progress text
                    _buildProgressText(styles, data),
                    const SizedBox(height: 2),

                    // Progress bar
                    _buildProgressBar(styles, data['progressPercentage']),
                  ],
                ),
              ),
            ),

            // Locked overlay (on top if locked)
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
      ),
    );
  }

  /// Build progress text showing current chapter and module
  Widget _buildProgressText(AppStyles styles, Map<String, dynamic> data) {
    final fontSize = styles.getStyles('course_cards.general.progress_text.font_size') as double;
    final fontWeight = styles.getStyles('course_cards.general.progress_text.font_weight') as FontWeight;
    final color = styles.getStyles('course_cards.general.progress_text.color') as Color;

    List<Shadow> textShadows = [];
    try {
      final Color baseColor = styles.getStyles('course_cards.general.progress_text.shadow.color') as Color;
      final sopRaw = styles.getStyles('course_cards.general.progress_text.shadow.opacity');
      final double sop = (sopRaw is num) ? sopRaw.toDouble() / 100.0 : (sopRaw as double);
      final sblur = styles.getStyles('course_cards.general.progress_text.shadow.blur_radius') as double;
      textShadows = [
        Shadow(
          color: baseColor.withAlpha((sop * 255).round()),
          blurRadius: sblur,
        )
      ];
    } catch (e) {
      textShadows = [];
    }

    return Text(
      'Chapter ${data['currentChapter']} | Module ${data['currentModule']}',
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        shadows: textShadows,
      ),
    );
  }

  /// Build progress bar showing completion percentage
  Widget _buildProgressBar(AppStyles styles, double progress) {
    final barHeight = styles.getStyles('course_cards.main_card.progress_bar.height') as double;
    final barBorderRadius = styles.getStyles('course_cards.main_card.progress_bar.border_radius') as double;
    final barBgColor = styles.getStyles('course_cards.main_card.progress_bar.background_color') as LinearGradient;
    final barFillColor = styles.getStyles('course_cards.main_card.progress_bar.fill_color') as Color;
    final fillBorderRadius = styles.getStyles('course_cards.main_card.progress_bar.fill_border_radius') as double;
    final strokeThickness = styles.getStyles('course_cards.main_card.progress_bar.stroke_thickness') as double;
    final strokeGradient = styles.getStyles('course_cards.main_card.progress_bar.stroke_gradient') as LinearGradient;
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
                double innerPadding = styles.getStyles('course_cards.main_card.progress_bar.inner_padding') as double;
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

  /// Format duration from EstimatedDuration object to display string
  String _formatDuration(dynamic duration) {
    if (duration is EstimatedDuration) {
      return '${duration.hours} H ${duration.minutes} M';
    }
    return '0 H 0 M';
  }
}
