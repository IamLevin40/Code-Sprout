import 'package:flutter/material.dart';
import '../models/styles_schema.dart';
import '../models/course_data_schema.dart';
import '../models/user_data.dart';
import '../widgets/main_course_cards.dart';
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

  // Language ID to display name mapping
  final Map<String, String> _languageNames = {
    'cpp': 'C++',
    'csharp': 'C#',
    'java': 'Java',
    'python': 'Python',
    'javascript': 'JavaScript',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Load available languages and user data
  Future<void> _loadData() async {
    try {
      // Load available languages from course schema
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

    final bottomNavHeight = styles.getStyles('bottom_navigation.bar.max_height') as double;
    final screenWidth = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      child: SizedBox(
        width: screenWidth,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomNavHeight),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 16),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Courses',
                  style: TextStyle(
                    fontSize: styles.getStyles('header.title.font_size') as double,
                    fontWeight: styles.getStyles('header.title.font_weight') as FontWeight,
                    color: styles.getStyles('header.title.color') as Color,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Beginner Section
              _buildDifficultySection(styles, 'Beginner'),
              const SizedBox(height: 32),

              // Intermediate Section
              _buildDifficultySection(styles, 'Intermediate'),
              const SizedBox(height: 32),

              // Advanced Section
              _buildDifficultySection(styles, 'Advanced'),
              const SizedBox(height: 32),
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
      final spacing = styles.getStyles('course_cards.main_card.attribute.padding') as double;

      int columns = (maxWidth / (fixedCardWidth + spacing)).floor();
      if (columns < 2) columns = 2;
      double cardWidth = (maxWidth - (columns - 1) * spacing) / columns;
      if (cardWidth > maxCardWidth) cardWidth = maxCardWidth;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              difficulty,
              style: TextStyle(
                fontSize: styles.getStyles('tab.label.font_size') as double,
                fontWeight: styles.getStyles('tab.label.font_weight') as FontWeight,
                color: styles.getStyles('global.text.primary.color') as Color,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Responsive grid of course cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: SizedBox(
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
          ),
        ],
      );
    });
  }

  /// Handle course card tap
  void _onCourseCardTap(String languageId, String difficulty) {
    // TODO: Navigate to course detail page
    final languageName = _languageNames[languageId] ?? languageId;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected $languageName - $difficulty'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
