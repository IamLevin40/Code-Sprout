import 'package:flutter/material.dart';
import '../models/styles_schema.dart';

/// Course page with tabs (Beginner, Intermediate, Advanced)
class CoursePage extends StatefulWidget {
  final bool showAppBar;

  const CoursePage({super.key, this.showAppBar = true});

  @override
  State<CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> {
  final List<String> _languages = ['C++', 'C#', 'Java', 'Python', 'JavaScript'];

  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Simple header for tabs
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text('Courses', style: TextStyle(fontSize: styles.getStyles('header.title.font_size') as double, fontWeight: styles.getStyles('header.title.font_weight') as FontWeight)),
        ),
        const SizedBox(height: 8),
        // Render each tab section sequentially (non-scrolling)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(3, (index) {
              final sectionTitle = ['Beginner', 'Intermediate', 'Advanced'][index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sectionTitle, style: TextStyle(fontSize: styles.getStyles('tab.label.font_size') as double, fontWeight: styles.getStyles('tab.label.font_weight') as FontWeight)),
                  const SizedBox(height: 8),
                  Column(
                    children: List.generate(_languages.length, (i) {
                      return Column(
                        children: [
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(styles.getStyles('card.border_radius') as double),
                              side: BorderSide(color: styles.getStyles('card.border.color') as Color),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: styles.getStyles('card.avatar.background_color') as Color,
                                child: Text(_languages[i][0], style: TextStyle(color: styles.getStyles('card.avatar.text.color') as Color)),
                              ),
                              title: Text(
                                _languages[i],
                                style: TextStyle(
                                  fontSize: styles.getStyles('course_page.list.title.font_size') as double,
                                  fontWeight: styles.getStyles('course_page.list.title.font_weight') as FontWeight,
                                ),
                              ),
                              subtitle: Text(
                                'A $sectionTitle level overview of ${_languages[i]}',
                                style: TextStyle(color: styles.getStyles('course_page.list.subtitle.color') as Color),
                              ),
                              trailing: Icon(Icons.chevron_right, color: styles.getStyles('course_page.list.trailing.color') as Color),
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Selected ${_languages[i]} ($sectionTitle)')));
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}
