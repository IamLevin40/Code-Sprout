import 'package:flutter/material.dart';
import 'dart:ui' as ui show ImageFilter;
import '../../models/styles_schema.dart';

/// Shared helpers for course card widgets
class GlobalCourseCards {
  /// Build loading placeholder card for the provided card type
  /// cardType should match the key under `course_cards`, e.g. 'main_card' or 'recommended_card'
  static Widget buildLoadingCard(AppStyles styles, String cardType, {double? cardWidth}) {
    final prefix = 'course_cards.$cardType.attribute';
    final borderRadius = styles.getStyles('$prefix.border_radius') as double;
    final fixedCardWidth = styles.getStyles('$prefix.width') as double;
    final cardMaxHeight = styles.getStyles('$prefix.max_height') as double;
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
  static Widget buildErrorCard(AppStyles styles, String cardType, {double? cardWidth}) {
    final prefix = 'course_cards.$cardType.attribute';
    final fixedCardWidth = styles.getStyles('$prefix.width') as double;
    final cardMaxHeight = styles.getStyles('$prefix.max_height') as double;
    final effectiveWidth = cardWidth ?? fixedCardWidth;
    final borderRadius = styles.getStyles('$prefix.border_radius') as double;

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

  /// Language icon widget (uses language-specific icon from styles schema)
  static Widget buildLanguageIcon(AppStyles styles, String languageId) {
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

  /// Language name text with optional shadow support defined in styles
  static Widget buildLanguageName(AppStyles styles, String languageName) {
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
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        shadows: textShadows,
      ),
    );
  }

  /// Difficulty label text only
  static Widget buildDifficultyLabel(AppStyles styles, String difficulty) {
    final fontSize = styles.getStyles('course_cards.general.difficulty.font_size') as double;
    final fontWeight = styles.getStyles('course_cards.general.difficulty.font_weight') as FontWeight;
    final color = styles.getStyles('course_cards.general.difficulty.color') as Color;

    return Text(
      difficulty,
      style: TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: color),
    );
  }

  /// Difficulty leaves widget (1-3 highlighted based on difficulty)
  static Widget buildDifficultyLeaves(AppStyles styles, String difficulty) {
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

                Image.asset(
                  i < highlightedLeaves ? highlightPath : unhighlightPath,
                  width: leafSize,
                  height: leafSize,
                ),
              ],
            ),
          ),
          if (i < 2) SizedBox(width: (styles.getStyles('course_cards.general.leaves.padding') as double)),
        ],
      ],
    );
  }

  /// Combined difficulty row used by MainCourseCard (label + spacer + leaves)
  static Widget buildDifficultyRowCombined(AppStyles styles, String difficulty) {
    return Row(
      children: [
        buildDifficultyLabel(styles, difficulty),
        const Spacer(),
        buildDifficultyLeaves(styles, difficulty),
      ],
    );
  }

  /// Info row shared between variants
  static Widget buildInfoRow(AppStyles styles, String iconPath, Color textColor, String text) {
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
}
