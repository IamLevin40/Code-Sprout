import 'package:flutter/material.dart';
import '../../models/styles_schema.dart';
import '../../models/sprout_data.dart' as sprout;
import '../../models/inventory_data.dart' as inv;
import '../../models/user_data.dart';
import '../../miscellaneous/glass_effect.dart';
import '../farm_items/sell_item_dialog.dart';

/// Reusable widget for displaying inventory items in a grid
class InventoryGridDisplay extends StatelessWidget {
  final List<sprout.InventoryItem> inventoryItems;
  final double maxWidth;
  final int columns;
  final double spacing;
  final inv.InventorySchema? inventorySchema;
  final UserData? userData;

  const InventoryGridDisplay({
    super.key,
    required this.inventoryItems,
    required this.maxWidth,
    this.columns = 3,
    this.spacing = 8.0,
    this.inventorySchema,
    this.userData,
  });

  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();
    
    // Get all styles
    final cardHeight = styles.getStyles('sprout_page.inventory.card.height') as double;
    final cardBorderRadius = styles.getStyles('sprout_page.inventory.card.border_radius') as double;
    final cardBorderWidth = styles.getStyles('sprout_page.inventory.card.border_width') as double;
    final cardBg = styles.getStyles('sprout_page.inventory.card.background_color') as LinearGradient;
    final cardStroke = styles.getStyles('sprout_page.inventory.card.stroke_color') as LinearGradient;

    final iconWidth = styles.getStyles('sprout_page.inventory.card.icon.width') as double;
    final iconHeight = styles.getStyles('sprout_page.inventory.card.icon.height') as double;

    final cropLabelColor = styles.getStyles('sprout_page.inventory.card.crop_label.color') as Color;
    final cropLabelSize = styles.getStyles('sprout_page.inventory.card.crop_label.font_size') as double;
    final cropLabelWeight = styles.getStyles('sprout_page.inventory.card.crop_label.font_weight') as FontWeight;

    final quantityColor = styles.getStyles('sprout_page.inventory.card.quantity_label.color') as Color;
    final quantitySize = styles.getStyles('sprout_page.inventory.card.quantity_label.font_size') as double;
    final quantityWeight = styles.getStyles('sprout_page.inventory.card.quantity_label.font_weight') as FontWeight;

    final lockedBgColor = styles.getStyles('sprout_page.inventory.card.locked_overlay.background.color') as Color;
    final lockedBgOpacity = styles.getStyles('sprout_page.inventory.card.locked_overlay.background.opacity') as double;
    final lockedBgBlur = styles.getStyles('sprout_page.inventory.card.locked_overlay.background.blur_sigma') as double;
    final lockedStrokeGradient = styles.getStyles('sprout_page.inventory.card.locked_overlay.stroke_color') as LinearGradient;
    final lockedStrokeThickness = styles.getStyles('sprout_page.inventory.card.locked_overlay.stroke_thickness') as double;
    final lockedLabelColor = styles.getStyles('sprout_page.inventory.card.locked_overlay.locked_label.color') as Color;
    final lockedLabelSize = styles.getStyles('sprout_page.inventory.card.locked_overlay.locked_label.font_size') as double;
    final lockedLabelWeight = styles.getStyles('sprout_page.inventory.card.locked_overlay.locked_label.font_weight') as FontWeight;
    final lockedIconImage = styles.getStyles('sprout_page.inventory.card.locked_overlay.icon') as String;

    final double itemWidth = (maxWidth - (columns - 1) * spacing) / columns;

    return SingleChildScrollView(
      child: Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: inventoryItems.map((item) {
          final imagePath = item.iconPath;

          return SizedBox(
            width: itemWidth,
            child: Stack(
              children: [
                // Card (clickable to sell)
                GestureDetector(
                  onTap: !item.isLocked && item.quantity > 0
                      ? () => _showSellDialog(context, item)
                      : null,
                  child: Container(
                    height: cardHeight,
                    decoration: BoxDecoration(
                      gradient: cardStroke,
                      borderRadius: BorderRadius.circular(cardBorderRadius),
                    ),
                    padding: EdgeInsets.all(cardBorderWidth),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: cardBg,
                        borderRadius: BorderRadius.circular(cardBorderRadius - cardBorderWidth),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Row(
                          children: [
                            // Left: icon
                            Expanded(
                              flex: 1,
                              child: Center(
                                child: Image.asset(imagePath!, width: iconWidth, height: iconHeight, fit: BoxFit.contain),
                              ),
                            ),

                            // Right: texts
                            Expanded(
                              flex: 3,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: cropLabelSize * 1.3,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        item.displayName,
                                        maxLines: 1,
                                        overflow: TextOverflow.visible,
                                        style: TextStyle(color: cropLabelColor, fontSize: cropLabelSize, fontWeight: cropLabelWeight),
                                      ),
                                    ),
                                  ),
                                  Text('x${item.quantity}', style: TextStyle(color: quantityColor, fontSize: quantitySize, fontWeight: quantityWeight)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Locked overlay if locked
                if (item.isLocked)
                  Positioned.fill(
                    child: GlassEffect(
                      background: lockedBgColor,
                      opacity: lockedBgOpacity,
                      blurSigma: lockedBgBlur,
                      strokeGradient: lockedStrokeGradient,
                      strokeThickness: lockedStrokeThickness,
                      borderRadius: cardBorderRadius,
                      padding: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Left: icon
                            Expanded(
                              flex: 1,
                              child: Center(
                                child: Image.asset(lockedIconImage, width: iconWidth, height: iconHeight),
                              ),
                            ),

                            // Right: "Locked" label
                            Expanded(
                              flex: 3,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Locked', style: TextStyle(color: lockedLabelColor, fontSize: lockedLabelSize, fontWeight: lockedLabelWeight)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _showSellDialog(BuildContext context, sprout.InventoryItem item) async {
    // Get schema item for sell amount (item.id is the item key)
    final schemaItem = inventorySchema?.getItem(item.id);
    if (schemaItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item information not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show sell dialog
    await showSellItemDialog(
      context: context,
      item: schemaItem,
      currentQuantity: item.quantity,
      userData: userData,
    );
  }
}
