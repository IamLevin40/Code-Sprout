import 'package:flutter/material.dart';
import '../../models/language_code_files.dart';
import '../../miscellaneous/handle_code_files.dart';

/// Shows a dialog to add a new code file
void showAddFileDialog({
  required BuildContext context,
  required String languageId,
  required LanguageCodeFiles codeFiles,
  required TextEditingController codeController,
  required bool isExecuting,
  required VoidCallback onStateChanged,
}) {
  if (isExecuting) return;
  
  final TextEditingController fileNameController = TextEditingController();
  final extension = LanguageCodeFiles.getFileExtension(languageId);
  
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Create New File'),
      content: Row(
        children: [
          Expanded(
            child: TextField(
              controller: fileNameController,
              decoration: const InputDecoration(
                hintText: 'Enter file name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              onSubmitted: (_) => _createFileFromDialog(
                context: context,
                dialogContext: dialogContext,
                fileName: fileNameController.text + extension,
                codeFiles: codeFiles,
                codeController: codeController,
                languageId: languageId,
                onStateChanged: onStateChanged,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            extension,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => _createFileFromDialog(
            context: context,
            dialogContext: dialogContext,
            fileName: fileNameController.text + extension,
            codeFiles: codeFiles,
            codeController: codeController,
            languageId: languageId,
            onStateChanged: onStateChanged,
          ),
          child: const Text('Create'),
        ),
      ],
    ),
  );
}

/// Helper to create file from dialog
void _createFileFromDialog({
  required BuildContext context,
  required BuildContext dialogContext,
  required String fileName,
  required LanguageCodeFiles codeFiles,
  required TextEditingController codeController,
  required String languageId,
  required VoidCallback onStateChanged,
}) {
  Navigator.pop(dialogContext);
  
  CodeFilesHandler.createFile(
    context: context,
    fileName: fileName,
    codeFiles: codeFiles,
    codeController: codeController,
    languageId: languageId,
    onStateChanged: onStateChanged,
  );
}
