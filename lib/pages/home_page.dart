import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../miscellaneous/touch_mouse_drag_scroll_behavior.dart';
import '../models/styles_schema.dart';
import '../models/course_data_schema.dart';
import '../models/user_data.dart';
import '../services/firestore_service.dart';
import '../widgets/course_cards/recommended_course_cards.dart';
import '../widgets/course_cards/discover_course_cards.dart';

class HomePage extends StatefulWidget {
  final ValueChanged<int>? onTabSelected;
  const HomePage({super.key, this.onTabSelected});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _recommendedScrollController = ScrollController();
  final ScrollController _discoverScrollController = ScrollController();
  UserData? _userData;

  @override
  Widget build(BuildContext context) {
    final content = _buildStackedContent();
    return content;
  }

  @override
  void dispose() {
    _recommendedScrollController.dispose();
    _discoverScrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final auth = AuthService();
    final currentUser = auth.currentUser;
    if (currentUser != null) {
      try {
        final ud = await FirestoreService.getUserData(currentUser.uid);
        if (mounted) setState(() => _userData = ud);
      } catch (_) {
        // ignore: no-op, leave _userData null
      }
    }
  }

  Widget _buildStackedContent() {
    final styles = AppStyles();

    final core = Container(
      color: styles.getStyles('global.background.color') as Color,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Recommended section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Recommended',
                    style: TextStyle(
                      fontSize: styles.getStyles('home_page.card_title.font_size') as double,
                      fontWeight: styles.getStyles('home_page.card_title.font_weight') as FontWeight,
                      color: styles.getStyles('home_page.card_title.color') as Color,
                    ),
                  ),
                ),
              ),
              FutureBuilder<List<String>>(
                future: CourseDataSchema().getRecommendedLanguages(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return SizedBox(height: styles.getStyles('course_cards.recommended_card.attribute.height') as double, child: const Center(child: CircularProgressIndicator()));
                  }
                  final langs = snap.data!;
                    final listHeight = styles.getStyles('course_cards.recommended_card.attribute.height') as double;
                    return LayoutBuilder(
                      builder: (ctx, constraints) {
                        final viewportWidth = constraints.maxWidth;
                        return SizedBox(
                          width: viewportWidth,
                          height: listHeight,
                          child: ScrollConfiguration(
                            behavior: const TouchMouseDragScrollBehavior(),
                            child: SingleChildScrollView(
                              controller: _recommendedScrollController,
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              clipBehavior: Clip.hardEdge,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                child: Row(
                                  children: [
                                    for (int i = 0; i < langs.length; i++) ...[
                                      FutureBuilder<Map<String, dynamic>>(
                                        future: CourseDataSchema().loadModuleSchema(langs[i]).then((module) => {'id': langs[i], 'name': module.programmingLanguage}),
                                        builder: (cctx, csnap) {
                                          final displayName = csnap.hasData ? (csnap.data!['name'] as String) : langs[i];
                                          return RecommendedCourseCard(
                                            languageId: langs[i],
                                            languageName: displayName,
                                            difficulty: 'Beginner',
                                            userData: _userData,
                                            onTap: () => _onCourseCardTap(langs[i], 'Beginner'),
                                          );
                                        },
                                      ),
                                      if (i < langs.length - 1)
                                        SizedBox(width: styles.getStyles('course_cards.recommended_card.attribute.spacing') as double),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                },
              ),
              const SizedBox(height: 16),

              // Discover section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Discover',
                    style: TextStyle(
                      fontSize: styles.getStyles('home_page.card_title.font_size') as double,
                      fontWeight: styles.getStyles('home_page.card_title.font_weight') as FontWeight,
                      color: styles.getStyles('home_page.card_title.color') as Color,
                    ),
                  ),
                ),
              ),
              FutureBuilder<List<String>>(
                future: CourseDataSchema().getAvailableLanguages(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return SizedBox(height: styles.getStyles('course_cards.discover_card.attribute.height') as double, child: const Center(child: CircularProgressIndicator()));
                  }
                  final langs = snap.data!;
                  final listHeight = styles.getStyles('course_cards.discover_card.attribute.height') as double;
                  return LayoutBuilder(
                    builder: (ctx, constraints) {
                      final viewportWidth = constraints.maxWidth;
                      return SizedBox(
                        width: viewportWidth,
                        height: listHeight,
                          child: ScrollConfiguration(
                          behavior: const TouchMouseDragScrollBehavior(),
                          child: SingleChildScrollView(
                            controller: _discoverScrollController,
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            clipBehavior: Clip.hardEdge,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Row(
                                children: [
                                  for (int i = 0; i < langs.length; i++) ...[
                                    FutureBuilder<Map<String, dynamic>>(
                                      future: CourseDataSchema().loadModuleSchema(langs[i]).then((module) => {'id': langs[i], 'name': module.programmingLanguage}),
                                      builder: (cctx, csnap) {
                                        final displayName = csnap.hasData ? (csnap.data!['name'] as String) : langs[i];
                                        return DiscoverCourseCard(
                                          languageId: langs[i],
                                          languageName: displayName,
                                          difficulty: 'Beginner',
                                          userData: _userData,
                                          onTap: () => _onCourseCardTap(langs[i], 'Beginner'),
                                        );
                                      },
                                    ),
                                    if (i < langs.length - 1)
                                      SizedBox(width: styles.getStyles('course_cards.discover_card.attribute.spacing') as double),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              
              // Logout button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: ElevatedButton.icon(
                  onPressed: () => _showLogoutDialog(context, AuthService()),
                  icon: Icon(Icons.logout, color: styles.getStyles('home_page.logout_button.icon.color') as Color),
                  label: Text('Logout', style: TextStyle(fontSize: styles.getStyles('home_page.logout_button.text.font_size') as double,
                    fontWeight: styles.getStyles('home_page.logout_button.text.font_weight') as FontWeight)),
                  style: ElevatedButton.styleFrom(backgroundColor: styles.getStyles('home_page.logout_button.background_color') as Color),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return core;
  }

  void _showLogoutDialog(BuildContext context, AuthService authService) {
    final styles = AppStyles();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(styles.getStyles('home_page.logout_dialog.border_radius') as double)),
        title: Text('Logout', style: TextStyle(fontWeight: styles.getStyles('home_page.logout_dialog.title.font_weight') as FontWeight, color: styles.getStyles('home_page.logout_dialog.title.color') as Color)),
        content: Text('Are you sure you want to logout?', style: TextStyle(color: styles.getStyles('home_page.logout_dialog.message.color') as Color)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Cancel', style: TextStyle(color: styles.getStyles('home_page.logout_dialog.cancel_button.color') as Color))),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await authService.signOut();
              if (context.mounted) Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  /// Handle course card tap
  void _onCourseCardTap(String languageId, String difficulty) {
    // TODO: Navigate to course detail page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected $languageId - $difficulty'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
