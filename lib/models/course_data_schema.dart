import 'dart:convert';
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

  /// Load the main courses schema
  Future<Map<String, CourseData>> loadCoursesSchema() async {
    if (_coursesCache.isNotEmpty) {
      return _coursesCache;
    }

    try {
      final String jsonString = await rootBundle.loadString('schemas/courses_schema.txt');
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      jsonData.forEach((key, value) {
        _coursesCache[key] = CourseData.fromJson(key, value as Map<String, dynamic>);
      });

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
      print('Error getting module: $e');
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
      print('Error getting modules by difficulty: $e');
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
      print('Error getting estimated duration: $e');
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
      print('Error getting level: $e');
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
      print('Error getting all levels: $e');
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
      print('Error getting level count: $e');
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
}
