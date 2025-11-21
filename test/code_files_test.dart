import 'package:flutter_test/flutter_test.dart';
import 'package:code_sprout/models/code_file.dart';
import 'package:code_sprout/models/language_code_files.dart';

void main() {
  group('CodeFile Model Tests', () {
    test('CodeFile creation with valid data', () {
      final file = CodeFile(
        fileName: 'main.cpp',
        content: '#include <iostream>\nint main() { return 0; }',
      );

      expect(file.fileName, 'main.cpp');
      expect(file.content, '#include <iostream>\nint main() { return 0; }');
      expect(file.extension, 'cpp');
      expect(file.nameWithoutExtension, 'main');
    });

    test('CodeFile get extension correctly', () {
      expect(CodeFile(fileName: 'test.py', content: '').extension, 'py');
      expect(CodeFile(fileName: 'Main.java', content: '').extension, 'java');
      expect(CodeFile(fileName: 'app.js', content: '').extension, 'js');
      expect(CodeFile(fileName: 'Program.cs', content: '').extension, 'cs');
      expect(CodeFile(fileName: 'noextension', content: '').extension, '');
    });

    test('CodeFile get name without extension', () {
      expect(CodeFile(fileName: 'main.cpp', content: '').nameWithoutExtension, 'main');
      expect(CodeFile(fileName: 'test.file.py', content: '').nameWithoutExtension, 'test.file');
      expect(CodeFile(fileName: 'single', content: '').nameWithoutExtension, 'single');
    });

    test('CodeFile JSON serialization', () {
      final file = CodeFile(fileName: 'test.cpp', content: 'int main() {}');
      final json = file.toJson();

      expect(json['fileName'], 'test.cpp');
      expect(json['content'], 'int main() {}');

      final restored = CodeFile.fromJson(json);
      expect(restored.fileName, file.fileName);
      expect(restored.content, file.content);
    });

    test('CodeFile copyWith', () {
      final original = CodeFile(fileName: 'main.cpp', content: 'original');
      final updated = original.copyWith(content: 'updated');

      expect(updated.fileName, 'main.cpp');
      expect(updated.content, 'updated');
      expect(original.content, 'original'); // Original unchanged
    });

    test('CodeFile equality', () {
      final file1 = CodeFile(fileName: 'test.cpp', content: 'code');
      final file2 = CodeFile(fileName: 'test.cpp', content: 'code');
      final file3 = CodeFile(fileName: 'test.cpp', content: 'different');

      expect(file1, equals(file2));
      expect(file1, isNot(equals(file3)));
    });
  });

  group('LanguageCodeFiles - Creation and Defaults', () {
    test('Create default C++ files', () {
      final cppFiles = LanguageCodeFiles.createDefault('cpp');

      expect(cppFiles.languageId, 'cpp');
      expect(cppFiles.files.length, 1);
      expect(cppFiles.currentFileName, 'main.cpp');
      expect(cppFiles.currentFile.content, contains('#include <iostream>'));
      expect(cppFiles.currentFileIndex, 0);
    });

    test('Create default files for all languages', () {
      final languages = ['cpp', 'csharp', 'java', 'python', 'javascript'];

      for (final lang in languages) {
        final files = LanguageCodeFiles.createDefault(lang);
        expect(files.languageId, lang);
        expect(files.files.length, greaterThanOrEqualTo(1));
        expect(files.currentFileName, isNotEmpty);
      }
    });

    test('Get default file names for each language', () {
      expect(LanguageCodeFiles.getDefaultFileName('cpp'), 'main.cpp');
      expect(LanguageCodeFiles.getDefaultFileName('csharp'), 'Main.cs');
      expect(LanguageCodeFiles.getDefaultFileName('java'), 'Main.java');
      expect(LanguageCodeFiles.getDefaultFileName('python'), 'main.py');
      expect(LanguageCodeFiles.getDefaultFileName('javascript'), 'main.js');
    });

    test('Get file extensions for each language', () {
      expect(LanguageCodeFiles.getFileExtension('cpp'), '.cpp');
      expect(LanguageCodeFiles.getFileExtension('csharp'), '.cs');
      expect(LanguageCodeFiles.getFileExtension('java'), '.java');
      expect(LanguageCodeFiles.getFileExtension('python'), '.py');
      expect(LanguageCodeFiles.getFileExtension('javascript'), '.js');
    });

    test('Ensure at least one file exists on creation', () {
      final files = LanguageCodeFiles(
        languageId: 'cpp',
        files: [], // Empty list
      );

      expect(files.files.length, 1);
      expect(files.files.first.fileName, 'main.cpp');
    });

    test('Validate currentFileIndex on creation', () {
      final file1 = CodeFile(fileName: 'main.cpp', content: 'code1');
      final file2 = CodeFile(fileName: 'test.cpp', content: 'code2');

      // Valid index
      final valid = LanguageCodeFiles(
        languageId: 'cpp',
        files: [file1, file2],
        currentFileIndex: 1,
      );
      expect(valid.currentFileIndex, 1);

      // Invalid index (too high) - should reset to 0
      final invalid = LanguageCodeFiles(
        languageId: 'cpp',
        files: [file1, file2],
        currentFileIndex: 10,
      );
      expect(invalid.currentFileIndex, 0);

      // Negative index - should reset to 0
      final negative = LanguageCodeFiles(
        languageId: 'cpp',
        files: [file1, file2],
        currentFileIndex: -1,
      );
      expect(negative.currentFileIndex, 0);
    });
  });

  group('LanguageCodeFiles - File Navigation', () {
    test('Navigate to next file (cycling)', () {
      final file1 = CodeFile(fileName: 'main.cpp', content: 'code1');
      final file2 = CodeFile(fileName: 'test.cpp', content: 'code2');
      final file3 = CodeFile(fileName: 'utils.cpp', content: 'code3');

      final files = LanguageCodeFiles(
        languageId: 'cpp',
        files: [file1, file2, file3],
        currentFileIndex: 0,
      );

      expect(files.currentFileName, 'main.cpp');

      files.nextFile();
      expect(files.currentFileName, 'test.cpp');
      expect(files.currentFileIndex, 1);

      files.nextFile();
      expect(files.currentFileName, 'utils.cpp');
      expect(files.currentFileIndex, 2);

      // Should cycle back to first
      files.nextFile();
      expect(files.currentFileName, 'main.cpp');
      expect(files.currentFileIndex, 0);
    });

    test('Navigate to previous file (cycling)', () {
      final file1 = CodeFile(fileName: 'main.cpp', content: 'code1');
      final file2 = CodeFile(fileName: 'test.cpp', content: 'code2');
      final file3 = CodeFile(fileName: 'utils.cpp', content: 'code3');

      final files = LanguageCodeFiles(
        languageId: 'cpp',
        files: [file1, file2, file3],
        currentFileIndex: 0,
      );

      expect(files.currentFileName, 'main.cpp');

      // Should cycle to last
      files.previousFile();
      expect(files.currentFileName, 'utils.cpp');
      expect(files.currentFileIndex, 2);

      files.previousFile();
      expect(files.currentFileName, 'test.cpp');
      expect(files.currentFileIndex, 1);

      files.previousFile();
      expect(files.currentFileName, 'main.cpp');
      expect(files.currentFileIndex, 0);
    });

    test('Set current file by name', () {
      final file1 = CodeFile(fileName: 'main.cpp', content: 'code1');
      final file2 = CodeFile(fileName: 'test.cpp', content: 'code2');

      final files = LanguageCodeFiles(
        languageId: 'cpp',
        files: [file1, file2],
      );

      final success = files.setCurrentFileByName('test.cpp');
      expect(success, true);
      expect(files.currentFileName, 'test.cpp');
      expect(files.currentFileIndex, 1);

      final failure = files.setCurrentFileByName('nonexistent.cpp');
      expect(failure, false);
      expect(files.currentFileName, 'test.cpp'); // Unchanged
    });

    test('Get file by name', () {
      final file1 = CodeFile(fileName: 'main.cpp', content: 'code1');
      final file2 = CodeFile(fileName: 'test.cpp', content: 'code2');

      final files = LanguageCodeFiles(
        languageId: 'cpp',
        files: [file1, file2],
      );

      final found = files.getFileByName('test.cpp');
      expect(found, isNotNull);
      expect(found!.content, 'code2');

      final notFound = files.getFileByName('missing.cpp');
      expect(notFound, isNull);
    });
  });

  group('LanguageCodeFiles - Content Management', () {
    test('Update current file content', () {
      final files = LanguageCodeFiles.createDefault('cpp');
      final originalContent = files.currentFile.content;

      files.updateCurrentFileContent('new content');

      expect(files.currentFile.content, 'new content');
      expect(files.currentFile.content, isNot(originalContent));
    });

    test('Content persists after file navigation', () {
      final file1 = CodeFile(fileName: 'main.cpp', content: 'original1');
      final file2 = CodeFile(fileName: 'test.cpp', content: 'original2');

      final files = LanguageCodeFiles(
        languageId: 'cpp',
        files: [file1, file2],
      );

      files.updateCurrentFileContent('modified1');
      files.nextFile();
      files.updateCurrentFileContent('modified2');
      files.previousFile();

      expect(files.currentFile.content, 'modified1');
      files.nextFile();
      expect(files.currentFile.content, 'modified2');
    });
  });

  group('LanguageCodeFiles - File Addition', () {
    test('Add valid file successfully', () {
      final files = LanguageCodeFiles.createDefault('cpp');
      final initialCount = files.files.length;

      final error = files.addFile('test.cpp');

      expect(error, isNull);
      expect(files.files.length, initialCount + 1);
      expect(files.currentFileName, 'test.cpp');
      expect(files.getFileByName('test.cpp'), isNotNull);
    });

    test('Add file with different languages', () {
      final languages = {
        'cpp': 'utils.cpp',
        'python': 'helper.py',
        'java': 'Helper.java',
        'csharp': 'Utils.cs',
        'javascript': 'utils.js',
      };

      languages.forEach((lang, fileName) {
        final files = LanguageCodeFiles.createDefault(lang);
        final error = files.addFile(fileName);
        expect(error, isNull, reason: 'Failed for $lang: $error');
        expect(files.getFileByName(fileName), isNotNull);
      });
    });

    test('Reject duplicate file names', () {
      final files = LanguageCodeFiles.createDefault('cpp');

      final error1 = files.addFile('test.cpp');
      expect(error1, isNull);

      final error2 = files.addFile('test.cpp');
      expect(error2, isNotNull);
      expect(error2, contains('already exists'));
    });

    test('Reject empty file name', () {
      final files = LanguageCodeFiles.createDefault('cpp');
      final error = files.addFile('');

      expect(error, isNotNull);
      expect(error, contains('cannot be empty'));
    });

    test('Reject invalid characters in file name', () {
      final files = LanguageCodeFiles.createDefault('cpp');
      final invalidNames = ['test<>.cpp', 'file|name.cpp', 'bad:file.cpp', 'test/file.cpp'];

      for (final name in invalidNames) {
        final error = files.addFile(name);
        expect(error, isNotNull, reason: 'Should reject: $name');
        expect(error, contains('invalid characters'));
      }
    });

    test('Reject wrong file extension', () {
      final files = LanguageCodeFiles.createDefault('cpp');

      final error1 = files.addFile('test.py'); // Wrong extension
      expect(error1, isNotNull);
      expect(error1, contains('.cpp extension'));

      final error2 = files.addFile('test'); // No extension
      expect(error2, isNotNull);
    });

    test('Reject file name that is only extension', () {
      final files = LanguageCodeFiles.createDefault('cpp');
      final error = files.addFile('.cpp');

      expect(error, isNotNull);
      expect(error, contains('cannot be just the extension'));
    });

    test('Reject file name that is too long', () {
      final files = LanguageCodeFiles.createDefault('cpp');
      final longName = 'a' * 51 + '.cpp'; // 51 characters + extension

      final error = files.addFile(longName);
      expect(error, isNotNull);
      expect(error, contains('too long'));
    });

    test('New file switches to be current', () {
      final files = LanguageCodeFiles.createDefault('cpp');
      expect(files.currentFileName, 'main.cpp');

      files.addFile('test.cpp');
      expect(files.currentFileName, 'test.cpp');
      expect(files.currentFileIndex, 1);
    });
  });

  group('LanguageCodeFiles - File Deletion', () {
    test('Delete file successfully', () {
      final files = LanguageCodeFiles.createDefault('cpp');
      files.addFile('test.cpp');
      files.addFile('utils.cpp');

      expect(files.files.length, 3);

      final success = files.deleteCurrentFile();
      expect(success, true);
      expect(files.files.length, 2);
    });

    test('Cannot delete last remaining file', () {
      final files = LanguageCodeFiles.createDefault('cpp');
      expect(files.files.length, 1);

      final success = files.deleteCurrentFile();
      expect(success, false);
      expect(files.files.length, 1);
    });

    test('File index adjusts after deletion', () {
      final file1 = CodeFile(fileName: 'main.cpp', content: 'code1');
      final file2 = CodeFile(fileName: 'test.cpp', content: 'code2');
      final file3 = CodeFile(fileName: 'utils.cpp', content: 'code3');

      final files = LanguageCodeFiles(
        languageId: 'cpp',
        files: [file1, file2, file3],
        currentFileIndex: 2, // On utils.cpp (last file)
      );

      files.deleteCurrentFile();

      expect(files.files.length, 2);
      expect(files.currentFileIndex, 1); // Adjusted to last valid index
      expect(files.currentFileName, 'test.cpp');
    });

    test('Delete middle file maintains correct index', () {
      final file1 = CodeFile(fileName: 'main.cpp', content: 'code1');
      final file2 = CodeFile(fileName: 'test.cpp', content: 'code2');
      final file3 = CodeFile(fileName: 'utils.cpp', content: 'code3');

      final files = LanguageCodeFiles(
        languageId: 'cpp',
        files: [file1, file2, file3],
        currentFileIndex: 1, // On test.cpp (middle)
      );

      files.deleteCurrentFile();

      expect(files.files.length, 2);
      expect(files.currentFileIndex, 1); // Now pointing to utils.cpp
      expect(files.currentFileName, 'utils.cpp');
    });
  });

  group('LanguageCodeFiles - Firestore Serialization', () {
    test('Convert to Firestore format', () {
      final file1 = CodeFile(fileName: 'main.cpp', content: 'code1');
      final file2 = CodeFile(fileName: 'test.cpp', content: 'code2');

      final files = LanguageCodeFiles(
        languageId: 'cpp',
        files: [file1, file2],
        currentFileIndex: 1,
      );

      final firestore = files.toFirestore();

      expect(firestore['main.cpp'], 'code1');
      expect(firestore['test.cpp'], 'code2');
      expect(firestore['_currentFile'], 'test.cpp');
    });

    test('Restore from Firestore format', () {
      final firestoreData = {
        'main.cpp': 'code1',
        'test.cpp': 'code2',
        'utils.cpp': 'code3',
        '_currentFile': 'test.cpp',
      };

      final files = LanguageCodeFiles.fromFirestore('cpp', firestoreData);

      expect(files.languageId, 'cpp');
      expect(files.files.length, 3);
      expect(files.currentFileName, 'test.cpp');
      expect(files.currentFileIndex, 1);
      expect(files.getFileByName('main.cpp')!.content, 'code1');
      expect(files.getFileByName('test.cpp')!.content, 'code2');
      expect(files.getFileByName('utils.cpp')!.content, 'code3');
    });

    test('Restore from empty Firestore data creates default', () {
      final files = LanguageCodeFiles.fromFirestore('python', {});

      expect(files.files.length, 1);
      expect(files.currentFileName, 'main.py');
    });

    test('Restore with missing _currentFile defaults to first', () {
      final firestoreData = {
        'main.cpp': 'code1',
        'test.cpp': 'code2',
        // _currentFile missing
      };

      final files = LanguageCodeFiles.fromFirestore('cpp', firestoreData);

      expect(files.currentFileIndex, 0);
      expect(files.currentFileName, 'main.cpp');
    });

    test('Round-trip: toFirestore → fromFirestore preserves data', () {
      final original = LanguageCodeFiles.createDefault('cpp');
      original.addFile('test.cpp');
      original.updateCurrentFileContent('modified content');

      final firestoreData = original.toFirestore();
      final restored = LanguageCodeFiles.fromFirestore('cpp', firestoreData);

      expect(restored.files.length, original.files.length);
      expect(restored.currentFileName, original.currentFileName);
      expect(restored.currentFile.content, original.currentFile.content);
    });
  });

  group('LanguageCodeFiles - JSON Serialization', () {
    test('Convert to JSON', () {
      final files = LanguageCodeFiles.createDefault('cpp');
      files.addFile('test.cpp');

      final json = files.toJson();

      expect(json['files'], isList);
      expect(json['files'].length, 2);
      expect(json['currentFileIndex'], isNotNull);
    });

    test('Restore from JSON', () {
      final json = {
        'files': [
          {'fileName': 'main.cpp', 'content': 'code1'},
          {'fileName': 'test.cpp', 'content': 'code2'},
        ],
        'currentFileIndex': 1,
      };

      final files = LanguageCodeFiles.fromJson('cpp', json);

      expect(files.files.length, 2);
      expect(files.currentFileIndex, 1);
      expect(files.currentFileName, 'test.cpp');
    });

    test('Round-trip: toJson → fromJson preserves data', () {
      final original = LanguageCodeFiles.createDefault('python');
      original.addFile('helper.py');
      original.updateCurrentFileContent('new content');

      final json = original.toJson();
      final restored = LanguageCodeFiles.fromJson('python', json);

      expect(restored.files.length, original.files.length);
      expect(restored.currentFileIndex, original.currentFileIndex);
      expect(restored.currentFile.content, original.currentFile.content);
    });
  });

  group('LanguageCodeFiles - Edge Cases', () {
    test('Handle single file operations correctly', () {
      final files = LanguageCodeFiles.createDefault('cpp');

      expect(files.files.length, 1);

      // Navigation should stay on same file
      files.nextFile();
      expect(files.currentFileIndex, 0);

      files.previousFile();
      expect(files.currentFileIndex, 0);

      // Deletion should fail
      expect(files.deleteCurrentFile(), false);
      expect(files.files.length, 1);
    });

    test('CopyWith creates independent copy', () {
      final original = LanguageCodeFiles.createDefault('cpp');
      original.addFile('test.cpp');

      final copy = original.copyWith();

      copy.addFile('utils.cpp');

      expect(copy.files.length, 3);
      expect(original.files.length, 2); // Original unchanged
    });

    test('ToString provides useful information', () {
      final files = LanguageCodeFiles.createDefault('cpp');
      files.addFile('test.cpp');

      final str = files.toString();

      expect(str, contains('cpp'));
      expect(str, contains('2')); // filesCount
      expect(str, contains('test.cpp')); // currentFile
    });
  });
}
