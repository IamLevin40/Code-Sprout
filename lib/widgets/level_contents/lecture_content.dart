import 'package:flutter/material.dart';
import '../../models/styles_schema.dart';
import '../../models/course_data.dart';

class LectureContentWidget extends StatelessWidget {
  final LectureContent lectureContent;
  final VoidCallback onProceed;

  const LectureContentWidget({
    super.key,
    required this.lectureContent,
    required this.onProceed,
  });

  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();

    final lectureTitleColor = styles.getStyles('module_pages.level_contents.lecture_mode.title.color') as Color;
    final lectureTitleFontSize = styles.getStyles('module_pages.level_contents.lecture_mode.title.font_size') as double;
    final lectureTitleFontWeight = styles.getStyles('module_pages.level_contents.lecture_mode.title.font_weight') as FontWeight;

    final plainColor = styles.getStyles('module_pages.level_contents.lecture_mode.plain.color') as Color;
    final plainFontSize = styles.getStyles('module_pages.level_contents.lecture_mode.plain.font_size') as double;
    final plainFontWeight = styles.getStyles('module_pages.level_contents.lecture_mode.plain.font_weight') as FontWeight;

    final inputBackground = styles.getStyles('module_pages.level_contents.lecture_mode.input_code.background_color') as Color;
    final inputBorderRadius = styles.getStyles('module_pages.level_contents.lecture_mode.input_code.border_radius') as double;
    final inputTextColor = styles.getStyles('module_pages.level_contents.lecture_mode.input_code.text.color') as Color;
    final inputTextFontSize = styles.getStyles('module_pages.level_contents.lecture_mode.input_code.text.font_size') as double;
    final inputTextFontWeight = styles.getStyles('module_pages.level_contents.lecture_mode.input_code.text.font_weight') as FontWeight;
    final inputAccentWidth = styles.getStyles('module_pages.level_contents.lecture_mode.input_code.accent_bar.width') as double;
    final inputAccentBorderRadius = styles.getStyles('module_pages.level_contents.lecture_mode.input_code.accent_bar.border_radius') as double;
    final inputAccentValidColor = styles.getStyles('module_pages.level_contents.lecture_mode.input_code.accent_bar.valid_color') as Color;
    final inputAccentErrorColor = styles.getStyles('module_pages.level_contents.lecture_mode.input_code.accent_bar.error_color') as Color;

    final outputBackground = styles.getStyles('module_pages.level_contents.lecture_mode.output_code.background_color') as Color;
    final outputBorderRadius = styles.getStyles('module_pages.level_contents.lecture_mode.output_code.border_radius') as double;
    final outputTextColor = styles.getStyles('module_pages.level_contents.lecture_mode.output_code.text.color') as Color;
    final outputTextFontSize = styles.getStyles('module_pages.level_contents.lecture_mode.output_code.text.font_size') as double;
    final outputTextFontWeight = styles.getStyles('module_pages.level_contents.lecture_mode.output_code.text.font_weight') as FontWeight;

    final proceedWidth = styles.getStyles('module_pages.level_contents.lecture_mode.proceed_button.width') as double;
    final proceedHeight = styles.getStyles('module_pages.level_contents.lecture_mode.proceed_button.height') as double;
    final proceedBackground = styles.getStyles('module_pages.level_contents.lecture_mode.proceed_button.background_color') as Color;
    final proceedBorderWidth = styles.getStyles('module_pages.level_contents.lecture_mode.proceed_button.border_width') as double;
    final proceedBorderRadius = styles.getStyles('module_pages.level_contents.lecture_mode.proceed_button.border_radius') as double;
    final proceedStroke = styles.getStyles('module_pages.level_contents.lecture_mode.proceed_button.stroke_color') as LinearGradient;
    final proceedTextColor = styles.getStyles('module_pages.level_contents.lecture_mode.proceed_button.text.color') as Color;
    final proceedTextFontSize = styles.getStyles('module_pages.level_contents.lecture_mode.proceed_button.text.font_size') as double;
    final proceedTextFontWeight = styles.getStyles('module_pages.level_contents.lecture_mode.proceed_button.text.font_weight') as FontWeight;

    Widget buildTitleSection(List<String> lines) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: lines
              .map((l) => Text(
                    l,
                    style: TextStyle(color: lectureTitleColor, fontSize: lectureTitleFontSize, fontWeight: lectureTitleFontWeight),
                  ))
              .toList(),
        ),
      );
    }

    Widget buildPlainSection(List<String> lines) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: lines
              .map((l) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(l, style: TextStyle(color: plainColor, fontSize: plainFontSize, fontWeight: plainFontWeight)),
                  ))
              .toList(),
        ),
      );
    }

    Widget buildCodeBlock(
      List<String> lines, {
      required Color background,
      required double borderRadius,
      double? accentWidth,
      double? accentBorderRadius,
      Color? accentColor,
      required Color textColor,
      required double textFontSize,
      required FontWeight textFontWeight,
    }) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (accentColor != null && accentWidth != null)
                Container(
                  width: accentWidth,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.all(
                      Radius.circular(accentBorderRadius ?? borderRadius),
                    ),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: lines
                        .map((l) => Padding(
                              padding: const EdgeInsets.only(bottom: 2.0),
                              child: Text(
                                l,
                                style: TextStyle(color: textColor, fontSize: textFontSize, fontWeight: textFontWeight),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final ordered = lectureContent.getOrderedSections();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in ordered) ...[
          (() {
            final sectionKey = entry.key; // e.g. '1_title'
            final parts = sectionKey.split('_');
            final sectionType = parts.length > 1 ? parts.sublist(1).join('_') : 'plain';
            final lines = entry.value;

            switch (sectionType) {
              case 'title':
                return buildTitleSection(lines);
              case 'plain':
                return buildPlainSection(lines);
              case 'input_valid_code':
                return buildCodeBlock(
                  lines,
                  background: inputBackground,
                  borderRadius: inputBorderRadius,
                  accentWidth: inputAccentWidth,
                  accentBorderRadius: inputAccentBorderRadius,
                  accentColor: inputAccentValidColor,
                  textColor: inputTextColor,
                  textFontSize: inputTextFontSize,
                  textFontWeight: inputTextFontWeight,
                );
              case 'input_error_code':
                return buildCodeBlock(
                  lines,
                  background: inputBackground,
                  borderRadius: inputBorderRadius,
                  accentWidth: inputAccentWidth,
                  accentBorderRadius: inputAccentBorderRadius,
                  accentColor: inputAccentErrorColor,
                  textColor: inputTextColor,
                  textFontSize: inputTextFontSize,
                  textFontWeight: inputTextFontWeight,
                );
              case 'output_code':
                return buildCodeBlock(
                  lines,
                  background: outputBackground,
                  borderRadius: outputBorderRadius,
                  accentColor: null,
                  textColor: outputTextColor,
                  textFontSize: outputTextFontSize,
                  textFontWeight: outputTextFontWeight,
                );
              default:
                return buildPlainSection(lines);
            }
          })(),
        ],

        const SizedBox(height: 16),

        // Proceed button
        Center(
          child: Container(
            width: proceedWidth,
            height: proceedHeight,
            decoration: BoxDecoration(
              gradient: proceedStroke,
              borderRadius: BorderRadius.circular(proceedBorderRadius),
            ),
            child: Padding(
              padding: EdgeInsets.all(proceedBorderWidth),
              child: Material(
                color: proceedBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(proceedBorderRadius - proceedBorderWidth),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(proceedBorderRadius - proceedBorderWidth),
                  onTap: onProceed,
                  child: Center(
                    child: Text(
                      'Proceed',
                      style: TextStyle(color: proceedTextColor, fontSize: proceedTextFontSize, fontWeight: proceedTextFontWeight),
                    ),
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
}
