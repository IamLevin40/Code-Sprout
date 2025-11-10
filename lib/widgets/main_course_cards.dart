import 'package:flutter/material.dart';
import 'dart:ui' as ui show ImageFilter;
import '../models/styles_schema.dart';
import '../models/course_data_schema.dart';
import '../models/course_data.dart';
import '../models/user_data.dart';

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
          return _buildLoadingCard(styles);
        }

        if (snapshot.hasError) {
          return _buildErrorCard(styles);
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

    return {
      'totalChapters': totalChapters,
      'duration': duration,
      'currentChapter': currentChapter,
      'currentModule': currentModule,
      'progressPercentage': progressPercentage,
    };
  }

  /// Build loading placeholder card
  Widget _buildLoadingCard(AppStyles styles) {
    final borderRadius = styles.getStyles('course_cards.main_card.attribute.border_radius') as double;
    final fixedCardWidth = styles.getStyles('course_cards.main_card.attribute.width') as double;
    final cardMaxHeight = styles.getStyles('course_cards.main_card.attribute.max_height') as double;
    final effectiveWidth = cardWidth ?? fixedCardWidth;

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

  /// Build error card when data fails to load
  Widget _buildErrorCard(AppStyles styles) {
    final fixedCardWidth = styles.getStyles('course_cards.main_card.attribute.width') as double;
    final cardMaxHeight = styles.getStyles('course_cards.main_card.attribute.max_height') as double;
    final effectiveWidth = cardWidth ?? fixedCardWidth;
    final borderRadius = styles.getStyles('course_cards.main_card.attribute.border_radius') as double;
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
      onTap: onTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: cardHeight,
          maxWidth: maxWidth,
        ),
        child: Container(
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
                // Language icon (centered)
                Align(
                  alignment: Alignment.center,
                  child: _buildLanguageIcon(styles),
                ),

                // Language name (centered)
                Center(child: _buildLanguageName(styles)),
                const SizedBox(height: 2),

                // Difficulty with leaves
                _buildDifficultyRow(styles),
                const SizedBox(height: 4),

                // Chapters info
                _buildInfoRow(
                  styles,
                  styles.getStyles('course_cards.general.info_row.light.chapter_icon') as String,
                  styles.getStyles('course_cards.general.info_row.light.text_color') as Color,
                  '${data['totalChapters']} Chapters',
                ),
                const SizedBox(height: 2),

                // Duration info
                _buildInfoRow(
                  styles,
                  styles.getStyles('course_cards.general.info_row.light.duration_icon') as String,
                  styles.getStyles('course_cards.general.info_row.light.text_color') as Color,
                  _formatDuration(data['duration']),
                ),
                const SizedBox(height: 4),

                // Current progress text
                _buildProgressText(styles, data),
                const SizedBox(height: 4),

                // Progress bar
                _buildProgressBar(styles, data['progressPercentage']),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build language icon with background
  Widget _buildLanguageIcon(AppStyles styles) {
    final iconSize = styles.getStyles('course_cards.general.language_icon.width') as double;
    final iconBorderRadius = styles.getStyles('course_cards.general.language_icon.border_radius') as double;
    final dynamic iconBg = styles.getStyles('course_cards.general.language_icon.background_color') as LinearGradient;

    return Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        gradient: iconBg,
        borderRadius: BorderRadius.circular(iconBorderRadius),
      ),
      padding: const EdgeInsets.all(12),
      child: Image.asset(
        styles.getStyles('course_cards.style_coding.$languageId.icon') as String,
        fit: BoxFit.contain,
      ),
    );
  }

  /// Build language name text
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
          blurRadius: sblur
        )
      ];
    } catch (e) {
      textShadows = [];
    }

    return Text(
      languageName,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        shadows: textShadows,
      ),
    );
  }

  /// Build difficulty row with leaf indicators
  /// 1 leaf highlighted = Beginner
  /// 2 leaves highlighted = Intermediate  
  /// 3 leaves highlighted = Advanced
  Widget _buildDifficultyRow(AppStyles styles) {
    final fontSize = styles.getStyles('course_cards.general.difficulty.font_size') as double;
    final fontWeight = styles.getStyles('course_cards.general.difficulty.font_weight') as FontWeight;
    final color = styles.getStyles('course_cards.general.difficulty.color') as Color;
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

    return Row(
      children: [
        Text(
          difficulty,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
          ),
        ),
        const Spacer(),
        // Three leaves with proper highlighting
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
                        styles.getStyles('course_cards.general.leaves.icons.highlight') as String,
                        width: leafSize,
                        height: leafSize,
                        color: leafShadowColor.withAlpha((leafShadowOpacity * 255).round()),
                        colorBlendMode: BlendMode.srcIn,
                      ),
                    ),
                  ),

                // Actual leaf image on top
                Image.asset(
                  i < highlightedLeaves 
                      ? styles.getStyles('course_cards.general.leaves.icons.highlight') as String 
                      : styles.getStyles('course_cards.general.leaves.icons.unhighlight') as String,
                  width: leafSize,
                  height: leafSize,
                ),
              ],
            ),
          ),
          if (i < 2) SizedBox(
            width: (styles.getStyles('course_cards.general.leaves.padding') as double)
          ),
        ],
      ],
    );
  }

  /// Build info row with icon and text (used for chapters and duration)
  Widget _buildInfoRow(AppStyles styles, String iconPath, Color textColor, String text) {
    final iconWidth = styles.getStyles('course_cards.general.info_row.icon_width') as double;
    final iconHeight = styles.getStyles('course_cards.general.info_row.icon_height') as double;
    final textFontSize = styles.getStyles('course_cards.general.info_row.text_font_size') as double;
    final textFontWeight = styles.getStyles('course_cards.general.info_row.text_font_weight') as FontWeight;
    final spacing = styles.getStyles('course_cards.general.info_row.spacing') as double;

    return Row(
      children: [
        Image.asset(
          iconPath,
          width: iconWidth,
          height: iconHeight,
        ),
        SizedBox(width: spacing),
        Text(
          text,
          style: TextStyle(
            fontSize: textFontSize,
            fontWeight: textFontWeight,
            color: textColor,
          ),
        ),
      ],
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
        painter: _ProgressBarBackgroundPainter(
          barBg: barBgColor,
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

/// Painter that draws the progress bar background and stroke in a single pass.
class _ProgressBarBackgroundPainter extends CustomPainter {
  final dynamic barBg; // Color or LinearGradient
  final LinearGradient? strokeGradient;
  final Color? strokeColor;
  final double borderRadius;
  final double strokeThickness;

  _ProgressBarBackgroundPainter({
    required this.barBg,
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
    final Paint bgPaint = Paint();
    if (barBg is LinearGradient) {
      bgPaint.shader = (barBg as LinearGradient).createShader(bgRRect.outerRect);
    } else if (barBg is Color) {
      bgPaint.color = barBg as Color;
    }
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
  bool shouldRepaint(covariant _ProgressBarBackgroundPainter oldDelegate) {
    return oldDelegate.barBg != barBg || oldDelegate.strokeGradient != strokeGradient || oldDelegate.strokeColor != strokeColor || oldDelegate.borderRadius != borderRadius || oldDelegate.strokeThickness != strokeThickness;
  }
}