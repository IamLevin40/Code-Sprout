import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/styles_schema.dart';

/// A dialog for confirming logout action
class LogoutDialog extends StatelessWidget {
  final VoidCallback? onLogoutSuccess;

  const LogoutDialog({
    super.key,
    this.onLogoutSuccess,
  });

  /// Shows the logout confirmation dialog
  static Future<void> show(
    BuildContext context, {
    VoidCallback? onLogoutSuccess,
  }) {
    final styles = AppStyles();
    final durationMs = styles.getStyles('settings_page.logout_dialog.transition_duration') as int;

    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: Duration(milliseconds: durationMs),
      pageBuilder: (context, animation, secondaryAnimation) {
        return LogoutDialog(onLogoutSuccess: onLogoutSuccess);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.of(context).pop(); // Close the dialog
        onLogoutSuccess?.call();
      }
    } catch (e) {
      if (context.mounted) {
        final styles = AppStyles();
        Navigator.of(context).pop(); // Close the dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: ${e.toString()}'),
            backgroundColor: styles.getStyles('settings_page.text_field.error_border') as Color,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: styles.getStyles('settings_page.logout_dialog.width') as double,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: styles.getStyles('settings_page.logout_dialog.background_color') as Color,
            borderRadius: BorderRadius.circular(
              styles.getStyles('settings_page.logout_dialog.border_radius') as double,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.logout,
                color: styles.getStyles('settings_page.text_field.error_border') as Color,
                size: 28,
              ),
              const SizedBox(height: 12),
              Text(
                'Logout',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: styles.getStyles('settings_page.logout_dialog.title.color') as Color,
                  fontSize: styles.getStyles('settings_page.logout_dialog.title.font_size') as double,
                  fontWeight: styles.getStyles('settings_page.logout_dialog.title.font_weight') as FontWeight,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to logout?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: styles.getStyles('settings_page.logout_dialog.content.font_size') as double,
                  color: styles.getStyles('settings_page.logout_dialog.content.color') as Color,
                  fontWeight: styles.getStyles('settings_page.logout_dialog.content.font_weight') as FontWeight,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Cancel button: uses stroke_color as outer gradient and background_color as inner color
                  SizedBox(
                    width: styles.getStyles('settings_page.logout_dialog.cancel_button.width') as double,
                    height: styles.getStyles('settings_page.logout_dialog.cancel_button.height') as double,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: styles.getStyles('settings_page.logout_dialog.cancel_button.stroke_color') as LinearGradient,
                        borderRadius: BorderRadius.circular(
                          styles.getStyles('settings_page.logout_dialog.cancel_button.border_radius') as double,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(
                          styles.getStyles('settings_page.logout_dialog.cancel_button.border_width') as double,
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: styles.getStyles('settings_page.logout_dialog.cancel_button.background_color') as Color,
                            borderRadius: BorderRadius.circular(
                              (styles.getStyles('settings_page.logout_dialog.cancel_button.border_radius') as double) -
                                  (styles.getStyles('settings_page.logout_dialog.cancel_button.border_width') as double),
                            ),
                          ),
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(padding: EdgeInsets.zero),
                            child: Center(
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: styles.getStyles('settings_page.logout_dialog.cancel_button.text.font_size') as double,
                                  fontWeight: styles.getStyles('settings_page.logout_dialog.cancel_button.text.font_weight') as FontWeight,
                                  color: styles.getStyles('settings_page.logout_dialog.cancel_button.text.color') as Color,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Logout button: gradient stroke + gradient background
                  SizedBox(
                    width: styles.getStyles('settings_page.logout_dialog.logout_button.width') as double,
                    height: styles.getStyles('settings_page.logout_dialog.logout_button.height') as double,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: styles.getStyles('settings_page.logout_dialog.logout_button.stroke_color') as LinearGradient,
                        borderRadius: BorderRadius.circular(
                          styles.getStyles('settings_page.logout_dialog.logout_button.border_radius') as double,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(
                          styles.getStyles('settings_page.logout_dialog.logout_button.border_width') as double,
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: styles.getStyles('settings_page.logout_dialog.logout_button.background_color') as LinearGradient,
                            borderRadius: BorderRadius.circular(
                              (styles.getStyles('settings_page.logout_dialog.logout_button.border_radius') as double) -
                                  (styles.getStyles('settings_page.logout_dialog.logout_button.border_width') as double),
                            ),
                          ),
                          child: TextButton(
                            onPressed: () => _handleLogout(context),
                            style: TextButton.styleFrom(padding: EdgeInsets.zero),
                            child: Center(
                              child: Text(
                                'Logout',
                                style: TextStyle(
                                  fontSize: styles.getStyles('settings_page.logout_dialog.logout_button.text.font_size') as double,
                                  fontWeight: styles.getStyles('settings_page.logout_dialog.logout_button.text.font_weight') as FontWeight,
                                  color: styles.getStyles('settings_page.logout_dialog.logout_button.text.color') as Color,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
