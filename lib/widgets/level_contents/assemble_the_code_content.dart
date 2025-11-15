import 'package:flutter/material.dart';
import '../../models/course_data.dart';

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
        if (trimmed.startsWith(s + ' ') || trimmed == s) {
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
      if (s.codeUnitAt(i) == 32) count++; else break; // count spaces
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question
        if (question.isNotEmpty) ...[
          Text(question, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
        ],

        // Code area
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8.0)),
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
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8.0)),
                child: Row(
                  children: [
                    SizedBox(width: indent * 16.0),
                    Expanded(
                      child: DragTarget<int>(
                        builder: (context, candidateData, rejectedData) {
                          return Container(
                            key: _lineRowKeys[lineIndex],
                            constraints: const BoxConstraints(minHeight: 48),
                            decoration: BoxDecoration(
                              color: candidateData.isNotEmpty ? Colors.blue.shade50 : Colors.transparent,
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: _buildLineChildren(lineIndex),
                              ),
                            ),
                          );
                        },
                        onWillAccept: (data) => data != null,
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

        // Bank of choices (centered)
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: _bankChoices.map((c) => _buildBankDraggable(c)).toList(),
          ),
        ),

        const SizedBox(height: 16),

        Row(children: [Expanded(child: ElevatedButton(onPressed: _onSubmit, child: const Text('Submit')))]),
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
      children.add(Container(key: key, child: _buildAssignedDraggable(choice)));
      if (hoverIndex != null && hoverIndex == i + 1) children.add(_buildGhostPlaceholder());
    }

    return children;
  }

  Widget _buildGhostPlaceholder() {
    return Container(
      width: 56,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      decoration: BoxDecoration(color: Colors.blue.shade200, borderRadius: BorderRadius.circular(6)),
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

  Widget _buildBankDraggable(_ChoiceItem c) {
    return Draggable<int>(
      data: c.id,
      feedback: Material(elevation: 4, borderRadius: BorderRadius.circular(8), child: _buildChip(c, isFeedback: true)),
      childWhenDragging: Opacity(opacity: 0.3, child: _buildChip(c)),
      child: _buildChip(c),
    );
  }

  Widget _buildAssignedDraggable(_ChoiceItem c) {
    return Draggable<int>(
      data: c.id,
      feedback: Material(elevation: 4, borderRadius: BorderRadius.circular(8), child: _buildChip(c, isFeedback: true)),
      childWhenDragging: const SizedBox(width: 8, height: 36),
      onDraggableCanceled: (_, __) {
        // return to bank
        _removeFromLine(c.id);
      },
      child: Align(alignment: Alignment.centerLeft, child: _buildChip(c, alignLeft: true)),
    );
  }

  Widget _buildChip(_ChoiceItem c, {bool isFeedback = false, bool alignLeft = false}) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Text(
          c.text,
          textAlign: alignLeft ? TextAlign.left : TextAlign.center,
          style: DefaultTextStyle.of(context).style.copyWith(fontSize: 14),
        ),
      ),
    );

    if (isFeedback) return Material(elevation: 4, borderRadius: BorderRadius.circular(8), child: child);
    return child;
  }
}

class _ChoiceItem {
  final int id;
  final String text;
  _ChoiceItem({required this.id, required this.text});
}
