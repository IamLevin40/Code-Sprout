import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/language_code_files.dart';
import '../services/code_files_service.dart';
import '../widgets/farm_items/delete_file_dialog.dart';

/// Handles code file loading, saving, and navigation operations
class CodeFilesHandler {
  /// Load code files from Firestore or create default files
  static Future<LanguageCodeFiles?> loadCodeFiles({
    required BuildContext context,
    required String languageId,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return null;
      }
      
      final loadedFiles = await CodeFilesService.loadOrCreateCodeFiles(
        userId: user.uid,
        languageId: languageId,
      );
      
      return loadedFiles;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load code files: $e')),
        );
      }
      return null;
    }
  }
  
  /// Save code files to Firestore
  static Future<void> saveCodeFiles({
    required String languageId,
    required LanguageCodeFiles codeFiles,
    required TextEditingController codeController,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      // Update current file content before saving
      codeFiles.updateCurrentFileContent(codeController.text);
      
      await CodeFilesService.saveCodeFiles(
        userId: user.uid,
        languageId: languageId,
        codeFiles: codeFiles,
      );
    } catch (e) {
      // Silent fail - don't interrupt user experience
    }
  }

  /// Navigate to next file in editor
  static void nextEditorFile({
    required LanguageCodeFiles codeFiles,
    required TextEditingController codeController,
    required String languageId,
    required bool isExecuting,
    required VoidCallback onStateChanged,
  }) {
    if (isExecuting) return;
    
    // Save current file content before switching
    codeFiles.updateCurrentFileContent(codeController.text);
    
    codeFiles.nextFile();
    codeController.text = codeFiles.currentFile.content;
    onStateChanged();
    
    saveCodeFiles(
      languageId: languageId,
      codeFiles: codeFiles,
      codeController: codeController,
    );
  }
  
  /// Navigate to previous file in editor
  static void previousEditorFile({
    required LanguageCodeFiles codeFiles,
    required TextEditingController codeController,
    required String languageId,
    required bool isExecuting,
    required VoidCallback onStateChanged,
  }) {
    if (isExecuting) return;
    
    // Save current file content before switching
    codeFiles.updateCurrentFileContent(codeController.text);
    
    codeFiles.previousFile();
    codeController.text = codeFiles.currentFile.content;
    onStateChanged();
    
    saveCodeFiles(
      languageId: languageId,
      codeFiles: codeFiles,
      codeController: codeController,
    );
  }
  
  /// Create a new file with the given name
  static void createFile({
    required BuildContext context,
    required String fileName,
    required LanguageCodeFiles codeFiles,
    required TextEditingController codeController,
    required String languageId,
    required VoidCallback onStateChanged,
  }) {
    final error = codeFiles.addFile(fileName);
    
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    } else {
      codeController.text = codeFiles.currentFile.content;
      onStateChanged();
      saveCodeFiles(
        languageId: languageId,
        codeFiles: codeFiles,
        codeController: codeController,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File "$fileName" created')),
      );
    }
  }
  
  /// Delete the current file
  static void deleteCurrentFile({
    required BuildContext context,
    required LanguageCodeFiles codeFiles,
    required TextEditingController codeController,
    required String languageId,
    required bool isExecuting,
    required int selectedExecutionFileIndex,
    required Function(int) onExecutionIndexChanged,
    required VoidCallback onStateChanged,
  }) {
    if (isExecuting) return;
    
    if (codeFiles.files.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete the only file')),
      );
      return;
    }
    
    final fileName = codeFiles.currentFileName;
    
    showDeleteFileDialog(
      context,
      fileName: fileName,
      onConfirm: () {
        final success = codeFiles.deleteCurrentFile();

        if (success) {
          // Adjust execution file index if needed
          if (selectedExecutionFileIndex >= codeFiles.files.length) {
            onExecutionIndexChanged(codeFiles.files.length - 1);
          }

          codeController.text = codeFiles.currentFile.content;
          onStateChanged();
          saveCodeFiles(
            languageId: languageId,
            codeFiles: codeFiles,
            codeController: codeController,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('File "$fileName" deleted')),
          );
        }
      },
    );
  }
}
