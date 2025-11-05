import 'package:flutter/material.dart';
import 'home_page.dart';
import 'course_page.dart';
import 'sprout_page.dart';
import 'settings_page.dart';
import '../widgets/main_header.dart';
import '../models/styles_schema.dart';

/// Main scaffold with bottom navigation for Home and Settings
class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();
    
    // Build pages here so we can pass a callback to the HomePage to update the
    // main bottom navigation index instead of pushing new routes. Pages are
    // embedded (no per-page AppBar) so the shared header from MainHeader is
    // displayed above all pages.
    final pages = [
      HomePage(
        showAppBar: false,
        onTabSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      const CoursePage(showAppBar: false),
      const SproutPage(showAppBar: false),
      const SettingsPage(showAppBar: false),
    ];

    return Scaffold(
      // Header is shared across all main navigation pages
      body: Column(
        children: [
          const MainHeader(),
          Expanded(child: pages[_currentIndex]),
        ],
      ),
      bottomNavigationBar: Container(
        // Background overlay gradient (transparent white -> opaque white)
        decoration: BoxDecoration(
          gradient: styles.getStyles('bottom_navigation.background_color') as LinearGradient,
          boxShadow: [
            BoxShadow(
              color: styles.withOpacity(
                'bottom_navigation.shadow.color',
                'bottom_navigation.shadow.opacity',
              ),
              blurRadius: styles.getStyles('bottom_navigation.shadow.blur_radius') as double,
              offset: Offset(
                styles.getStyles('bottom_navigation.shadow.offset.x') as double,
                styles.getStyles('bottom_navigation.shadow.offset.y') as double,
              ),
            ),
          ],
        ),
        child: SizedBox(
          height: styles.getStyles('bottom_navigation.bar.max_height') as double,
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: styles.getStyles('bottom_navigation.bar.padding_vertical') as double,
            ),
            child: Center(
              child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: styles.getStyles('bottom_navigation.bar.padding_horizontal') as double,
              ),
              // Outline using outer gradient; inner padding creates the outline thickness
              padding: EdgeInsets.all(styles.getStyles('bottom_navigation.bar.outline.thickness') as double),
              decoration: BoxDecoration(
                gradient: styles.getStyles('bottom_navigation.bar.outline.stroke_color') as LinearGradient,
                borderRadius: BorderRadius.circular(styles.getStyles('bottom_navigation.bar.border_radius') as double),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: styles.getStyles('bottom_navigation.bar.background_color') as LinearGradient,
                  borderRadius: BorderRadius.circular(styles.getStyles('bottom_navigation.bar.border_radius') as double),
                ),
                padding: EdgeInsets.symmetric(
                  vertical: styles.getStyles('bottom_navigation.bar.padding_buttons_vertical') as double,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(4, (index) {
                    final keys = ['home', 'course', 'sprout', 'settings'];
                    final key = keys[index];
                    final isSelected = index == _currentIndex;
                    final imagePath = styles.getStyles(
                      'bottom_navigation.items.$key.${isSelected ? 'selected' : 'unselected'}',
                    ) as String;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            imagePath,
                            width: styles.getStyles('bottom_navigation.icon.width') as double,
                            height: styles.getStyles('bottom_navigation.icon.height') as double,
                          ),
                          SizedBox(height: styles.getStyles('bottom_navigation.selected_indicator.padding') as double),
                          // Selected indicator
                          isSelected
                              ? Container(
                                  width: styles.getStyles('bottom_navigation.selected_indicator.width') as double,
                                  height: styles.getStyles('bottom_navigation.selected_indicator.height') as double,
                                  decoration: BoxDecoration(
                                    color: styles.getStyles('bottom_navigation.selected_indicator.color') as Color,
                                    borderRadius: BorderRadius.circular(
                                      styles.getStyles('bottom_navigation.selected_indicator.border_radius') as double,
                                    ),
                                  ),
                                )
                              : SizedBox(height: styles.getStyles('bottom_navigation.selected_indicator.height') as double),
                        ],
                      ),
                    );
                  }),
                ),
              ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
