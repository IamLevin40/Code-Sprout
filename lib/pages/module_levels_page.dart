import 'package:flutter/material.dart';
import 'dart:ui' as ui show ImageFilter;
import '../models/styles_schema.dart';
import '../models/course_data_schema.dart';
import '../models/course_data.dart';
import '../services/local_storage_service.dart';
import '../models/user_data.dart';
import '../widgets/level_popups/module_accomplished_popup.dart';
import '../widgets/level_popups/back_confirmation_popup.dart';
import '../widgets/module_items/level_content_display.dart';

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
    final navigator = Navigator.of(context);
    final ud = LocalStorageService.instance.userDataNotifier.value;
    if (ud == null) {
      if (mounted) navigator.pop();
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

    if (mounted) {
      try {
        final merged = {'uid': ud.uid, ...updated};
        // compute updated progress for the course/difficulty
        final progress = await CourseDataSchema().getProgressPercentage(
          userData: merged,
          languageId: widget.languageId,
          difficulty: widget.difficulty.toLowerCase(),
        );

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          await ModuleAccomplishedPopup.show(context, progressPercent: progress);
          if (!mounted) return;
          navigator.pop(); // back to module list
        });
      } catch (_) {
        // fallback: just pop back
        if (mounted) navigator.pop();
      }
    }
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

    final titleColor = styles.getStyles('module_pages.levels_page.title.color') as Color;
    final titleFontSize = styles.getStyles('module_pages.levels_page.title.font_size') as double;
    final titleFontWeight = styles.getStyles('module_pages.levels_page.title.font_weight') as FontWeight;

    List<Shadow> titleShadows = [];
    try {
      final Color baseColor = styles.getStyles('module_pages.levels_page.title.shadow.color') as Color;
      final sopRaw = styles.getStyles('module_pages.levels_page.title.shadow.opacity');
      final double sop = (sopRaw is num) ? sopRaw.toDouble() / 100.0 : (sopRaw as double);
      final sblur = styles.getStyles('module_pages.levels_page.title.shadow.blur_radius') as double;
      titleShadows = [
        Shadow(
          color: baseColor.withAlpha((sop * 255).round()),
          blurRadius: sblur,
        )
      ];
    } catch (e) {
      titleShadows = [];
    }

    final subtitleColor = styles.getStyles('module_pages.levels_page.subtitle.color') as Color;
    final subtitleFontSize = styles.getStyles('module_pages.levels_page.subtitle.font_size') as double;
    final subtitleFontWeight = styles.getStyles('module_pages.levels_page.subtitle.font_weight') as FontWeight;

    final iconImage = styles.getStyles('course_cards.style_coding.${widget.languageId}.icon') as String;
    final langDisplayWidth = styles.getStyles('module_pages.levels_page.language_display.width') as double;
    final langDisplayHeight = styles.getStyles('module_pages.levels_page.language_display.height') as double;
    final langDisplayBorderRadius = styles.getStyles('module_pages.levels_page.language_display.border_radius') as double;
    final langDisplayBorderWidth = styles.getStyles('module_pages.levels_page.language_display.border_width') as double;
    final langDisplayBgGradient = styles.getStyles('module_pages.levels_page.language_display.background_color') as LinearGradient;
    final langDisplayStrokeGradient = styles.getStyles('course_cards.style_coding.${widget.languageId}.stroke_color') as LinearGradient;

    final leafSize = styles.getStyles('module_pages.levels_page.leaves.width') as double;
    final leafPadding = styles.getStyles('module_pages.levels_page.leaves.padding') as double;
    final leafHighlightPath = styles.getStyles('module_pages.levels_page.leaves.icons.highlight') as String;
    final leafUnhighlightPath = styles.getStyles('module_pages.levels_page.leaves.icons.unhighlight') as String;

    Color? leafShadowColor;
    double? leafShadowOpacity;
    double? leafShadowBlur;
    try {
      leafShadowColor = styles.getStyles('module_pages.levels_page.leaves.highlight_shadow.color') as Color;
      final lopRaw = styles.getStyles('module_pages.levels_page.leaves.highlight_shadow.opacity');
      leafShadowOpacity = (lopRaw is num) ? lopRaw.toDouble() / 100.0 : (lopRaw as double);
      leafShadowBlur = styles.getStyles('module_pages.levels_page.leaves.highlight_shadow.blur_radius') as double;
    } catch (e) {
      leafShadowColor = null;
      leafShadowOpacity = null;
      leafShadowBlur = null;
    }

    final levelBarHeight = styles.getStyles('module_pages.level_contents.level_bars.height') as double;
    final levelBarGap = styles.getStyles('module_pages.level_contents.level_bars.gap') as double;
    final levelBarBorderRadius = styles.getStyles('module_pages.level_contents.level_bars.border_radius') as double;
    final currentBarBackground = styles.getStyles('module_pages.level_contents.level_bars.current_bar.background_color') as Color;
    final currentBarBorderWidth = styles.getStyles('module_pages.level_contents.level_bars.current_bar.border_width') as double;
    final currentBarStroke = styles.getStyles('module_pages.level_contents.level_bars.current_bar.stroke_color') as LinearGradient;
    final finishedBarBackground = styles.getStyles('module_pages.level_contents.level_bars.finished_bar.background_color') as Color;
    final lockedBarBackground = styles.getStyles('module_pages.level_contents.level_bars.locked_bar.background_color') as Color;

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
                              child: GestureDetector(
                                onTap: () async {
                                  final navigator = Navigator.of(context);
                                  final leave = await BackConfirmationPopup.show(context);
                                  if (!mounted) return;
                                  if (leave) navigator.pop();
                                },
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

                          // center column: title and chapter/module label
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  modTitle,
                                  style: TextStyle(
                                    fontSize: titleFontSize,
                                    fontWeight: titleFontWeight,
                                    color: titleColor,
                                    shadows: titleShadows,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  'Chapter ${widget.chapterNumber}, Module ${widget.moduleNumber}',
                                  style: TextStyle(fontSize: subtitleFontSize, fontWeight: subtitleFontWeight, color: subtitleColor),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),

                          // right column: language icon on top and leaves overlapping bottom center of icon
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Language display
                                Container(
                                  width: langDisplayWidth,
                                  height: langDisplayHeight,
                                  decoration: BoxDecoration(
                                    gradient: langDisplayStrokeGradient,
                                    borderRadius: BorderRadius.circular(langDisplayBorderRadius),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(langDisplayBorderWidth),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: langDisplayBgGradient,
                                        borderRadius: BorderRadius.circular((langDisplayBorderRadius - langDisplayBorderWidth).clamp(0.0, double.infinity)),
                                      ),
                                      padding: const EdgeInsets.all(8.0),
                                      child: Image.asset(iconImage, width: langDisplayWidth, height: langDisplayHeight),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Difficulty leaves
                                Transform.translate(
                                  offset: Offset(0, -leafSize / 2),
                                  child: SizedBox(
                                    width: langDisplayWidth + langDisplayBorderWidth,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        for (int i = 0; i < 3; i++) ...[
                                          SizedBox(
                                            width: leafSize,
                                            height: leafSize,
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                if (i < highlightedLeaves && leafShadowColor != null && leafShadowOpacity != null && leafShadowBlur != null)
                                                  ImageFiltered(
                                                    imageFilter: ui.ImageFilter.blur(sigmaX: leafShadowBlur, sigmaY: leafShadowBlur),
                                                    child: Image.asset(
                                                      leafHighlightPath,
                                                      width: leafSize,
                                                      height: leafSize,
                                                      color: leafShadowColor.withAlpha((leafShadowOpacity * 255).round()),
                                                      colorBlendMode: BlendMode.srcIn,
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
                            children: List.generate(levelKeys.length, (i) {
                              final lk = levelKeys[i];
                              final idx = int.tryParse(lk.split('_').last) ?? 0;
                              final bool finished = idx < _currentLevelIndex;
                              final bool current = idx == _currentLevelIndex;
                              final bool isFirst = i == 0;
                              final bool isLast = i == levelKeys.length - 1;

                              return Expanded(
                                child: Container(
                                  margin: EdgeInsets.only(left: isFirst ? 0.0 : levelBarGap, right: isLast ? 0.0 : levelBarGap),
                                  child: current
                                      ? Container(
                                          height: levelBarHeight,
                                          decoration: BoxDecoration(
                                            gradient: currentBarStroke,
                                            borderRadius: BorderRadius.circular(levelBarBorderRadius),
                                          ),
                                          child: Padding(
                                            padding: EdgeInsets.all(currentBarBorderWidth),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: currentBarBackground,
                                                borderRadius: BorderRadius.circular((levelBarBorderRadius - currentBarBorderWidth).clamp(0.0, double.infinity)),
                                              ),
                                            ),
                                          ),
                                        )
                                      : Container(
                                          height: levelBarHeight,
                                          decoration: BoxDecoration(
                                            color: finished ? finishedBarBackground : lockedBarBackground,
                                            borderRadius: BorderRadius.circular(levelBarBorderRadius),
                                          ),
                                        ),
                                ),
                              );
                            }),
                          ),

                          const SizedBox(height: 16),

                          // Level content area
                          Builder(builder: (_) {
                            final currentKey = 'level_$_currentLevelIndex';
                            final Level? lvl = levelsMap[currentKey];

                            return LevelContentDisplay(
                              level: lvl,
                              currentLevelIndex: _currentLevelIndex,
                              totalLevels: totalLevels,
                              onNext: () async => await _handleNext(totalLevels),
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
