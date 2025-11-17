import 'package:flutter/material.dart';
import '../../models/styles_schema.dart';
import '../course_cards/global_course_cards.dart';

class CurrentLanguageCard extends StatelessWidget {
  final String? selectedLanguageId;
  final Map<String, String> languageNames;
  final List<String> availableLanguages;
  final ValueChanged<String> onLanguageSelected;

  const CurrentLanguageCard({
    super.key,
    required this.selectedLanguageId,
    required this.languageNames,
    required this.availableLanguages,
    required this.onLanguageSelected,
  });

  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();

    final height = styles.getStyles('sprout_page.current_language_card.height') as double;
    final borderRadius = styles.getStyles('sprout_page.current_language_card.border_radius') as double;
    final borderWidth = styles.getStyles('sprout_page.current_language_card.border_width') as double;

    final String? langId = selectedLanguageId;
    final String langDisplay = (langId != null) ? (languageNames[langId] ?? langId) : '—';

    if (langId == null || langId.isEmpty || availableLanguages.isEmpty) {
      final placeholderColor = styles.getStyles('sprout_page.current_language_card.placeholder.color') as Color;
      return Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: placeholderColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Center(child: SizedBox(child: CircularProgressIndicator(strokeWidth: borderWidth))),
      );
    }

    final bgGradient = styles.getStyles('course_cards.style_coding.$langId.background_color') as LinearGradient;
    final strokeGradient = styles.getStyles('course_cards.style_coding.$langId.stroke_color') as LinearGradient;

    return Container(
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Left column: static label, language name, change button
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Static label
                  Builder(builder: (ctx) {
                    final fontSize = styles.getStyles('sprout_page.current_language_card.static_label.font_size') as double;
                    final color = styles.getStyles('sprout_page.current_language_card.static_label.color') as Color;
                    final fontWeight = styles.getStyles('sprout_page.current_language_card.static_label.font_weight') as FontWeight;
                    return Text('Current Language', style: TextStyle(fontSize: fontSize, color: color, fontWeight: fontWeight));
                  }),

                  // Language name
                  Builder(builder: (ctx) {
                    const base = 'sprout_page.current_language_card.language_name';
                    final fontSize = styles.getStyles('$base.font_size') as double;
                    final fontWeight = styles.getStyles('$base.font_weight') as FontWeight;
                    final color = styles.getStyles('$base.color') as Color;

                    // Shadow (optional in schema) - follow same extraction pattern as other helpers
                    List<Shadow> textShadows = [];
                    try {
                      final Color baseColor = styles.getStyles('$base.shadow.color') as Color;
                      final sopRaw = styles.getStyles('$base.shadow.opacity');
                      final double sop = (sopRaw is num) ? sopRaw.toDouble() / 100.0 : (sopRaw as double);
                      final sblur = styles.getStyles('$base.shadow.blur_radius') as double;
                      textShadows = [Shadow(color: baseColor.withAlpha((sop * 255).round()), blurRadius: sblur)];
                    } catch (_) {
                      textShadows = [];
                    }

                    return Text(
                      langDisplay,
                      style: TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: color, shadows: textShadows),
                    );
                  }),

                  // Change button
                  Builder(builder: (ctx) {
                    const prefix = 'sprout_page.current_language_card.change_button';
                    final btnWidth = styles.getStyles('$prefix.width') as double;
                    final btnHeight = styles.getStyles('$prefix.height') as double;
                    final btnRadius = styles.getStyles('$prefix.border_radius') as double;
                    final btnBorder = styles.getStyles('$prefix.border_width') as double;
                    final btnBg = styles.getStyles('$prefix.background_color') as LinearGradient;
                    final btnStroke = styles.getStyles('$prefix.stroke_color') as LinearGradient;
                    final textColor = styles.getStyles('$prefix.text.color') as Color;
                    final textSize = styles.getStyles('$prefix.text.font_size') as double;
                    final textWeight = styles.getStyles('$prefix.text.font_weight') as FontWeight;

                    return GestureDetector(
                      onTap: () {
                        _showLanguagePicker(ctx);
                      },
                      child: Container(
                        width: btnWidth,
                        height: btnHeight,
                        decoration: BoxDecoration(
                          gradient: btnStroke,
                          borderRadius: BorderRadius.circular(btnRadius),
                        ),
                        padding: EdgeInsets.all(btnBorder),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: btnBg,
                            borderRadius: BorderRadius.circular(btnRadius - btnBorder),
                          ),
                          alignment: Alignment.center,
                          child: Text('Change', style: TextStyle(color: textColor, fontSize: textSize, fontWeight: textWeight)),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Right column: language icon
            Align(
              alignment: Alignment.centerRight,
              child: Builder(builder: (ctx) {
                final iconId = langId;
                return GlobalCourseCards.buildLanguageIcon(AppStyles(), iconId);
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            itemBuilder: (c, i) {
              final id = availableLanguages[i];
              final display = languageNames[id] ?? id;
              return ListTile(
                title: Text(display),
                onTap: () {
                  Navigator.of(context).pop();
                  onLanguageSelected(id);
                },
              );
            },
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemCount: availableLanguages.length,
          ),
        );
      },
    );
  }
}
