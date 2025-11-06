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
      if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
      return;
    }

    try {
      final userData = await FirestoreService.getUserData(uid);
      if (!mounted) return;
      setState(() {
        _username = (userData?.get('accountInformation.username') as String?) ?? '';
        _loadingUsername = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _username = null;
        _loadingUsername = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildStackedContent();
    return content;
  }

  Widget _buildStackedContent() {
    final styles = AppStyles();

    final core = Container(
      color: styles.getStyles('global.background.color') as Color,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: styles.getStyles('home_page.welcome_container.background_color') as LinearGradient,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.home, size: styles.getStyles('home_page.welcome_container.icon.font_size') as double,
                  color: styles.getStyles('home_page.welcome_container.icon.color') as Color),
              ),
              const SizedBox(height: 40),
              _loadingUsername
                  ? SizedBox(
                      height: styles.getStyles('home_page.username_loader.height') as double,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: styles.getStyles('home_page.username_loader.stroke_weight') as double,
                          color: styles.getStyles('home_page.welcome_text.color') as Color,
                        ),
                      ),
                    )
                  : Text('Welcome${_username != null && _username!.isNotEmpty ? ', ${_username!}' : ''}!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: styles.getStyles('home_page.welcome_text.font_size') as double,
                        fontWeight: styles.getStyles('home_page.welcome_text.font_weight') as FontWeight,
                        color: styles.getStyles('home_page.welcome_text.color') as Color,
                      )),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: styles.getStyles('home_page.email_container.background_color') as Color,
                  borderRadius: BorderRadius.circular(styles.getStyles('home_page.email_container.border_radius') as double),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.email_outlined, color: styles.getStyles('home_page.email_container.icon.color') as Color,
                      size: styles.getStyles('home_page.email_container.icon.width') as double),
                    const SizedBox(width: 8),
                    Text(AuthService().currentUser?.email ?? 'No email',
                      style: TextStyle(fontSize: styles.getStyles('home_page.email_container.text.font_size') as double,
                        color: styles.getStyles('home_page.email_container.text.color') as Color)),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Text('You are successfully logged in!', style: TextStyle(
                fontSize: styles.getStyles('home_page.info_text.primary.font_size') as double,
                color: styles.getStyles('home_page.info_text.primary.color') as Color,
              )),
              const SizedBox(height: 8),
              Text('Your session is secure and will persist until you logout.', style: TextStyle(
                fontSize: styles.getStyles('home_page.info_text.secondary.font_size') as double,
                color: styles.getStyles('home_page.info_text.secondary.color') as Color,
              )),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () { if (widget.onTabSelected != null) widget.onTabSelected!(1); },
                    icon: Icon(Icons.school, color: styles.getStyles('home_page.quick_nav.course.icon.color') as Color),
                    label: Text('Courses', style: TextStyle(fontSize: styles.getStyles('home_page.quick_nav.course.text.font_size') as double)),
                    style: ElevatedButton.styleFrom(backgroundColor: styles.getStyles('home_page.quick_nav.course.background_color') as Color),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () { if (widget.onTabSelected != null) widget.onTabSelected!(2); },
                    icon: Icon(Icons.grass, color: styles.getStyles('home_page.quick_nav.sprout.icon.color') as Color),
                    label: Text('The Sprout', style: TextStyle(fontSize: styles.getStyles('home_page.quick_nav.sprout.text.font_size') as double)),
                    style: ElevatedButton.styleFrom(backgroundColor: styles.getStyles('home_page.quick_nav.sprout.background_color') as Color),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _showLogoutDialog(context, AuthService()),
                icon: Icon(Icons.logout, color: styles.getStyles('home_page.logout_button.icon.color') as Color),
                label: Text('Logout', style: TextStyle(fontSize: styles.getStyles('home_page.logout_button.text.font_size') as double,
                  fontWeight: styles.getStyles('home_page.logout_button.text.font_weight') as FontWeight)),
                style: ElevatedButton.styleFrom(backgroundColor: styles.getStyles('home_page.logout_button.background_color') as Color),
              ),
            ],
          ),
        ),
      ),
    );

    final overlay = _loadingUsername
        ? Container(
            color: styles.withOpacity('home_page.loading_overlay.background_color', 'home_page.loading_overlay.background_opacity'),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: styles.getStyles('home_page.loading_overlay.container.background_color') as LinearGradient,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(styles.getStyles('home_page.loading_overlay.title.color') as Color),
                      strokeWidth: styles.getStyles('home_page.loading_overlay.progress_indicator.stroke_weight') as double,
                    ),
                    const SizedBox(height: 20),
                    Text('Loading...', style: TextStyle(
                      color: styles.getStyles('home_page.loading_overlay.title.color') as Color,
                      fontSize: styles.getStyles('home_page.loading_overlay.title.font_size') as double,
                    )),
                  ],
                ),
              ),
            ),
          )
        : const SizedBox.shrink();

    return Stack(children: [core, if (_loadingUsername) overlay]);
  }

  void _showLogoutDialog(BuildContext context, AuthService authService) {
    final styles = AppStyles();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(styles.getStyles('home_page.logout_dialog.border_radius') as double)),
        title: Text('Logout', style: TextStyle(fontWeight: styles.getStyles('home_page.logout_dialog.title.font_weight') as FontWeight, color: styles.getStyles('home_page.logout_dialog.title.color') as Color)),
        content: Text('Are you sure you want to logout?', style: TextStyle(color: styles.getStyles('home_page.logout_dialog.message.color') as Color)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Cancel', style: TextStyle(color: styles.getStyles('home_page.logout_dialog.cancel_button.color') as Color))),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await authService.signOut();
              if (context.mounted) Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
