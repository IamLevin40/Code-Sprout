import 'package:flutter/material.dart';
import '../../models/styles_schema.dart';
import '../../models/course_data.dart';

class FillInTheCodeContentWidget extends StatefulWidget {
  final FillInTheCodeContent content;
  final ValueChanged<bool> onAnswer; // true = correct, false = incorrect

  const FillInTheCodeContentWidget({
    super.key,
    required this.content,
    required this.onAnswer,
  });

  @override
  State<FillInTheCodeContentWidget> createState() => _FillInTheCodeContentWidgetState();
}

class _FillInTheCodeContentWidgetState extends State<FillInTheCodeContentWidget> {
  late List<_ChoiceItem> _choices; // flattened choices with ids
  late int _totalBlanks;
  // assignment: containerIndex -> choiceId
  final Map<int, int> _assignment = {};

  @override
  void initState() {
    super.initState();
    _initChoices();
  }

  void _initChoices() {
    _choices = [];
    final choices = widget.content.choices;
    for (var i = 0; i < choices.length; i++) {
      _choices.add(_ChoiceItem(id: i, text: choices[i]));
    }
    _choices.shuffle();

    // Count blanks across all code lines
    int blanks = 0;
    for (final line in widget.content.codeLines) {
      final parts = line.split('[_]');
      blanks += (parts.length - 1).clamp(0, parts.length);
    }
    _totalBlanks = blanks;
  }

  List<_ChoiceItem> get _bankChoices {
    final assignedIds = _assignment.values.toSet();
    return _choices.where((c) => !assignedIds.contains(c.id)).toList();
  }

  void _assignToContainer(int containerIndex, int choiceId) {
    setState(() {
      // remove this choice from any other container
      _assignment.removeWhere((k, v) => v == choiceId);
      // assign to new container (overwrites any existing)
      _assignment[containerIndex] = choiceId;
    });
  }

  void _unassignChoice(int choiceId) {
    setState(() {
      _assignment.removeWhere((k, v) => v == choiceId);
    });
  }

  Future<void> _onSubmit() async {
    // Build assigned answers in order
    final assigned = <String>[];
    for (int i = 0; i < _totalBlanks; i++) {
      final cid = _assignment[i];
      if (cid == null) {
        assigned.add('');
      } else {
        final choice = _choices.firstWhere((c) => c.id == cid, orElse: () => const _ChoiceItem(id: -1, text: ''));
        assigned.add(choice.text);
      }
    }

    final correct = widget.content.correctAnswers;
    final isCorrect = assigned.length == correct.length &&
        List.generate(correct.length, (i) => assigned[i] == correct[i]).every((v) => v);

    if (context.mounted) {
      widget.onAnswer(isCorrect);
    }
  }

  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();

    final codeAreaBg = styles.getStyles('module_pages.level_contents.fill_in_the_code_mode.code_area.background_color') as Color;
    final codeAreaBorderRadius = styles.getStyles('module_pages.level_contents.fill_in_the_code_mode.code_area.border_radius') as double;

    final codeLineBg = styles.getStyles('module_pages.level_contents.fill_in_the_code_mode.code_line_area.background_color') as Color;
    final codeLineBorderRadius = styles.getStyles('module_pages.level_contents.fill_in_the_code_mode.code_line_area.border_radius') as double;

    final codeTextColor = styles.getStyles('module_pages.level_contents.fill_in_the_code_mode.code_text.color') as Color;
    final codeTextFontSize = styles.getStyles('module_pages.level_contents.fill_in_the_code_mode.code_text.font_size') as double;
    final codeTextFontWeight = styles.getStyles('module_pages.level_contents.fill_in_the_code_mode.code_text.font_weight') as FontWeight;

    final containerMinWidth = styles.getStyles('module_pages.level_contents.fill_in_the_code_mode.code_container.min_width') as double;
    final containerHeight = styles.getStyles('module_pages.level_contents.fill_in_the_code_mode.code_container.height') as double;
    final containerBorderRadius = styles.getStyles('module_pages.level_contents.fill_in_the_code_mode.code_container.border_radius') as double;
    final containerBorderWidth = styles.getStyles('module_pages.level_contents.fill_in_the_code_mode.code_container.border_width') as double;
    final containerBackground = styles.getStyles('module_pages.level_contents.fill_in_the_code_mode.code_container.background_color') as LinearGradient;
    final containerStroke = styles.getStyles('module_pages.level_contents.fill_in_the_code_mode.code_container.stroke_color') as LinearGradient;

    final submitWidth = styles.getStyles('module_pages.level_contents.fill_in_the_code_mode.submit_button.width') as double;
    final submitHeight = styles.getStyles('module_pages.level_contents.fill_in_the_code_mode.submit_button.height') as double;
    final submitBackground = styles.getStyles('module_pages.level_contents.fill_in_the_code_mode.submit_button.background_color') as Color;
    final submitBorderWidth = styles.getStyles('module_pages.level_contents.fill_in_the_code_mode.submit_button.border_width') as double;
    final submitBorderRadius = styles.getStyles('module_pages.level_contents.fill_in_the_code_mode.submit_button.border_radius') as double;
    final submitStroke = styles.getStyles('module_pages.level_contents.fill_in_the_code_mode.submit_button.stroke_color') as LinearGradient;
    final submitTextColor = styles.getStyles('module_pages.level_contents.fill_in_the_code_mode.submit_button.text.color') as Color;
    final submitTextFontSize = styles.getStyles('module_pages.level_contents.fill_in_the_code_mode.submit_button.text.font_size') as double;
    final submitTextFontWeight = styles.getStyles('module_pages.level_contents.fill_in_the_code_mode.submit_button.text.font_weight') as FontWeight;

    // Build code lines with placeholders replaced by drag targets
    int runningIndex = 0;

    final codeWidgets = <Widget>[];
    for (final line in widget.content.codeLines) {
      final parts = line.split('[_]');
      final children = <InlineSpan>[];

      for (int i = 0; i < parts.length; i++) {
        if (parts[i].isNotEmpty) {
          children.add(TextSpan(text: parts[i], style: TextStyle(color: codeTextColor, fontSize: codeTextFontSize, fontWeight: codeTextFontWeight)));
        }

        if (i < parts.length - 1) {
          final containerIndex = runningIndex;
          runningIndex += 1;

          // Build a widget representing the container; use a DragTarget
          final assignedId = _assignment[containerIndex];

          final container = DragTarget<int>(
            builder: (context, candidateData, rejectedData) {
              final has = assignedId != null;
              return Container(
                constraints: BoxConstraints(minWidth: containerMinWidth),
                margin: const EdgeInsets.only(left: 8, right: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(containerBorderRadius),
                  gradient: containerStroke,
                ),
                child: Padding(
                  padding: EdgeInsets.all(containerBorderWidth),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: containerBackground,
                      borderRadius: BorderRadius.circular(containerBorderRadius - containerBorderWidth),
                    ),
                    child: has
                        ? _buildAssignedDraggable(_choices.firstWhere((c) => c.id == assignedId), containerMinWidth, containerHeight)
                        : SizedBox(width: containerMinWidth, height: containerHeight),
                  ),
                ),
              );
            },
            onWillAcceptWithDetails: (details) => true,
            onAcceptWithDetails: (details) {
              _assignToContainer(containerIndex, details.data);
            },
          );

          children.add(WidgetSpan(child: container, alignment: PlaceholderAlignment.middle));
        }
      }

      codeWidgets.add(
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: codeLineBg,
            borderRadius: BorderRadius.circular(codeLineBorderRadius),
          ),
          child: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style.copyWith(fontSize: codeTextFontSize, color: codeTextColor, fontWeight: codeTextFontWeight),
              children: children,
            ),
          ),
        ),
      );
    }

    // Build choices bank
    final bank = Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: _bankChoices.map((c) => _buildBankDraggable(c)).toList(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Code area
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(color: codeAreaBg, borderRadius: BorderRadius.circular(codeAreaBorderRadius)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: codeWidgets),
        ),

        const SizedBox(height: 12),

        // Bank area
        DragTarget<int>(
          builder: (context, candidateData, rejectedData) => Container(
            padding: const EdgeInsets.all(12.0),
            color: Colors.transparent,
            child: Center(child: bank),
          ),
            onWillAcceptWithDetails: (details) => true,
            onAcceptWithDetails: (details) {
              _unassignChoice(details.data);
            },
          ),

        const SizedBox(height: 16),

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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(submitBorderRadius - submitBorderWidth)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(submitBorderRadius - submitBorderWidth),
                  onTap: _onSubmit,
                  child: Center(
                    child: Text('Submit', style: TextStyle(color: submitTextColor, fontSize: submitTextFontSize, fontWeight: submitTextFontWeight)),
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

  Widget _buildBankDraggable(_ChoiceItem c) {
    final styles = AppStyles();
    final choiceBorderRadius = styles.getStyles('module_pages.level_contents.fill_in_the_code_mode.choice_container.border_radius') as double;
    return Draggable<int>(
      data: c.id,
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(choiceBorderRadius),
        child: _buildChoiceChip(c, isFeedback: true),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: _buildChoiceChip(c)),
      child: _buildChoiceChip(c),
    );
  }

  Widget _buildAssignedDraggable(_ChoiceItem c, double width, double height) {
    final styles = AppStyles();
    final choiceBorderRadius = styles.getStyles('module_pages.level_contents.fill_in_the_code_mode.choice_container.border_radius') as double;
    return Draggable<int>(
      data: c.id,
      feedback: Material(elevation: 4, borderRadius: BorderRadius.circular(choiceBorderRadius), child: _buildChoiceChip(c, isFeedback: true)),
      childWhenDragging: SizedBox(width: width, height: height),
      onDraggableCanceled: (_, __) {
        _unassignChoice(c.id);
      },
      child: _buildChoiceChip(c),
    );
  }

  Widget _buildChoiceChip(_ChoiceItem c, {bool isFeedback = false}) {
    final styles = AppStyles();
    final minWidth = styles.getStyles('module_pages.level_contents.fill_in_the_code_mode.choice_container.min_width') as double;
    final minHeight = styles.getStyles('module_pages.level_contents.fill_in_the_code_mode.choice_container.min_height') as double;
    final borderRadius = styles.getStyles('module_pages.level_contents.fill_in_the_code_mode.choice_container.border_radius') as double;
    final borderWidth = styles.getStyles('module_pages.level_contents.fill_in_the_code_mode.choice_container.border_width') as double;
    final background = styles.getStyles('module_pages.level_contents.fill_in_the_code_mode.choice_container.background_color') as LinearGradient;
    final stroke = styles.getStyles('module_pages.level_contents.fill_in_the_code_mode.choice_container.stroke_color') as LinearGradient;
    final textColor = styles.getStyles('module_pages.level_contents.fill_in_the_code_mode.choice_container.text.color') as Color;
    final textSize = styles.getStyles('module_pages.level_contents.fill_in_the_code_mode.choice_container.text.font_size') as double;
    final textWeight = styles.getStyles('module_pages.level_contents.fill_in_the_code_mode.choice_container.text.font_weight') as FontWeight;

    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: minWidth, minHeight: minHeight),
      child: IntrinsicWidth(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: stroke,
          ),
          child: Padding(
            padding: EdgeInsets.all(borderWidth),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: background,
                borderRadius: BorderRadius.circular(borderRadius - borderWidth),
              ),
              child: Text(
                c.text,
                textAlign: TextAlign.center,
                style: TextStyle(color: textColor, fontSize: textSize, fontWeight: textWeight),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceItem {
  final int id;
  final String text;
  const _ChoiceItem({required this.id, required this.text});
}
