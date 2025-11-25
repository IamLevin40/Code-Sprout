import 'package:flutter/material.dart';
import '../../models/inventory_data.dart';
import '../../models/user_data.dart';
import '../../models/styles_schema.dart';
import 'notification_display.dart';

/// Enum for sell multipliers
enum SellMultiplier {
  x1(1, '1x'),
  x10(10, '10x'),
  x100(100, '100x'),
  all(-1, 'ALL');

  final int value;
  final String label;

  const SellMultiplier(this.value, this.label);
}

/// Shows a dialog to sell inventory items
Future<void> showSellItemDialog({
  required BuildContext context,
  required InventoryItem item,
  required int currentQuantity,
  required UserData? userData,
  NotificationController? notificationController,
}) {
  final styles = AppStyles();
  final transitionMs = (styles.getStyles('farm_page.sell_item_dialog.transition_duration') as num).toInt();

  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
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
      return _SellItemDialogContent(
        item: item,
        currentQuantity: currentQuantity,
        userData: userData,
        notificationController: notificationController,
      );
    },
  );
}

/// Internal dialog content widget
class _SellItemDialogContent extends StatefulWidget {
  final InventoryItem item;
  final int currentQuantity;
  final UserData? userData;
  final NotificationController? notificationController;

  const _SellItemDialogContent({
    required this.item,
    required this.currentQuantity,
    required this.userData,
    this.notificationController,
  });

  @override
  State<_SellItemDialogContent> createState() => _SellItemDialogContentState();
}

class _SellItemDialogContentState extends State<_SellItemDialogContent> {
  SellMultiplier _selectedMultiplier = SellMultiplier.x1;
  bool _isSelling = false;

  // Load all styles
  final styles = AppStyles();
  late final double dialogWidth;
  late final Color bgColor;
  late final double borderRadius;
  late final Color titleColor;
  late final double titleSize;
  late final FontWeight titleWeight;
  late final double iconWidth;
  late final double iconHeight;
  late final Color nameColor;
  late final double nameSize;
  late final FontWeight nameWeight;
  late final Color quantityColor;
  late final double quantitySize;
  late final FontWeight quantityWeight;
  late final Color sellPricePerColor;
  late final double sellPricePerSize;
  late final FontWeight sellPricePerWeight;
  late final double multiplierWidth;
  late final double multiplierHeight;
  late final double multiplierBorderRadius;
  late final double multiplierBorderWidth;
  late final LinearGradient selectedBgGradient;
  late final LinearGradient selectedStrokeGradient;
  late final Color selectedTextColor;
  late final double selectedTextSize;
  late final FontWeight selectedTextWeight;
  late final Color unselectedBgColor;
  late final LinearGradient unselectedStrokeGradient;
  late final Color unselectedTextColor;
  late final double unselectedTextSize;
  late final FontWeight unselectedTextWeight;
  late final String coinsIconImage;
  late final double coinsIconWidth;
  late final double coinsIconHeight;
  late final Color sellPriceLabelColor;
  late final double sellPriceLabelSize;
  late final FontWeight sellPriceLabelWeight;
  late final double cancelWidth;
  late final double cancelHeight;
  late final double cancelBorderRadius;
  late final double cancelBorderWidth;
  late final Color cancelBgColor;
  late final LinearGradient cancelStrokeGradient;
  late final Color cancelTextColor;
  late final double cancelTextSize;
  late final FontWeight cancelTextWeight;
  late final double sellWidth;
  late final double sellHeight;
  late final double sellBorderRadius;
  late final double sellBorderWidth;
  late final LinearGradient sellBgGradient;
  late final LinearGradient sellStrokeGradient;
  late final Color sellTextColor;
  late final double sellTextSize;
  late final FontWeight sellTextWeight;

  @override
  void initState() {
    super.initState();
    _loadStyles();
  }

  void _loadStyles() {
    dialogWidth = styles.getStyles('farm_page.sell_item_dialog.width') as double;
    bgColor = styles.getStyles('farm_page.sell_item_dialog.background_color') as Color;
    borderRadius = styles.getStyles('farm_page.sell_item_dialog.border_radius') as double;
    titleColor = styles.getStyles('farm_page.sell_item_dialog.title.color') as Color;
    titleSize = styles.getStyles('farm_page.sell_item_dialog.title.font_size') as double;
    titleWeight = styles.getStyles('farm_page.sell_item_dialog.title.font_weight') as FontWeight;
    iconWidth = styles.getStyles('farm_page.sell_item_dialog.item_display.icon.width') as double;
    iconHeight = styles.getStyles('farm_page.sell_item_dialog.item_display.icon.height') as double;
    nameColor = styles.getStyles('farm_page.sell_item_dialog.item_display.name.color') as Color;
    nameSize = styles.getStyles('farm_page.sell_item_dialog.item_display.name.font_size') as double;
    nameWeight = styles.getStyles('farm_page.sell_item_dialog.item_display.name.font_weight') as FontWeight;
    quantityColor = styles.getStyles('farm_page.sell_item_dialog.item_display.quantity.color') as Color;
    quantitySize = styles.getStyles('farm_page.sell_item_dialog.item_display.quantity.font_size') as double;
    quantityWeight = styles.getStyles('farm_page.sell_item_dialog.item_display.quantity.font_weight') as FontWeight;
    sellPricePerColor = styles.getStyles('farm_page.sell_item_dialog.item_display.sell_price_per.color') as Color;
    sellPricePerSize = styles.getStyles('farm_page.sell_item_dialog.item_display.sell_price_per.font_size') as double;
    sellPricePerWeight = styles.getStyles('farm_page.sell_item_dialog.item_display.sell_price_per.font_weight') as FontWeight;
    multiplierWidth = styles.getStyles('farm_page.sell_item_dialog.purchase_multipliers.general.width') as double;
    multiplierHeight = styles.getStyles('farm_page.sell_item_dialog.purchase_multipliers.general.height') as double;
    multiplierBorderRadius = styles.getStyles('farm_page.sell_item_dialog.purchase_multipliers.general.border_radius') as double;
    multiplierBorderWidth = styles.getStyles('farm_page.sell_item_dialog.purchase_multipliers.general.border_width') as double;
    selectedBgGradient = styles.getStyles('farm_page.sell_item_dialog.purchase_multipliers.selected.background_color') as LinearGradient;
    selectedStrokeGradient = styles.getStyles('farm_page.sell_item_dialog.purchase_multipliers.selected.stroke_color') as LinearGradient;
    selectedTextColor = styles.getStyles('farm_page.sell_item_dialog.purchase_multipliers.selected.text.color') as Color;
    selectedTextSize = styles.getStyles('farm_page.sell_item_dialog.purchase_multipliers.selected.text.font_size') as double;
    selectedTextWeight = styles.getStyles('farm_page.sell_item_dialog.purchase_multipliers.selected.text.font_weight') as FontWeight;
    unselectedBgColor = styles.getStyles('farm_page.sell_item_dialog.purchase_multipliers.unselected.background_color') as Color;
    unselectedStrokeGradient = styles.getStyles('farm_page.sell_item_dialog.purchase_multipliers.unselected.stroke_color') as LinearGradient;
    unselectedTextColor = styles.getStyles('farm_page.sell_item_dialog.purchase_multipliers.unselected.text.color') as Color;
    unselectedTextSize = styles.getStyles('farm_page.sell_item_dialog.purchase_multipliers.unselected.text.font_size') as double;
    unselectedTextWeight = styles.getStyles('farm_page.sell_item_dialog.purchase_multipliers.unselected.text.font_weight') as FontWeight;
    coinsIconImage = styles.getStyles('farm_page.sell_item_dialog.total_sell_price_display.coins_icon.image') as String;
    coinsIconWidth = styles.getStyles('farm_page.sell_item_dialog.total_sell_price_display.coins_icon.width') as double;
    coinsIconHeight = styles.getStyles('farm_page.sell_item_dialog.total_sell_price_display.coins_icon.height') as double;
    sellPriceLabelColor = styles.getStyles('farm_page.sell_item_dialog.total_sell_price_display.sell_price_label.color') as Color;
    sellPriceLabelSize = styles.getStyles('farm_page.sell_item_dialog.total_sell_price_display.sell_price_label.font_size') as double;
    sellPriceLabelWeight = styles.getStyles('farm_page.sell_item_dialog.total_sell_price_display.sell_price_label.font_weight') as FontWeight;
    cancelWidth = styles.getStyles('farm_page.sell_item_dialog.cancel_button.width') as double;
    cancelHeight = styles.getStyles('farm_page.sell_item_dialog.cancel_button.height') as double;
    cancelBorderRadius = styles.getStyles('farm_page.sell_item_dialog.cancel_button.border_radius') as double;
    cancelBorderWidth = styles.getStyles('farm_page.sell_item_dialog.cancel_button.border_width') as double;
    cancelBgColor = styles.getStyles('farm_page.sell_item_dialog.cancel_button.background_color') as Color;
    cancelStrokeGradient = styles.getStyles('farm_page.sell_item_dialog.cancel_button.stroke_color') as LinearGradient;
    cancelTextColor = styles.getStyles('farm_page.sell_item_dialog.cancel_button.text.color') as Color;
    cancelTextSize = styles.getStyles('farm_page.sell_item_dialog.cancel_button.text.font_size') as double;
    cancelTextWeight = styles.getStyles('farm_page.sell_item_dialog.cancel_button.text.font_weight') as FontWeight;
    sellWidth = styles.getStyles('farm_page.sell_item_dialog.sell_button.width') as double;
    sellHeight = styles.getStyles('farm_page.sell_item_dialog.sell_button.height') as double;
    sellBorderRadius = styles.getStyles('farm_page.sell_item_dialog.sell_button.border_radius') as double;
    sellBorderWidth = styles.getStyles('farm_page.sell_item_dialog.sell_button.border_width') as double;
    sellBgGradient = styles.getStyles('farm_page.sell_item_dialog.sell_button.background_color') as LinearGradient;
    sellStrokeGradient = styles.getStyles('farm_page.sell_item_dialog.sell_button.stroke_color') as LinearGradient;
    sellTextColor = styles.getStyles('farm_page.sell_item_dialog.sell_button.text.color') as Color;
    sellTextSize = styles.getStyles('farm_page.sell_item_dialog.sell_button.text.font_size') as double;
    sellTextWeight = styles.getStyles('farm_page.sell_item_dialog.sell_button.text.font_weight') as FontWeight;
  }

  int get _quantityToSell {
    if (_selectedMultiplier == SellMultiplier.all) {
      return widget.currentQuantity;
    }
    return _selectedMultiplier.value.clamp(0, widget.currentQuantity);
  }

  int get _coinsToReceive {
    return widget.item.sellAmount * _quantityToSell;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: dialogWidth,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTitle(),
            const SizedBox(height: 24),
            _buildItemDisplay(),
            const SizedBox(height: 24),
            _buildMultiplierButtons(),
            const SizedBox(height: 24),
            _buildTotalSellPrice(),
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'Sell Item',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: titleColor,
        fontSize: titleSize,
        fontWeight: titleWeight,
      ),
    );
  }

  Widget _buildItemDisplay() {
    return Row(
      children: [
        // Item icon on left
        Image.asset(
          widget.item.icon,
          width: iconWidth,
          height: iconHeight,
          errorBuilder: (context, error, stackTrace) {
            return SizedBox(
              width: iconWidth,
              height: iconHeight,
              child: Icon(Icons.image_not_supported, size: iconWidth * 0.6),
            );
          },
        ),
        const SizedBox(width: 16),
        // Item details on right
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item name
              Text(
                widget.item.name,
                style: TextStyle(
                  color: nameColor,
                  fontSize: nameSize,
                  fontWeight: nameWeight,
                ),
              ),
              // Quantity
              Text(
                'x${widget.currentQuantity}',
                style: TextStyle(
                  color: quantityColor,
                  fontSize: quantitySize,
                  fontWeight: quantityWeight,
                ),
              ),
              const SizedBox(height: 4),
              // Price per item
              Text(
                '${widget.item.sellAmount} coins each',
                style: TextStyle(
                  color: sellPricePerColor,
                  fontSize: sellPricePerSize,
                  fontWeight: sellPricePerWeight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMultiplierButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: SellMultiplier.values.map((multiplier) {
        final isDisabled = multiplier != SellMultiplier.all &&
            multiplier.value > widget.currentQuantity;
        final isSelected = _selectedMultiplier == multiplier;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _buildMultiplierButton(multiplier, isSelected, isDisabled),
        );
      }).toList(),
    );
  }

  Widget _buildMultiplierButton(SellMultiplier multiplier, bool isSelected, bool isDisabled) {
    return GestureDetector(
      onTap: isDisabled
          ? null
          : () {
              setState(() {
                _selectedMultiplier = multiplier;
              });
            },
      child: Container(
        width: multiplierWidth,
        height: multiplierHeight,
        decoration: BoxDecoration(
          gradient: isDisabled 
              ? null 
              : (isSelected ? selectedStrokeGradient : unselectedStrokeGradient),
          color: isDisabled ? quantityColor.withAlpha(77) : null,
          borderRadius: BorderRadius.circular(multiplierBorderRadius),
        ),
        padding: EdgeInsets.all(multiplierBorderWidth),
        child: Container(
          decoration: BoxDecoration(
            gradient: isDisabled 
                ? null 
                : (isSelected ? selectedBgGradient : null),
            color: isDisabled 
                ? bgColor 
                : (isSelected ? null : unselectedBgColor),
            borderRadius: BorderRadius.circular(multiplierBorderRadius - multiplierBorderWidth),
          ),
          child: Center(
            child: Text(
              multiplier.label,
              style: TextStyle(
                color: isDisabled
                    ? quantityColor.withAlpha(128)
                    : (isSelected ? selectedTextColor : unselectedTextColor),
                fontSize: isSelected ? selectedTextSize : unselectedTextSize,
                fontWeight: isSelected ? selectedTextWeight : unselectedTextWeight,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTotalSellPrice() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          coinsIconImage,
          width: coinsIconWidth,
          height: coinsIconHeight,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.monetization_on,
              size: coinsIconWidth,
              color: sellPriceLabelColor,
            );
          },
        ),
        const SizedBox(width: 8),
        Text(
          '$_coinsToReceive',
          style: TextStyle(
            color: sellPriceLabelColor,
            fontSize: sellPriceLabelSize,
            fontWeight: sellPriceLabelWeight,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Cancel button
        GestureDetector(
          onTap: _isSelling ? null : () => Navigator.of(context).pop(),
          child: Container(
            width: cancelWidth,
            height: cancelHeight,
            decoration: BoxDecoration(
              gradient: cancelStrokeGradient,
              borderRadius: BorderRadius.circular(cancelBorderRadius),
            ),
            padding: EdgeInsets.all(cancelBorderWidth),
            child: Container(
              decoration: BoxDecoration(
                color: cancelBgColor,
                borderRadius: BorderRadius.circular(cancelBorderRadius - cancelBorderWidth),
              ),
              child: Center(
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: cancelTextColor,
                    fontSize: cancelTextSize,
                    fontWeight: cancelTextWeight,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Sell button
        GestureDetector(
          onTap: _isSelling || _quantityToSell <= 0 ? null : _handleSell,
          child: Container(
            width: sellWidth,
            height: sellHeight,
            decoration: BoxDecoration(
              gradient: sellStrokeGradient,
              borderRadius: BorderRadius.circular(sellBorderRadius),
            ),
            padding: EdgeInsets.all(sellBorderWidth),
            child: Container(
              decoration: BoxDecoration(
                gradient: sellBgGradient,
                borderRadius: BorderRadius.circular(sellBorderRadius - sellBorderWidth),
              ),
              child: Center(
                child: _isSelling
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(sellTextColor),
                        ),
                      )
                    : Text(
                        'Sell',
                        style: TextStyle(
                          color: sellTextColor,
                          fontSize: sellTextSize,
                          fontWeight: sellTextWeight,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleSell() async {
    if (widget.userData == null) {
      _showError('User data not available');
      return;
    }

    setState(() {
      _isSelling = true;
    });

    try {
      final success = await widget.userData!.sellItem(
        itemId: widget.item.id,
        quantity: _quantityToSell,
        sellAmountPerItem: widget.item.sellAmount,
      );

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop(true);
        _showSuccess('Sold $_quantityToSell ${widget.item.name} for $_coinsToReceive coins!');
      } else {
        setState(() {
          _isSelling = false;
        });
        _showError('Failed to sell item. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSelling = false;
      });
      _showError('Error: $e');
    }
  }

  void _showError(String message) {
    if (widget.notificationController != null) {
      widget.notificationController!.showError(message);
    } else {
      // No notification controller available; log instead of SnackBar
      debugPrint('Error notification: $message');
    }
  }

  void _showSuccess(String message) {
    if (widget.notificationController != null) {
      widget.notificationController!.showSuccess(message);
    } else {
      debugPrint('Success notification: $message');
    }
  }
}
