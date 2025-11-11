import 'package:flutter/material.dart';
import '../models/styles_schema.dart';
import '../models/course_data_schema.dart';
import '../models/user_data.dart';
import '../widgets/course_cards/main_course_cards.dart';
import '../widgets/course_cards/continue_course_cards.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

/// Course page displaying all available courses organized by difficulty
/// Shows main course cards for each language and difficulty level
class CoursePage extends StatefulWidget {
  const CoursePage({super.key});

  @override
  State<CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> {
  final CourseDataSchema _courseSchema = CourseDataSchema();
  final AuthService _authService = AuthService();
  
  List<String> _availableLanguages = [];
  UserData? _userData;
  bool _isLoading = true;

  String _selectedDifficulty = '';
  List<String> _difficulties = [];
  final Map<String, String> _languageNames = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Load available languages and user data
  Future<void> _loadData() async {
    try {
      final languages = await _courseSchema.getAvailableLanguages();
      
      // Load user data if authenticated
      UserData? userData;
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        try {
          userData = await FirestoreService.getUserData(currentUser.uid);
        } catch (e) {
          // User data not found, continue without it
          userData = null;
        }
      }

      if (mounted) {
        final Set<String> difficultiesFound = {};
        for (final langId in languages) {
          try {
            final moduleSchema = await _courseSchema.loadModuleSchema(langId);
            _languageNames[langId] = moduleSchema.programmingLanguage;

            if (moduleSchema.beginner.chapters.isNotEmpty) difficultiesFound.add('Beginner');
            if (moduleSchema.intermediate.chapters.isNotEmpty) difficultiesFound.add('Intermediate');
            if (moduleSchema.advanced.chapters.isNotEmpty) difficultiesFound.add('Advanced');
          } catch (e) {
            _languageNames[langId] = langId;
          }
        }

        final preferredOrder = ['Beginner', 'Intermediate', 'Advanced'];
        _difficulties = preferredOrder.where((d) => difficultiesFound.contains(d)).toList();
        if (_difficulties.isEmpty) {
          _difficulties = List.from(preferredOrder);
        }

        if (_selectedDifficulty.isEmpty || !_difficulties.contains(_selectedDifficulty)) {
          _selectedDifficulty = _difficulties.first;
        }

        setState(() {
          _availableLanguages = languages;
          _userData = userData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading courses: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final screenWidth = MediaQuery.of(context).size.width;

    final double selectorGap = styles.getStyles('course_page.selector.gap') as double;
    final double selectorHeight = (styles.getStyles('course_page.selector.height') as num).toDouble();
    final Color selectorBackground = styles.getStyles('course_page.selector.background_color') as Color;
    final Color selectorTextColor = styles.getStyles('course_page.selector.text_color') as Color;
    final Color selectorSelectedTextColor = styles.getStyles('course_page.selector.selected_text_color') as Color;
    final Color selectorSelectedBorderColor = styles.getStyles('course_page.selector.selected_border_color') as Color;
    final double selectorSelectedBorderWidth = (styles.getStyles('course_page.selector.selected_border_width') as num).toDouble();

    return SingleChildScrollView(
      child: SizedBox(
        width: screenWidth,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Continue section (show only if user has lastInteraction)
              Builder(builder: (context) {
                final Map<String, dynamic>? lastMap = _userData?.toFirestore();
                final dynamic lastInteraction = lastMap == null ? null : lastMap['lastInteraction'];
                final String? continueLanguageId = lastInteraction is Map ? (lastInteraction['languageId'] as String?) : null;
                final String? continueDifficulty = lastInteraction is Map ? (lastInteraction['difficulty'] as String?) : null;
                final bool showContinue =
                    continueLanguageId != null && continueLanguageId.isNotEmpty && continueDifficulty != null && continueDifficulty.isNotEmpty;

                if (!showContinue) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: styles.getStyles('home_page.card_title.font_size') as double,
                            fontWeight: styles.getStyles('home_page.card_title.font_weight') as FontWeight,
                            color: styles.getStyles('home_page.card_title.color') as Color,
                          ),
                        ),
                      ),
                    ),
                    ContinueCourseCard(
                      userData: _userData,
                      onTap: () {
                        // Navigate using stored lastInteraction (capitalize difficulty)
                        final String lang = continueLanguageId;
                        final String diff = continueDifficulty;
                        _onCourseCardTap(lang, '${diff[0].toUpperCase()}${diff.substring(1)}');
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              }),

              // Title
              Text(
                'Courses',
                style: TextStyle(
                  fontSize: styles.getStyles('course_page.title.font_size') as double,
                  fontWeight: styles.getStyles('course_page.title.font_weight') as FontWeight,
                  color: styles.getStyles('course_page.title.color') as Color,
                ),
              ),
              const SizedBox(height: 4),

              // Difficulty selector (one row, equally spaced buttons)
              LayoutBuilder(builder: (context, constraints) {
                final double maxW = constraints.maxWidth;
                final int count = _difficulties.length;
                final double totalGap = selectorGap * (count - 1);
                final double buttonWidth = (maxW - totalGap) / count;

                return Row(
                  children: List<Widget>.generate(count * 2 - 1, (index) {
                    if (index.isOdd) return SizedBox(width: selectorGap);
                    final int i = index ~/ 2;
                    final String d = _difficulties[i];
                    final bool selected = d == _selectedDifficulty;

                    return SizedBox(
                      width: buttonWidth,
                      height: selectorHeight,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedDifficulty = d),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selectorBackground,
                            borderRadius: BorderRadius.circular(selectorHeight / 2),
                            border: selected
                                ? Border.all(color: selectorSelectedBorderColor, width: selectorSelectedBorderWidth)
                                : null,
                          ),
                          child: Text(
                            d,
                            style: TextStyle(
                              fontSize: (styles.getStyles('course_page.selector.font_size') as num).toDouble(),
                              fontWeight: styles.getStyles('course_page.selector.font_weight') as FontWeight,
                              color: selected ? selectorSelectedTextColor : selectorTextColor,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              }),
              const SizedBox(height: 12),

              _buildDifficultySection(styles, _selectedDifficulty)
            ],
          ),
        ),
      ),
    );
  }

  /// Build a section for a specific difficulty level
  Widget _buildDifficultySection(AppStyles styles, String difficulty) {
    return LayoutBuilder(builder: (context, constraints) {
      final double maxWidth = constraints.maxWidth;
      final fixedCardWidth = styles.getStyles('course_cards.main_card.attribute.width') as double;
      final maxCardWidth = styles.getStyles('course_cards.main_card.attribute.max_width') as double;
      final spacing = styles.getStyles('course_cards.main_card.attribute.spacing') as double;

      int columns = (maxWidth / (fixedCardWidth + spacing)).floor();
      if (columns < 2) columns = 2;
      double cardWidth = (maxWidth - (columns - 1) * spacing) / columns;
      if (cardWidth > maxCardWidth) cardWidth = maxCardWidth;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Responsive grid of course cards
          SizedBox(
            width: double.infinity,
            child: Wrap(
              spacing: spacing,
              runSpacing: spacing,
              alignment: WrapAlignment.center,
              runAlignment: WrapAlignment.center,
              children: _availableLanguages.map((languageId) {
                final languageName = _languageNames[languageId] ?? languageId.toUpperCase();
                return SizedBox(
                  width: cardWidth,
                  child: MainCourseCard(
                    languageId: languageId,
                    languageName: languageName,
                    difficulty: difficulty,
                    userData: _userData,
                    cardWidth: cardWidth,
                    onTap: () => _onCourseCardTap(languageId, difficulty),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      );
    });
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
