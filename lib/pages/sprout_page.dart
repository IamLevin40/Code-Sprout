import 'package:flutter/material.dart';
import '../models/styles_schema.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_data.dart';
import '../models/rank_data.dart';
import '../widgets/rank_card.dart';

class SproutPage extends StatefulWidget {
  const SproutPage({super.key});

  @override
  State<SproutPage> createState() => _SproutPageState();
}

class _SproutPageState extends State<SproutPage> {
  final List<String> _inventory = ['Wheat', 'Corn', 'Rice', 'Carrot', 'Potato'];
  final List<String> _languages = ['C++', 'C#', 'Java', 'Python', 'JavaScript'];
  String _selectedLanguage = 'Python';
  
  UserData? _userData;

  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();

    // embedded-only UI (single source of truth)
    return Container(
      color: styles.getStyles('global.background.color') as Color,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rank display section
            if (_userData != null) ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: FutureBuilder<RankData>(
                    future: RankData.load(),
                    builder: (ctx, rsnap) {
                      if (!rsnap.hasData) return const SizedBox();
                      final rankData = rsnap.data!;
                      final userMap = _userData!.toFirestore();
                      final display = rankData.getDisplayData(userMap);
                      final title = display['title'] as String;
                      final progressValue = display['progressValue'] as double;
                      final displayText = display['displayText'] as String;

                      return RankCard(
                        title: title,
                        progress: progressValue.clamp(0.0, 1.0),
                        displayText: displayText,
                        onTap: () {},
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Language section
            Text('Language', style: TextStyle(fontSize: styles.getStyles('sprout_page.language.title.font_size') as double)),
            const SizedBox(height: 6),
            DropdownButton<String>(
              value: _selectedLanguage,
              items: _languages.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() => _selectedLanguage = v);
              },
            ),
            const SizedBox(height: 20),

            // Visit / Start button section
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opening sprout for $_selectedLanguage (placeholder)')));
                },
                icon: Icon(Icons.rocket_launch, color: styles.getStyles('sprout_page.start_button.icon.color') as Color),
                label: Text('Start Sprout', style: TextStyle(fontSize: styles.getStyles('sprout_page.start_button.text.font_size') as double)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: styles.getStyles('sprout_page.start_button.background_color') as Color,
                  foregroundColor: styles.getStyles('sprout_page.start_button.text.color') as Color,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(styles.getStyles('sprout_page.start_button.border_radius') as double)),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Inventory
            Text('Inventory', style: TextStyle(fontSize: styles.getStyles('sprout_page.inventory.title.font_size') as double, fontWeight: styles.getStyles('sprout_page.inventory.title.font_weight') as FontWeight)),
            const SizedBox(height: 8),

            Column(
              children: List.generate(_inventory.length, (i) {
                return Column(
                  children: [
                    Card(
                      child: ListTile(
                        leading: Icon(Icons.spa, color: styles.getStyles('sprout_page.inventory.icon.color') as Color),
                        title: Text(_inventory[i], style: TextStyle(fontSize: styles.getStyles('sprout_page.inventory.item.font_size') as double)),
                        subtitle: Text('Amount: ${5 + i}', style: TextStyle(color: styles.getStyles('sprout_page.inventory.item.subtitle.color') as Color)),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final auth = AuthService();
    final currentUser = auth.currentUser;
    if (currentUser != null) {
      try {
        final ud = await FirestoreService.getUserData(currentUser.uid);
        if (mounted) setState(() => _userData = ud);
      } catch (_) {
        // ignore
      }
    }
  }
}
