import 'package:flutter/material.dart';
import '../../models/styles_schema.dart';
import '../../models/course_data.dart';

class TrueOrFalseContentWidget extends StatelessWidget {
  final TrueOrFalseContent content;
  final ValueChanged<bool> onAnswer; // true = correct, false = incorrect

  const TrueOrFalseContentWidget({
    super.key,
    required this.content,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();

    final titleColor = styles.getStyles('module_pages.level_contents.true_or_false_mode.question_text.color') as Color;
    final titleFontSize = styles.getStyles('module_pages.level_contents.true_or_false_mode.question_text.font_size') as double;
    final titleFontWeight = styles.getStyles('module_pages.level_contents.true_or_false_mode.question_text.font_weight') as FontWeight;

    final choiceBorderRadius = styles.getStyles('module_pages.level_contents.true_or_false_mode.choice_card.border_radius') as double;
    final choiceBorderWidth = styles.getStyles('module_pages.level_contents.true_or_false_mode.choice_card.border_width') as double;
    final choiceBackground = styles.getStyles('module_pages.level_contents.true_or_false_mode.choice_card.background_color') as LinearGradient;
    final choiceStroke = styles.getStyles('module_pages.level_contents.true_or_false_mode.choice_card.stroke_color') as LinearGradient;
    final choiceTextColor = styles.getStyles('module_pages.level_contents.true_or_false_mode.choice_card.text.color') as Color;
    final choiceTextFontSize = styles.getStyles('module_pages.level_contents.true_or_false_mode.choice_card.text.font_size') as double;
    final choiceTextFontWeight = styles.getStyles('module_pages.level_contents.true_or_false_mode.choice_card.text.font_weight') as FontWeight;

    final question = content.question;
    final bool correctAnswer = content.correctAnswer;

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

        // True button
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 96.0),
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
                    onTap: () async {
                      final correct = correctAnswer == true;
                      onAnswer(correct);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: choiceBackground,
                        borderRadius: BorderRadius.circular(choiceBorderRadius - choiceBorderWidth),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                      child: Text('TRUE', textAlign: TextAlign.center, style: TextStyle(color: choiceTextColor, fontSize: choiceTextFontSize, fontWeight: choiceTextFontWeight)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // False button
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 96.0),
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
                    onTap: () async {
                      final correct = correctAnswer == false;
                      onAnswer(correct);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: choiceBackground,
                        borderRadius: BorderRadius.circular(choiceBorderRadius - choiceBorderWidth),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                      child: Text('FALSE', textAlign: TextAlign.center, style: TextStyle(color: choiceTextColor, fontSize: choiceTextFontSize, fontWeight: choiceTextFontWeight)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
