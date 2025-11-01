import 'package:flutter/material.dart';
import 'home_page.dart';
import 'settings_page.dart';
import '../services/app_styles_service.dart';

/// Main scaffold with bottom navigation for Home and Settings
class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  // Pages for navigation
  final List<Widget> _pages = [
    const HomePage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();
    
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: styles.getColorWithOpacity(
                'bottom_navigation.shadow.color',
                opacityPath: 'bottom_navigation.shadow.opacity',
              ),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          selectedItemColor: styles.getColor('bottom_navigation.selected.icon.color'),
          unselectedItemColor: styles.getColor('bottom_navigation.unselected.icon.color'),
          selectedLabelStyle: TextStyle(
            fontWeight: styles.getFontWeight('bottom_navigation.selected.label.font_weight'),
            fontSize: styles.getFontSize('bottom_navigation.selected.label.font_size'),
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: styles.getFontSize('bottom_navigation.unselected.label.font_size'),
            fontWeight: styles.getFontWeight('bottom_navigation.unselected.label.font_weight'),
          ),
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
