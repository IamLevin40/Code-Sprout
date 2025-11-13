import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/styles_schema.dart';

class MainHeader extends StatefulWidget {
  const MainHeader({super.key});

  @override
  State<MainHeader> createState() => _MainHeaderState();
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
      height: styles.getStyles('header.height') as double,
      decoration: BoxDecoration(
        color: styles.getStyles('header.background_color') as Color,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(styles.getStyles('header.border_radius') as double)),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: styles.getStyles('header.padding_horizontal') as double,
        vertical: styles.getStyles('header.padding_vertical') as double,
      ),
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
                    color: styles.getStyles('header.greeting.color') as Color,
                    fontSize: styles.getStyles('header.greeting.font_size') as double,
                    fontWeight: styles.getStyles('header.greeting.font_weight') as FontWeight,
                  ),
                ),
                Text(
                  "Let's Grow Together",
                  style: TextStyle(
                    color: styles.getStyles('header.title.color') as Color,
                    fontSize: styles.getStyles('header.title.font_size') as double,
                    fontWeight: styles.getStyles('header.title.font_weight') as FontWeight,
                  ),
                ),
              ],
            ),
          ),

          // Right image box
          Container(
            width: styles.getStyles('header.icon.width') as double,
            height: styles.getStyles('header.icon.height') as double,
            decoration: BoxDecoration(
              color: styles.getStyles('header.icon_background_color') as Color,
              borderRadius: BorderRadius.circular(styles.getStyles('header.icon.border_radius') as double),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(styles.getStyles('header.icon.border_radius') as double),
              child: Padding(
                padding: EdgeInsets.all(styles.getStyles('header.icon.padding') as double),
                child: Image.asset(
                  styles.getStyles('header.icon.image') as String,
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
