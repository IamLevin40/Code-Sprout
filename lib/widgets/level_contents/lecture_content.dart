import 'package:flutter/material.dart';
import '../../models/styles_schema.dart';
import '../../models/course_data.dart';

/// A data-driven widget that renders lecture-style level content.
/// It expects a [LectureContent] object (from the level schema) and
/// renders each section in ascending order based on the numeric prefix.
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

    // Reuse module title/subtitle tokens where appropriate for consistent styling
    final titleColor = styles.getStyles('module_pages.title.color') as Color;
    final titleFontSize = styles.getStyles('module_pages.title.font_size') as double;
    final titleFontWeight = styles.getStyles('module_pages.title.font_weight') as FontWeight;

    final plainColor = styles.getStyles('module_pages.subtitle.color') as Color;
    final plainFontSize = styles.getStyles('module_pages.subtitle.font_size') as double;

    // Code block layout constants (left accent bar width)
    final double barWidth = 8.0;

    Widget buildTitleSection(List<String> lines) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: lines
              .map((l) => Text(
                    l,
                    style: TextStyle(color: titleColor, fontSize: titleFontSize, fontWeight: titleFontWeight),
                  ))
              .toList(),
        ),
      );
    }

    Widget buildPlainSection(List<String> lines) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: lines
              .map((l) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text(l, style: TextStyle(color: plainColor, fontSize: plainFontSize)),
                  ))
              .toList(),
        ),
      );
    }

    Widget buildCodeBlock(List<String> lines, {required Color accent, required Color background, required Color textColor}) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: barWidth,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: lines
                        .map((l) => Padding(
                              padding: const EdgeInsets.only(bottom: 6.0),
                              child: Text(
                                l,
                                style: TextStyle(color: textColor, fontSize: 13),
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
                return buildCodeBlock(lines, accent: Colors.green.shade600, background: Colors.green.shade50, textColor: Colors.black87);
              case 'input_error_code':
                return buildCodeBlock(lines, accent: Colors.red.shade600, background: Colors.red.shade50, textColor: Colors.black87);
              case 'output_code':
                return buildCodeBlock(lines, accent: Colors.transparent, background: Colors.grey.shade800, textColor: Colors.white);
              default:
                return buildPlainSection(lines);
            }
          })(),
        ],

        const SizedBox(height: 16),

        // Proceed button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onProceed,
            child: const Text('Proceed'),
          ),
        ),
      ],
    );
  }
}
