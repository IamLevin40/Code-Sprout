import 'package:flutter/material.dart';
import '../models/styles_schema.dart';

/// Example Course page with tabs (Beginner, Intermediate, Advanced)
class CoursePage extends StatefulWidget {
  const CoursePage({super.key});

  @override
  State<CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> {
  final List<String> _languages = ['C++', 'C#', 'Java', 'Python', 'JavaScript'];

  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: styles.getColor('common.background.color'),
        appBar: AppBar(
          title: Text(
            'Courses',
            style: TextStyle(
              fontWeight: styles.getFontWeight('appbar.title.font_weight'),
              color: styles.getColor('appbar.title.color'),
              fontSize: styles.getFontSize('appbar.title.font_size'),
            ),
          ),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: styles.getLinearGradient('appbar.background.linear_gradient'),
            ),
          ),
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Beginner'),
              Tab(text: 'Intermediate'),
              Tab(text: 'Advanced'),
            ],
            indicatorColor: styles.getColor('appbar.title.color'),
            labelStyle: TextStyle(fontWeight: styles.getFontWeight('tab.label.font_weight')),
          ),
        ),
        body: TabBarView(
          children: List.generate(3, (index) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.separated(
                itemCount: _languages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) => Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(styles.getBorderRadius('card.border_radius')),
                    side: BorderSide(color: styles.getColor('card.border.color')),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: styles.getColor('card.avatar.background.color'),
                      child: Text(
                        _languages[i][0],
                        style: TextStyle(color: styles.getColor('card.avatar.text.color')),
                      ),
                    ),
                    title: Text(
                      _languages[i],
                      style: TextStyle(
                        fontSize: styles.getFontSize('course_page.list.title.font_size'),
                        fontWeight: styles.getFontWeight('course_page.list.title.font_weight'),
                      ),
                    ),
                    subtitle: Text(
                      'A ${['Beginner', 'Intermediate', 'Advanced'][index]} level overview of ${_languages[i]}',
                      style: TextStyle(
                        color: styles.getColor('course_page.list.subtitle.color'),
                      ),
                    ),
                    trailing: Icon(Icons.chevron_right, color: styles.getColor('course_page.list.trailing.color')),
                    onTap: () {
                      // Placeholder: in future navigate to a course detail page
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Selected ${_languages[i]} (${['Beginner','Intermediate','Advanced'][index]})')),
                      );
                    },
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
