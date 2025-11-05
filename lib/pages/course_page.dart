import 'package:flutter/material.dart';
import '../models/styles_schema.dart';

/// Example Course page with tabs (Beginner, Intermediate, Advanced)
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

    final tabs = TabBar(
      tabs: const [
        Tab(text: 'Beginner'),
        Tab(text: 'Intermediate'),
        Tab(text: 'Advanced'),
      ],
      indicatorColor: styles.getStyles('header.title.color') as Color,
      labelStyle: TextStyle(fontWeight: styles.getStyles('tab.label.font_weight') as FontWeight),
    );

    final tabViews = TabBarView(
      children: List.generate(3, (index) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView.separated(
            itemCount: _languages.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(styles.getStyles('card.border_radius') as double),
                side: BorderSide(color: styles.getStyles('card.border.color') as Color),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: styles.getStyles('card.avatar.background_color') as Color,
                  child: Text(
                    _languages[i][0],
                    style: TextStyle(color: styles.getStyles('card.avatar.text.color') as Color),
                  ),
                ),
                title: Text(
                  _languages[i],
                  style: TextStyle(
                    fontSize: styles.getStyles('course_page.list.title.font_size') as double,
                    fontWeight: styles.getStyles('course_page.list.title.font_weight') as FontWeight,
                  ),
                ),
                subtitle: Text(
                  'A ${['Beginner', 'Intermediate', 'Advanced'][index]} level overview of ${_languages[i]}',
                  style: TextStyle(
                    color: styles.getStyles('course_page.list.subtitle.color') as Color,
                  ),
                ),
                trailing: Icon(Icons.chevron_right, color: styles.getStyles('course_page.list.trailing.color') as Color),
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
    );

    if (widget.showAppBar) {
      return DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: styles.getStyles('global.background.color') as Color,
          appBar: AppBar(
            title: Text(
              'Courses',
              style: TextStyle(
                fontWeight: styles.getStyles('header.title.font_weight') as FontWeight,
                color: styles.getStyles('header.title.color') as Color,
                fontSize: styles.getStyles('header.title.font_size') as double,
              ),
            ),
            centerTitle: true,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                color: styles.getStyles('header.background_color') as Color,
              ),
            ),
            bottom: tabs,
          ),
          body: tabViews,
        ),
      );
    }

    // Embedded: show tab bar at top of content
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(color: styles.getStyles('global.background.color') as Color, child: tabs),
          Expanded(child: tabViews),
        ],
      ),
    );
  }
}
