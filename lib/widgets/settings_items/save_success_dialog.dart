import 'package:flutter/material.dart';

/// A dialog shown after successfully saving settings changes
class SaveSuccessDialog extends StatelessWidget {
  final String message;
  final VoidCallback? onClose;

  const SaveSuccessDialog({
    super.key,
    this.message = 'Settings saved successfully!',
    this.onClose,
  });

  /// Shows the save success dialog
  static Future<void> show(
    BuildContext context, {
    String? message,
    VoidCallback? onClose,
  }) {
    return showDialog(
      context: context,
      builder: (context) => SaveSuccessDialog(
        message: message ?? 'Settings saved successfully!',
        onClose: onClose,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 28),
          SizedBox(width: 12),
          Text('Success'),
        ],
      ),
      content: Text(
        message,
        style: const TextStyle(fontSize: 16),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onClose?.call();
          },
          child: const Text(
            'OK',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
