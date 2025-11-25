import 'package:flutter/material.dart';
import '../models/styles_schema.dart';
import '../miscellaneous/number_utils.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/local_storage_service.dart';
import '../models/user_data.dart';
import '../models/rank_data.dart';
import '../widgets/rank_card.dart';
import '../models/course_data_schema.dart';
import '../models/sprout_data.dart' as sprout;
import '../models/inventory_data.dart' as inv;
import '../widgets/sprout_items/current_language_card.dart';
import '../widgets/sprout_items/inventory_grid_display.dart';
import '../widgets/farm_items/notification_display.dart';
import 'farm_page.dart';

class SproutPage extends StatefulWidget {
  const SproutPage({super.key});

  @override
  State<SproutPage> createState() => _SproutPageState();
}

class _SproutPageState extends State<SproutPage> {
  List<sprout.InventoryItem> _inventoryItems = [];
  inv.InventorySchema? _inventorySchema;

  final CourseDataSchema _courseSchema = CourseDataSchema();
  List<String> _languages = [];
  final Map<String, String> _languageNames = {};
  String? _selectedLanguage;
  
  UserData? _userData;
  late NotificationController _notificationController;

  @override
  void initState() {
    super.initState();
    _notificationController = NotificationController();
    _init();
    // Listen to local cached user data changes so UI updates immediately
    LocalStorageService.instance.userDataNotifier.addListener(_onUserDataChanged);
  }

  @override
  void dispose() {
    LocalStorageService.instance.userDataNotifier.removeListener(_onUserDataChanged);
    _notificationController.dispose();
    super.dispose();
  }

  void _onUserDataChanged() {
    final ud = LocalStorageService.instance.userDataNotifier.value;

    if (!mounted) return;

    setState(() {
      _userData = ud;
    });

    // Recompute derived data (crop items) when user data changes
    sprout.SproutDataHelpers.getInventoryItemsForUser(ud).then((items) {
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

    final String? selected = await sprout.SproutData.resolveSelectedLanguage(
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
    // load crop items and inventory schema after initial set
    try {
      final items = await sprout.SproutDataHelpers.getInventoryItemsForUser(ud);
      final schema = await inv.InventorySchema.load();
      if (mounted) {
        setState(() {
        _inventoryItems = items;
        _inventorySchema = schema;
      });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();

    return Container(
      color: styles.getStyles('global.background.color') as Color,
      child: Stack(
        children: [
          Padding(
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
                    final updated = await sprout.SproutData.setSelectedLanguage(userData: _userData!, languageId: v);
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
                          _notificationController.showError('Please select a language first');
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Inventory',
                    style: TextStyle(
                      color: styles.getStyles('sprout_page.inventory.title.color') as Color,
                      fontSize: styles.getStyles('sprout_page.inventory.title.font_size') as double,
                      fontWeight: styles.getStyles('sprout_page.inventory.title.font_weight') as FontWeight,
                    ),
                  ),
                ),
                _buildCoinsDisplay(),
              ],
            ),
            const SizedBox(height: 16),

            // Inventory grid (3 columns max)
            LayoutBuilder(builder: (context, constraints) {
              return InventoryGridDisplay(
                inventoryItems: _inventoryItems,
                maxWidth: constraints.maxWidth,
                inventorySchema: _inventorySchema,
                userData: _userData,
                notificationController: _notificationController,
              );
            }),
              ],
            ),
          ),
          // Notification display moved to overlay (Layer 2 style)
          Positioned(
            left: 24,
            right: 24,
            top: 24,
            child: NotificationDisplay(
              controller: _notificationController,
              position: NotificationPosition.topToBottom,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoinsDisplay() {
    final styles = AppStyles();
    final width = styles.getStyles('farm_page.top_layer.coins_display.width') as double;
    final height = styles.getStyles('farm_page.top_layer.coins_display.height') as double;
    final borderRadius = styles.getStyles('farm_page.top_layer.coins_display.border_radius') as double;
    final borderWidth = styles.getStyles('farm_page.top_layer.coins_display.border_width') as double;
    final bgGradient = styles.getStyles('farm_page.top_layer.coins_display.background_color') as LinearGradient;
    final strokeGradient = styles.getStyles('farm_page.top_layer.coins_display.stroke_color') as LinearGradient;
    final iconPath = styles.getStyles('farm_page.top_layer.coins_display.icon.image') as String;
    final iconWidth = styles.getStyles('farm_page.top_layer.coins_display.icon.width') as double;
    final iconHeight = styles.getStyles('farm_page.top_layer.coins_display.icon.height') as double;
    final textColor = styles.getStyles('farm_page.top_layer.coins_display.text.color') as Color;
    final textFontSize = styles.getStyles('farm_page.top_layer.coins_display.text.font_size') as double;
    final textFontWeight = styles.getStyles('farm_page.top_layer.coins_display.text.font_weight') as FontWeight;

    return ValueListenableBuilder<UserData?>(
      valueListenable: LocalStorageService.instance.userDataNotifier,
      builder: (context, userData, _) {
        final coins = userData?.getCoins() ?? 0;

        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            gradient: strokeGradient,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: EdgeInsets.all(borderWidth),
          child: Container(
            decoration: BoxDecoration(
              gradient: bgGradient,
              borderRadius: BorderRadius.circular(borderRadius - borderWidth),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  iconPath,
                  width: iconWidth,
                  height: iconHeight,
                ),
                const SizedBox(width: 8),
                Text(
                  NumberUtils.formatNumberShort(coins),
                  style: TextStyle(
                    color: textColor,
                    fontSize: textFontSize,
                    fontWeight: textFontWeight,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
