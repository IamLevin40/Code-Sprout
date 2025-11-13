import 'package:flutter/material.dart';
import '../models/styles_schema.dart';
import '../models/course_data_schema.dart';
import '../models/course_data.dart';

class ModuleListPage extends StatelessWidget {
  final String languageId;
  final String difficulty;

  const ModuleListPage({super.key, required this.languageId, required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();
    final bgGradient = styles.getStyles('course_cards.style_coding.$languageId.background_color') as LinearGradient;
    final strokeGradient = styles.getStyles('course_cards.style_coding.$languageId.stroke_color') as LinearGradient;

    final titleColor = styles.getStyles('module_list_page.title.color') as Color;
    final titleFontSize = styles.getStyles('module_list_page.title.font_size') as double;
    final titleFontWeight = styles.getStyles('module_list_page.title.font_weight') as FontWeight;
    final subtitleColor = styles.getStyles('module_list_page.subtitle.color') as Color;
    final subtitleFontSize = styles.getStyles('module_list_page.subtitle.font_size') as double;

    final borderRadius = styles.getStyles('module_list_page.card.border_radius') as double;
    final borderWidth = styles.getStyles('module_list_page.card.border_width') as double;
    final horizontalMargin = styles.getStyles('module_list_page.card.margin.left-right') as double;
    final verticalMargin = styles.getStyles('module_list_page.card.margin.top-bottom') as double;
    final cardPadding = styles.getStyles('module_list_page.card.padding') as double;

    final iconWidth = styles.getStyles('module_list_page.icon.width') as double;
    final iconHeight = styles.getStyles('module_list_page.icon.height') as double;
    final iconBorderRadius = styles.getStyles('module_list_page.icon.border_radius') as double;
    final iconPadding = styles.getStyles('module_list_page.icon.padding') as double;
    final iconBg = styles.getStyles('module_list_page.icon.background_color') as LinearGradient;
    final iconImage = styles.getStyles('course_cards.style_coding.$languageId.icon') as String;

    final backIconColor = styles.getStyles('module_list_page.back.color') as Color;
    final backIconSize = styles.getStyles('module_list_page.back.size') as double;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalMargin, vertical: verticalMargin / 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button row
                Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                      color: backIconColor,
                      iconSize: backIconSize,
                      tooltip: 'Back',
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Module card and header info
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(borderRadius),
                      gradient: strokeGradient,
                    ),
                    padding: EdgeInsets.all(borderWidth),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular((borderRadius - borderWidth).clamp(0.0, borderRadius)),
                        gradient: bgGradient,
                      ),
                      padding: EdgeInsets.all(cardPadding),
                      child: FutureBuilder<ModuleData>(
                        future: CourseDataSchema().loadModuleSchema(languageId),
                        builder: (context, snap) {
                          final displayName = snap.hasData ? snap.data!.programmingLanguage : languageId;
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Language icon
                              Container(
                                width: iconWidth,
                                height: iconHeight,
                                decoration: BoxDecoration(
                                  gradient: iconBg,
                                  borderRadius: BorderRadius.circular(iconBorderRadius),
                                ),
                                padding: EdgeInsets.all(iconPadding),
                                child: Image.asset(iconImage, fit: BoxFit.contain),
                              ),
                              const SizedBox(height: 8),

                              // Language title (display name)
                              Text(
                                displayName,
                                style: TextStyle(
                                  fontSize: titleFontSize,
                                  fontWeight: titleFontWeight,
                                  color: titleColor,
                                ),
                              ),
                              const SizedBox(height: 6),

                              // Difficulty label
                              Text(
                                difficulty,
                                style: TextStyle(fontSize: subtitleFontSize, color: subtitleColor),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Placeholder for more scrollable content (chapters, modules, etc.)
                // We will populate this with real module/chapter lists next.
              ],
            ),
          ),
        ),
      ),
    );
  }
}
