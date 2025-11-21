import 'package:flutter/material.dart';
import '../../models/styles_schema.dart';
import '../../models/user_data.dart';
import '../../models/sprout_data.dart';
import '../sprout_items/inventory_grid_display.dart';

/// Shows an animated inventory popup dialog
Future<void> showInventoryPopup(BuildContext context, UserData? userData) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 300),
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
      return _InventoryPopupDialog(userData: userData);
    },
  );
}

/// Internal inventory popup dialog widget
class _InventoryPopupDialog extends StatefulWidget {
  final UserData? userData;

  const _InventoryPopupDialog({required this.userData});

  @override
  State<_InventoryPopupDialog> createState() => _InventoryPopupDialogState();
}

class _InventoryPopupDialogState extends State<_InventoryPopupDialog> {
  List<InventoryItem> _inventoryItems = [];

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    final items = await SproutDataHelpers.getInventoryItemsForUser(widget.userData);
    if (mounted) {
      setState(() => _inventoryItems = items);
    }
  }

  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();

    final pickerHeight = styles.getStyles('sprout_page.language_selection.height') as double;
    final pickerRadius = styles.getStyles('sprout_page.language_selection.border_radius') as double;
    final pickerBg = styles.getStyles('sprout_page.language_selection.background_color') as Color;

    final titleColor = styles.getStyles('sprout_page.language_selection.title.color') as Color;
    final titleSize = styles.getStyles('sprout_page.language_selection.title.font_size') as double;
    final titleWeight = styles.getStyles('sprout_page.language_selection.title.font_weight') as FontWeight;

    final closeIcon = styles.getStyles('sprout_page.language_selection.close_button.icon') as String;
    final closeW = styles.getStyles('sprout_page.language_selection.close_button.width') as double;
    final closeH = styles.getStyles('sprout_page.language_selection.close_button.height') as double;

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

            // Inventory grid (3 columns)
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return InventoryGridDisplay(
                    inventoryItems: _inventoryItems,
                    maxWidth: constraints.maxWidth,
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
