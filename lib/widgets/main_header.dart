import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/styles_schema.dart';

class MainHeader extends StatefulWidget implements PreferredSizeWidget {
  const MainHeader({super.key});

  @override
  State<MainHeader> createState() => _MainHeaderState();

  @override
  Size get preferredSize => const Size.fromHeight(96);
}

class _MainHeaderState extends State<MainHeader> {
  String _username = '';

  @override
  void initState() {
    super.initState();
    final auth = AuthService();
    _username = auth.currentUser?.displayName ?? auth.currentUser?.email?.split('@').first ?? '';
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 18) return 'afternoon';
    return 'evening';
  }

  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();

    return Container(
      height: widget.preferredSize.height,
      decoration: BoxDecoration(
        color: styles.getColor('header.background.color'),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(styles.getBorderRadius('header.border_radius'))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left texts
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good ${_greeting()}, ${_username.isNotEmpty ? _username : '<username>'}!',
                  style: TextStyle(
                    color: styles.getColor('header.greeting.color'),
                    fontSize: styles.getFontSize('header.greeting.font_size'),
                    fontWeight: styles.getFontWeight('header.greeting.font_weight'),
                  ),
                ),
                Text(
                  "Let's Grow Together",
                  style: TextStyle(
                    color: styles.getColor('header.title.color'),
                    fontSize: styles.getFontSize('header.title.font_size'),
                    fontWeight: styles.getFontWeight('header.title.font_weight'),
                  ),
                ),
              ],
            ),
          ),

          // Right image box
          Container(
            width: styles.getWidth('header.icon.width'),
            height: styles.getHeight('header.icon.height'),
            decoration: BoxDecoration(
              color: styles.getColor('header.icon_background.color'),
              borderRadius: BorderRadius.circular(styles.getBorderRadius('header.icon.border_radius')),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(styles.getBorderRadius('header.icon.border_radius')),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Image.asset(
                  styles.getImagePath('header.icon.image_path'),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
