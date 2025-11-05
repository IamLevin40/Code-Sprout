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
          gradient: styles.getLinearGradient('bottom_navigation.background.linear_gradient'),
          boxShadow: [
            BoxShadow(
              color: styles.getColorWithOpacity(
                'bottom_navigation.shadow.color',
                opacityPath: 'bottom_navigation.shadow.opacity',
              ),
              blurRadius: styles.getBlurRadius('bottom_navigation.shadow.blur_radius'),
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SizedBox(
          height: styles.getHeight('bottom_navigation.bar.max_height'),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: styles.getWidth('bottom_navigation.bar.padding_vertical').toDouble(),
            ),
            child: Center(
              child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: styles.getWidth('bottom_navigation.bar.padding_horizontal').toDouble(),
              ),
              // Outline using outer gradient; inner padding creates the outline thickness
              padding: EdgeInsets.all(styles.getWidth('bottom_navigation.bar.outline.thickness').toDouble()),
              decoration: BoxDecoration(
                gradient: styles.getLinearGradient('bottom_navigation.bar.outline.linear_gradient'),
                borderRadius: BorderRadius.circular(styles.getBorderRadius('bottom_navigation.bar.border_radius')),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: styles.getLinearGradient('bottom_navigation.bar.background.linear_gradient'),
                  borderRadius: BorderRadius.circular(styles.getBorderRadius('bottom_navigation.bar.border_radius')),
                ),
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(4, (index) {
                    final keys = ['home', 'course', 'sprout', 'settings'];
                    final key = keys[index];
                    final isSelected = index == _currentIndex;
                    final imagePath = styles.getImagePath(
                      'bottom_navigation.items.$key.${isSelected ? 'selected' : 'unselected'}.image_path',
                    );

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
                            width: styles.getWidth('bottom_navigation.icon.width'),
                            height: styles.getHeight('bottom_navigation.icon.height'),
                          ),
                          const SizedBox(height: 4),
                          // Selected indicator
                          isSelected
                              ? Container(
                                  width: styles.getWidth('bottom_navigation.selected_indicator.width'),
                                  height: styles.getHeight('bottom_navigation.selected_indicator.height'),
                                  decoration: BoxDecoration(
                                    color: styles.getColor('bottom_navigation.selected_indicator.color'),
                                    borderRadius: BorderRadius.circular(
                                      styles.getBorderRadius('bottom_navigation.selected_indicator.border_radius'),
                                    ),
                                  ),
                                )
                              : SizedBox(height: styles.getHeight('bottom_navigation.selected_indicator.height')),
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
