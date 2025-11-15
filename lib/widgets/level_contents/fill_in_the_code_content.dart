import 'package:flutter/material.dart';
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
    final codeBg = Colors.grey.shade100;
    const codeText = Colors.black87;

    // Build code lines with placeholders replaced by drag targets
    int runningIndex = 0;

    final codeWidgets = <Widget>[];
    for (final line in widget.content.codeLines) {
      final parts = line.split('[_]');
      final children = <InlineSpan>[];

      for (int i = 0; i < parts.length; i++) {
        if (parts[i].isNotEmpty) {
          children.add(TextSpan(text: parts[i], style: const TextStyle(color: codeText)));
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
                constraints: const BoxConstraints(minWidth: 48),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                margin: const EdgeInsets.only(left: 8, right: 8),
                decoration: BoxDecoration(
                  color: has ? Colors.white : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blueGrey.shade100),
                ),
                child: has
                    ? _buildAssignedDraggable(_choices.firstWhere((c) => c.id == assignedId))
                    : const SizedBox(width: 48, height: 36),
              );
                },
                  onWillAcceptWithDetails: (details) => true,
                onAcceptWithDetails: (details) {
                  _assignToContainer(containerIndex, details.data);
                },
          );

          // Use WidgetSpan to place the container inline with code text
          children.add(WidgetSpan(child: container, alignment: PlaceholderAlignment.middle));
        }
      }

      codeWidgets.add(
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 6.0),
          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style.copyWith(fontSize: 14, color: codeText),
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
          decoration: BoxDecoration(color: codeBg, borderRadius: BorderRadius.circular(8.0)),
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

        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _onSubmit,
                child: const Text('Submit'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBankDraggable(_ChoiceItem c) {
    return Draggable<int>(
      data: c.id,
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: _buildChoiceChip(c, isFeedback: true),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: _buildChoiceChip(c)),
      child: _buildChoiceChip(c),
    );
  }

  Widget _buildAssignedDraggable(_ChoiceItem c) {
    return Draggable<int>(
      data: c.id,
      feedback: Material(elevation: 4, borderRadius: BorderRadius.circular(8), child: _buildChoiceChip(c, isFeedback: true)),
      childWhenDragging: const SizedBox(width: 56, height: 36),
      onDraggableCanceled: (_, __) {
        _unassignChoice(c.id);
      },
      child: _buildChoiceChip(c),
    );
  }

  Widget _buildChoiceChip(_ChoiceItem c, {bool isFeedback = false}) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 56),
      child: IntrinsicWidth(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isFeedback
                ? const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))]
                : const [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
          ),
            child: Text(
            c.text,
            textAlign: TextAlign.center,
            style: DefaultTextStyle.of(context).style.copyWith(fontSize: 14),
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
