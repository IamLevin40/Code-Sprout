import 'code_file.dart';

/// Manager class for code files for a specific programming language
class LanguageCodeFiles {
  final String languageId; // e.g., "cpp", "python", "java"
  final List<CodeFile> files;
  int currentFileIndex;

  LanguageCodeFiles({
    required this.languageId,
    required this.files,
    this.currentFileIndex = 0,
  }) {
    // Ensure at least one file exists
    if (files.isEmpty) {
      files.add(_createDefaultFile());
    }
    // Validate index
    if (currentFileIndex < 0 || currentFileIndex >= files.length) {
      currentFileIndex = 0;
    }
  }

  /// Get default file name for the language
  static String getDefaultFileName(String languageId) {
    switch (languageId) {
      case 'cpp':
        return 'main.cpp';
      case 'csharp':
        return 'Main.cs';
      case 'java':
        return 'Main.java';
      case 'python':
        return 'main.py';
      case 'javascript':
        return 'main.js';
      default:
        return 'main.txt';
    }
  }

  /// Get file extension for the language
  static String getFileExtension(String languageId) {
    switch (languageId) {
      case 'cpp':
        return '.cpp';
      case 'csharp':
        return '.cs';
      case 'java':
        return '.java';
      case 'python':
        return '.py';
      case 'javascript':
        return '.js';
      default:
        return '.txt';
    }
  }

  /// Get default code template for the language
  static String getDefaultCode(String languageId) {
    switch (languageId) {
      case 'cpp':
        return '// C++ Farm Drone Code\n'
            '#include <iostream>\n\n'
            'int main() {\n'
            '    // Example: Move and till\n'
            '    move(Direction::East);\n'
            '    till();\n'
            '    water();\n'
            '    plant(SeedType::WheatSeeds);\n'
            '    harvest();\n\n'
            '    return 0;\n'
            '}';
      case 'csharp':
        return '// C# Farm Drone Code\n'
            'using System;\n\n'
            'class Program {\n'
            '    static void Main() {\n'
            '        // Example: Move and till\n'
            '        move(Direction.East);\n'
            '        till();\n'
            '        water();\n'
            '        plant(SeedType.WheatSeeds);\n'
            '        harvest();\n'
            '    }\n'
            '}';
      case 'java':
        return '// Java Farm Drone Code\n'
            'public class Main {\n'
            '    public static void main(String[] args) {\n'
            '        // Example: Move and till\n'
            '        move(Direction.EAST);\n'
            '        till();\n'
            '        water();\n'
            '        plant(SeedType.WHEAT_SEEDS);\n'
            '        harvest();\n'
            '    }\n'
            '}';
      case 'python':
        return '# Python Farm Drone Code\n'
            '# Example: Move and till\n'
            'move(Direction.East)\n'
            'till()\n'
            'water()\n'
            'plant(SeedType.wheatSeeds)\n'
            'harvest()';
      case 'javascript':
        return '// JavaScript Farm Drone Code\n'
            '// Example: Move and till\n'
            'move(Direction.East);\n'
            'till();\n'
            'water();\n'
            'plant(SeedType.wheatSeeds);\n'
            'harvest();';
      default:
        return '// Write your code here';
    }
  }

  /// Create default file for the language
  CodeFile _createDefaultFile() {
    return CodeFile(
      fileName: getDefaultFileName(languageId),
      content: getDefaultCode(languageId),
    );
  }

  /// Get current file
  CodeFile get currentFile => files[currentFileIndex];

  /// Get current file name
  String get currentFileName => currentFile.fileName;

  /// Update current file content
  void updateCurrentFileContent(String content) {
    files[currentFileIndex] = files[currentFileIndex].copyWith(content: content);
  }

  /// Move to next file (cycles)
  void nextFile() {
    currentFileIndex = (currentFileIndex + 1) % files.length;
  }

  /// Move to previous file (cycles)
  void previousFile() {
    currentFileIndex = (currentFileIndex - 1 + files.length) % files.length;
  }

  /// Add a new file with validation
  /// Returns error message if invalid, null if successful
  String? addFile(String fileName) {
    // Validate file name
    final validation = validateFileName(fileName);
    if (validation != null) {
      return validation;
    }

    // Check for duplicates
    if (files.any((f) => f.fileName == fileName)) {
      return 'File "$fileName" already exists';
    }

    // Create new file
    files.add(CodeFile(
      fileName: fileName,
      content: '// ${fileName}\n',
    ));

    // Switch to new file
    currentFileIndex = files.length - 1;

    return null;
  }

  /// Validate file name
  /// Returns error message if invalid, null if valid
  String? validateFileName(String fileName) {
    if (fileName.isEmpty) {
      return 'File name cannot be empty';
    }

    // Check for invalid characters
    final invalidChars = RegExp(r'[<>:"/\\|?*]');
    if (invalidChars.hasMatch(fileName)) {
      return 'File name contains invalid characters';
    }

    // Check for proper extension
    final expectedExt = getFileExtension(languageId);
    if (!fileName.endsWith(expectedExt)) {
      return 'File must have $expectedExt extension';
    }

    // Check file name length (without extension)
    final nameWithoutExt = fileName.substring(0, fileName.length - expectedExt.length);
    if (nameWithoutExt.isEmpty) {
      return 'File name cannot be just the extension';
    }

    if (nameWithoutExt.length > 50) {
      return 'File name is too long (max 50 characters)';
    }

    return null;
  }

  /// Delete current file
  /// Returns false if cannot delete (only one file left)
  bool deleteCurrentFile() {
    if (files.length <= 1) {
      return false;
    }

    files.removeAt(currentFileIndex);

    // Adjust index
    if (currentFileIndex >= files.length) {
      currentFileIndex = files.length - 1;
    }

    return true;
  }

  /// Get file by name
  CodeFile? getFileByName(String fileName) {
    try {
      return files.firstWhere((f) => f.fileName == fileName);
    } catch (_) {
      return null;
    }
  }

  /// Set current file by name
  /// Returns false if file not found
  bool setCurrentFileByName(String fileName) {
    final index = files.indexWhere((f) => f.fileName == fileName);
    if (index == -1) return false;

    currentFileIndex = index;
    return true;
  }

  /// Convert to Firestore format (Map<fileName, code>)
  Map<String, dynamic> toFirestore() {
    final Map<String, dynamic> result = {};
    for (final file in files) {
      result[file.fileName] = file.content;
    }
    // Store current file selection
    result['_currentFile'] = currentFileName;
    return result;
  }

  /// Create from Firestore format
  factory LanguageCodeFiles.fromFirestore(String languageId, Map<String, dynamic> data) {
    final List<CodeFile> files = [];
    String? currentFileName;

    data.forEach((key, value) {
      if (key == '_currentFile') {
        currentFileName = value as String?;
      } else if (value is String) {
        files.add(CodeFile(
          fileName: key,
          content: value,
        ));
      }
    });

    // Ensure at least one file
    if (files.isEmpty) {
      files.add(CodeFile(
        fileName: getDefaultFileName(languageId),
        content: getDefaultCode(languageId),
      ));
    }

    // Find current file index
    int currentIndex = 0;
    if (currentFileName != null) {
      final index = files.indexWhere((f) => f.fileName == currentFileName);
      if (index != -1) {
        currentIndex = index;
      }
    }

    return LanguageCodeFiles(
      languageId: languageId,
      files: files,
      currentFileIndex: currentIndex,
    );
  }

  /// Create default for language
  factory LanguageCodeFiles.createDefault(String languageId) {
    return LanguageCodeFiles(
      languageId: languageId,
      files: [
        CodeFile(
          fileName: getDefaultFileName(languageId),
          content: getDefaultCode(languageId),
        ),
      ],
      currentFileIndex: 0,
    );
  }

  /// Create from JSON
  factory LanguageCodeFiles.fromJson(String languageId, Map<String, dynamic> json) {
    final filesList = (json['files'] as List?)?.map((f) => CodeFile.fromJson(f as Map<String, dynamic>)).toList() ?? [];
    final currentIndex = (json['currentFileIndex'] as int?) ?? 0;

    return LanguageCodeFiles(
      languageId: languageId,
      files: filesList.isEmpty ? [CodeFile(fileName: getDefaultFileName(languageId), content: getDefaultCode(languageId))] : filesList,
      currentFileIndex: currentIndex,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'files': files.map((f) => f.toJson()).toList(),
      'currentFileIndex': currentFileIndex,
    };
  }

  /// Copy with modifications
  LanguageCodeFiles copyWith({
    List<CodeFile>? files,
    int? currentFileIndex,
  }) {
    return LanguageCodeFiles(
      languageId: languageId,
      files: files ?? List.from(this.files),
      currentFileIndex: currentFileIndex ?? this.currentFileIndex,
    );
  }

  @override
  String toString() {
    return 'LanguageCodeFiles(languageId: $languageId, filesCount: ${files.length}, currentFile: $currentFileName)';
  }
}
