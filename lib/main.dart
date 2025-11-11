import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'models/styles_schema.dart';
import 'miscellaneous/touch_mouse_drag_scroll_behavior.dart';
import 'pages/register_page.dart';
import 'pages/login_page.dart';
import 'pages/main_navigation_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Load app styles from schema
  await AppStyles().loadStyles();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();
    
    return MaterialApp(
      title: 'Code Sprout',
      scrollBehavior: const TouchMouseDragScrollBehavior(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: styles.getStyles('constant_values.colors.light_purple') as Color,
          secondary: styles.getStyles('constant_values.colors.dark_green') as Color,
        ),
        useMaterial3: true,
        fontFamily: 'Poppins',
      ),
      home: const AuthWrapper(),
      routes: {
        '/register': (context) => const RegisterPage(),
        '/login': (context) => const LoginPage(),
        '/home': (context) => const MainNavigationPage(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final styles = AppStyles();

    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading screen while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: styles.getStyles('constant_values.colors.white') as Color,
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  styles.getStyles('constant_values.colors.light_purple') as Color,
                ),
              ),
            ),
          );
        }

        // If user is logged in, show main navigation page
        if (snapshot.hasData) {
          return const MainNavigationPage();
        }

        // If user is not logged in, show login page
        // (Unauthenticated users should be prompted to login)
        return const LoginPage();
      },
    );
  }
}
