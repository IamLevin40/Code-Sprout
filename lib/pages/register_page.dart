import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/styles_schema.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if passwords match
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Register user with Firebase Authentication first
    final error = await _authService.register(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (error == null) {
      // Get the newly created user's UID
      final uid = _authService.currentUser?.uid;

      if (uid != null) {
        // Now that user is authenticated, check if username exists
        try {
          final usernameExists = await FirestoreService.usernameExists(_usernameController.text.trim());
          if (usernameExists) {
            // Username exists - delete the auth user and show error
            await _authService.currentUser?.delete();
            await _authService.signOut();
            
            if (mounted) {
              setState(() {
                _isLoading = false;
                _errorMessage = 'Username already exists. Please choose another.';
              });
            }
            return;
          }
        } catch (e) {
          // Failed to check username - delete auth user and show error
          await _authService.currentUser?.delete();
          await _authService.signOut();
          
          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage = 'Failed to verify username. Please try again.';
            });
          }
          return;
        }

        // Username is available - create Firestore document
        try {
          await FirestoreService.createUserDocument(
            uid: uid,
            username: _usernameController.text.trim(),
          );

          // Success!
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            _showSuccessDialog();
          }
        } catch (e) {
          // Failed to create user document - delete auth user
          await _authService.currentUser?.delete();
          await _authService.signOut();
          
          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage = 'Failed to create user profile. Please try again.';
            });
          }
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Registration succeeded but failed to get user info.';
        });
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = error;
      });
    }
  }

  void _showSuccessDialog() {
    final styles = AppStyles();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(styles.getStyles('register_page.success_dialog.border_radius') as double),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: styles.getStyles('register_page.success_dialog.background_color') as Color,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: styles.getStyles('register_page.success_dialog.icon.color') as Color,
                  size: styles.getStyles('register_page.success_dialog.icon.width') as double,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Successfully Registered!',
                style: TextStyle(
                  fontSize: styles.getStyles('register_page.success_dialog.title.font_size') as double,
                  fontWeight: styles.getStyles('register_page.success_dialog.title.font_weight') as FontWeight,
                  color: styles.getStyles('register_page.success_dialog.title.color') as Color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Your account has been created successfully.',
                style: TextStyle(
                  fontSize: styles.getStyles('register_page.success_dialog.message.font_size') as double,
                  color: styles.getStyles('register_page.success_dialog.message.color') as Color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Navigate to Home when user continues
                    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: styles.getStyles('register_page.success_dialog.button.background_color') as Color,
                    foregroundColor: styles.getStyles('register_page.success_dialog.button.text.color') as Color,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(styles.getStyles('register_page.success_dialog.button.border_radius') as double),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: styles.getStyles('register_page.success_dialog.button.text.font_size') as double,
                      fontWeight: styles.getStyles('register_page.success_dialog.button.text.font_weight') as FontWeight,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Success dialog is shown on registration completion; Firestore write runs in background.

  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();
    
    return Scaffold(
      backgroundColor: styles.getStyles('global.background.color') as Color,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo/Icon
                  Container(
                    width: styles.getStyles('register_page.logo_container.width') as double,
                    height: styles.getStyles('register_page.logo_container.height') as double,
                    decoration: BoxDecoration(
                      color: styles.getStyles('register_page.logo_container.background_color') as Color,
                      borderRadius: BorderRadius.circular(styles.getStyles('register_page.logo_container.border_radius') as double),
                    ),
                    child: Center(
                      child: Image.asset(
                        styles.getStyles('register_page.logo_container.icon.image') as String,
                        width: styles.getStyles('register_page.logo_container.icon.width') as double,
                        height: styles.getStyles('register_page.logo_container.icon.height') as double,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Title
                  Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: styles.getStyles('register_page.title.font_size') as double,
                      fontWeight: styles.getStyles('register_page.title.font_weight') as FontWeight,
                      color: styles.getStyles('register_page.title.color') as Color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign up to get started',
                    style: TextStyle(
                      fontSize: styles.getStyles('register_page.subtitle.font_size') as double,
                      color: styles.getStyles('register_page.subtitle.color') as Color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Error Message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: styles.getStyles('register_page.error_container.background_color') as Color,
                        borderRadius: BorderRadius.circular(styles.getStyles('register_page.error_container.border_radius') as double),
                        border: Border.all(
                          color: styles.getStyles('register_page.error_container.border.color') as Color,
                          width: styles.getStyles('register_page.error_container.border.width') as double,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: styles.getStyles('register_page.error_container.icon.color') as Color,
                            size: styles.getStyles('register_page.error_container.icon.width') as double,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: styles.getStyles('register_page.error_container.text.color') as Color,
                                fontSize: styles.getStyles('register_page.error_container.text.font_size') as double,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Username Field
                  TextFormField(
                    controller: _usernameController,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      hintText: 'Enter your username',
                      prefixIcon: Icon(Icons.account_circle_outlined, color: styles.getStyles('register_page.username_field.icon.color') as Color),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(styles.getStyles('register_page.username_field.border_radius') as double),
                        borderSide: BorderSide(
                          color: styles.getStyles('register_page.username_field.border.color') as Color,
                          width: styles.getStyles('register_page.username_field.border.width') as double,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(styles.getStyles('register_page.username_field.border_radius') as double),
                        borderSide: BorderSide(
                          color: styles.getStyles('register_page.username_field.border.color') as Color,
                          width: styles.getStyles('register_page.username_field.border.width') as double,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(styles.getStyles('register_page.username_field.border_radius') as double),
                        borderSide: BorderSide(
                          color: styles.getStyles('register_page.username_field.focused_border.color') as Color,
                          width: styles.getStyles('register_page.username_field.focused_border.width') as double,
                        ),
                      ),
                      filled: true,
                      fillColor: styles.getStyles('register_page.username_field.background_color') as Color,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a username';
                      }
                      if (value.length < 8) {
                        return 'Username must be at least 8 characters';
                      }
                      // Check if alphanumeric (letters and numbers only, no spaces)
                      if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
                        return 'Username must be alphanumeric (letters and numbers only)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your email',
                      prefixIcon: Icon(Icons.email_outlined, color: styles.getStyles('register_page.email_field.icon.color') as Color),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(styles.getStyles('register_page.email_field.border_radius') as double),
                        borderSide: BorderSide(
                          color: styles.getStyles('register_page.email_field.border.color') as Color,
                          width: styles.getStyles('register_page.email_field.border.width') as double,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(styles.getStyles('register_page.email_field.border_radius') as double),
                        borderSide: BorderSide(
                          color: styles.getStyles('register_page.email_field.border.color') as Color,
                          width: styles.getStyles('register_page.email_field.border.width') as double,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(styles.getStyles('register_page.email_field.border_radius') as double),
                        borderSide: BorderSide(
                          color: styles.getStyles('register_page.email_field.focused_border.color') as Color,
                          width: styles.getStyles('register_page.email_field.focused_border.width') as double,
                        ),
                      ),
                      filled: true,
                      fillColor: styles.getStyles('register_page.email_field.background_color') as Color,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      prefixIcon: Icon(Icons.lock_outline, color: styles.getStyles('register_page.password_field.icon.color') as Color),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: styles.getStyles('global.text.secondary.color') as Color,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(styles.getStyles('register_page.password_field.border_radius') as double),
                        borderSide: BorderSide(
                          color: styles.getStyles('register_page.password_field.border.color') as Color,
                          width: styles.getStyles('register_page.password_field.border.width') as double,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(styles.getStyles('register_page.password_field.border_radius') as double),
                        borderSide: BorderSide(
                          color: styles.getStyles('register_page.password_field.border.color') as Color,
                          width: styles.getStyles('register_page.password_field.border.width') as double,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(styles.getStyles('register_page.password_field.border_radius') as double),
                        borderSide: BorderSide(
                          color: styles.getStyles('register_page.password_field.focused_border.color') as Color,
                          width: styles.getStyles('register_page.password_field.focused_border.width') as double,
                        ),
                      ),
                      filled: true,
                      fillColor: styles.getStyles('register_page.password_field.background_color') as Color,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password Field
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      hintText: 'Re-enter your password',
                      prefixIcon: Icon(Icons.lock_outline, color: styles.getStyles('register_page.password_field.icon.color') as Color),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: styles.getStyles('global.text.secondary.color') as Color,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(styles.getStyles('register_page.password_field.border_radius') as double),
                        borderSide: BorderSide(
                          color: styles.getStyles('register_page.password_field.border.color') as Color,
                          width: styles.getStyles('register_page.password_field.border.width') as double,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(styles.getStyles('register_page.password_field.border_radius') as double),
                        borderSide: BorderSide(
                          color: styles.getStyles('register_page.password_field.border.color') as Color,
                          width: styles.getStyles('register_page.password_field.border.width') as double,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(styles.getStyles('register_page.password_field.border_radius') as double),
                        borderSide: BorderSide(
                          color: styles.getStyles('register_page.password_field.focused_border.color') as Color,
                          width: styles.getStyles('register_page.password_field.focused_border.width') as double,
                        ),
                      ),
                      filled: true,
                      fillColor: styles.getStyles('register_page.password_field.background_color') as Color,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Register Button
                  Container(
                    width: styles.getStyles('register_page.register_button.width') as double,
                    height: styles.getStyles('register_page.register_button.height') as double,
                    decoration: BoxDecoration(
                      gradient: styles.getStyles('register_page.register_button.stroke_color') as LinearGradient,
                      borderRadius: BorderRadius.circular(styles.getStyles('register_page.register_button.border_radius') as double),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(styles.getStyles('register_page.register_button.border_width') as double),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: styles.getStyles('register_page.register_button.background_color') as LinearGradient,
                          borderRadius: BorderRadius.circular(
                            (styles.getStyles('register_page.register_button.border_radius') as double) - 
                            (styles.getStyles('register_page.register_button.border_width') as double)
                          ),
                        ),
                        child: TextButton(
                          onPressed: _isLoading ? null : _register,
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                (styles.getStyles('register_page.register_button.border_radius') as double) - 
                                (styles.getStyles('register_page.register_button.border_width') as double)
                              ),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: Center(
                            child: _isLoading
                                ? SizedBox(
                                    height: styles.getStyles('register_page.register_button.progress_indicator.height') as double,
                                    width: styles.getStyles('register_page.register_button.progress_indicator.width') as double,
                                    child: CircularProgressIndicator(
                                      strokeWidth: styles.getStyles('register_page.register_button.progress_indicator.stroke_weight') as double,
                                      valueColor: AlwaysStoppedAnimation<Color>(styles.getStyles('register_page.register_button.text.color') as Color),
                                    ),
                                  )
                                : Text(
                                    'Register',
                                    style: TextStyle(
                                      color: styles.getStyles('register_page.register_button.text.color') as Color,
                                      fontSize: styles.getStyles('register_page.register_button.text.font_size') as double,
                                      fontWeight: styles.getStyles('register_page.register_button.text.font_weight') as FontWeight,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(
                          color: styles.getStyles('global.text.secondary.color') as Color,
                          fontSize: styles.getStyles('global.text.secondary.font_size') as double,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Login',
                          style: TextStyle(
                            color: styles.getStyles('register_page.login_link.color') as Color,
                            fontSize: styles.getStyles('register_page.login_link.font_size') as double,
                            fontWeight: styles.getStyles('register_page.login_link.font_weight') as FontWeight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

