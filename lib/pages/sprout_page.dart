import 'package:flutter/material.dart';
import '../models/styles_schema.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_data.dart';
import '../models/rank_data.dart';
import '../widgets/rank_card.dart';
import '../models/course_data_schema.dart';
import '../models/sprout_data.dart';

class SproutPage extends StatefulWidget {
  const SproutPage({super.key});

  @override
  State<SproutPage> createState() => _SproutPageState();
}

class _SproutPageState extends State<SproutPage> {
  List<CropItem> _cropItems = [];

  final CourseDataSchema _courseSchema = CourseDataSchema();
  List<String> _languages = [];
  final Map<String, String> _languageNames = {};
  String? _selectedLanguage;
  
  UserData? _userData;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    List<String> langs = [];
    final Map<String, String> names = {};

    try {
      langs = await _courseSchema.getAvailableLanguages();

      for (final id in langs) {
        try {
          final module = await _courseSchema.loadModuleSchema(id);
          names[id] = module.programmingLanguage;
        } catch (_) {
          names[id] = id;
        }
      }
    } catch (_) {}

    final auth = AuthService();
    final currentUser = auth.currentUser;
    UserData? ud;
    try {
      if (currentUser != null) {
        ud = await FirestoreService.getUserData(currentUser.uid);
      }
    } catch (_) {}

    final String? selected = await SproutData.resolveSelectedLanguage(
      availableLanguages: langs,
      userData: ud,
    );

    if (ud != null) {
      final current = ud.get('sproutProgress.selectedLanguage') as String?;
      if ((current == null || current.isEmpty) && selected != null) {
        try {
          ud = ud.copyWith({'sproutProgress.selectedLanguage': selected});
        } catch (_) {}
      }
    }

    if (mounted) {
      setState(() {
        _languages = langs;
        _languageNames.clear();
        _languageNames.addAll(names);
        _userData = ud;
        _selectedLanguage = selected;
      });
    }
    // load crop items after initial set
    try {
      final items = await SproutDataHelpers.getCropItemsForUser(ud);
      if (mounted) setState(() => _cropItems = items);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();

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
              items: _languages.map((langId) {
                final display = _languageNames[langId] ?? langId;
                return DropdownMenuItem(value: langId, child: Text(display));
              }).toList(),
              onChanged: (v) async {
                if (v == null) return;
                setState(() => _selectedLanguage = v);

                if (_userData != null) {
                  try {
                    final updated = await SproutData.setSelectedLanguage(userData: _userData!, languageId: v);
                    setState(() {
                      _userData = updated;
                    });
                  } catch (e) {
                    debugPrint('Failed to persist sprout selection: $e');
                  }
                }
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

            // Inventory grid (3 columns max)
            LayoutBuilder(builder: (context, constraints) {
              final double maxWidth = constraints.maxWidth;
              const int columns = 3;
              const double spacing = 8.0;
              final double itemWidth = (maxWidth - (columns - 1) * spacing) / columns;

              final cropImages = styles.getStyles('sprout_researches.crop_items') as Map<String, dynamic>;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: _cropItems.map((item) {
                  final String imagePath = cropImages[item.id] as String;

                  return SizedBox(
                    width: itemWidth,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            SizedBox(
                              width: itemWidth * 0.35,
                              height: itemWidth * 0.35,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Image.asset(imagePath, fit: BoxFit.contain),
                                  if (item.isLocked) ...[
                                    Container(color: const Color.fromARGB(192, 255, 255, 255)),
                                    Builder(builder: (_) {
                                      final lockedImg = styles.getStyles('sprout_researches.locked_overlay.icon.image') as String;
                                      return Image.asset(lockedImg, width: itemWidth * 0.18, height: itemWidth * 0.18, fit: BoxFit.contain);
                                    }),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    item.isLocked ? 'Locked' : item.displayName,
                                    style: TextStyle(fontSize: styles.getStyles('sprout_page.inventory.item.font_size') as double),
                                  ),
                                  if (!item.isLocked) ...[
                                    Text(
                                      'x${item.quantity}',
                                      style: TextStyle(color: styles.getStyles('sprout_page.inventory.item.subtitle.color') as Color),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }
}
