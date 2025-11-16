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

    final titleColor = styles.getStyles('module_pages.level_contents.multiple_choice_mode.question_text.color') as Color;
    final titleFontSize = styles.getStyles('module_pages.level_contents.multiple_choice_mode.question_text.font_size') as double;
    final titleFontWeight = styles.getStyles('module_pages.level_contents.multiple_choice_mode.question_text.font_weight') as FontWeight;

    final choiceBorderRadius = styles.getStyles('module_pages.level_contents.multiple_choice_mode.choice_card.border_radius') as double;
    final choiceBorderWidth = styles.getStyles('module_pages.level_contents.multiple_choice_mode.choice_card.border_width') as double;
    final choiceBackground = styles.getStyles('module_pages.level_contents.multiple_choice_mode.choice_card.background_color') as LinearGradient;
    final choiceStroke = styles.getStyles('module_pages.level_contents.multiple_choice_mode.choice_card.stroke_color') as LinearGradient;
    final choiceTextColor = styles.getStyles('module_pages.level_contents.multiple_choice_mode.choice_card.text.color') as Color;
    final choiceTextFontSize = styles.getStyles('module_pages.level_contents.multiple_choice_mode.choice_card.text.font_size') as double;
    final choiceTextFontWeight = styles.getStyles('module_pages.level_contents.multiple_choice_mode.choice_card.text.font_weight') as FontWeight;

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
        const SizedBox(height: 16),

        // Choice cards
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: _options.map((opt) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 32.0),
              child: SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: choiceStroke,
                    borderRadius: BorderRadius.circular(choiceBorderRadius),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(choiceBorderWidth),
                    child: Material(
                      color: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(choiceBorderRadius - choiceBorderWidth),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(choiceBorderRadius - choiceBorderWidth),
                        onTap: () => _onSelect(opt),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: choiceBackground,
                            borderRadius: BorderRadius.circular(choiceBorderRadius - choiceBorderWidth),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                          child: Text(
                            opt,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: choiceTextColor, fontSize: choiceTextFontSize, fontWeight: choiceTextFontWeight),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
