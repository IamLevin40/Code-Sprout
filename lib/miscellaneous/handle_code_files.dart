import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/language_code_files.dart';
import '../services/code_files_service.dart';
import '../widgets/farm_items/delete_file_dialog.dart';
import '../widgets/farm_items/notification_display.dart';

/// Handles code file loading, saving, and navigation operations
class CodeFilesHandler {
  /// Load code files from Firestore or create default files
  static Future<LanguageCodeFiles?> loadCodeFiles({
    required BuildContext context,
    required String languageId,
    NotificationController? notificationController,
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
        if (notificationController != null) {
          notificationController.showError('Failed to load code files: $e');
        } else {
          debugPrint('Failed to load code files: $e');
        }
      }
      return null;
    }
  }
  
  /// Save code files to Firestore
  static Future<void> saveCodeFiles({
    required String languageId,
    required LanguageCodeFiles codeFiles,
    required TextEditingController codeController,
    NotificationController? notificationController,
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
      if (notificationController != null) {
        notificationController.showError('Failed to save code files: $e');
      } else {
        debugPrint('Failed to save code files: $e');
      }
    }
  }

  /// Navigate to next file in editor
  static void nextEditorFile({
    required LanguageCodeFiles codeFiles,
    required TextEditingController codeController,
    required String languageId,
    required bool isExecuting,
    required VoidCallback onStateChanged,
    NotificationController? notificationController,
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
      notificationController: notificationController,
    );
  }
  
  /// Navigate to previous file in editor
  static void previousEditorFile({
    required LanguageCodeFiles codeFiles,
    required TextEditingController codeController,
    required String languageId,
    required bool isExecuting,
    required VoidCallback onStateChanged,
    NotificationController? notificationController,
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
      notificationController: notificationController,
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
    NotificationController? notificationController,
  }) {
    final error = codeFiles.addFile(fileName);
    
    if (error != null) {
      if (notificationController != null) {
        notificationController.showError(error);
      } else {
        debugPrint(error);
      }
    } else {
      codeController.text = codeFiles.currentFile.content;
      onStateChanged();
      saveCodeFiles(
        languageId: languageId,
        codeFiles: codeFiles,
        codeController: codeController,
        notificationController: notificationController,
      );
      if (notificationController != null) {
        notificationController.showSuccess('File "$fileName" created');
      } else {
        debugPrint('File "$fileName" created');
      }
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
    NotificationController? notificationController,
  }) {
    if (isExecuting) return;
    
    if (codeFiles.files.length <= 1) {
      if (notificationController != null) {
        notificationController.showError('Cannot delete the only file');
      } else {
        debugPrint('Cannot delete the only file');
      }
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
              notificationController: notificationController,
            );
          
          if (notificationController != null) {
            notificationController.showSuccess('File "$fileName" deleted');
          } else {
            debugPrint('File "$fileName" deleted');
          }
        }
      },
    );
  }
}
