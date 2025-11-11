import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'course_data.dart';

class CourseDataSchema {
  static final CourseDataSchema _instance = CourseDataSchema._internal();
  factory CourseDataSchema() => _instance;
  CourseDataSchema._internal();

  // Cache for loaded schemas
  final Map<String, CourseData> _coursesCache = {};
  final Map<String, ModuleData> _modulesCache = {};
  final Map<String, LevelData> _levelsCache = {};
  List<String> _recommendedLanguages = [];

  /// Load the main courses schema
  Future<Map<String, CourseData>> loadCoursesSchema() async {
    if (_coursesCache.isNotEmpty) {
      return _coursesCache;
    }

    try {
      final String jsonString = await rootBundle.loadString('schemas/courses_schema.txt');
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      // Only parse entries that look like course definitions (have module_schema_file)
      jsonData.forEach((key, value) {
        try {
          if (value is Map<String, dynamic> && value.containsKey('module_schema_file')) {
            _coursesCache[key] = CourseData.fromJson(key, value);
          }
        } catch (e) {
          // skip unexpected entries without failing
        }
      });

      // Cache recommended languages if present in the schema file
      try {
        final rec = jsonData['recommended'];
        if (rec is List) {
          _recommendedLanguages = rec.whereType<String>().toList();
        }
      } catch (_) {
        _recommendedLanguages = [];
      }

      return _coursesCache;
    } catch (e) {
      throw Exception('Failed to load courses schema: $e');
    }
  }

  /// Load a specific programming language's module schema
  Future<ModuleData> loadModuleSchema(String programmingLanguageId) async {
    // Check cache first
    if (_modulesCache.containsKey(programmingLanguageId)) {
      return _modulesCache[programmingLanguageId]!;
    }

    try {
      // Get the course schema first
      final courses = await loadCoursesSchema();
      final courseSchema = courses[programmingLanguageId];
      
      if (courseSchema == null) {
        throw Exception('Programming language "$programmingLanguageId" not found');
      }

      // Load the module schema file
      final String jsonString = await rootBundle.loadString(courseSchema.moduleSchemaFile);
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      final moduleSchema = ModuleData.fromJson(jsonData);
      _modulesCache[programmingLanguageId] = moduleSchema;
      
      return moduleSchema;
    } catch (e) {
      throw Exception('Failed to load module schema for $programmingLanguageId: $e');
    }
  }

  /// Load a specific level schema
  Future<LevelData> loadLevelSchema(String levelSchemaPath) async {
    // Check cache first
    if (_levelsCache.containsKey(levelSchemaPath)) {
      return _levelsCache[levelSchemaPath]!;
    }

    try {
      final String jsonString = await rootBundle.loadString(levelSchemaPath);
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      final levelSchema = LevelData.fromJson(jsonData);
      _levelsCache[levelSchemaPath] = levelSchema;
      
      return levelSchema;
    } catch (e) {
      throw Exception('Failed to load level schema from $levelSchemaPath: $e');
    }
  }

  /// Get all available programming languages
  Future<List<String>> getAvailableLanguages() async {
    final courses = await loadCoursesSchema();
    return courses.keys.toList();
  }

  /// Get recommended languages
  Future<List<String>> getRecommendedLanguages() async {
    if (_recommendedLanguages.isNotEmpty) return _recommendedLanguages;
    await loadCoursesSchema();
    return _recommendedLanguages;
  }

  /// Get a specific module by path
  Future<Module?> getModule({
    required String programmingLanguageId,
    required String difficulty,
    required String chapterId,
    required String moduleId,
  }) async {
    try {
      final moduleSchema = await loadModuleSchema(programmingLanguageId);
      
      DifficultyLevel? difficultyLevel;
      switch (difficulty.toLowerCase()) {
        case 'beginner':
          difficultyLevel = moduleSchema.beginner;
          break;
        case 'intermediate':
          difficultyLevel = moduleSchema.intermediate;
          break;
        case 'advanced':
          difficultyLevel = moduleSchema.advanced;
          break;
        default:
          return null;
      }

      final chapter = difficultyLevel.chapters[chapterId];
      if (chapter == null) return null;

      return chapter.modules[moduleId];
    } catch (e) {
      debugPrint('Error getting module: $e');
      return null;
    }
  }

  /// Get all modules for a specific difficulty level
  Future<Map<String, Map<String, Module>>> getModulesByDifficulty({
    required String programmingLanguageId,
    required String difficulty,
  }) async {
    try {
      final moduleSchema = await loadModuleSchema(programmingLanguageId);
      
      DifficultyLevel? difficultyLevel;
      switch (difficulty.toLowerCase()) {
        case 'beginner':
          difficultyLevel = moduleSchema.beginner;
          break;
        case 'intermediate':
          difficultyLevel = moduleSchema.intermediate;
          break;
        case 'advanced':
          difficultyLevel = moduleSchema.advanced;
          break;
        default:
          return {};
      }

      final Map<String, Map<String, Module>> result = {};
      difficultyLevel.chapters.forEach((chapterId, chapter) {
        result[chapterId] = chapter.modules;
      });

      return result;
    } catch (e) {
      debugPrint('Error getting modules by difficulty: $e');
      return {};
    }
  }

  /// Get estimated duration for a difficulty level
  Future<EstimatedDuration?> getEstimatedDuration({
    required String programmingLanguageId,
    required String difficulty,
  }) async {
    try {
      final moduleSchema = await loadModuleSchema(programmingLanguageId);
      
      switch (difficulty.toLowerCase()) {
        case 'beginner':
          return moduleSchema.beginner.estimatedDuration;
        case 'intermediate':
          return moduleSchema.intermediate.estimatedDuration;
        case 'advanced':
          return moduleSchema.advanced.estimatedDuration;
        default:
          return null;
      }
    } catch (e) {
      debugPrint('Error getting estimated duration: $e');
      return null;
    }
  }

  /// Get a specific level from a module
  Future<Level?> getLevel({
    required String levelSchemaPath,
    required String levelId,
  }) async {
    try {
      final levelSchema = await loadLevelSchema(levelSchemaPath);
      return levelSchema.levels[levelId];
    } catch (e) {
      debugPrint('Error getting level: $e');
      return null;
    }
  }

  /// Get all levels for a module
  Future<Map<String, Level>> getAllLevels({
    required String levelSchemaPath,
  }) async {
    try {
      final levelSchema = await loadLevelSchema(levelSchemaPath);
      return levelSchema.levels;
    } catch (e) {
      debugPrint('Error getting all levels: $e');
      return {};
    }
  }

  /// Get the total number of levels in a module
  Future<int> getLevelCount({
    required String levelSchemaPath,
  }) async {
    try {
      final levelSchema = await loadLevelSchema(levelSchemaPath);
      return levelSchema.levels.length;
    } catch (e) {
      debugPrint('Error getting level count: $e');
      return 0;
    }
  }

  /// Clear all caches
  void clearCache() {
    _coursesCache.clear();
    _modulesCache.clear();
    _levelsCache.clear();
  }

  /// Clear cache for specific programming language
  void clearLanguageCache(String programmingLanguageId) {
    _modulesCache.remove(programmingLanguageId);
    // Also clear related level schemas
    _levelsCache.removeWhere((key, value) => key.contains(programmingLanguageId));
  }

  /// Get course progress structure (useful for UI navigation)
  Future<Map<String, dynamic>> getCourseStructure(String programmingLanguageId) async {
    try {
      final moduleSchema = await loadModuleSchema(programmingLanguageId);
      
      return {
        'language': moduleSchema.programmingLanguage,
        'difficulties': {
          'beginner': {
            'duration': moduleSchema.beginner.estimatedDuration.toDisplayString(),
            'chapters': moduleSchema.beginner.chapters.length,
            'modules': _countModules(moduleSchema.beginner.chapters),
          },
          'intermediate': {
            'duration': moduleSchema.intermediate.estimatedDuration.toDisplayString(),
            'chapters': moduleSchema.intermediate.chapters.length,
            'modules': _countModules(moduleSchema.intermediate.chapters),
          },
          'advanced': {
            'duration': moduleSchema.advanced.estimatedDuration.toDisplayString(),
            'chapters': moduleSchema.advanced.chapters.length,
            'modules': _countModules(moduleSchema.advanced.chapters),
          },
        },
      };
    } catch (e) {
      throw Exception('Failed to get course structure: $e');
    }
  }

  int _countModules(Map<String, Chapter> chapters) {
    int count = 0;
    chapters.forEach((_, chapter) {
      count += chapter.modules.length;
    });
    return count;
  }

  // ============================================================
  // PROGRESS TRACKING HELPERS
  // ============================================================

  /// Get current progress for a specific language and difficulty
  /// Returns a map with 'currentChapter' and 'currentModule' (both int)
  Map<String, int> getCurrentProgress({
    required Map<String, dynamic> userData,
    required String languageId,
    required String difficulty,
  }) {
    try {
      final progress = userData['courseProgress']?[languageId]?[difficulty.toLowerCase()];
      if (progress == null) {
        return {'currentChapter': 1, 'currentModule': 1};
      }
      
      return {
        'currentChapter': (progress['currentChapter'] as num?)?.toInt() ?? 1,
        'currentModule': (progress['currentModule'] as num?)?.toInt() ?? 1,
      };
    } catch (e) {
      debugPrint('Error getting current progress: $e');
      return {'currentChapter': 1, 'currentModule': 1};
    }
  }

  /// Get the total number of chapters for a difficulty level
  Future<int> getChapterCount({
    required String languageId,
    required String difficulty,
  }) async {
    try {
      final moduleSchema = await loadModuleSchema(languageId);
      
      switch (difficulty.toLowerCase()) {
        case 'beginner':
          return moduleSchema.beginner.chapters.length;
        case 'intermediate':
          return moduleSchema.intermediate.chapters.length;
        case 'advanced':
          return moduleSchema.advanced.chapters.length;
        default:
          return 0;
      }
    } catch (e) {
      debugPrint('Error getting chapter count: $e');
      return 0;
    }
  }

  /// Get the total number of modules in a specific chapter
  Future<int> getModuleCountInChapter({
    required String languageId,
    required String difficulty,
    required int chapterNumber,
  }) async {
    try {
      final moduleSchema = await loadModuleSchema(languageId);
      final chapterId = 'chapter_$chapterNumber';
      
      DifficultyLevel? difficultyLevel;
      switch (difficulty.toLowerCase()) {
        case 'beginner':
          difficultyLevel = moduleSchema.beginner;
          break;
        case 'intermediate':
          difficultyLevel = moduleSchema.intermediate;
          break;
        case 'advanced':
          difficultyLevel = moduleSchema.advanced;
          break;
        default:
          return 0;
      }

      final chapter = difficultyLevel.chapters[chapterId];
      return chapter?.modules.length ?? 0;
    } catch (e) {
      debugPrint('Error getting module count in chapter: $e');
      return 0;
    }
  }

  /// Advance to the next module for a user
  /// Returns updated userData map with new progress
  /// Automatically moves to next chapter if current chapter is completed
  Future<Map<String, dynamic>> advanceModule({
    required Map<String, dynamic> userData,
    required String languageId,
    required String difficulty,
  }) async {
    try {
      final progress = getCurrentProgress(
        userData: userData,
        languageId: languageId,
        difficulty: difficulty,
      );
      
      int currentChapter = progress['currentChapter']!;
      int currentModule = progress['currentModule']!;
      
      // Get total modules in current chapter
      final totalChapters = await getChapterCount(
        languageId: languageId,
        difficulty: difficulty,
      );

      // If user already beyond the last chapter marker (totalChapters + 1), do nothing
      if (currentChapter > totalChapters + 1) {
        // Cap the chapter to totalChapters + 1 and keep module at 1
        currentChapter = totalChapters + 1;
        currentModule = 1;
      } else if (currentChapter > totalChapters) {
        // We are already in the 'completed' sentinel state (chapter == totalChapters+1)
        // Do nothing further; keep at sentinel
        currentModule = 1;
      } else {
        // Normal case: determine modules in current chapter
        final totalModulesInChapter = await getModuleCountInChapter(
          languageId: languageId,
          difficulty: difficulty,
          chapterNumber: currentChapter,
        );

        // If current module is the last module in the chapter
        if (totalModulesInChapter == 0) {
          // No modules in this chapter, move to next chapter
          if (currentChapter < totalChapters) {
            currentChapter += 1;
            currentModule = 1;
          } else {
            // Last chapter with no modules -> mark as completed
            currentChapter = totalChapters + 1;
            currentModule = 1;
          }
        } else if (currentModule >= totalModulesInChapter) {
          // Move to next chapter or completion sentinel
          if (currentChapter < totalChapters) {
            currentChapter += 1;
            currentModule = 1;
          } else {
            // Finished last module of last chapter -> move to sentinel (totalChapters + 1)
            currentChapter = totalChapters + 1;
            currentModule = 1;
          }
        } else {
          // Move to next module in same chapter
          currentModule += 1;
        }
      }
      
      // Update userData
      final updatedData = Map<String, dynamic>.from(userData);
      if (updatedData['courseProgress'] == null) {
        updatedData['courseProgress'] = {};
      }
      if (updatedData['courseProgress'][languageId] == null) {
        updatedData['courseProgress'][languageId] = {};
      }
      if (updatedData['courseProgress'][languageId][difficulty.toLowerCase()] == null) {
        updatedData['courseProgress'][languageId][difficulty.toLowerCase()] = {};
      }
      
      updatedData['courseProgress'][languageId][difficulty.toLowerCase()]['currentChapter'] = currentChapter;
      updatedData['courseProgress'][languageId][difficulty.toLowerCase()]['currentModule'] = currentModule;
      
      return updatedData;
    } catch (e) {
      debugPrint('Error advancing module: $e');
      return userData;
    }
  }

  /// Get the current module object the user is on
  Future<Module?> getCurrentModule({
    required Map<String, dynamic> userData,
    required String languageId,
    required String difficulty,
  }) async {
    try {
      final progress = getCurrentProgress(
        userData: userData,
        languageId: languageId,
        difficulty: difficulty,
      );
      
      final chapterId = 'chapter_${progress['currentChapter']}';
      final moduleId = 'module_${progress['currentModule']}';
      
      return await getModule(
        programmingLanguageId: languageId,
        difficulty: difficulty,
        chapterId: chapterId,
        moduleId: moduleId,
      );
    } catch (e) {
      debugPrint('Error getting current module: $e');
      return null;
    }
  }

  /// Check if user has completed all modules in a difficulty level
  Future<bool> hasCompletedDifficulty({
    required Map<String, dynamic> userData,
    required String languageId,
    required String difficulty,
  }) async {
    try {
      final progress = getCurrentProgress(
        userData: userData,
        languageId: languageId,
        difficulty: difficulty,
      );
      
      final totalChapters = await getChapterCount(
        languageId: languageId,
        difficulty: difficulty,
      );
      
      final currentChapter = progress['currentChapter']!;
      
      // If current chapter exceeds total chapters, difficulty is completed
      if (currentChapter > totalChapters) {
        return true;
      }
      
      // If on last chapter, check if all modules are completed
      if (currentChapter == totalChapters) {
        final totalModulesInLastChapter = await getModuleCountInChapter(
          languageId: languageId,
          difficulty: difficulty,
          chapterNumber: currentChapter,
        );
        
        final currentModule = progress['currentModule']!;
        return currentModule > totalModulesInLastChapter;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error checking completion: $e');
      return false;
    }
  }

  /// Determine whether a given difficulty is locked for a user.
  /// Rules:
  /// - 'beginner' is never locked.
  /// - 'intermediate' is locked unless the user has completed 'beginner'.
  /// - 'advanced' is locked unless the user has completed 'intermediate'.
  /// If `userData` is null the method treats non-beginner difficulties as locked.
  Future<bool> isDifficultyLocked({
    Map<String, dynamic>? userData,
    required String languageId,
    required String difficulty,
  }) async {
    final diffLower = difficulty.toLowerCase();
    if (diffLower == 'beginner') return false;

    // If no user data provided treat non-beginner as locked by default
    if (userData == null) return true;

    final prev = diffLower == 'intermediate' ? 'beginner' : 'intermediate';
    try {
      final completedPrev = await hasCompletedDifficulty(
        userData: userData,
        languageId: languageId,
        difficulty: prev,
      );
      return !completedPrev;
    } catch (e) {
      debugPrint('Error determining lock state: $e');
      return true;
    }
  }

  /// Reset progress for a specific language and difficulty
  Map<String, dynamic> resetProgress({
    required Map<String, dynamic> userData,
    required String languageId,
    required String difficulty,
  }) {
    try {
      final updatedData = Map<String, dynamic>.from(userData);
      
      if (updatedData['courseProgress'] == null) {
        updatedData['courseProgress'] = {};
      }
      if (updatedData['courseProgress'][languageId] == null) {
        updatedData['courseProgress'][languageId] = {};
      }
      
      updatedData['courseProgress'][languageId][difficulty.toLowerCase()] = {
        'currentChapter': 1,
        'currentModule': 1,
      };
      
      return updatedData;
    } catch (e) {
      debugPrint('Error resetting progress: $e');
      return userData;
    }
  }

  /// Get progress percentage for a difficulty level (0.0 to 1.0)
  Future<double> getProgressPercentage({
    required Map<String, dynamic> userData,
    required String languageId,
    required String difficulty,
  }) async {
    try {
      final progress = getCurrentProgress(
        userData: userData,
        languageId: languageId,
        difficulty: difficulty,
      );
      
      final currentChapter = progress['currentChapter']!;
      final currentModule = progress['currentModule']!;
      
      // Calculate total modules completed
      int completedModules = 0;
      for (int i = 1; i < currentChapter; i++) {
        final modulesInChapter = await getModuleCountInChapter(
          languageId: languageId,
          difficulty: difficulty,
          chapterNumber: i,
        );
        completedModules += modulesInChapter;
      }
      completedModules += (currentModule - 1); // Add modules in current chapter (minus current)
      
      // Calculate total modules
      final totalChapters = await getChapterCount(
        languageId: languageId,
        difficulty: difficulty,
      );
      int totalModules = 0;
      for (int i = 1; i <= totalChapters; i++) {
        final modulesInChapter = await getModuleCountInChapter(
          languageId: languageId,
          difficulty: difficulty,
          chapterNumber: i,
        );
        totalModules += modulesInChapter;
      }
      
      if (totalModules == 0) return 0.0;
      return completedModules / totalModules;
    } catch (e) {
      debugPrint('Error calculating progress percentage: $e');
      return 0.0;
    }
  }
}
