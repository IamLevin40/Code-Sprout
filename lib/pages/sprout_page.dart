import 'package:flutter/material.dart';
import '../models/styles_schema.dart';

class SproutPage extends StatefulWidget {
  final bool showAppBar;

  const SproutPage({super.key, this.showAppBar = true});

  @override
  State<SproutPage> createState() => _SproutPageState();
}

class _SproutPageState extends State<SproutPage> {
  final List<String> _inventory = ['Wheat', 'Corn', 'Rice', 'Carrot', 'Potato'];
  final List<String> _languages = ['C++', 'C#', 'Java', 'Python', 'JavaScript'];
  String _selectedLanguage = 'Python';
  final int _sproutRank = 1;

  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();

    final content = Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rank and language
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sprout Rank', style: TextStyle(fontSize: styles.toDouble(styles.getStyles('sprout_page.rank.title.font_size')))),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: styles.getStyles('sprout_page.rank.container.background_color') as Color,
                      borderRadius: BorderRadius.circular(styles.toDouble(styles.getStyles('sprout_page.rank.container.border_radius'))),
                    ),
                    child: Text('#$_sproutRank', style: TextStyle(fontSize: styles.toDouble(styles.getStyles('sprout_page.rank.number.font_size')))),
                  ),
                ],
              ),
              // Language selector
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Language', style: TextStyle(fontSize: styles.toDouble(styles.getStyles('sprout_page.language.title.font_size')))),
                  const SizedBox(height: 6),
                  DropdownButton<String>(
                    value: _selectedLanguage,
                    items: _languages.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _selectedLanguage = v);
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Start button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opening sprout for $_selectedLanguage (placeholder)')));
              },
              icon: Icon(Icons.rocket_launch, color: styles.getStyles('sprout_page.start_button.icon.color') as Color),
              label: Text('Start Sprout', style: TextStyle(fontSize: styles.toDouble(styles.getStyles('sprout_page.start_button.text.font_size')))),
              style: ElevatedButton.styleFrom(
                backgroundColor: styles.getStyles('sprout_page.start_button.background_color') as Color,
                foregroundColor: styles.getStyles('sprout_page.start_button.text.color') as Color,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(styles.toDouble(styles.getStyles('sprout_page.start_button.border_radius')))),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Inventory header
          Text('Inventory', style: TextStyle(fontSize: styles.toDouble(styles.getStyles('sprout_page.inventory.title.font_size')), fontWeight: styles.toFontWeight(styles.getStyles('sprout_page.inventory.title.font_weight')))),
          const SizedBox(height: 8),

          // Inventory list
          Expanded(
            child: ListView.separated(
              itemCount: _inventory.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) => Card(
                child: ListTile(
                  leading: Icon(Icons.spa, color: styles.getStyles('sprout_page.inventory.icon.color') as Color),
                  title: Text(_inventory[i], style: TextStyle(fontSize: styles.toDouble(styles.getStyles('sprout_page.inventory.item.font_size')))),
                  subtitle: Text('Amount: ${5 + i}', style: TextStyle(color: styles.getStyles('sprout_page.inventory.item.subtitle.color') as Color)),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (widget.showAppBar) {
      return Scaffold(
        backgroundColor: styles.getStyles('global.background.color') as Color,
        appBar: AppBar(
          title: Text(
            'The Sprout',
            style: TextStyle(
              fontWeight: styles.toFontWeight(styles.getStyles('header.title.font_weight')),
              color: styles.getStyles('header.title.color') as Color,
              fontSize: styles.toDouble(styles.getStyles('header.title.font_size')),
            ),
          ),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              color: styles.getStyles('header.background_color') as Color,
            ),
          ),
          elevation: 0,
        ),
        body: content,
      );
    }

    return Container(color: styles.getStyles('global.background.color') as Color, child: content);
  }
}
