import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/styles_schema.dart';
import '../../models/course_data.dart';

class MultipleChoiceContentWidget extends StatefulWidget {
  final MultipleChoiceContent content;
  final ValueChanged<bool> onAnswer; // true = correct, false = incorrect

  const MultipleChoiceContentWidget({
    super.key,
    required this.content,
    required this.onAnswer,
  });

  @override
  State<MultipleChoiceContentWidget> createState() => _MultipleChoiceContentWidgetState();
}

class _MultipleChoiceContentWidgetState extends State<MultipleChoiceContentWidget> {
  late List<String> _options;
  final Random _rnd = Random();

  @override
  void initState() {
    super.initState();
    _shuffleOptions();
  }

  void _shuffleOptions() {
    _options = [widget.content.correctAnswer, ...widget.content.incorrectAnswers];
    _options.shuffle(_rnd);
    setState(() {});
  }

  Future<void> _onSelect(String selected) async {
    final correct = widget.content.correctAnswer;
    final isCorrect = selected == correct;
    widget.onAnswer(isCorrect);
  }

  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();
    final titleColor = styles.getStyles('module_pages.title.color') as Color;
    final titleFontSize = styles.getStyles('module_pages.title.font_size') as double;
    final titleFontWeight = styles.getStyles('module_pages.title.font_weight') as FontWeight;

    final question = widget.content.question;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Question
        Text(
          question,
          style: TextStyle(color: titleColor, fontSize: titleFontSize, fontWeight: titleFontWeight),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),

        // Answer cards
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: _options.map((opt) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 12.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  ),
                  onPressed: () => _onSelect(opt),
                  child: Text(opt, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
