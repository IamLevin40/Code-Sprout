import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/styles_schema.dart';
import '../miscellaneous/handle_account_validation.dart';
import '../widgets/settings_items/string_field_settings.dart';
import '../widgets/settings_items/save_success_dialog.dart';
import '../widgets/settings_items/logout_dialog.dart';
import '../widgets/error_boundary.dart';

/// User settings page for managing account information
/// Allows users to edit email, password, and username
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _authService = AuthService();
  String? _uid;
  String? _userEmail;
  String? _username;

  bool _isLoading = true;
  bool _isSavingEmail = false;
  bool _isSavingPassword = false;
  bool _isSavingUsername = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authService.currentUser;
      if (user == null) {
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
        }
        return;
      }

      _uid = user.uid;
      _userEmail = user.email;

      // Load username from Firestore
      final userData = await FirestoreService.getUserData(_uid!);
      _username = userData?.get('accountInformation.username') as String?;

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to load user data');
      }
    }
  }

  Future<void> _saveEmail(String newEmail) async {
    setState(() {
      _isSavingEmail = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No user logged in');

      await user.verifyBeforeUpdateEmail(newEmail);
      
      if (mounted) {
        setState(() {
          _userEmail = newEmail;
          _isSavingEmail = false;
        });
        await SaveSuccessDialog.show(
          context,
          message: 'Email update initiated! Please check your new email for verification.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSavingEmail = false;
        });
        _showErrorSnackBar('Failed to update email: ${e.toString()}');
      }
    }
  }

  Future<void> _savePassword(String newPassword) async {
    setState(() {
      _isSavingPassword = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No user logged in');

      await user.updatePassword(newPassword);

      if (mounted) {
        setState(() {
          _isSavingPassword = false;
        });
        await SaveSuccessDialog.show(
          context,
          message: 'Password updated successfully!',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSavingPassword = false;
        });
        if (e.toString().contains('requires-recent-login')) {
          _showErrorSnackBar('Please log out and log back in to change your password');
        } else {
          _showErrorSnackBar('Failed to update password: ${e.toString()}');
        }
      }
    }
  }

  Future<void> _saveUsername(String newUsername) async {
    setState(() {
      _isSavingUsername = true;
    });

    try {
      if (_uid == null) throw Exception('No user ID found');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .update({'accountInformation.username': newUsername});

      if (mounted) {
        setState(() {
          _username = newUsername;
          _isSavingUsername = false;
        });
        await SaveSuccessDialog.show(
          context,
          message: 'Username updated successfully!',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSavingUsername = false;
        });
        _showErrorSnackBar('Failed to update username: ${e.toString()}');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    final styles = AppStyles();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: styles.getStyles('settings_page.text_field.error_border') as Color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _handleLogout() async {
    await LogoutDialog.show(
      context,
      onLogoutSuccess: () {
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary.wrapBuild(
      context: context,
      pageName: 'SettingsPage',
      builder: () {
        final styles = AppStyles();

        if (_isLoading) {
          return Container(
            color: styles.getStyles('global.background.color') as Color,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: styles.getStyles('settings_page.loading_indicator.stroke_weight') as double,
                color: styles.getStyles('settings_page.title.color') as Color,
              ),
            ),
          );
        }

        return Container(
          color: styles.getStyles('global.background.color') as Color,
          child: SafeArea(
            bottom: true,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // Header
                Text(
                  'Account Settings',
                  style: TextStyle(
                    fontSize: styles.getStyles('settings_page.title.font_size') as double,
                    fontWeight: styles.getStyles('settings_page.title.font_weight') as FontWeight,
                    color: styles.getStyles('settings_page.title.color') as Color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage your account information',
                  style: TextStyle(
                    fontSize: styles.getStyles('settings_page.subtitle.font_size') as double,
                    fontWeight: styles.getStyles('settings_page.subtitle.font_weight') as FontWeight,
                    color: styles.getStyles('settings_page.subtitle.color') as Color,
                  ),
                ),
                const SizedBox(height: 24),

                // Email Field
                StringFieldSettings(
                  fieldName: 'email',
                  displayName: 'Email Address',
                  currentValue: _userEmail,
                  isEditable: !_isSavingEmail,
                  fieldType: 'string',
                  isRequired: true,
                  validator: AccountValidation.validateEmail,
                  onSave: _saveEmail,
                ),

                // Password Field
                StringFieldSettings(
                  fieldName: 'password',
                  displayName: 'Password',
                  currentValue: '********',
                  isEditable: !_isSavingPassword,
                  fieldType: 'string',
                  isRequired: true,
                  isPassword: true,
                  validator: AccountValidation.validatePassword,
                  onSave: _savePassword,
                ),

                // Username Field
                StringFieldSettings(
                  fieldName: 'username',
                  displayName: 'Username',
                  currentValue: _username,
                  isEditable: !_isSavingUsername,
                  fieldType: 'string',
                  isRequired: true,
                  validator: AccountValidation.validateUsername,
                  onSave: _saveUsername,
                ),

                SizedBox(height: styles.getStyles('settings_page.divider.height') as double),

                // Logout Button (centered) - uses stroke_color as outer gradient and background_color as inner gradient
                Center(
                  child: SizedBox(
                    width: styles.getStyles('settings_page.logout_button.width') as double,
                    height: styles.getStyles('settings_page.logout_button.height') as double,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: styles.getStyles('settings_page.logout_button.stroke_color') as LinearGradient,
                        borderRadius: BorderRadius.circular(
                          styles.getStyles('settings_page.logout_button.border_radius') as double,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(
                          styles.getStyles('settings_page.logout_button.border_width') as double,
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: styles.getStyles('settings_page.logout_button.background_color') as LinearGradient,
                            borderRadius: BorderRadius.circular(
                              (styles.getStyles('settings_page.logout_button.border_radius') as double) -
                                  (styles.getStyles('settings_page.logout_button.border_width') as double),
                            ),
                          ),
                          child: TextButton(
                            onPressed: _handleLogout,
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  (styles.getStyles('settings_page.logout_button.border_radius') as double) -
                                      (styles.getStyles('settings_page.logout_button.border_width') as double),
                                ),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: Center(
                              child: Text(
                                'Logout',
                                style: TextStyle(
                                  color: styles.getStyles('settings_page.logout_button.text.color') as Color,
                                  fontSize: styles.getStyles('settings_page.logout_button.text.font_size') as double,
                                  fontWeight: styles.getStyles('settings_page.logout_button.text.font_weight') as FontWeight,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: styles.getStyles('settings_page.divider.height') as double),

                // Info Text
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: styles.getStyles('settings_page.info_container.background_color') as Color,
                    borderRadius: BorderRadius.circular(
                      styles.getStyles('settings_page.info_container.border_radius') as double,
                    ),
                    border: Border.all(
                      color: styles.getStyles('settings_page.info_container.stroke_color') as Color,
                      width: styles.getStyles('settings_page.info_container.border_width') as double,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: styles.getStyles('settings_page.info_container.icon.color') as Color,
                        size: styles.getStyles('settings_page.info_container.icon.width') as double,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Changes to your email require verification. You\'ll receive a confirmation email at your new address.',
                          style: TextStyle(
                            fontSize: styles.getStyles('settings_page.info_container.text.font_size') as double,
                            fontWeight: styles.getStyles('settings_page.info_container.text.font_weight') as FontWeight,
                            color: styles.getStyles('settings_page.info_container.text.color') as Color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      },
    );
  }
}
