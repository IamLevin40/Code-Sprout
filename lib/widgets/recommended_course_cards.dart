import 'package:flutter/material.dart';
import 'dart:ui' as ui show ImageFilter;
import '../models/styles_schema.dart';
import '../models/course_data_schema.dart';
import '../models/course_data.dart';
import '../models/user_data.dart';

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
          return _buildLoadingCard(styles);
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return _buildErrorCard(styles);
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

    return {
      'totalChapters': totalChapters,
      'duration': duration,
      'currentChapter': currentChapter,
      'currentModule': currentModule,
      'progressPercentage': progressPercentage,
    };
  }

  Widget _buildLoadingCard(AppStyles styles) {
    final fixedCardWidth = styles.getStyles('course_cards.recommended_card.attribute.width') as double;
    final cardMaxHeight = styles.getStyles('course_cards.recommended_card.attribute.max_height') as double;
    final borderRadius = styles.getStyles('course_cards.recommended_card.attribute.border_radius') as double;
    final effectiveWidth = fixedCardWidth;

    return Container(
      width: effectiveWidth,
      height: cardMaxHeight,
      decoration: BoxDecoration(
        color: styles.getStyles('course_cards.general.placeholder.color') as Color,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorCard(AppStyles styles) {
    final fixedCardWidth = styles.getStyles('course_cards.recommended_card.attribute.width') as double;
    final cardMaxHeight = styles.getStyles('course_cards.recommended_card.attribute.max_height') as double;
    final borderRadius = styles.getStyles('course_cards.recommended_card.attribute.border_radius') as double;
    final effectiveWidth = fixedCardWidth;

    return Container(
      width: effectiveWidth,
      height: cardMaxHeight,
      decoration: BoxDecoration(
        color: styles.getStyles('course_cards.general.error.color') as Color,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Icon(
          Icons.error,
          color: styles.getStyles('course_cards.general.error.color') as Color,
          size: styles.getStyles('course_cards.general.error.icon_size') as double,
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, AppStyles styles, Map<String, dynamic> data) {
    final width = styles.getStyles('course_cards.recommended_card.attribute.width') as double;
    final height = styles.getStyles('course_cards.recommended_card.attribute.height') as double;
    final borderRadius = styles.getStyles('course_cards.recommended_card.attribute.border_radius') as double;

    final bgGradient = styles.getStyles('course_cards.style_coding.$languageId.background_color') as LinearGradient;
    final strokeGradient = styles.getStyles('course_cards.style_coding.$languageId.stroke_color') as LinearGradient;
    final borderWidth = styles.getStyles('course_cards.recommended_card.attribute.border_width') as double;

    final chapters = data['totalChapters'] as int;
    final duration = data['duration'];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
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
                          _buildLanguageName(styles),
                          _buildDifficultyLabel(styles),
                          const SizedBox(height: 4),
                          _buildDifficultyLeaves(styles),
                        ],
                      ),
                    ),

                    // Right: language icon
                    _buildLanguageIcon(styles),
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
                      _buildInfoRow(styles, styles.getStyles('course_cards.general.info_row.dark.chapter_icon') as String, styles.getStyles('course_cards.general.info_row.dark.text_color') as Color, '$chapters Chapters'),
                      const SizedBox(height: 2),
                      _buildInfoRow(styles, styles.getStyles('course_cards.general.info_row.dark.duration_icon') as String, styles.getStyles('course_cards.general.info_row.dark.text_color') as Color, _formatDuration(duration)),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageIcon(AppStyles styles) {
    final iconSizeW = styles.getStyles('course_cards.general.language_icon.width') as double;
    final iconSizeH = styles.getStyles('course_cards.general.language_icon.height') as double;
    final iconRadius = styles.getStyles('course_cards.general.language_icon.border_radius') as double;
    final iconBg = styles.getStyles('course_cards.general.language_icon.background_color') as LinearGradient;

    return Container(
      width: iconSizeW,
      height: iconSizeH,
      decoration: BoxDecoration(
        gradient: iconBg,
        borderRadius: BorderRadius.circular(iconRadius),
      ),
      child: Center(child: Image.asset(styles.getStyles('course_cards.style_coding.$languageId.icon') as String, width: iconSizeW * 0.6, height: iconSizeH * 0.6)),
    );
  }

  Widget _buildLanguageName(AppStyles styles) {
    final fontSize = styles.getStyles('course_cards.general.language_name.font_size') as double;
    final fontWeight = styles.getStyles('course_cards.general.language_name.font_weight') as FontWeight;
    final color = styles.getStyles('course_cards.general.language_name.color') as Color;
    List<Shadow> textShadows = [];
    try {
      final Color baseColor = styles.getStyles('course_cards.general.language_name.shadow.color') as Color;
      final sopRaw = styles.getStyles('course_cards.general.language_name.shadow.opacity');
      final double sop = (sopRaw is num) ? sopRaw.toDouble() / 100.0 : (sopRaw as double);
      final sblur = styles.getStyles('course_cards.general.language_name.shadow.blur_radius') as double;
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
      languageName,
      style: TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: color, shadows: textShadows),
    );
  }

  Widget _buildDifficultyLabel(AppStyles styles) {
    final fontSize = styles.getStyles('course_cards.general.difficulty.font_size') as double;
    final fontWeight = styles.getStyles('course_cards.general.difficulty.font_weight') as FontWeight;
    final color = styles.getStyles('course_cards.general.difficulty.color') as Color;

    return Text(
      difficulty,
      style: TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: color),
    );
  }

  Widget _buildDifficultyLeaves(AppStyles styles) {
    final leafSize = styles.getStyles('course_cards.general.leaves.width') as double;
    Color? leafShadowColor;
    double? leafShadowOpacity;
    double? leafShadowBlur;
    try {
      leafShadowColor = styles.getStyles('course_cards.general.leaves.highlight_shadow.color') as Color;
      final lopRaw = styles.getStyles('course_cards.general.leaves.highlight_shadow.opacity');
      leafShadowOpacity = (lopRaw is num) ? lopRaw.toDouble() / 100.0 : (lopRaw as double);
      leafShadowBlur = styles.getStyles('course_cards.general.leaves.highlight_shadow.blur_radius') as double;
    } catch (e) {
      leafShadowColor = null;
      leafShadowOpacity = null;
      leafShadowBlur = null;
    }

    // Determine leaf count based on difficulty
    int highlightedLeaves = 0;
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        highlightedLeaves = 1;
        break;
      case 'intermediate':
        highlightedLeaves = 2;
        break;
      case 'advanced':
        highlightedLeaves = 3;
        break;
    }

    final highlightPath = styles.getStyles('course_cards.general.leaves.icons.highlight') as String;
    final unhighlightPath = styles.getStyles('course_cards.general.leaves.icons.unhighlight') as String;

    return Row(
      children: [
        // Three leaves with proper highlighting and shadow for highlighted ones
        for (int i = 0; i < 3; i++) ...[
          SizedBox(
            width: leafSize,
            height: leafSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (i < highlightedLeaves && leafShadowColor != null && leafShadowOpacity != null && leafShadowBlur != null)
                  Transform.translate(
                    offset: const Offset(0.0, 0.0),
                    child: ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(sigmaX: leafShadowBlur, sigmaY: leafShadowBlur),
                      child: Image.asset(
                        highlightPath,
                        width: leafSize,
                        height: leafSize,
                        color: leafShadowColor.withAlpha((leafShadowOpacity * 255).round()),
                        colorBlendMode: BlendMode.srcIn,
                      ),
                    ),
                  ),

                // Actual leaf image on top
                Image.asset(
                  i < highlightedLeaves ? highlightPath : unhighlightPath,
                  width: leafSize,
                  height: leafSize,
                ),
              ],
            ),
          ),
          if (i < 2)
            SizedBox(width: (styles.getStyles('course_cards.general.leaves.padding') as double)),
        ],
      ],
    );
  }

  Widget _buildInfoRow(AppStyles styles, String iconPath, Color textColor, String text) {
    final iconW = styles.getStyles('course_cards.general.info_row.icon_width') as double;
    final iconH = styles.getStyles('course_cards.general.info_row.icon_height') as double;
    final spacing = styles.getStyles('course_cards.general.info_row.spacing') as double;
    final fontSize = styles.getStyles('course_cards.general.info_row.text_font_size') as double;
    final fontWeight = styles.getStyles('course_cards.general.info_row.text_font_weight') as FontWeight;

    return Row(
      children: [
        Image.asset(iconPath, width: iconW, height: iconH),
        SizedBox(width: spacing),
        Text(text, style: TextStyle(color: textColor, fontSize: fontSize, fontWeight: fontWeight)),
      ],
    );
  }

  String _formatDuration(dynamic duration) {
    if (duration is EstimatedDuration) {
      return '${duration.hours} Hours ${duration.minutes} Minutes';
    }
    return duration?.toString() ?? '0 Hours 0 Minutes';
  }
}
