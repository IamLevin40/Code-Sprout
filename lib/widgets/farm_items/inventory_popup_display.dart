import 'package:flutter/material.dart';
import '../../models/styles_schema.dart';
import '../../models/user_data.dart';
import '../../models/sprout_data.dart' as sprout;
import '../../models/inventory_data.dart' as inv;
import '../../services/local_storage_service.dart';
import '../sprout_items/inventory_grid_display.dart';
import 'notification_display.dart';

/// Shows an animated inventory popup dialog
Future<void> showInventoryPopup(BuildContext context, UserData? userData, {NotificationController? notificationController}) {
  final styles = AppStyles();
  final transitionMs = styles.getStyles('farm_page.inventory_popup.transition_duration') as int;
  
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: Duration(milliseconds: transitionMs),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        ),
        child: child,
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) {
      return _InventoryPopupDialog(userData: userData, notificationController: notificationController);
    },
  );
}

/// Internal inventory popup dialog widget
class _InventoryPopupDialog extends StatefulWidget {
  final UserData? userData;
  final NotificationController? notificationController;

  const _InventoryPopupDialog({required this.userData, this.notificationController});

  @override
  State<_InventoryPopupDialog> createState() => _InventoryPopupDialogState();
}

class _InventoryPopupDialogState extends State<_InventoryPopupDialog> {
  List<sprout.InventoryItem> _inventoryItems = [];
  inv.InventorySchema? _inventorySchema;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInventory();
    // Listen to real-time user data changes from LocalStorageService
    LocalStorageService.instance.userDataNotifier.addListener(_onUserDataChanged);
  }

  @override
  void dispose() {
    // Remove listener when dialog is closed
    LocalStorageService.instance.userDataNotifier.removeListener(_onUserDataChanged);
    super.dispose();
  }

  void _onUserDataChanged() {
    // Reload inventory whenever user data changes (e.g., when crops are harvested)
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    if (!mounted) return;
    
    // Get the latest user data from the notifier
    final currentUserData = LocalStorageService.instance.userDataNotifier.value ?? widget.userData;
    
    try {
      final items = await sprout.SproutDataHelpers.getInventoryItemsForUser(currentUserData);
      final schema = await inv.InventorySchema.load();
      if (mounted) {
        setState(() {
          _inventoryItems = items;
          _inventorySchema = schema;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();

    final pickerHeight = styles.getStyles('farm_page.inventory_popup.height') as double;
    final pickerRadius = styles.getStyles('farm_page.inventory_popup.border_radius') as double;
    final pickerBg = styles.getStyles('farm_page.inventory_popup.background_color') as Color;

    final titleColor = styles.getStyles('farm_page.inventory_popup.title.color') as Color;
    final titleSize = styles.getStyles('farm_page.inventory_popup.title.font_size') as double;
    final titleWeight = styles.getStyles('farm_page.inventory_popup.title.font_weight') as FontWeight;

    final closeIcon = styles.getStyles('farm_page.inventory_popup.close_button.icon') as String;
    final closeW = styles.getStyles('farm_page.inventory_popup.close_button.width') as double;
    final closeH = styles.getStyles('farm_page.inventory_popup.close_button.height') as double;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        height: pickerHeight,
        decoration: BoxDecoration(
          color: pickerBg,
          borderRadius: BorderRadius.circular(pickerRadius),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header with title and close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Inventory',
                  style: TextStyle(color: titleColor, fontSize: titleSize, fontWeight: titleWeight),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Image.asset(closeIcon, width: closeW, height: closeH),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Inventory grid (3 columns) with loading indicator
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(titleColor),
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final currentUserData = LocalStorageService.instance.userDataNotifier.value ?? widget.userData;
                        return InventoryGridDisplay(
                          inventoryItems: _inventoryItems,
                          maxWidth: constraints.maxWidth,
                          inventorySchema: _inventorySchema,
                          userData: currentUserData,
                          notificationController: widget.notificationController,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
