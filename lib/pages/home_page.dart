import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/styles_schema.dart';

class HomePage extends StatefulWidget {
  final ValueChanged<int>? onTabSelected;

  const HomePage({super.key, this.onTabSelected});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _username;
  bool _loadingUsername = true;

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final authService = AuthService();
    final uid = authService.currentUser?.uid;
    if (uid == null) {
      // Not logged in - navigate to login
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
      }
      return;
    }

    try {
      final userData = await FirestoreService.getUserData(uid);
      if (!mounted) return;
      setState(() {
        _username = (userData?.get('accountInformation.username') as String?) ?? '';
        _loadingUsername = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _username = null;
        _loadingUsername = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;
    final styles = AppStyles();

    return Stack(
      children: [
        Scaffold(
          backgroundColor: styles.getColor('common.background.color'),
          appBar: AppBar(
            title: Text(
              'Code Sprout',
              style: TextStyle(
                fontWeight: styles.getFontWeight('appbar.title.font_weight'),
                color: styles.getColor('appbar.title.color'),
                fontSize: styles.getFontSize('appbar.title.font_size'),
              ),
            ),
            centerTitle: true,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: styles.getLinearGradient('appbar.background.linear_gradient'),
              ),
            ),
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(Icons.logout, color: styles.getColor('appbar.icon.color')),
                tooltip: 'Logout',
                onPressed: () => _showLogoutDialog(context, authService),
              ),
            ],
          ),
          body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Welcome Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: styles.getLinearGradient('home_page.welcome_container.background.linear_gradient'),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: styles.getColorWithOpacity(
                        'home_page.welcome_container.shadow.color',
                        opacityPath: 'home_page.welcome_container.shadow.opacity',
                      ),
                      blurRadius: styles.getBlurRadius('home_page.welcome_container.shadow.blur_radius'),
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.home,
                  size: styles.getFontSize('home_page.welcome_container.icon.font_size'),
                  color: styles.getColor('home_page.welcome_container.icon.color'),
                ),
              ),
              const SizedBox(height: 40),

              // Welcome Text
              _loadingUsername
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: SizedBox(
                        height: styles.getHeight('home_page.username_loader.height'),
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: styles.getStrokeWeight('home_page.username_loader.stroke_weight'),
                            color: styles.getColor('appbar.background.linear_gradient.begin.color'),
                          ),
                        ),
                      ),
                    )
                  : Text(
                      'Welcome${_username != null && _username!.isNotEmpty ? ', ${_username!}' : ''}!',
                      style: TextStyle(
                        fontSize: styles.getFontSize('home_page.welcome_text.font_size'),
                        fontWeight: styles.getFontWeight('home_page.welcome_text.font_weight'),
                        color: styles.getColor('home_page.welcome_text.color'),
                      ),
                      textAlign: TextAlign.center,
                    ),
              const SizedBox(height: 16),

              // User Email
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: styles.getColor('home_page.email_container.background.color'),
                  borderRadius: BorderRadius.circular(styles.getBorderRadius('home_page.email_container.border_radius')),
                  border: Border.all(
                    color: styles.getColor('home_page.email_container.border.color'),
                    width: styles.getWidth('home_page.email_container.border.width'),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.email_outlined,
                      color: styles.getColor('home_page.email_container.icon.color'),
                      size: styles.getWidth('home_page.email_container.icon.width'),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      user?.email ?? 'No email',
                      style: TextStyle(
                        fontSize: styles.getFontSize('home_page.email_container.text.font_size'),
                        color: styles.getColor('home_page.email_container.text.color'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Info Text
              Text(
                'You are successfully logged in!',
                style: TextStyle(
                  fontSize: styles.getFontSize('home_page.info_text.primary.font_size'),
                  color: styles.getColor('home_page.info_text.primary.color'),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Your session is secure and will persist until you logout.',
                style: TextStyle(
                  fontSize: styles.getFontSize('home_page.info_text.secondary.font_size'),
                  color: styles.getColor('home_page.info_text.secondary.color'),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Quick navigation to Course and Sprout pages
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      // Switch to Courses tab (index 1)
                      if (widget.onTabSelected != null) widget.onTabSelected!(1);
                    },
                    icon: Icon(Icons.school, color: styles.getColor('home_page.quick_nav.course.icon.color')),
                    label: Text('Courses', style: TextStyle(fontSize: styles.getFontSize('home_page.quick_nav.course.text.font_size'))),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: styles.getColor('home_page.quick_nav.course.background.color'),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Switch to Sprout tab (index 2)
                      if (widget.onTabSelected != null) widget.onTabSelected!(2);
                    },
                    icon: Icon(Icons.grass, color: styles.getColor('home_page.quick_nav.sprout.icon.color')),
                    label: Text('The Sprout', style: TextStyle(fontSize: styles.getFontSize('home_page.quick_nav.sprout.text.font_size'))),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: styles.getColor('home_page.quick_nav.sprout.background.color'),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Logout Button
              ElevatedButton.icon(
                onPressed: () => _showLogoutDialog(context, authService),
                icon: Icon(Icons.logout, color: styles.getColor('home_page.logout_button.icon.color')),
                label: Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: styles.getFontSize('home_page.logout_button.text.font_size'),
                    fontWeight: styles.getFontWeight('home_page.logout_button.text.font_weight'),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: styles.getColor('home_page.logout_button.background.color'),
                  foregroundColor: styles.getColor('home_page.logout_button.text.color'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(styles.getBorderRadius('home_page.logout_button.border_radius')),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      ),
        ),
        // Loading Overlay
        if (_loadingUsername)
          Container(
            color: styles.getColorWithOpacity(
              'home_page.loading_overlay.background.color',
              opacityPath: 'home_page.loading_overlay.background.opacity',
            ),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: styles.getLinearGradient('home_page.loading_overlay.container.background.linear_gradient'),
                  borderRadius: BorderRadius.circular(styles.getBorderRadius('home_page.loading_overlay.container.border_radius')),
                  boxShadow: [
                    BoxShadow(
                      color: styles.getColorWithOpacity(
                        'home_page.loading_overlay.container.shadow.color',
                        opacityPath: 'home_page.loading_overlay.container.shadow.opacity',
                      ),
                      blurRadius: styles.getBlurRadius('home_page.loading_overlay.container.shadow.blur_radius'),
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(styles.getColor('home_page.loading_overlay.title.color')),
                      strokeWidth: styles.getStrokeWeight('home_page.loading_overlay.progress_indicator.stroke_weight'),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Loading...',
                      style: TextStyle(
                        color: styles.getColor('home_page.loading_overlay.title.color'),
                        fontSize: styles.getFontSize('home_page.loading_overlay.title.font_size'),
                        fontWeight: styles.getFontWeight('home_page.loading_overlay.title.font_weight'),
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Preparing your workspace',
                      style: TextStyle(
                        color: styles.getColorWithOpacity(
                          'home_page.loading_overlay.subtitle.color',
                          opacityPath: 'home_page.loading_overlay.subtitle.opacity',
                        ),
                        fontSize: styles.getFontSize('home_page.loading_overlay.subtitle.font_size'),
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context, AuthService authService) {
    final styles = AppStyles();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(styles.getBorderRadius('home_page.logout_dialog.border_radius')),
        ),
        title: Text(
          'Logout',
          style: TextStyle(
            fontWeight: styles.getFontWeight('home_page.logout_dialog.title.font_weight'),
            color: styles.getColor('home_page.logout_dialog.title.color'),
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(
            color: styles.getColor('home_page.logout_dialog.message.color'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: styles.getColor('home_page.logout_dialog.cancel_button.color'),
                fontWeight: styles.getFontWeight('home_page.logout_dialog.cancel_button.font_weight'),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await authService.signOut();
              // After signing out, clear navigation stack and go to Login page
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: styles.getColor('home_page.logout_dialog.confirm_button.background.color'),
              foregroundColor: styles.getColor('home_page.logout_dialog.confirm_button.text.color'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(styles.getBorderRadius('home_page.logout_dialog.confirm_button.border_radius')),
              ),
              elevation: 0,
            ),
            child: Text(
              'Logout',
              style: TextStyle(
                fontWeight: styles.getFontWeight('home_page.logout_dialog.confirm_button.text.font_weight'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
