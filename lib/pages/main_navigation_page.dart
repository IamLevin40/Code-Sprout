import 'package:flutter/material.dart';
import 'home_page.dart';
import 'course_page.dart';
import 'sprout_page.dart';
import 'settings_page.dart';
import '../widgets/main_header.dart';
import '../models/styles_schema.dart';
import '../services/local_storage_service.dart';
import '../widgets/error_boundary.dart';

/// Main scaffold with bottom navigation
class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> with WidgetsBindingObserver {
  int _currentIndex = 0;
  final ScrollController _scrollController = ScrollController();
  bool _sproutEnabled = true;

  final List<GlobalKey> _iconKeys = <GlobalKey>[];
  final GlobalKey _barKey = GlobalKey();

  double _indicatorLeft = 0.0;
  double _indicatorWidth = 0.0;
  bool _animateIndicator = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateIndicatorPosition());

    _loadUserData();

    // Listen to cached user data changes so UI updates automatically when data is saved elsewhere
    LocalStorageService.instance.userDataNotifier.addListener(_onUserDataChanged);
  }

  void _onUserDataChanged() {
    final userData = LocalStorageService.instance.userDataNotifier.value;

    final enabled = userData == null
      ? _sproutEnabled
      : (userData.get('interaction.hasLearnedChapter') as bool?) ?? false;

    final styles = AppStyles();
    final itemsMap = styles.getStyles('bottom_navigation.items') as Map<String, dynamic>;
    final navKeys = itemsMap.keys.toList();
    final sproutIndex = navKeys.indexOf('sprout');

    if (!mounted) return;

    setState(() {
      _sproutEnabled = enabled;
      if (!_sproutEnabled && sproutIndex >= 0 && _currentIndex == sproutIndex) {
        _currentIndex = 0;
      }
    });

    _updateIndicatorPosition();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await LocalStorageService.instance.getUserData();

      final enabled = userData == null
        ? _sproutEnabled
        : (userData.get('interaction.hasLearnedChapter') as bool?) ?? false;

      final styles = AppStyles();
      final itemsMap = styles.getStyles('bottom_navigation.items') as Map<String, dynamic>;
      final navKeys = itemsMap.keys.toList();
      final sproutIndex = navKeys.indexOf('sprout');

      if (!mounted) return;

      setState(() {
        _sproutEnabled = enabled;
        if (!_sproutEnabled && sproutIndex >= 0 && _currentIndex == sproutIndex) {
          _currentIndex = 0;
        }
      });

      _updateIndicatorPosition();
    } catch (e, stackTrace) {
      // Log error but don't crash - navigation should still work
      debugPrint('Error loading user data in MainNavigationPage: $e');
      debugPrint('Stack trace: $stackTrace');
      // Ensure UI is still usable even if data load fails
      if (mounted) {
        setState(() {
          _sproutEnabled = false;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    LocalStorageService.instance.userDataNotifier.removeListener(_onUserDataChanged);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (mounted) {
      setState(() {
        _animateIndicator = false;
      });
    }
    _updateIndicatorPosition();
    super.didChangeMetrics();
  }

  void _updateIndicatorPosition() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final styles = AppStyles();
      final barContext = _barKey.currentContext;
      if (barContext == null) return;
      final barBox = barContext.findRenderObject() as RenderBox?;
      if (barBox == null) return;

      final indicatorW = (styles.getStyles('bottom_navigation.selected_indicator.width') as double);
      final itemsMap = styles.getStyles('bottom_navigation.items') as Map<String, dynamic>;
      final itemCount = itemsMap.length;
      final effectiveCount = itemCount > 0 ? itemCount : 1;

      double centerX;
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

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _animateIndicator = true;
        });
      });
    });
  }

  /// Helper method to build error display for failed page instantiation
  Widget _buildPageError(BuildContext context, String pageName, Object error, StackTrace stackTrace) {
    final stackLines = stackTrace.toString().split('\n').take(5).join('\n');
    return Container(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error Loading $pageName',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Error:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    SelectableText(error.toString(), style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 8),
                    const Text('Stack Trace:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    SelectableText(stackLines, style: const TextStyle(fontSize: 10, fontFamily: 'monospace')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary.wrapBuild(
      context: context,
      pageName: 'MainNavigationPage',
      builder: () => _buildMainContent(context),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    final styles = AppStyles();
    final itemsMap = styles.getStyles('bottom_navigation.items') as Map<String, dynamic>;
    final navKeys = itemsMap.keys.toList();
    final itemCount = navKeys.length;

    if (_iconKeys.length < itemCount) {
      _iconKeys.addAll(List.generate(itemCount - _iconKeys.length, (_) => GlobalKey()));
    } else if (_iconKeys.length > itemCount) {
      _iconKeys.removeRange(itemCount, _iconKeys.length);
    }

    // Wrap each page with a Builder to catch instantiation errors
    final pages = [
      Builder(
        builder: (context) {
          try {
            return HomePage(
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
            );
          } catch (e, stackTrace) {
            return _buildPageError(context, 'HomePage', e, stackTrace);
          }
        },
      ),
      Builder(
        builder: (context) {
          try {
            return const CoursePage();
          } catch (e, stackTrace) {
            return _buildPageError(context, 'CoursePage', e, stackTrace);
          }
        },
      ),
      Builder(
        builder: (context) {
          try {
            return const SproutPage();
          } catch (e, stackTrace) {
            return _buildPageError(context, 'SproutPage', e, stackTrace);
          }
        },
      ),
      Builder(
        builder: (context) {
          try {
            return const SettingsPage();
          } catch (e, stackTrace) {
            return _buildPageError(context, 'SettingsPage', e, stackTrace);
          }
        },
      ),
    ];

    final contentPadding = (styles.getStyles('bottom_navigation.bar.content_padding') as double) + MediaQuery.of(context).padding.bottom;
    final headerHeight = styles.getStyles('header.height') as double;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
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

                                  final isSprout = key == 'sprout';
                                  final isDisabled = isSprout && !_sproutEnabled;

                                  String imagePath;
                                  if (isDisabled) {
                                    imagePath = styles.getStyles('bottom_navigation.items.$key.disabled') as String;
                                  } else {
                                    imagePath = styles.getStyles(
                                      'bottom_navigation.items.$key.${isSelected ? 'selected' : 'unselected'}',
                                    ) as String;
                                  }

                                  return Expanded(
                                    child: Material(
                                      color: styles.getStyles('constant_values.colors.transparent') as Color,
                                      child: InkWell(
                                        splashColor: styles.getStyles('constant_values.colors.transparent') as Color,
                                        highlightColor: styles.getStyles('constant_values.colors.transparent') as Color,
                                        hoverColor: styles.getStyles('constant_values.colors.transparent') as Color,
                                        focusColor: styles.getStyles('constant_values.colors.transparent') as Color,
                                        splashFactory: NoSplash.splashFactory,
                                        // Disable tap if this is the disabled sprout
                                        onTap: isDisabled
                                            ? null
                                            : () {
                                                setState(() {
                                                  _currentIndex = index;
                                                });
                                                _updateIndicatorPosition();
                                                if (_scrollController.hasClients) {
                                                  _scrollController.animateTo(
                                                    0.0,
                                                    duration: Duration(milliseconds: (styles.getStyles('global.animation.scroll_back_duration') as int)),
                                                    curve: Curves.easeOut,
                                                  );
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
                                      duration: _animateIndicator
                                          ? Duration(milliseconds: styles.getStyles('bottom_navigation.selected_indicator.animation_duration') as int)
                                          : Duration.zero,
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
