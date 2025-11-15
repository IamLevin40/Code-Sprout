import 'package:flutter/material.dart';
import '../../models/styles_schema.dart';
import '../../models/course_data.dart';
import '../../widgets/level_popups/correct_popup.dart';
import '../../widgets/level_popups/incorrect_popup.dart';

class TrueOrFalseContentWidget extends StatelessWidget {
  final TrueOrFalseContent content;
  final VoidCallback onCorrectProceed;

  const TrueOrFalseContentWidget({
    super.key,
    required this.content,
    required this.onCorrectProceed,
  });

  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();
    final titleColor = styles.getStyles('module_pages.title.color') as Color;
    final titleFontSize = styles.getStyles('module_pages.title.font_size') as double;
    final titleFontWeight = styles.getStyles('module_pages.title.font_weight') as FontWeight;

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
        const SizedBox(height: 18),

        // True button
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 12.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
              ),
                onPressed: () async {
                final correct = correctAnswer == true;
                if (context.mounted) {
                  if (correct) {
                    await CorrectLevelPopup.show(context);
                    onCorrectProceed();
                  } else {
                    await IncorrectLevelPopup.show(context);
                  }
                }
              },
              child: const Text('True', textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
            ),
          ),
        ),

        // False button
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 12.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
              ),
                onPressed: () async {
                final correct = correctAnswer == false;
                if (context.mounted) {
                  if (correct) {
                    await CorrectLevelPopup.show(context);
                    onCorrectProceed();
                  } else {
                    await IncorrectLevelPopup.show(context);
                  }
                }
              },
              child: const Text('False', textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
            ),
          ),
        ),
      ],
    );
  }
}
