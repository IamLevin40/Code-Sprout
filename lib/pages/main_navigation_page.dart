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
          gradient: styles.getStyles('bottom_navigation.background') as LinearGradient,
          boxShadow: [
            BoxShadow(
              color: styles.withOpacity(
                'bottom_navigation.shadow.color',
                'bottom_navigation.shadow.opacity',
              ),
              blurRadius: styles.toDouble(styles.getStyles('bottom_navigation.shadow.blur_radius')),
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SizedBox(
          height: styles.toDouble(styles.getStyles('bottom_navigation.bar.max_height')),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: styles.toDouble(styles.getStyles('bottom_navigation.bar.padding_vertical')),
            ),
            child: Center(
              child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: styles.toDouble(styles.getStyles('bottom_navigation.bar.padding_horizontal')),
              ),
              // Outline using outer gradient; inner padding creates the outline thickness
              padding: EdgeInsets.all(styles.toDouble(styles.getStyles('bottom_navigation.bar.outline.thickness'))),
              decoration: BoxDecoration(
                gradient: styles.getStyles('bottom_navigation.bar.outline') as LinearGradient,
                borderRadius: BorderRadius.circular(styles.toDouble(styles.getStyles('bottom_navigation.bar.border_radius'))),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: styles.getStyles('bottom_navigation.bar.background') as LinearGradient,
                  borderRadius: BorderRadius.circular(styles.toDouble(styles.getStyles('bottom_navigation.bar.border_radius'))),
                ),
                padding: const EdgeInsets.symmetric(vertical: 6.0),
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
                            width: styles.toDouble(styles.getStyles('bottom_navigation.icon.width')),
                            height: styles.toDouble(styles.getStyles('bottom_navigation.icon.height')),
                          ),
                          const SizedBox(height: 4),
                          // Selected indicator
                          isSelected
                              ? Container(
                                  width: styles.toDouble(styles.getStyles('bottom_navigation.selected_indicator.width')),
                                  height: styles.toDouble(styles.getStyles('bottom_navigation.selected_indicator.height')),
                                  decoration: BoxDecoration(
                                    color: styles.getStyles('bottom_navigation.selected_indicator.color') as Color,
                                    borderRadius: BorderRadius.circular(
                                      styles.toDouble(styles.getStyles('bottom_navigation.selected_indicator.border_radius')),
                                    ),
                                  ),
                                )
                              : SizedBox(height: styles.toDouble(styles.getStyles('bottom_navigation.selected_indicator.height'))),
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
