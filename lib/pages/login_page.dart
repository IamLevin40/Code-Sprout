import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/styles_schema.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final error = await _authService.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (error == null) {
      // Success - navigate immediately to Home for faster UX
      setState(() {
        _isLoading = false;
      });
      if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = error;
      });
    }
  }

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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo/Icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: styles.getStyles('login_page.logo_container.background_color') as LinearGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.login,
                      size: styles.getStyles('login_page.logo_container.icon.font_size') as double,
                      color: styles.getStyles('login_page.logo_container.icon.color') as Color,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Title
                  Text(
                    'Welcome!',
                    style: TextStyle(
                      fontSize: styles.getStyles('login_page.title.font_size') as double,
                      fontWeight: styles.getStyles('login_page.title.font_weight') as FontWeight,
                      color: styles.getStyles('login_page.title.color') as Color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to continue',
                    style: TextStyle(
                      fontSize: styles.getStyles('login_page.subtitle.font_size') as double,
                      color: styles.getStyles('login_page.subtitle.color') as Color,
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
                        color: styles.getStyles('login_page.error_container.background_color') as Color,
                        borderRadius: BorderRadius.circular(styles.getStyles('login_page.error_container.border_radius') as double),
                        border: Border.all(
                          color: styles.getStyles('login_page.error_container.border.color') as Color,
                          width: styles.getStyles('login_page.error_container.border.width') as double,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: styles.getStyles('login_page.error_container.icon.color') as Color,
                            size: styles.getStyles('login_page.error_container.icon.width') as double,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: styles.getStyles('login_page.error_container.text.color') as Color,
                                fontSize: styles.getStyles('login_page.error_container.text.font_size') as double,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your email',
                      prefixIcon: Icon(Icons.email_outlined, color: styles.getStyles('login_page.email_field.icon.color') as Color),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(styles.getStyles('login_page.email_field.border_radius') as double),
                        borderSide: BorderSide(color: styles.getStyles('login_page.email_field.border.color') as Color),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(styles.getStyles('login_page.email_field.border_radius') as double),
                        borderSide: BorderSide(
                          color: styles.getStyles('login_page.email_field.border.color') as Color,
                          width: styles.getStyles('login_page.email_field.border.width') as double,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(styles.getStyles('login_page.email_field.border_radius') as double),
                        borderSide: BorderSide(
                          color: styles.getStyles('login_page.email_field.focused_border.color') as Color,
                          width: styles.getStyles('login_page.email_field.focused_border.width') as double,
                        ),
                      ),
                      filled: true,
                      fillColor: styles.getStyles('login_page.email_field.background_color') as Color,
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
                      prefixIcon: Icon(Icons.lock_outline, color: styles.getStyles('login_page.password_field.icon.color') as Color),
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
                        borderRadius: BorderRadius.circular(styles.getStyles('login_page.password_field.border_radius') as double),
                        borderSide: BorderSide(
                          color: styles.getStyles('login_page.password_field.border.color') as Color,
                          width: styles.getStyles('login_page.password_field.border.width') as double,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(styles.getStyles('login_page.password_field.border_radius') as double),
                        borderSide: BorderSide(
                          color: styles.getStyles('login_page.password_field.border.color') as Color,
                          width: styles.getStyles('login_page.password_field.border.width') as double,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(styles.getStyles('login_page.password_field.border_radius') as double),
                        borderSide: BorderSide(
                          color: styles.getStyles('login_page.password_field.focused_border.color') as Color,
                          width: styles.getStyles('login_page.password_field.focused_border.width') as double,
                        ),
                      ),
                      filled: true,
                      fillColor: styles.getStyles('login_page.password_field.background_color') as Color,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Login Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: styles.getStyles('login_page.login_button.background_color') as Color,
                      foregroundColor: styles.getStyles('login_page.login_button.text.color') as Color,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(styles.getStyles('login_page.login_button.border_radius') as double),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: styles.getStyles('login_page.login_button.progress_indicator.height') as double,
                            width: styles.getStyles('login_page.login_button.progress_indicator.width') as double,
                            child: CircularProgressIndicator(
                              strokeWidth: styles.getStyles('login_page.login_button.progress_indicator.stroke_weight') as double,
                              valueColor: AlwaysStoppedAnimation<Color>(styles.getStyles('login_page.login_button.text.color') as Color),
                            ),
                          )
                        : Text(
                            'Login',
                            style: TextStyle(
                              fontSize: styles.getStyles('login_page.login_button.text.font_size') as double,
                              fontWeight: styles.getStyles('login_page.login_button.text.font_weight') as FontWeight,
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),

                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Don\'t have an account? ',
                        style: TextStyle(
                          color: styles.getStyles('global.text.secondary.color') as Color,
                          fontSize: styles.getStyles('global.text.secondary.font_size') as double,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/register');
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Register',
                          style: TextStyle(
                            color: styles.getStyles('login_page.register_link.color') as Color,
                            fontSize: styles.getStyles('login_page.register_link.font_size') as double,
                            fontWeight: styles.getStyles('login_page.register_link.font_weight') as FontWeight,
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
