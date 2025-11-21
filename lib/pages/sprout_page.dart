import 'package:flutter/material.dart';
import '../models/styles_schema.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/local_storage_service.dart';
import '../models/user_data.dart';
import '../models/rank_data.dart';
import '../widgets/rank_card.dart';
import '../models/course_data_schema.dart';
import '../models/sprout_data.dart';
import '../widgets/sprout_items/current_language_card.dart';
import '../widgets/sprout_items/inventory_grid_display.dart';
import 'farm_page.dart';

class SproutPage extends StatefulWidget {
  const SproutPage({super.key});

  @override
  State<SproutPage> createState() => _SproutPageState();
}

class _SproutPageState extends State<SproutPage> {
  List<InventoryItem> _inventoryItems = [];

  final CourseDataSchema _courseSchema = CourseDataSchema();
  List<String> _languages = [];
  final Map<String, String> _languageNames = {};
  String? _selectedLanguage;
  
  UserData? _userData;

  @override
  void initState() {
    super.initState();
    _init();
    // Listen to local cached user data changes so UI updates immediately
    LocalStorageService.instance.userDataNotifier.addListener(_onUserDataChanged);
  }

  void _onUserDataChanged() {
    final ud = LocalStorageService.instance.userDataNotifier.value;

    if (!mounted) return;

    setState(() {
      _userData = ud;
    });

    // Recompute derived data (crop items) when user data changes
    SproutDataHelpers.getInventoryItemsForUser(ud).then((items) {
      if (!mounted) return;
      setState(() => _inventoryItems = items);
    }).catchError((_) {});
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
      final items = await SproutDataHelpers.getInventoryItemsForUser(ud);
      if (mounted) setState(() => _inventoryItems = items);
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

            // Current language card
            CurrentLanguageCard(
              selectedLanguageId: _selectedLanguage,
              languageNames: _languageNames,
              availableLanguages: _languages,
              onLanguageSelected: (v) async {
                if (!mounted) return;
                setState(() => _selectedLanguage = v);

                if (_userData != null) {
                  try {
                    final updated = await SproutData.setSelectedLanguage(userData: _userData!, languageId: v);
                    if (!mounted) return;
                    setState(() {
                      _userData = updated;
                    });
                  } catch (e) {
                    debugPrint('Failed to persist sprout selection: $e');
                  }
                }
              },
            ),
            const SizedBox(height: 16),

            // Visit / Start button section
            Builder(builder: (ctx) {
              final staticFontSize = styles.getStyles('sprout_page.visit_section.static_label.font_size') as double;
              final staticColor = styles.getStyles('sprout_page.visit_section.static_label.color') as Color;
              final staticWeight = styles.getStyles('sprout_page.visit_section.static_label.font_weight') as FontWeight;

              final btnWidth = styles.getStyles('sprout_page.visit_section.start_button.width') as double;
              final btnHeight = styles.getStyles('sprout_page.visit_section.start_button.height') as double;
              final btnRadius = styles.getStyles('sprout_page.visit_section.start_button.border_radius') as double;
              final btnBorder = styles.getStyles('sprout_page.visit_section.start_button.border_width') as double;
              final btnBg = styles.getStyles('sprout_page.visit_section.start_button.background_color') as LinearGradient;
              final btnStroke = styles.getStyles('sprout_page.visit_section.start_button.stroke_color') as LinearGradient;
              final btnTextColor = styles.getStyles('sprout_page.visit_section.start_button.text.color') as Color;
              final btnTextSize = styles.getStyles('sprout_page.visit_section.start_button.text.font_size') as double;
              final btnTextWeight = styles.getStyles('sprout_page.visit_section.start_button.text.font_weight') as FontWeight;

              return Row(
                children: [
                  // Left column: two static labels
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Let's get more resources!", style: TextStyle(fontSize: staticFontSize, color: staticColor, fontWeight: staticWeight)),
                        const SizedBox(height: 4),
                        Text('Time to farm!', style: TextStyle(fontSize: staticFontSize, color: staticColor, fontWeight: staticWeight)),
                      ],
                    ),
                  ),

                  // Right column: Visit The Farm button
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        if (_selectedLanguage == null || _selectedLanguage!.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select a language first')),
                          );
                          return;
                        }
                        
                        final languageName = _languageNames[_selectedLanguage] ?? _selectedLanguage!;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => FarmPage(
                              languageId: _selectedLanguage!,
                              languageName: languageName,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: btnWidth,
                        height: btnHeight,
                        decoration: BoxDecoration(
                          gradient: btnStroke,
                          borderRadius: BorderRadius.circular(btnRadius),
                        ),
                        padding: EdgeInsets.all(btnBorder),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: btnBg,
                            borderRadius: BorderRadius.circular(btnRadius - btnBorder),
                          ),
                          alignment: Alignment.center,
                          child: Text('Visit The Farm', style: TextStyle(color: btnTextColor, fontSize: btnTextSize, fontWeight: btnTextWeight)),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 16),

            // Inventory
            Text('Inventory', style: 
              TextStyle(
                color: styles.getStyles('sprout_page.inventory.title.color') as Color,
                fontSize: styles.getStyles('sprout_page.inventory.title.font_size') as double, 
                fontWeight: styles.getStyles('sprout_page.inventory.title.font_weight') as FontWeight
              )
            ),
            const SizedBox(height: 12),

            // Inventory grid (3 columns max)
            LayoutBuilder(builder: (context, constraints) {
              return InventoryGridDisplay(
                inventoryItems: _inventoryItems,
                maxWidth: constraints.maxWidth,
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    LocalStorageService.instance.userDataNotifier.removeListener(_onUserDataChanged);
    super.dispose();
  }
}
