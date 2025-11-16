import 'package:flutter/material.dart';
import 'dart:ui' as ui show ImageFilter;
import '../models/styles_schema.dart';
import '../models/course_data_schema.dart';
import '../models/course_data.dart';
import '../services/local_storage_service.dart';
import '../models/user_data.dart';
import 'module_levels_page.dart';
import '../widgets/module_items/progress_display.dart';

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

    final backIconImage = styles.getStyles('module_pages.back.icon.image') as String;
    final backIconWidth = styles.getStyles('module_pages.back.icon.width') as double;
    final backIconHeight = styles.getStyles('module_pages.back.icon.height') as double;
    final backBgColor = styles.getStyles('module_pages.back.background_color') as Color;
    final backBorderRadius = styles.getStyles('module_pages.back.border_radius') as double;
    final backWidth = styles.getStyles('module_pages.back.width') as double;
    final backHeight = styles.getStyles('module_pages.back.height') as double;

    final iconImage = styles.getStyles('course_cards.style_coding.${widget.languageId}.icon') as String;
    final langIconWidth = styles.getStyles('module_pages.list_page.language_display.width') as double;
    final langIconHeight = styles.getStyles('module_pages.list_page.language_display.height') as double;
    final langDisplayBgGradient = styles.getStyles('module_pages.list_page.language_display.background_color') as LinearGradient;
    final langDisplayBorderRadius = styles.getStyles('module_pages.list_page.language_display.border_radius') as double;
    final langDisplayBorderWidth = styles.getStyles('module_pages.list_page.language_display.border_width') as double;
    final langDisplayStrokeGradient = styles.getStyles('course_cards.style_coding.${widget.languageId}.stroke_color') as LinearGradient;

    

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
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: backWidth,
                        height: backHeight,
                        decoration: BoxDecoration(
                          color: backBgColor,
                          borderRadius: BorderRadius.circular(backBorderRadius),
                        ),
                        child: Image.asset(backIconImage, width: backIconWidth, height: backIconHeight),
                      ),
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

                        final infoIconChapter = styles.getStyles('module_pages.list_page.info_row.dark.chapter_icon') as String;
                        final infoIconDuration = styles.getStyles('module_pages.list_page.info_row.dark.duration_icon') as String;
                        final infoTextColor = styles.getStyles('module_pages.list_page.info_row.text_color') as Color;
                        final infoFontSize = styles.getStyles('module_pages.list_page.info_row.font_size') as double;
                        final infoFontWeight = styles.getStyles('module_pages.list_page.info_row.font_weight') as FontWeight;
                        final infoIconWidth = styles.getStyles('module_pages.list_page.info_row.icon_width') as double;
                        final infoIconHeight = styles.getStyles('module_pages.list_page.info_row.icon_height') as double;
                        
                        final leafSize = styles.getStyles('module_pages.list_page.leaves.width') as double;
                        final leafPadding = styles.getStyles('module_pages.list_page.leaves.padding') as double;
                        final leafHighlightPath = styles.getStyles('module_pages.list_page.leaves.icons.highlight') as String;
                        final leafUnhighlightPath = styles.getStyles('module_pages.list_page.leaves.icons.unhighlight') as String;

                        final langNameFontSize = styles.getStyles('module_pages.list_page.language_name.font_size') as double;
                        final langNameFontWeight = styles.getStyles('module_pages.list_page.language_name.font_weight') as FontWeight;
                        final langNameColor = styles.getStyles('module_pages.list_page.language_name.color') as Color;

                        List<Shadow> langNameShadows = [];
                        try {
                          final Color baseColor = styles.getStyles('module_pages.list_page.language_name.shadow.color') as Color;
                          final sopRaw = styles.getStyles('module_pages.list_page.language_name.shadow.opacity');
                          final double sop = (sopRaw is num) ? sopRaw.toDouble() / 100.0 : (sopRaw as double);
                          final sblur = styles.getStyles('module_pages.list_page.language_name.shadow.blur_radius') as double;
                          langNameShadows = [
                            Shadow(
                              color: baseColor.withAlpha((sop * 255).round()),
                              blurRadius: sblur,
                            )
                          ];
                        } catch (e) {
                          langNameShadows = [];
                        }

                        final diffFontSize = styles.getStyles('module_pages.list_page.difficulty.font_size') as double;
                        final diffFontWeight = styles.getStyles('module_pages.list_page.difficulty.font_weight') as FontWeight;
                        final diffColor = styles.getStyles('module_pages.list_page.difficulty.color') as Color;

                        Color? leafShadowColor;
                        double? leafShadowOpacity;
                        double? leafShadowBlur;
                        try {
                          leafShadowColor = styles.getStyles('module_pages.list_page.leaves.highlight_shadow.color') as Color;
                          final lopRaw = styles.getStyles('module_pages.list_page.leaves.highlight_shadow.opacity');
                          leafShadowOpacity = (lopRaw is num) ? lopRaw.toDouble() / 100.0 : (lopRaw as double);
                          leafShadowBlur = styles.getStyles('module_pages.list_page.leaves.highlight_shadow.blur_radius') as double;
                        } catch (e) {
                          leafShadowColor = null;
                          leafShadowOpacity = null;
                          leafShadowBlur = null;
                        }

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
                            // Row 1: icon (left) and progress percent (right)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Left column: language display
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 12.0),
                                      child: Container(
                                        width: langIconWidth,
                                        height: langIconHeight,
                                        decoration: BoxDecoration(
                                          gradient: langDisplayStrokeGradient,
                                          borderRadius: BorderRadius.circular(langDisplayBorderRadius),
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.all(langDisplayBorderWidth),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: langDisplayBgGradient,
                                              borderRadius: BorderRadius.circular(langDisplayBorderRadius - langDisplayBorderWidth),
                                            ),
                                            padding: const EdgeInsets.all(16.0),
                                            child: Image.asset(iconImage, width: langIconWidth, height: langIconHeight),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Right column: progress display
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 12.0),
                                      child: ProgressDisplay(stylePath: 'module_pages.list_page.progress_display', progress: progress),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Row 2: language name
                            Text(
                              displayName,
                              style: TextStyle(
                                fontSize: langNameFontSize,
                                fontWeight: langNameFontWeight,
                                color: langNameColor,
                                shadows: langNameShadows,
                              ),
                            ),

                            // Row 3: difficulty label left, leaves right
                            Row(
                              children: [
                                Text(widget.difficulty, style: TextStyle(fontSize: diffFontSize, fontWeight: diffFontWeight, color: diffColor)),
                                const Spacer(),
                                Row(
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
                                                    leafHighlightPath,
                                                    width: leafSize,
                                                    height: leafSize,
                                                    color: leafShadowColor.withAlpha((leafShadowOpacity * 255).round()),
                                                    colorBlendMode: BlendMode.srcIn,
                                                  ),
                                                ),
                                              ),

                                            Image.asset(
                                              i < highlightedLeaves ? leafHighlightPath : leafUnhighlightPath,
                                              width: leafSize,
                                              height: leafSize,
                                            ),
                                          ],
                                        ),
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
                              boxShadow: completedCard ? const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))] : null,
                            ),
                            child: Row(
                              children: [
                                Icon(leftIcon, size: 36, color: completedCard ? Colors.white : Colors.grey.shade700),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(module.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

                          widgets.add(Text('Chapter $chapNum', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)));
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

                          widgets.add(Text('Chapter $chapNum', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)));
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
