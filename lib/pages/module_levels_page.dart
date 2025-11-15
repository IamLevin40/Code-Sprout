import 'package:flutter/material.dart';
import '../models/styles_schema.dart';
import '../models/course_data_schema.dart';
import '../models/course_data.dart';
import '../services/local_storage_service.dart';
import '../models/user_data.dart';
import '../widgets/level_contents/lecture_content.dart';
import '../widgets/level_contents/multiple_choice_content.dart';

class ModuleLevelsPage extends StatefulWidget {
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
  State<ModuleLevelsPage> createState() => _ModuleLevelsPageState();
}

class _ModuleLevelsPageState extends State<ModuleLevelsPage> {
  late Future<Map<String, dynamic>> _moduleInfoFuture;
  int _currentLevelIndex = 1; // 1-based

  @override
  void initState() {
    super.initState();
    _moduleInfoFuture = _loadModuleInfo();
  }

  Future<Map<String, dynamic>> _loadModuleInfo() async {
    final moduleSchema = await CourseDataSchema().loadModuleSchema(widget.languageId);
    String title = widget.moduleTitle ?? '';
    LevelData? levelData;
    String? levelSchemaPath;

    try {
      final diffKey = widget.difficulty.toLowerCase();
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

      final chap = level.chapters['chapter_${widget.chapterNumber}'];
      final mod = chap?.modules['module_${widget.moduleNumber}'];
      if (mod != null) {
        title = title.isEmpty ? mod.title : title;
        levelSchemaPath = mod.levelSchema;
      }

      if (levelSchemaPath != null) {
        final levels = await CourseDataSchema().getAllLevels(levelSchemaPath: levelSchemaPath);
        levelData = LevelData(levels: levels);
      }
    } catch (_) {}

    return {
      'moduleTitle': title,
      'languageName': moduleSchema.programmingLanguage,
      'levelSchemaPath': levelSchemaPath,
      'levelsMap': levelData?.levels ?? {},
    };
  }

  Future<void> _handleNext(int totalLevels) async {
    // If not last level, go to next level locally
    if (_currentLevelIndex < totalLevels) {
      setState(() => _currentLevelIndex += 1);
      return;
    }

    // Last level -> module accomplished: advance module for user and go back
    final ud = LocalStorageService.instance.userDataNotifier.value;
    if (ud == null) {
      if (context.mounted) Navigator.of(context).pop();
      return;
    }

    final userMap = ud.toFirestore();
    final updated = await CourseDataSchema().advanceModule(
      userData: userMap,
      languageId: widget.languageId,
      difficulty: widget.difficulty,
      completedChapter: widget.chapterNumber,
      completedModule: widget.moduleNumber,
    );

    try {
      final merged = {'uid': ud.uid, ...updated};
      final newUser = UserData.fromJson(merged);

      await LocalStorageService.instance.saveUserData(newUser);

      try {
        await newUser.save();
      } catch (_) {}
    } catch (_) {}

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Module Accomplished'),
          content: const Text('You completed the module. Progress advanced.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // close dialog
                Navigator.of(context).pop(); // back to module list
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();

    final backIconColor = styles.getStyles('module_pages.back.color') as Color;
    final backIconSize = styles.getStyles('module_pages.back.size') as double;

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

    final leafSize = styles.getStyles('module_pages.leaves.width') as double;
    final leafPadding = styles.getStyles('module_pages.leaves.padding') as double;
    final leafHighlightPath = styles.getStyles('module_pages.leaves.icons.highlight') as String;
    final leafUnhighlightPath = styles.getStyles('module_pages.leaves.icons.unhighlight') as String;

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
                  child: FutureBuilder<Map<String, dynamic>>(
                    future: _moduleInfoFuture,
                    builder: (context, snap) {
                      if (!snap.hasData) return const SizedBox();
                      final info = snap.data!;
                      final modTitle = info['moduleTitle'] as String? ?? 'Module ${widget.moduleNumber}';

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
                                Text('Chapter ${widget.chapterNumber}, Module ${widget.moduleNumber}', style: TextStyle(fontSize: subtitleFontSize, color: subtitleColor), textAlign: TextAlign.center),
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

                const SizedBox(height: 8),

                // Level content section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: FutureBuilder<Map<String, dynamic>>(
                    future: _moduleInfoFuture,
                    builder: (context, snap) {
                      if (!snap.hasData) return const SizedBox();
                      final info = snap.data!;
                      final levelsMap = info['levelsMap'] as Map<String, Level>;

                      final levelKeys = levelsMap.keys.toList()..sort((a, b) {
                        final aNum = int.tryParse(a.split('_').last) ?? 0;
                        final bNum = int.tryParse(b.split('_').last) ?? 0;
                        return aNum.compareTo(bNum);
                      });

                      final totalLevels = levelKeys.length;

                      if (_currentLevelIndex < 1) _currentLevelIndex = 1;
                      if (_currentLevelIndex > (totalLevels == 0 ? 1 : totalLevels)) _currentLevelIndex = totalLevels == 0 ? 1 : totalLevels;

                      if (totalLevels == 0) return const SizedBox();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Level bars row
                          Row(
                            children: levelKeys.map((lk) {
                              final idx = int.tryParse(lk.split('_').last) ?? 0;
                              final bool finished = idx < _currentLevelIndex;
                              final bool current = idx == _currentLevelIndex;

                              return Expanded(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 6.0),
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: finished ? Colors.green.shade400 : (current ? Colors.blue.shade400 : Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: current ? Colors.blue.shade700 : Colors.transparent, width: current ? 2 : 0),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 16),

                          // Level content area
                          Builder(builder: (_) {
                            final currentKey = 'level_$_currentLevelIndex';
                            final Level? lvl = levelsMap[currentKey];
                            final mode = lvl?.mode ?? '';
                            final modeInfo = CourseDataSchema().getModeDisplay(mode);
                            final modeTitle = modeInfo['title'] ?? mode;
                            final modeDesc = modeInfo['description'] ?? '';

                            // Mode title and description
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  modeTitle,
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  modeDesc,
                                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),

                                // Level-specific widget area
                                Builder(builder: (_) {
                                  // Lecture mode
                                  if (mode.toLowerCase() == 'lecture') {
                                    final lec = lvl?.getLectureContent();
                                    if (lec != null) {
                                      return Align(alignment: Alignment.centerLeft, child: LectureContentWidget(lectureContent: lec, onProceed: () => _handleNext(totalLevels)));
                                    }
                                  }

                                  // Multiple choice mode
                                  if (mode.toLowerCase() == 'multiple_choice') {
                                    final mc = lvl?.getMultipleChoiceContent();
                                    if (mc != null) {
                                      return MultipleChoiceContentWidget(content: mc, onCorrectProceed: () => _handleNext(totalLevels));
                                    }
                                  }

                                  // Fallback content area for other modes (you can replace with actual widgets later)
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // Placeholder box for mode content
                                      Container(
                                        padding: const EdgeInsets.all(12.0),
                                        margin: const EdgeInsets.only(bottom: 12.0),
                                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8.0)),
                                        child: Text('Content for mode "$mode" is not yet implemented.', style: TextStyle(color: Colors.grey.shade800)),
                                      ),

                                      // Fallback Next button for non-lecture modes
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () async => await _handleNext(totalLevels),
                                          child: const Text('Next'),
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ],
                            );
                          }),
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
