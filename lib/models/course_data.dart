class CourseData {
  final String programmingLanguageId;
  final String moduleSchemaFile;

  CourseData({
    required this.programmingLanguageId,
    required this.moduleSchemaFile,
  });

  factory CourseData.fromJson(String id, Map<String, dynamic> json) {
    return CourseData(
      programmingLanguageId: id,
      moduleSchemaFile: json['module_schema_file'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'module_schema_file': moduleSchemaFile,
    };
  }
}

class ModuleData {
  final String programmingLanguage;
  final DifficultyLevel beginner;
  final DifficultyLevel intermediate;
  final DifficultyLevel advanced;

  ModuleData({
    required this.programmingLanguage,
    required this.beginner,
    required this.intermediate,
    required this.advanced,
  });

  factory ModuleData.fromJson(Map<String, dynamic> json) {
    return ModuleData(
      programmingLanguage: json['programming_language'] as String,
      beginner: DifficultyLevel.fromJson(json['beginner'] as Map<String, dynamic>),
      intermediate: DifficultyLevel.fromJson(json['intermediate'] as Map<String, dynamic>),
      advanced: DifficultyLevel.fromJson(json['advanced'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'programming_language': programmingLanguage,
      'beginner': beginner.toJson(),
      'intermediate': intermediate.toJson(),
      'advanced': advanced.toJson(),
    };
  }
}

class DifficultyLevel {
  final EstimatedDuration estimatedDuration;
  final Map<String, Chapter> chapters;

  DifficultyLevel({
    required this.estimatedDuration,
    required this.chapters,
  });

  factory DifficultyLevel.fromJson(Map<String, dynamic> json) {
    final Map<String, Chapter> chapters = {};
    
    json.forEach((key, value) {
      if (key.startsWith('chapter_')) {
        chapters[key] = Chapter.fromJson(value as Map<String, dynamic>);
      }
    });

    return DifficultyLevel(
      estimatedDuration: EstimatedDuration.fromJson(json['estimated_duration'] as Map<String, dynamic>),
      chapters: chapters,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'estimated_duration': estimatedDuration.toJson(),
    };
    
    chapters.forEach((key, value) {
      json[key] = value.toJson();
    });
    
    return json;
  }
}

class EstimatedDuration {
  final int hours;
  final int minutes;

  EstimatedDuration({
    required this.hours,
    required this.minutes,
  });

  factory EstimatedDuration.fromJson(Map<String, dynamic> json) {
    return EstimatedDuration(
      hours: (json['hours'] as num).toInt(),
      minutes: (json['minutes'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hours': hours,
      'minutes': minutes,
    };
  }

  String toDisplayString() {
    if (hours > 0 && minutes > 0) {
      return '$hours hour${hours > 1 ? 's' : ''} $minutes minute${minutes > 1 ? 's' : ''}';
    } else if (hours > 0) {
      return '$hours hour${hours > 1 ? 's' : ''}';
    } else {
      return '$minutes minute${minutes > 1 ? 's' : ''}';
    }
  }
}

class Chapter {
  final Map<String, Module> modules;

  Chapter({required this.modules});

  factory Chapter.fromJson(Map<String, dynamic> json) {
    final Map<String, Module> modules = {};
    
    json.forEach((key, value) {
      if (key.startsWith('module_')) {
        modules[key] = Module.fromJson(value as Map<String, dynamic>);
      }
    });

    return Chapter(modules: modules);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    modules.forEach((key, value) {
      json[key] = value.toJson();
    });
    return json;
  }
}

class Module {
  final String title;
  final String levelSchema;

  Module({
    required this.title,
    required this.levelSchema,
  });

  factory Module.fromJson(Map<String, dynamic> json) {
    return Module(
      title: json['title'] as String,
      levelSchema: json['level_schema'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'level_schema': levelSchema,
    };
  }
}

class LevelData {
  final Map<String, Level> levels;

  LevelData({required this.levels});

  factory LevelData.fromJson(Map<String, dynamic> json) {
    final Map<String, Level> levels = {};
    
    json.forEach((key, value) {
      if (key.startsWith('level_')) {
        levels[key] = Level.fromJson(value as Map<String, dynamic>);
      }
    });

    return LevelData(levels: levels);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    levels.forEach((key, value) {
      json[key] = value.toJson();
    });
    return json;
  }
}

class Level {
  final String mode;
  final Map<String, dynamic> content;

  Level({
    required this.mode,
    required this.content,
  });

  factory Level.fromJson(Map<String, dynamic> json) {
    return Level(
      mode: json['mode'] as String,
      content: json['content'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mode': mode,
      'content': content,
    };
  }

  // Helper methods to get typed content based on mode
  LectureContent? getLectureContent() {
    if (mode == 'lecture') {
      return LectureContent.fromJson(content);
    }
    return null;
  }

  MultipleChoiceContent? getMultipleChoiceContent() {
    if (mode == 'multiple_choice') {
      return MultipleChoiceContent.fromJson(content);
    }
    return null;
  }

  TrueOrFalseContent? getTrueOrFalseContent() {
    if (mode == 'true_or_false') {
      return TrueOrFalseContent.fromJson(content);
    }
    return null;
  }

  FillInTheCodeContent? getFillInTheCodeContent() {
    if (mode == 'fill_in_the_code') {
      return FillInTheCodeContent.fromJson(content);
    }
    return null;
  }

  AssembleTheCodeContent? getAssembleTheCodeContent() {
    if (mode == 'assemble_the_code') {
      return AssembleTheCodeContent.fromJson(content);
    }
    return null;
  }
}

// Content models for different modes

class LectureContent {
  final Map<String, List<String>> sections;

  LectureContent({required this.sections});

  factory LectureContent.fromJson(Map<String, dynamic> json) {
    final Map<String, List<String>> sections = {};
    
    json.forEach((key, value) {
      sections[key] = (value as List).map((e) => e.toString()).toList();
    });

    return LectureContent(sections: sections);
  }

  Map<String, dynamic> toJson() {
    return sections;
  }

  // Get sections in order
  List<MapEntry<String, List<String>>> getOrderedSections() {
    final entries = sections.entries.toList();
    entries.sort((a, b) {
      final aNum = int.tryParse(a.key.split('_')[0]) ?? 0;
      final bNum = int.tryParse(b.key.split('_')[0]) ?? 0;
      return aNum.compareTo(bNum);
    });
    return entries;
  }

  String getSectionType(String key) {
    final parts = key.split('_');
    if (parts.length > 1) {
      return parts.sublist(1).join('_');
    }
    return 'plain';
  }
}

class MultipleChoiceContent {
  final String question;
  final String correctAnswer;
  final List<String> incorrectAnswers;

  MultipleChoiceContent({
    required this.question,
    required this.correctAnswer,
    required this.incorrectAnswers,
  });

  factory MultipleChoiceContent.fromJson(Map<String, dynamic> json) {
    return MultipleChoiceContent(
      question: json['question'] as String,
      correctAnswer: json['correct_answer'] as String,
      incorrectAnswers: (json['incorrect_answers'] as List).map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'correct_answer': correctAnswer,
      'incorrect_answers': incorrectAnswers,
    };
  }

  List<String> getAllChoices({bool shuffled = false}) {
    final choices = [correctAnswer, ...incorrectAnswers];
    if (shuffled) {
      choices.shuffle();
    }
    return choices;
  }
}

class TrueOrFalseContent {
  final String question;
  final bool correctAnswer;

  TrueOrFalseContent({
    required this.question,
    required this.correctAnswer,
  });

  factory TrueOrFalseContent.fromJson(Map<String, dynamic> json) {
    return TrueOrFalseContent(
      question: json['question'] as String,
      correctAnswer: json['correct_answer'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'correct_answer': correctAnswer,
    };
  }
}

class FillInTheCodeContent {
  final List<String> codeLines;
  final List<String> choices;
  final List<String> correctAnswers;

  FillInTheCodeContent({
    required this.codeLines,
    required this.choices,
    required this.correctAnswers,
  });

  factory FillInTheCodeContent.fromJson(Map<String, dynamic> json) {
    return FillInTheCodeContent(
      codeLines: (json['code_lines'] as List).map((e) => e.toString()).toList(),
      choices: (json['choices'] as List).map((e) => e.toString()).toList(),
      correctAnswers: (json['correct_answers'] as List).map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code_lines': codeLines,
      'choices': choices,
      'correct_answers': correctAnswers,
    };
  }

  int getBlankCount() {
    int count = 0;
    for (var line in codeLines) {
      count += '[_]'.allMatches(line).length;
    }
    return count;
  }
}

class AssembleTheCodeContent {
  final String question;
  final List<String> correctCodeLines;
  final List<String> choices;

  AssembleTheCodeContent({
    required this.question,
    required this.correctCodeLines,
    required this.choices,
  });

  factory AssembleTheCodeContent.fromJson(Map<String, dynamic> json) {
    return AssembleTheCodeContent(
      question: json['question'] as String,
      correctCodeLines: (json['correct_code_lines'] as List).map((e) => e.toString()).toList(),
      choices: (json['choices'] as List).map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'correct_code_lines': correctCodeLines,
      'choices': choices,
    };
  }

  static String _leadingIndent(String line) {
    final m = RegExp(r'^(\s*)').firstMatch(line);
    return m?.group(1) ?? '';
  }

  List<String> get lineIndents => correctCodeLines.map((l) => _leadingIndent(l)).toList();

  List<String> get trimmedCorrectCodeLines =>
      correctCodeLines.map((l) => l.replaceFirst(RegExp(r'^\s*'), '')).toList();

  List<String> get normalizedChoicesForDisplay {
    final trimmedLines = trimmedCorrectCodeLines;
    return choices.map((choice) {
      for (var i = 0; i < correctCodeLines.length; i++) {
        final full = correctCodeLines[i];
        final trimmed = trimmedLines[i];
        if (choice == full || choice == trimmed) {
          return trimmed;
        }
      }
      return choice;
    }).toList();
  }

  String assembleLine(int lineIndex, List<String> tokens, {String separator = ''}) {
    final indent = (lineIndex >= 0 && lineIndex < lineIndents.length) ? lineIndents[lineIndex] : '';
    return indent + tokens.join(separator);
  }
}
