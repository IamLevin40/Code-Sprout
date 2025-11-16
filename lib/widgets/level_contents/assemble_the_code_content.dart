import 'package:flutter/material.dart';
import '../../models/course_data.dart';
import '../../models/styles_schema.dart';

class AssembleTheCodeContentWidget extends StatefulWidget {
  final AssembleTheCodeContent content;
  final ValueChanged<bool> onAnswer; // true = correct, false = incorrect

  const AssembleTheCodeContentWidget({
    super.key,
    required this.content,
    required this.onAnswer,
  });

  @override
  State<AssembleTheCodeContentWidget> createState() => _AssembleTheCodeContentWidgetState();
}

class _AssembleTheCodeContentWidgetState extends State<AssembleTheCodeContentWidget> {
  late List<_ChoiceItem> _choices;
  late List<List<int>> _lines; // list of choice ids per line
  // keys for measuring positions
  late List<GlobalKey> _lineRowKeys;
  final Map<String, GlobalKey> _childKeys = {};
  final Map<int, int?> _hoverInsert = {};

  @override
  void initState() {
    super.initState();
    _initStateFromContent();
  }

  void _initStateFromContent() {
    _choices = [];
    final choices = widget.content.choices;
    for (var i = 0; i < choices.length; i++) {
      _choices.add(_ChoiceItem(id: i, text: choices[i]));
    }
    _choices.shuffle();

    // initialize empty lines (one list for each correct line)
    _lines = List.generate(widget.content.correctCodeLines.length, (_) => <int>[]);
    _lineRowKeys = List.generate(widget.content.correctCodeLines.length, (_) => GlobalKey());
    _childKeys.clear();
    _hoverInsert.clear();
  }

  List<int> _allAssignedIds() => _lines.expand((l) => l).toList();

  List<_ChoiceItem> get _bankChoices => _choices.where((c) => !_allAssignedIds().contains(c.id)).toList();

  void _insertIntoLine({required int lineIndex, required int insertIndex, required int choiceId}) {
    setState(() {
      // remove from any other line
      for (final l in _lines) {
        l.remove(choiceId);
      }
      final list = _lines[lineIndex];
      final idx = insertIndex.clamp(0, list.length);
      list.insert(idx, choiceId);
    });
  }

  void _removeFromLine(int choiceId) {
    setState(() {
      for (final l in _lines) {
        l.remove(choiceId);
      }
    });
  }

  // Build assembled strings per line
  List<String> _assembledLines() {
    return _lines.map((l) {
      final parts = l.map((id) => _choices.firstWhere((c) => c.id == id).text).toList();
      return parts.join(' ').trim();
    }).toList();
  }

  // Compute indent levels based on rules described (applied to provided lines)
  List<int> _computeIndentLevelsFromLines(List<String> lines) {
    int indent = 0;
    final result = <int>[];
    for (var i = 0; i < lines.length; i++) {
      final trimmed = lines[i].trim();

      // decrease rules (apply before current line)
      final lowerStarters = ['elif', 'else', 'except', 'finally'];
      bool startsLower = false;
      for (final s in lowerStarters) {
        if (trimmed.startsWith('$s ') || trimmed == s) {
          startsLower = true;
          break;
        }
      }
      if (trimmed.startsWith('}')) {
        indent = (indent - 1).clamp(0, indent);
      } else if (startsLower) {
        indent = (indent - 1).clamp(0, indent);
      }

      result.add(indent);

      // increase rules (apply after current line)
      if (trimmed.endsWith('{') || trimmed.endsWith(':')) {
        indent += 1;
      }
    }
    return result;
  }

  int _countIndentFromString(String s) {
    int count = 0;
    for (int i = 0; i < s.length; i++) {
      if (s.codeUnitAt(i) == 32) {
        count++;
      } else {
        break; // count spaces
      }
    }
    // assume 2 spaces per indent level (heuristic)
    return (count / 2).floor();
  }

  Future<void> _onSubmit() async {
    final assembled = _assembledLines();
    final correct = widget.content.correctCodeLines.map((e) => e.trim()).toList();

    // Compare content trimmed
    final contentMatches = List.generate(correct.length, (i) => (assembled[i].trim() == correct[i].trim())).every((v) => v);

    // Compute indent levels for assembled using rules
    final assembledIndentLevels = _computeIndentLevelsFromLines(assembled);

    // Compute expected indent levels from correct lines by counting leading spaces
    final expectedIndentLevels = widget.content.correctCodeLines.map((l) => _countIndentFromString(l)).toList();

    final indentMatches = List.generate(expectedIndentLevels.length, (i) => assembledIndentLevels[i] == expectedIndentLevels[i]).every((v) => v);

    final isCorrect = contentMatches && indentMatches;

    if (context.mounted) {
      widget.onAnswer(isCorrect);
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.content.question;
    final styles = AppStyles();

    final questionColor = styles.getStyles('module_pages.level_contents.assemble_the_code_mode.question_text.color') as Color;
    final questionFontSize = styles.getStyles('module_pages.level_contents.assemble_the_code_mode.question_text.font_size') as double;
    final questionFontWeight = styles.getStyles('module_pages.level_contents.assemble_the_code_mode.question_text.font_weight') as FontWeight;

    final codeAreaBg = styles.getStyles('module_pages.level_contents.assemble_the_code_mode.code_area.background_color') as Color;
    final codeAreaBorderRadius = styles.getStyles('module_pages.level_contents.assemble_the_code_mode.code_area.border_radius') as double;

    final codeLineBg = styles.getStyles('module_pages.level_contents.assemble_the_code_mode.code_line_area.background_color') as Color;
    final codeLineBorderRadius = styles.getStyles('module_pages.level_contents.assemble_the_code_mode.code_line_area.border_radius') as double;
    final containerHeight = styles.getStyles('module_pages.level_contents.assemble_the_code_mode.code_container.height') as double;

    final choiceMinWidth = styles.getStyles('module_pages.level_contents.assemble_the_code_mode.choice_container.min_width') as double;
    final choiceMinHeight = styles.getStyles('module_pages.level_contents.assemble_the_code_mode.choice_container.min_height') as double;
    final choiceBorderRadius = styles.getStyles('module_pages.level_contents.assemble_the_code_mode.choice_container.border_radius') as double;
    final choiceBorderWidth = styles.getStyles('module_pages.level_contents.assemble_the_code_mode.choice_container.border_width') as double;
    final choiceBackground = styles.getStyles('module_pages.level_contents.assemble_the_code_mode.choice_container.background_color') as LinearGradient;
    final choiceStroke = styles.getStyles('module_pages.level_contents.assemble_the_code_mode.choice_container.stroke_color') as LinearGradient;
    final choiceTextColor = styles.getStyles('module_pages.level_contents.assemble_the_code_mode.choice_container.text.color') as Color;
    final choiceTextSize = styles.getStyles('module_pages.level_contents.assemble_the_code_mode.choice_container.text.font_size') as double;
    final choiceTextWeight = styles.getStyles('module_pages.level_contents.assemble_the_code_mode.choice_container.text.font_weight') as FontWeight;

    final submitWidth = styles.getStyles('module_pages.level_contents.assemble_the_code_mode.submit_button.width') as double;
    final submitHeight = styles.getStyles('module_pages.level_contents.assemble_the_code_mode.submit_button.height') as double;
    final submitBackground = styles.getStyles('module_pages.level_contents.assemble_the_code_mode.submit_button.background_color') as Color;
    final submitBorderWidth = styles.getStyles('module_pages.level_contents.assemble_the_code_mode.submit_button.border_width') as double;
    final submitBorderRadius = styles.getStyles('module_pages.level_contents.assemble_the_code_mode.submit_button.border_radius') as double;
    final submitStroke = styles.getStyles('module_pages.level_contents.assemble_the_code_mode.submit_button.stroke_color') as LinearGradient;
    final submitTextColor = styles.getStyles('module_pages.level_contents.assemble_the_code_mode.submit_button.text.color') as Color;
    final submitTextSize = styles.getStyles('module_pages.level_contents.assemble_the_code_mode.submit_button.text.font_size') as double;
    final submitTextWeight = styles.getStyles('module_pages.level_contents.assemble_the_code_mode.submit_button.text.font_weight') as FontWeight;

    // Build UI
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question
        if (question.isNotEmpty) ...[
          Container(
            width: double.infinity,
            alignment: Alignment.center,
            child: Text(
              question,
              textAlign: TextAlign.center,
              style: TextStyle(color: questionColor, fontSize: questionFontSize, fontWeight: questionFontWeight),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Code area
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(color: codeAreaBg, borderRadius: BorderRadius.circular(codeAreaBorderRadius)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(_lines.length, (lineIndex) {
                final indentLevels = _computeIndentLevelsFromLines(_assembledLines());
                final indent = (indentLevels.length > lineIndex && _assembledLines()[lineIndex].trim().isNotEmpty)
                  ? indentLevels[lineIndex]
                  : 0;

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6.0),
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                decoration: BoxDecoration(color: codeLineBg, borderRadius: BorderRadius.circular(codeLineBorderRadius)),
                child: Row(
                  children: [
                    SizedBox(width: indent * 16.0),
                    Expanded(
                      child: DragTarget<int>(
                        builder: (context, candidateData, rejectedData) {
                          return Container(
                            key: _lineRowKeys[lineIndex],
                            constraints: BoxConstraints(minHeight: containerHeight),
                            decoration: const BoxDecoration(color: Colors.transparent),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: _buildLineChildren(lineIndex),
                              ),
                            ),
                          );
                        },
                        onWillAcceptWithDetails: (details) => true,
                        onAcceptWithDetails: (details) {
                          // compute insert index from drop position
                          final renderBox = _lineRowKeys[lineIndex].currentContext?.findRenderObject() as RenderBox?;
                          if (renderBox == null) {
                            _insertIntoLine(lineIndex: lineIndex, insertIndex: _lines[lineIndex].length, choiceId: details.data);
                            return;
                          }
                          final local = renderBox.globalToLocal(details.offset);
                          final insertAt = _computeInsertIndexFromLocal(lineIndex, local.dx);
                          _insertIntoLine(lineIndex: lineIndex, insertIndex: insertAt, choiceId: details.data);
                          _hoverInsert[lineIndex] = null;
                        },
                        onMove: (details) {
                          final renderBox = _lineRowKeys[lineIndex].currentContext?.findRenderObject() as RenderBox?;
                          if (renderBox == null) return;
                          final local = renderBox.globalToLocal(details.offset);
                          final insertAt = _computeInsertIndexFromLocal(lineIndex, local.dx);
                          setState(() => _hoverInsert[lineIndex] = insertAt);
                        },
                        onLeave: (data) {
                          setState(() => _hoverInsert[lineIndex] = null);
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: 12),

        // Bank of choices
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: _bankChoices.map((c) => _buildBankDraggable(c, choiceMinWidth, choiceMinHeight, choiceBorderRadius, choiceBorderWidth, choiceBackground, choiceStroke, choiceTextColor, choiceTextSize, choiceTextWeight)).toList(),
          ),
        ),

        const SizedBox(height: 32),

        // Submit button
        Center(
          child: Container(
            width: submitWidth,
            height: submitHeight,
            decoration: BoxDecoration(gradient: submitStroke, borderRadius: BorderRadius.circular(submitBorderRadius)),
            child: Padding(
              padding: EdgeInsets.all(submitBorderWidth),
              child: Material(
                color: submitBackground,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular((submitBorderRadius - submitBorderWidth).clamp(0, submitBorderRadius))),
                child: InkWell(
                  borderRadius: BorderRadius.circular((submitBorderRadius - submitBorderWidth).clamp(0, submitBorderRadius)),
                  onTap: _onSubmit,
                  child: Center(
                    child: Text('Submit', style: TextStyle(color: submitTextColor, fontSize: submitTextSize, fontWeight: submitTextWeight)),
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  List<Widget> _buildLineChildren(int lineIndex) {
    final list = _lines[lineIndex];
    final children = <Widget>[];

    // leading ghost placeholder only (no separate tiny insert targets)
    final hoverIndex = _hoverInsert[lineIndex];
    if (hoverIndex != null && hoverIndex == 0) children.add(_buildGhostPlaceholder());

    for (var i = 0; i < list.length; i++) {
      final id = list[i];
      final choice = _choices.firstWhere((c) => c.id == id);
      // assigned draggable wrapped with a measurable key for hit testing
      final keyStr = '${lineIndex}_$i';
      final key = _childKeys.putIfAbsent(keyStr, () => GlobalKey());
      // add a small spacer before each chip except the first to control gap
      if (i > 0) children.add(const SizedBox(width: 4));
      // Render assigned draggable directly
      children.add(Container(key: key, child: _buildAssignedDraggable(choice)));
      if (hoverIndex != null && hoverIndex == i + 1) children.add(_buildGhostPlaceholder());
    }

    return children;
  }

  Widget _buildGhostPlaceholder() {
    final styles = AppStyles();
    final width = styles.getStyles('module_pages.level_contents.assemble_the_code_mode.ghost_placeholder.width') as double;
    final height = styles.getStyles('module_pages.level_contents.assemble_the_code_mode.ghost_placeholder.height') as double;
    final borderRadius = styles.getStyles('module_pages.level_contents.assemble_the_code_mode.ghost_placeholder.border_radius') as double;
    final bg = styles.getStyles('module_pages.level_contents.assemble_the_code_mode.ghost_placeholder.background_color') as Color;

    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(borderRadius)),
    );
  }

  int _computeInsertIndexFromLocal(int lineIndex, double localDx) {
    final rowKey = _lineRowKeys[lineIndex];
    final rowBox = rowKey.currentContext?.findRenderObject() as RenderBox?;
    if (rowBox == null) return _lines[lineIndex].length;

    final positions = <Map<String, double>>[]; // {'left':..., 'width': ...}
    final list = _lines[lineIndex];
    for (var i = 0; i < list.length; i++) {
      final keyStr = '${lineIndex}_$i';
      final k = _childKeys[keyStr];
      if (k == null) continue;
      final childBox = k.currentContext?.findRenderObject() as RenderBox?;
      if (childBox == null) continue;
      final childGlobal = childBox.localToGlobal(Offset.zero);
      final childLocal = rowBox.globalToLocal(childGlobal);
      positions.add({'left': childLocal.dx, 'width': childBox.size.width});
    }

    if (positions.isEmpty) return 0;

    // decide by comparing to midpoints
    for (var i = 0; i < positions.length; i++) {
      final left = positions[i]['left']!;
      final width = positions[i]['width']!;
      final midpoint = left + width / 2;
      if (localDx < midpoint) return i;
    }
    return positions.length;
  }

  Widget _buildBankDraggable(
    _ChoiceItem c,
    double minWidth,
    double minHeight,
    double borderRadius,
    double borderWidth,
    LinearGradient background,
    LinearGradient stroke,
    Color textColor,
    double textSize,
    FontWeight textWeight,
  ) {
    return Draggable<int>(
      data: c.id,
      feedback: Material(elevation: 4, borderRadius: BorderRadius.circular(borderRadius), child: _buildChoiceChip(c, minWidth, minHeight, borderRadius, borderWidth, background, stroke, textColor, textSize, textWeight, isFeedback: true)),
      childWhenDragging: Opacity(opacity: 0.3, child: _buildChoiceChip(c, minWidth, minHeight, borderRadius, borderWidth, background, stroke, textColor, textSize, textWeight)),
      child: _buildChoiceChip(c, minWidth, minHeight, borderRadius, borderWidth, background, stroke, textColor, textSize, textWeight),
    );
  }

  Widget _buildAssignedDraggable(_ChoiceItem c) {
    final styles = AppStyles();
    final minWidth = styles.getStyles('module_pages.level_contents.assemble_the_code_mode.choice_container.min_width') as double;
    final minHeight = styles.getStyles('module_pages.level_contents.assemble_the_code_mode.choice_container.min_height') as double;
    final borderRadius = styles.getStyles('module_pages.level_contents.assemble_the_code_mode.choice_container.border_radius') as double;
    final borderWidth = styles.getStyles('module_pages.level_contents.assemble_the_code_mode.choice_container.border_width') as double;
    final background = styles.getStyles('module_pages.level_contents.assemble_the_code_mode.choice_container.background_color') as LinearGradient;
    final stroke = styles.getStyles('module_pages.level_contents.assemble_the_code_mode.choice_container.stroke_color') as LinearGradient;
    final textColor = styles.getStyles('module_pages.level_contents.assemble_the_code_mode.choice_container.text.color') as Color;
    final textSize = styles.getStyles('module_pages.level_contents.assemble_the_code_mode.choice_container.text.font_size') as double;
    final textWeight = styles.getStyles('module_pages.level_contents.assemble_the_code_mode.choice_container.text.font_weight') as FontWeight;

    return Draggable<int>(
      data: c.id,
      feedback: Material(elevation: 4, borderRadius: BorderRadius.circular(borderRadius), child: _buildChoiceChip(c, minWidth, minHeight, borderRadius, borderWidth, background, stroke, textColor, textSize, textWeight, isFeedback: true)),
      childWhenDragging: SizedBox(width: minWidth, height: minHeight),
      onDraggableCanceled: (_, __) {
        _removeFromLine(c.id);
      },
      child: _buildChoiceChip(c, minWidth, minHeight, borderRadius, borderWidth, background, stroke, textColor, textSize, textWeight),
    );
  }

  Widget _buildChoiceChip(
    _ChoiceItem c,
    double minWidth,
    double minHeight,
    double borderRadius,
    double borderWidth,
    LinearGradient background,
    LinearGradient stroke,
    Color textColor,
    double textSize,
    FontWeight textWeight, {
    bool isFeedback = false,
  }) {
    final chip = ConstrainedBox(
      constraints: BoxConstraints(minWidth: minWidth, minHeight: minHeight),
      child: IntrinsicWidth(
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(borderRadius), gradient: stroke),
          child: Padding(
            padding: EdgeInsets.all(borderWidth),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(gradient: background, borderRadius: BorderRadius.circular((borderRadius - borderWidth).clamp(0, borderRadius))),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(c.text, textAlign: TextAlign.center, style: TextStyle(color: textColor, fontSize: textSize, fontWeight: textWeight)),
              ),
            ),
          ),
        ),
      ),
    );

    if (isFeedback) return Material(elevation: 4, borderRadius: BorderRadius.circular(borderRadius), child: chip);
    return chip;
  }
}

class _ChoiceItem {
  final int id;
  final String text;
  _ChoiceItem({required this.id, required this.text});
}
