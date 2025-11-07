import 'package:flutter/material.dart';
import 'package:code_sprout/models/course_data_schema.dart';

/// Small runner so this example page can be launched directly with
/// `flutter run -t test/course_schema_example_page.dart` (or opened in an
/// editor and executed). It starts a minimal MaterialApp using the
/// `CourseSchemaExamplePage` as the home screen.
void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: CourseSchemaExamplePage(),
  ));
}

/// Example page demonstrating how to use the Course Data Schema
class CourseSchemaExamplePage extends StatefulWidget {
  const CourseSchemaExamplePage({super.key});

  @override
  State<CourseSchemaExamplePage> createState() => _CourseSchemaExamplePageState();
}

class _CourseSchemaExamplePageState extends State<CourseSchemaExamplePage> {
  final CourseDataSchema _courseService = CourseDataSchema();
  
  String _output = 'Press buttons to test schema loading...';
  bool _isLoading = false;

  Future<void> _loadAllCourses() async {
    setState(() {
      _isLoading = true;
      _output = 'Loading all courses...';
    });

    try {
      final courses = await _courseService.loadCoursesSchema();
      
      String result = 'Available Courses:\n\n';
      courses.forEach((id, course) {
        result += 'ID: $id\n';
        result += 'Schema Path: ${course.moduleSchemaFile}\n\n';
      });
      
      setState(() {
        _output = result;
      });
    } catch (e) {
      setState(() {
        _output = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCppCourse() async {
    setState(() {
      _isLoading = true;
      _output = 'Loading C++ course structure...';
    });

    try {
      final moduleSchema = await _courseService.loadModuleSchema('cpp');
      
      String result = 'C++ Course Structure:\n\n';
      result += 'Language: ${moduleSchema.programmingLanguage}\n\n';
      
      // Beginner level
      result += 'BEGINNER LEVEL:\n';
      result += 'Duration: ${moduleSchema.beginner.estimatedDuration.toDisplayString()}\n';
      result += 'Chapters: ${moduleSchema.beginner.chapters.length}\n';
      moduleSchema.beginner.chapters.forEach((chapterId, chapter) {
        result += '  $chapterId:\n';
        chapter.modules.forEach((moduleId, module) {
          result += '    $moduleId: ${module.title}\n';
        });
      });
      
      // Intermediate level
      result += '\nINTERMEDIATE LEVEL:\n';
      result += 'Duration: ${moduleSchema.intermediate.estimatedDuration.toDisplayString()}\n';
      result += 'Chapters: ${moduleSchema.intermediate.chapters.length}\n';
      
      // Advanced level
      result += '\nADVANCED LEVEL:\n';
      result += 'Duration: ${moduleSchema.advanced.estimatedDuration.toDisplayString()}\n';
      result += 'Chapters: ${moduleSchema.advanced.chapters.length}\n';
      
      setState(() {
        _output = result;
      });
    } catch (e) {
      setState(() {
        _output = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSampleLevel() async {
    setState(() {
      _isLoading = true;
      _output = 'Loading sample level...';
    });

    try {
      final level = await _courseService.getLevel(
        levelSchemaPath: 'schemas/courses/cpp/beginner/chapter_1/module_1_levels.txt',
        levelId: 'level_1',
      );

      if (level == null) {
        setState(() {
          _output = 'Level not found!';
        });
        return;
      }

      String result = 'Sample Level Content:\n\n';
      result += 'Mode: ${level.mode}\n\n';

      if (level.mode == 'lecture') {
        final lectureContent = level.getLectureContent();
        if (lectureContent != null) {
          result += 'Lecture Sections:\n';
          final sections = lectureContent.getOrderedSections();
          for (var section in sections) {
            final type = lectureContent.getSectionType(section.key);
            result += '\n[$type]:\n';
            for (var line in section.value) {
              result += '  $line\n';
            }
          }
        }
      }

      setState(() {
        _output = result;
      });
    } catch (e) {
      setState(() {
        _output = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMultipleChoiceLevel() async {
    setState(() {
      _isLoading = true;
      _output = 'Loading multiple choice level...';
    });

    try {
      final level = await _courseService.getLevel(
        levelSchemaPath: 'schemas/courses/cpp/beginner/chapter_1/module_1_levels.txt',
        levelId: 'level_2',
      );

      if (level == null) {
        setState(() {
          _output = 'Level not found!';
        });
        return;
      }

      String result = 'Multiple Choice Question:\n\n';
      result += 'Mode: ${level.mode}\n\n';

      final mcContent = level.getMultipleChoiceContent();
      if (mcContent != null) {
        result += 'Question: ${mcContent.question}\n\n';
        result += 'Choices (shuffled):\n';
        final choices = mcContent.getAllChoices(shuffled: true);
        for (var i = 0; i < choices.length; i++) {
          result += '  ${i + 1}. ${choices[i]}\n';
        }
        result += '\nCorrect Answer: ${mcContent.correctAnswer}\n';
      }

      setState(() {
        _output = result;
      });
    } catch (e) {
      setState(() {
        _output = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getCourseStructure() async {
    setState(() {
      _isLoading = true;
      _output = 'Loading course structure...';
    });

    try {
      final structure = await _courseService.getCourseStructure('cpp');
      
      String result = 'Course Structure Summary:\n\n';
      result += 'Language: ${structure['language']}\n\n';
      
      final difficulties = structure['difficulties'] as Map<String, dynamic>;
      difficulties.forEach((difficulty, data) {
        final diffData = data as Map<String, dynamic>;
        result += '${difficulty.toUpperCase()}:\n';
        result += '  Duration: ${diffData['duration']}\n';
        result += '  Chapters: ${diffData['chapters']}\n';
        result += '  Modules: ${diffData['modules']}\n\n';
      });
      
      setState(() {
        _output = result;
      });
    } catch (e) {
      setState(() {
        _output = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Schema Test'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _loadAllCourses,
                  child: const Text('Load All Courses'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _loadCppCourse,
                  child: const Text('Load C++ Course Details'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _loadSampleLevel,
                  child: const Text('Load Sample Lecture Level'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _loadMultipleChoiceLevel,
                  child: const Text('Load Multiple Choice Level'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _getCourseStructure,
                  child: const Text('Get Course Structure Summary'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Text(
                        _output,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
