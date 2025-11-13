import 'package:flutter/material.dart';
import '../models/styles_schema.dart';
import '../models/course_data_schema.dart';
import '../models/course_data.dart';

class ModuleLevelsPage extends StatelessWidget {
  final String languageId;
  final String difficulty;
  final int chapterNumber;
  final int moduleNumber;
  final String? moduleTitle;

  const ModuleLevelsPage({
    super.key,
    required this.languageId,
    required this.difficulty,
    required this.chapterNumber,
    required this.moduleNumber,
    this.moduleTitle,
  });

  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();

    final backIconColor = styles.getStyles('module_list_page.back.color') as Color;
    final backIconSize = styles.getStyles('module_list_page.back.size') as double;

    final titleColor = styles.getStyles('module_list_page.title.color') as Color;
    final titleFontSize = styles.getStyles('module_list_page.title.font_size') as double;
    final titleFontWeight = styles.getStyles('module_list_page.title.font_weight') as FontWeight;

    final subtitleColor = styles.getStyles('module_list_page.subtitle.color') as Color;
    final subtitleFontSize = styles.getStyles('module_list_page.subtitle.font_size') as double;

    final iconWidth = styles.getStyles('module_list_page.icon.width') as double;
    final iconHeight = styles.getStyles('module_list_page.icon.height') as double;
    final iconBorderRadius = styles.getStyles('module_list_page.icon.border_radius') as double;
    final iconPadding = styles.getStyles('module_list_page.icon.padding') as double;
    final iconBg = styles.getStyles('module_list_page.icon.background_color') as LinearGradient;
    final iconImage = styles.getStyles('course_cards.style_coding.$languageId.icon') as String;

    final leafSize = styles.getStyles('module_list_page.leaves.width') as double;
    final leafPadding = styles.getStyles('module_list_page.leaves.padding') as double;
    final leafHighlightPath = styles.getStyles('module_list_page.leaves.icons.highlight') as String;
    final leafUnhighlightPath = styles.getStyles('module_list_page.leaves.icons.unhighlight') as String;

    final Future<Map<String, String>> moduleInfoFuture = () async {
      // Load module schema to get language display name and module title if not provided
      final moduleSchema = await CourseDataSchema().loadModuleSchema(languageId);
      String title = moduleTitle ?? '';
      if (title.isEmpty) {
        try {
          final diffKey = difficulty.toLowerCase();
          DifficultyLevel? level;
          switch (diffKey) {
            case 'beginner':
              level = moduleSchema.beginner;
              break;
            case 'intermediate':
              level = moduleSchema.intermediate;
              break;
            case 'advanced':
              level = moduleSchema.advanced;
              break;
            default:
              level = moduleSchema.beginner;
          }

          final chap = level.chapters['chapter_$chapterNumber'];
          final mod = chap?.modules['module_$moduleNumber'];
          if (mod != null) title = mod.title;
        } catch (_) {
          // ignore
        }
      }

      return {'moduleTitle': title, 'languageName': moduleSchema.programmingLanguage};
    }();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Module information section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: FutureBuilder<Map<String, String>>(
                    future: moduleInfoFuture,
                    builder: (context, snap) {
                      if (!snap.hasData) return const SizedBox();
                      final info = snap.data!;
                      final modTitle = info['moduleTitle'] ?? 'Module $moduleNumber';

                      // Determine highlighted leaves from difficulty
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // left column: back button
                          Expanded(
                            flex: 1,
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.arrow_back),
                                color: backIconColor,
                                iconSize: backIconSize,
                                tooltip: 'Back',
                              ),
                            ),
                          ),

                          // center column: title and chapter/module label (centered)
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(height: 4),
                                Text(modTitle, style: TextStyle(fontSize: titleFontSize, fontWeight: titleFontWeight, color: titleColor), textAlign: TextAlign.center),
                                Text('Chapter $chapterNumber, Module $moduleNumber', style: TextStyle(fontSize: subtitleFontSize, color: subtitleColor), textAlign: TextAlign.center),
                              ],
                            ),
                          ),

                          // right column: language icon on top and leaves overlapping bottom center of icon
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Icon container
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
                                const SizedBox(height: 12),

                                // Leaves positioned centered under the icon and overlapping its bottom
                                Transform.translate(
                                  offset: Offset(0, -leafSize / 2),
                                  child: SizedBox(
                                    width: iconWidth,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        for (int i = 0; i < 3; i++) ...[
                                          SizedBox(width: leafSize, height: leafSize, child: Image.asset(i < highlightedLeaves ? leafHighlightPath : leafUnhighlightPath)),
                                          if (i < 2) SizedBox(width: leafPadding),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
