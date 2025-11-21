import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/language_code_files.dart';

/// Service for managing code files in Firestore
/// Structure: users/[userId]/codeFiles/[languageId]
class CodeFilesService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get code files collection reference for a user
  static CollectionReference _getCodeFilesCollection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('codeFiles');
  }

  /// Save code files for a specific language
  /// Structure: users/[userId]/codeFiles/[languageId] = { "fileName1": "code1", "fileName2": "code2", ... }
  static Future<void> saveCodeFiles({
    required String userId,
    required String languageId,
    required LanguageCodeFiles codeFiles,
  }) async {
    try {
      final docRef = _getCodeFilesCollection(userId).doc(languageId);
      await docRef.set(codeFiles.toFirestore());
    } catch (e) {
      throw Exception('Failed to save code files for $languageId: $e');
    }
  }

  /// Load code files for a specific language
  /// Returns null if document doesn't exist
  static Future<LanguageCodeFiles?> loadCodeFiles({
    required String userId,
    required String languageId,
  }) async {
    try {
      final docRef = _getCodeFilesCollection(userId).doc(languageId);
      final doc = await docRef.get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return LanguageCodeFiles.fromFirestore(
        languageId,
        doc.data() as Map<String, dynamic>,
      );
    } catch (e) {
      throw Exception('Failed to load code files for $languageId: $e');
    }
  }

  /// Load or create default code files for a language
  static Future<LanguageCodeFiles> loadOrCreateCodeFiles({
    required String userId,
    required String languageId,
  }) async {
    try {
      final existing = await loadCodeFiles(
        userId: userId,
        languageId: languageId,
      );

      if (existing != null) {
        return existing;
      }

      // Create default
      final defaultFiles = LanguageCodeFiles.createDefault(languageId);

      // Save to Firestore
      await saveCodeFiles(
        userId: userId,
        languageId: languageId,
        codeFiles: defaultFiles,
      );

      return defaultFiles;
    } catch (e) {
      throw Exception('Failed to load or create code files for $languageId: $e');
    }
  }

  /// Delete all code files for a specific language
  static Future<void> deleteCodeFiles({
    required String userId,
    required String languageId,
  }) async {
    try {
      final docRef = _getCodeFilesCollection(userId).doc(languageId);
      await docRef.delete();
    } catch (e) {
      throw Exception('Failed to delete code files for $languageId: $e');
    }
  }

  /// Update a single file in the code files collection
  static Future<void> updateFile({
    required String userId,
    required String languageId,
    required String fileName,
    required String content,
  }) async {
    try {
      final docRef = _getCodeFilesCollection(userId).doc(languageId);
      await docRef.update({
        fileName: content,
      });
    } catch (e) {
      throw Exception('Failed to update file $fileName for $languageId: $e');
    }
  }

  /// Add a new file to the code files collection
  static Future<void> addFile({
    required String userId,
    required String languageId,
    required String fileName,
    required String content,
  }) async {
    try {
      final docRef = _getCodeFilesCollection(userId).doc(languageId);
      await docRef.update({
        fileName: content,
      });
    } catch (e) {
      throw Exception('Failed to add file $fileName for $languageId: $e');
    }
  }

  /// Delete a file from the code files collection
  static Future<void> deleteFile({
    required String userId,
    required String languageId,
    required String fileName,
  }) async {
    try {
      final docRef = _getCodeFilesCollection(userId).doc(languageId);
      await docRef.update({
        fileName: FieldValue.delete(),
      });
    } catch (e) {
      throw Exception('Failed to delete file $fileName for $languageId: $e');
    }
  }

  /// Update the current file selection
  static Future<void> updateCurrentFile({
    required String userId,
    required String languageId,
    required String fileName,
  }) async {
    try {
      final docRef = _getCodeFilesCollection(userId).doc(languageId);
      await docRef.update({
        '_currentFile': fileName,
      });
    } catch (e) {
      throw Exception('Failed to update current file for $languageId: $e');
    }
  }

  /// Check if code files exist for a language
  static Future<bool> codeFilesExist({
    required String userId,
    required String languageId,
  }) async {
    try {
      final docRef = _getCodeFilesCollection(userId).doc(languageId);
      final doc = await docRef.get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Get all language IDs that have code files
  static Future<List<String>> getAvailableLanguages(String userId) async {
    try {
      final snapshot = await _getCodeFilesCollection(userId).get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      throw Exception('Failed to get available languages: $e');
    }
  }

  /// Batch save multiple language code files
  static Future<void> batchSaveCodeFiles({
    required String userId,
    required Map<String, LanguageCodeFiles> codeFilesMap,
  }) async {
    try {
      final batch = _firestore.batch();

      codeFilesMap.forEach((languageId, codeFiles) {
        final docRef = _getCodeFilesCollection(userId).doc(languageId);
        batch.set(docRef, codeFiles.toFirestore());
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to batch save code files: $e');
    }
  }

  /// Delete all code files for a user (for account deletion)
  static Future<void> deleteAllCodeFiles(String userId) async {
    try {
      final snapshot = await _getCodeFilesCollection(userId).get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete all code files: $e');
    }
  }
}
