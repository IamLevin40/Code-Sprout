import 'package:flutter/material.dart';
import '../models/styles_schema.dart';
import '../models/course_data_schema.dart';
import '../models/course_data.dart';
import '../services/local_storage_service.dart';
import '../models/user_data.dart';
import 'module_levels_page.dart';

class ModuleListPage extends StatefulWidget {
  final String languageId;
  final String difficulty;

  const ModuleListPage({super.key, required this.languageId, required this.difficulty});

  @override
  State<ModuleListPage> createState() => _ModuleListPageState();
}

class _ModuleListPageState extends State<ModuleListPage> {
  late Future<Map<String, dynamic>> _courseInfoFuture;

  @override
  void initState() {
    super.initState();
    _refreshCourseInfo();
    LocalStorageService.instance.userDataNotifier.addListener(_onUserDataChanged);
  }

  @override
  void dispose() {
    LocalStorageService.instance.userDataNotifier.removeListener(_onUserDataChanged);
    super.dispose();
  }

  void _onUserDataChanged() {
    if (!mounted) return;
    setState(() => _refreshCourseInfo());
  }

  void _refreshCourseInfo() {
    _courseInfoFuture = _loadCourseInfo();
  }

  Future<Map<String, dynamic>> _loadCourseInfo() async {
    final module = await CourseDataSchema().loadModuleSchema(widget.languageId);
    final difficultyKey = widget.difficulty.toLowerCase();

    final UserData? ud = LocalStorageService.instance.userDataNotifier.value;
    final Map<String, dynamic> userMap = ud == null ? <String, dynamic>{} : ud.toFirestore();

    final chapterCount = await CourseDataSchema().getChapterCount(languageId: widget.languageId, difficulty: difficultyKey);
    final est = await CourseDataSchema().getEstimatedDuration(programmingLanguageId: widget.languageId, difficulty: difficultyKey);
    final progress = await CourseDataSchema().getProgressPercentage(userData: userMap, languageId: widget.languageId, difficulty: difficultyKey);

    final modulesByDifficulty = await CourseDataSchema().getModulesByDifficulty(programmingLanguageId: widget.languageId, difficulty: difficultyKey);
    final currentProgress = CourseDataSchema().getCurrentProgress(userData: userMap, languageId: widget.languageId, difficulty: difficultyKey);
    final int currentChapter = currentProgress['currentChapter'] ?? 1;
    final int currentModule = currentProgress['currentModule'] ?? 1;

    return {
      'module': module,
      'displayName': module.programmingLanguage,
      'chapterCount': chapterCount,
      'estimatedDuration': est,
      'progress': progress,
      'modulesByDifficulty': modulesByDifficulty,
      'currentChapter': currentChapter,
      'currentModule': currentModule,
    };
  }

  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();
    final titleColor = styles.getStyles('module_pages.title.color') as Color;
    final titleFontSize = styles.getStyles('module_pages.title.font_size') as double;
    final titleFontWeight = styles.getStyles('module_pages.title.font_weight') as FontWeight;
    final subtitleColor = styles.getStyles('module_pages.subtitle.color') as Color;
    final subtitleFontSize = styles.getStyles('module_pages.subtitle.font_size') as double;

    final iconWidth = styles.getStyles('module_pages.icon.width') as double;
    final iconHeight = styles.getStyles('module_pages.icon.height') as double;
    final iconBorderRadius = styles.getStyles('module_pages.icon.border_radius') as double;
    final iconPadding = styles.getStyles('module_pages.icon.padding') as double;
    final iconBg = styles.getStyles('module_pages.icon.background_color') as LinearGradient;
  final iconImage = styles.getStyles('course_cards.style_coding.${widget.languageId}.icon') as String;

    final backIconColor = styles.getStyles('module_pages.back.color') as Color;
    final backIconSize = styles.getStyles('module_pages.back.size') as double;

    // course info future is provided by the state field `_courseInfoFuture`

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
                    future: _courseInfoFuture,
                    builder: (context, snap) {
                        if (!snap.hasData) {
                          return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
                        }

                        final info = snap.data!;
                        final String displayName = info['displayName'] as String;
                        final int chapterCount = info['chapterCount'] as int;
                        final dynamic est = info['estimatedDuration'];
                        final double progress = info['progress'] as double;

                        final progressColor = styles.getStyles('module_pages.progress_text.color') as Color;
                        final progressFontSize = styles.getStyles('module_pages.progress_text.font_size') as double;
                        final progressFontWeight = styles.getStyles('module_pages.progress_text.font_weight') as FontWeight;

                        final infoIconChapter = styles.getStyles('module_pages.info_row.dark.chapter_icon') as String;
                        final infoIconDuration = styles.getStyles('module_pages.info_row.dark.duration_icon') as String;
                        final infoTextColor = styles.getStyles('module_pages.info_row.text_color') as Color;
                        final infoFontSize = styles.getStyles('module_pages.info_row.font_size') as double;
                        final infoFontWeight = styles.getStyles('module_pages.info_row.font_weight') as FontWeight;
                        final infoIconWidth = styles.getStyles('module_pages.info_row.icon_width') as double;
                        final infoIconHeight = styles.getStyles('module_pages.info_row.icon_height') as double;

                        final leafSize = styles.getStyles('module_pages.leaves.width') as double;
                        final leafPadding = styles.getStyles('module_pages.leaves.padding') as double;
                        final leafHighlightPath = styles.getStyles('module_pages.leaves.icons.highlight') as String;
                        final leafUnhighlightPath = styles.getStyles('module_pages.leaves.icons.unhighlight') as String;

                        // Determine highlighted leaves from difficulty
                        int highlightedLeaves = 0;
                        switch (widget.difficulty.toLowerCase()) {
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
                                Text(widget.difficulty, style: TextStyle(fontSize: subtitleFontSize, color: subtitleColor)),
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

                // Chapters-Modules list section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: FutureBuilder<Map<String, dynamic>>(
                    future: _courseInfoFuture,
                    builder: (context, snap) {
                      if (!snap.hasData) return const SizedBox();
                      final info = snap.data!;
                      final modulesByDifficulty = info['modulesByDifficulty'] as Map<String, Map<String, Module>>;
                      final int curChap = info['currentChapter'] as int;
                      final int curMod = info['currentModule'] as int;

                      // Partition modules
                      final Map<String, List<MapEntry<String, Module>>> completed = {};
                      final Map<String, List<MapEntry<String, Module>>> notCompleted = {};

                      final chapterKeys = modulesByDifficulty.keys.toList()..sort((a, b) {
                        final aNum = int.tryParse(a.split('_').last) ?? 0;
                        final bNum = int.tryParse(b.split('_').last) ?? 0;
                        return aNum.compareTo(bNum);
                      });

                      for (final chapterId in chapterKeys) {
                        final chapModules = modulesByDifficulty[chapterId]!;
                        final moduleEntries = chapModules.entries.toList()..sort((a, b) {
                          final aNum = int.tryParse(a.key.split('_').last) ?? 0;
                          final bNum = int.tryParse(b.key.split('_').last) ?? 0;
                          return aNum.compareTo(bNum);
                        });

                        final chapNum = int.tryParse(chapterId.split('_').last) ?? 0;
                        final List<MapEntry<String, Module>> compList = [];
                        final List<MapEntry<String, Module>> notCompList = [];

                        for (final me in moduleEntries) {
                          final modIdNum = int.tryParse(me.key.split('_').last) ?? 0;
                          if (chapNum < curChap || (chapNum == curChap && modIdNum < curMod)) {
                            compList.add(me);
                          } else {
                            notCompList.add(me);
                          }
                        }

                        if (notCompList.isNotEmpty) notCompleted[chapterId] = notCompList;
                        if (compList.isNotEmpty) completed[chapterId] = compList;
                      }

                      Widget buildModuleCard(MapEntry<String, Module> entry, {required int chapterNum, required bool pressable, required bool completedCard}) {
                        final moduleKey = entry.key;
                        final module = entry.value;
                        final moduleNumber = int.tryParse(moduleKey.split('_').last) ?? 0;

                        final leftIcon = completedCard
                            ? Icons.check_circle_outline
                            : (pressable ? Icons.play_circle_fill : Icons.lock_outline);

                                return GestureDetector(
                                  onTap: pressable
                                      ? () {
                                          // Navigate to ModuleLevelsPage for this module
                                          Navigator.of(context).push(MaterialPageRoute(
                                            builder: (_) => ModuleLevelsPage(
                                              languageId: widget.languageId,
                                              difficulty: widget.difficulty,
                                              chapterNumber: chapterNum,
                                              moduleNumber: moduleNumber,
                                              moduleTitle: module.title,
                                            ),
                                          ));
                                        }
                                      : null,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: completedCard ? Colors.blue.shade300 : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade400, width: 1.5),
                              boxShadow: completedCard ? [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))] : null,
                            ),
                            child: Row(
                              children: [
                                Icon(leftIcon, size: 36, color: completedCard ? Colors.white : Colors.grey.shade700),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(module.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text('Module $moduleNumber', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final List<Widget> widgets = [];
                      
                      // Not Completed section
                      if (notCompleted.isNotEmpty) {
                        widgets.add(const Text('Not Completed', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)));
                        widgets.add(const SizedBox(height: 8));

                        for (final chapterId in chapterKeys) {
                          final chapNum = int.tryParse(chapterId.split('_').last) ?? 0;
                          final notList = notCompleted[chapterId];
                          if (notList == null) continue;

                          widgets.add(Text('Chapter $chapNum', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)));
                          widgets.add(const SizedBox(height: 8));

                            for (final entry in notList) {
                            final modNum = int.tryParse(entry.key.split('_').last) ?? 0;
                            final pressable = (chapNum == curChap && modNum == curMod);
                            widgets.add(buildModuleCard(entry, chapterNum: chapNum, pressable: pressable, completedCard: false));
                          }
                        }
                      }

                      // Completed section
                      if (completed.isNotEmpty) {
                        widgets.add(const SizedBox(height: 12));
                        widgets.add(const Text('Completed', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)));
                        widgets.add(const SizedBox(height: 8));

                        for (final chapterId in chapterKeys) {
                          final chapNum = int.tryParse(chapterId.split('_').last) ?? 0;
                          final compList = completed[chapterId];
                          if (compList == null) continue;

                          widgets.add(Text('Chapter $chapNum', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)));
                          widgets.add(const SizedBox(height: 8));

                          for (final entry in compList) {
                            widgets.add(buildModuleCard(entry, chapterNum: chapNum, pressable: true, completedCard: true));
                          }
                        }
                      }

                      return Column(children: widgets);
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
