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
  final ScrollController _scrollController = ScrollController();

  final List<GlobalKey> _iconKeys = <GlobalKey>[];
  final GlobalKey _barKey = GlobalKey();

  double _indicatorLeft = 0.0;
  double _indicatorWidth = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateIndicatorPosition());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _updateIndicatorPosition() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final styles = AppStyles();
      final barContext = _barKey.currentContext;
      if (barContext == null) return;
      final barBox = barContext.findRenderObject() as RenderBox?;
      if (barBox == null) return;

      final indicatorW = (styles.getStyles('bottom_navigation.selected_indicator.width') as double);

      // Determine number of nav items from schema so fallback spacing is dynamic
      final itemsMap = styles.getStyles('bottom_navigation.items') as Map<String, dynamic>;
      final itemCount = itemsMap.length;
      final effectiveCount = itemCount > 0 ? itemCount : 1;

      double centerX;
      // Guard indexing in case keys haven't been created yet
      if (_currentIndex < _iconKeys.length && _iconKeys[_currentIndex].currentContext != null) {
        final iconContext = _iconKeys[_currentIndex].currentContext!;
        final iconBox = iconContext.findRenderObject() as RenderBox?;
        if (iconBox != null) {
          final iconCenterGlobal = iconBox.localToGlobal(iconBox.size.center(Offset.zero));
          final barGlobal = barBox.localToGlobal(Offset.zero);
          centerX = iconCenterGlobal.dx - barGlobal.dx;
        } else {
          centerX = barBox.size.width * (_currentIndex + 0.5) / effectiveCount;
        }
      } else {
        centerX = barBox.size.width * (_currentIndex + 0.5) / effectiveCount;
      }

      final left = (centerX - indicatorW / 2.0).clamp(0.0, barBox.size.width - indicatorW);
      setState(() {
        _indicatorLeft = left;
        _indicatorWidth = indicatorW;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();
    final itemsMap = styles.getStyles('bottom_navigation.items') as Map<String, dynamic>;
    final navKeys = itemsMap.keys.toList();
    final itemCount = navKeys.length;

    if (_iconKeys.length < itemCount) {
      _iconKeys.addAll(List.generate(itemCount - _iconKeys.length, (_) => GlobalKey()));
    } else if (_iconKeys.length > itemCount) {
      _iconKeys.removeRange(itemCount, _iconKeys.length);
    }

    final pages = [
      HomePage(
        showAppBar: false,
        onTabSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0.0,
              duration: Duration(milliseconds: (styles.getStyles('global.animation.scroll_back_duration') as int)),
              curve: Curves.easeOut,
            );
          }
        },
      ),
      const CoursePage(showAppBar: false),
      const SproutPage(showAppBar: false),
      const SettingsPage(showAppBar: false),
    ];

    final contentPadding = (styles.getStyles('bottom_navigation.bar.content_padding') as double) + MediaQuery.of(context).padding.bottom;
    final headerHeight = styles.getStyles('header.height') as double;

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.only(top: headerHeight, bottom: contentPadding),
            child: pages[_currentIndex],
          ),

          // Positioned overlay header
          const Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: MainHeader(),
          ),

          // Positioned overlay bottom navigation
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                decoration: BoxDecoration(
                  gradient: styles.getStyles('bottom_navigation.background_color') as LinearGradient,
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
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: List.generate(itemCount, (index) {
                                  final key = navKeys[index];
                                  final isSelected = index == _currentIndex;
                                  final imagePath = styles.getStyles(
                                    'bottom_navigation.items.$key.${isSelected ? 'selected' : 'unselected'}',
                                  ) as String;

                                  return Expanded(
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            _currentIndex = index;
                                          });
                                          _updateIndicatorPosition();
                                          // Reset scroll to top when switching pages
                                          if (_scrollController.hasClients) {
                                            _scrollController.animateTo(0.0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
                                          }
                                        },
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Image.asset(
                                              imagePath,
                                              key: _iconKeys[index],
                                              width: styles.getStyles('bottom_navigation.icon.width') as double,
                                              height: styles.getStyles('bottom_navigation.icon.height') as double,
                                            ),
                                            SizedBox(height: styles.getStyles('bottom_navigation.selected_indicator.padding') as double),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),

                              // Animated moving indicator below the icons
                              SizedBox(height: styles.getStyles('bottom_navigation.selected_indicator.padding') as double),
                              SizedBox(
                                height: styles.getStyles('bottom_navigation.selected_indicator.height') as double,
                                child: Stack(
                                  key: _barKey,
                                  children: [
                                    AnimatedPositioned(
                                      left: _indicatorLeft,
                                      duration: Duration(
                                        milliseconds: styles.getStyles('bottom_navigation.selected_indicator.animation_duration') as int
                                      ),
                                      curve: Curves.easeInOut,
                                      child: Container(
                                        width: _indicatorWidth == 0
                                            ? styles.getStyles('bottom_navigation.selected_indicator.width') as double
                                            : _indicatorWidth,
                                        height: styles.getStyles('bottom_navigation.selected_indicator.height') as double,
                                        decoration: BoxDecoration(
                                          color: styles.getStyles('bottom_navigation.selected_indicator.color') as Color,
                                          borderRadius: BorderRadius.circular(styles.getStyles('bottom_navigation.selected_indicator.border_radius') as double),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
