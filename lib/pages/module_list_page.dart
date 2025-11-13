import 'package:flutter/material.dart';
import '../models/styles_schema.dart';
import '../models/course_data_schema.dart';
import '../models/course_data.dart';
import '../services/local_storage_service.dart';
import '../models/user_data.dart';

class ModuleListPage extends StatelessWidget {
  final String languageId;
  final String difficulty;

  const ModuleListPage({super.key, required this.languageId, required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();
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

    final backIconColor = styles.getStyles('module_list_page.back.color') as Color;
    final backIconSize = styles.getStyles('module_list_page.back.size') as double;

    final Future<Map<String, dynamic>> courseInfoFuture = () async {
      final module = await CourseDataSchema().loadModuleSchema(languageId);
      final difficultyKey = difficulty.toLowerCase();

      final UserData? ud = LocalStorageService.instance.userDataNotifier.value;
      final Map<String, dynamic> userMap = ud == null ? <String, dynamic>{} : ud.toFirestore();

      final chapterCount = await CourseDataSchema().getChapterCount(languageId: languageId, difficulty: difficultyKey);
      final est = await CourseDataSchema().getEstimatedDuration(programmingLanguageId: languageId, difficulty: difficultyKey);
      final progress = await CourseDataSchema().getProgressPercentage(userData: userMap, languageId: languageId, difficulty: difficultyKey);

      return {
        'module': module,
        'displayName': module.programmingLanguage,
        'chapterCount': chapterCount,
        'estimatedDuration': est,
        'progress': progress,
      };
    }();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                      color: backIconColor,
                      iconSize: backIconSize,
                      tooltip: 'Back',
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Course information section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: FutureBuilder<Map<String, dynamic>>(
                    future: courseInfoFuture,
                    builder: (context, snap) {
                        if (!snap.hasData) {
                          return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
                        }

                        final info = snap.data!;
                        final String displayName = info['displayName'] as String;
                        final int chapterCount = info['chapterCount'] as int;
                        final dynamic est = info['estimatedDuration'];
                        final double progress = info['progress'] as double;

                        final progressColor = styles.getStyles('module_list_page.progress_text.color') as Color;
                        final progressFontSize = styles.getStyles('module_list_page.progress_text.font_size') as double;
                        final progressFontWeight = styles.getStyles('module_list_page.progress_text.font_weight') as FontWeight;

                        final infoIconChapter = styles.getStyles('module_list_page.info_row.dark.chapter_icon') as String;
                        final infoIconDuration = styles.getStyles('module_list_page.info_row.dark.duration_icon') as String;
                        final infoTextColor = styles.getStyles('module_list_page.info_row.text_color') as Color;
                        final infoFontSize = styles.getStyles('module_list_page.info_row.font_size') as double;
                        final infoFontWeight = styles.getStyles('module_list_page.info_row.font_weight') as FontWeight;
                        final infoIconWidth = styles.getStyles('module_list_page.info_row.icon_width') as double;
                        final infoIconHeight = styles.getStyles('module_list_page.info_row.icon_height') as double;

                        final leafSize = styles.getStyles('module_list_page.leaves.width') as double;
                        final leafPadding = styles.getStyles('module_list_page.leaves.padding') as double;
                        final leafHighlightPath = styles.getStyles('module_list_page.leaves.icons.highlight') as String;
                        final leafUnhighlightPath = styles.getStyles('module_list_page.leaves.icons.unhighlight') as String;

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

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Row 1: icon (left) and progress percent (right), centered vertically
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
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
                                const Spacer(),
                                Text('${(progress * 100).toStringAsFixed(1)}%', style: TextStyle(fontSize: progressFontSize, fontWeight: progressFontWeight, color: progressColor)),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Row 2: language name
                            Text(displayName, style: TextStyle(fontSize: titleFontSize, fontWeight: titleFontWeight, color: titleColor)),

                            const SizedBox(height: 4),

                            // Row 3: difficulty label left, leaves right
                            Row(
                              children: [
                                Text(difficulty, style: TextStyle(fontSize: subtitleFontSize, color: subtitleColor)),
                                const Spacer(),
                                Row(
                                  children: [
                                    for (int i = 0; i < 3; i++) ...[
                                      SizedBox(
                                        width: leafSize,
                                        height: leafSize,
                                        child: Image.asset(i < highlightedLeaves ? leafHighlightPath : leafUnhighlightPath),
                                      ),
                                      if (i < 2) SizedBox(width: leafPadding),
                                    ],
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Row 4: chapters | duration
                            Row(
                              children: [
                                Image.asset(infoIconChapter, width: infoIconWidth, height: infoIconHeight),
                                const SizedBox(width: 6),
                                Text('$chapterCount Chapters', style: TextStyle(fontSize: infoFontSize, fontWeight: infoFontWeight, color: infoTextColor)),
                                const SizedBox(width: 12),
                                Text('|', style: TextStyle(fontSize: infoFontSize, fontWeight: infoFontWeight, color: infoTextColor)),
                                const SizedBox(width: 12),
                                Image.asset(infoIconDuration, width: infoIconWidth, height: infoIconHeight),
                                const SizedBox(width: 6),
                                Text(est is EstimatedDuration ? '${est.hours} Hours ${est.minutes} Minutes' : '0 H 0 M', style: TextStyle(fontSize: infoFontSize, fontWeight: infoFontWeight, color: infoTextColor)),
                              ],
                            ),
                          ],
                        );
                      },
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
