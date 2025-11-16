import 'package:flutter/material.dart';
import '../../models/course_data.dart';
import '../../models/course_data_schema.dart';
import '../level_contents/lecture_content.dart';
import '../level_contents/multiple_choice_content.dart';
import '../level_contents/true_or_false_content.dart';
import '../level_contents/fill_in_the_code_content.dart';
import '../level_contents/assemble_the_code_content.dart';
import '../level_popups/correct_popup.dart';
import '../level_popups/incorrect_popup.dart';

/// Extracted level content area used by `ModuleLevelsPage`.
class LevelContentDisplay extends StatelessWidget {
  final Level? level;
  final int currentLevelIndex;
  final int totalLevels;
  final Future<void> Function() onNext;

  const LevelContentDisplay({
    super.key,
    required this.level,
    required this.currentLevelIndex,
    required this.totalLevels,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final mode = level?.mode ?? '';
    final modeInfo = CourseDataSchema().getModeDisplay(mode);
    final modeTitle = modeInfo['title'] ?? mode;
    final modeDesc = modeInfo['description'] ?? '';

    final bool isLastLevel = currentLevelIndex >= totalLevels;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          modeTitle,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            final lec = level?.getLectureContent();
            if (lec != null) {
              return Align(
                alignment: Alignment.centerLeft,
                child: LectureContentWidget(lectureContent: lec, onProceed: () async => await onNext()),
              );
            }
          }

          // Multiple choice mode
          if (mode.toLowerCase() == 'multiple_choice') {
            final mc = level?.getMultipleChoiceContent();
            if (mc != null) {
              return MultipleChoiceContentWidget(
                content: mc,
                onAnswer: (correct) async {
                  if (correct) {
                    if (!isLastLevel) {
                      await CorrectLevelPopup.show(context);
                      await onNext();
                    } else {
                      await onNext();
                    }
                  } else {
                    await IncorrectLevelPopup.show(context);
                  }
                },
              );
            }
          }

          // True/False mode
          if (mode.toLowerCase() == 'true_or_false') {
            final tf = level?.getTrueOrFalseContent();
            if (tf != null) {
              return TrueOrFalseContentWidget(
                content: tf,
                onAnswer: (correct) async {
                  if (correct) {
                    if (!isLastLevel) {
                      await CorrectLevelPopup.show(context);
                      await onNext();
                    } else {
                      await onNext();
                    }
                  } else {
                    await IncorrectLevelPopup.show(context);
                  }
                },
              );
            }
          }

          // Fill-in-the-code mode
          if (mode.toLowerCase() == 'fill_in_the_code') {
            final fill = level?.getFillInTheCodeContent();
            if (fill != null) {
              return FillInTheCodeContentWidget(
                content: fill,
                onAnswer: (correct) async {
                  if (correct) {
                    if (!isLastLevel) {
                      await CorrectLevelPopup.show(context);
                      await onNext();
                    } else {
                      await onNext();
                    }
                  } else {
                    await IncorrectLevelPopup.show(context);
                  }
                },
              );
            }
          }

          // Assemble-the-code mode
          if (mode.toLowerCase() == 'assemble_the_code') {
            final ac = level?.getAssembleTheCodeContent();
            if (ac != null) {
              return AssembleTheCodeContentWidget(
                content: ac,
                onAnswer: (correct) async {
                  if (correct) {
                    if (!isLastLevel) {
                      await CorrectLevelPopup.show(context);
                      await onNext();
                    } else {
                      await onNext();
                    }
                  } else {
                    await IncorrectLevelPopup.show(context);
                  }
                },
              );
            }
          }

          // Fallback content area for other modes
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12.0),
                margin: const EdgeInsets.only(bottom: 12.0),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8.0)),
                child: Text('Content for mode "$mode" is not yet implemented.', style: TextStyle(color: Colors.grey.shade800)),
              ),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async => await onNext(),
                  child: const Text('Next'),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}
