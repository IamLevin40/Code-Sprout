import 'package:flutter/material.dart';
import '../../models/styles_schema.dart';

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
    final styles = AppStyles();
    
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: styles.getStyles('settings_page.text_field.focused_stroke_color') as Color,
            size: styles.getStyles('settings_page.success_dialog.icon.width') as double,
          ),
          const SizedBox(width: 12),
          Text(
            'Success',
            style: TextStyle(
              color: styles.getStyles('settings_page.logout_dialog.title.color') as Color,
              fontSize: styles.getStyles('settings_page.logout_dialog.title.font_size') as double,
              fontWeight: styles.getStyles('settings_page.logout_dialog.title.font_weight') as FontWeight,
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: TextStyle(
          fontSize: styles.getStyles('settings_page.logout_dialog.content.font_size') as double,
          color: styles.getStyles('settings_page.logout_dialog.content.color') as Color,
          fontWeight: styles.getStyles('settings_page.logout_dialog.content.font_weight') as FontWeight,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onClose?.call();
          },
          child: Text(
            'OK',
            style: TextStyle(
              fontSize: styles.getStyles('settings_page.logout_dialog.cancel_button.text.font_size') as double,
              fontWeight: styles.getStyles('settings_page.logout_dialog.cancel_button.text.font_weight') as FontWeight,
              color: styles.getStyles('settings_page.text_field.focused_stroke_color') as Color,
            ),
          ),
        ),
      ],
    );
  }
}
