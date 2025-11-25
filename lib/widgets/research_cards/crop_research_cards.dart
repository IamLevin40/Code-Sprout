import 'package:flutter/material.dart';
import '../../models/styles_schema.dart';
import '../../models/research_data.dart';
import '../../models/user_data.dart';
import '../../models/research_items_schema.dart';
import '../../miscellaneous/glass_effect.dart';
import '../farm_items/notification_display.dart';

/// Widget that displays crop research cards
class CropResearchCards extends StatefulWidget {
  final ResearchState researchState;
  final UserData? userData;
  final String? currentLanguage;
  final Function(String researchId, Map<String, int> requirements)? onResearchCompleted;
  final NotificationController? notificationController;

  const CropResearchCards({
    super.key,
    required this.researchState,
    required this.userData,
    this.currentLanguage,
    this.onResearchCompleted,
    this.notificationController,
  });

  @override
  State<CropResearchCards> createState() => _CropResearchCardsState();
}

class _CropResearchCardsState extends State<CropResearchCards> {
  // Track purchase multiplier for each item (1x, 10x, or 100x)
  final Map<String, int> _purchaseMultipliers = {};

  int _getMultiplier(String itemId) {
    return _purchaseMultipliers[itemId] ?? 1;
  }

  void _setMultiplier(String itemId, int multiplier) {
    setState(() {
      _purchaseMultipliers[itemId] = multiplier;
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = ResearchItemsSchema.instance.getCropResearchItems();
    
    return Column(
      children: items.map((item) {
        final state = widget.researchState.getCropResearchState(item);
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildCropCard(item, state),
        );
      }).toList(),
    );
  }

  Widget _buildCropCard(CropResearchItemSchema item, CropResearchState state) {
    final styles = AppStyles();
    
    // General card styles
    final borderRadius = styles.getStyles('research_card.general.border_radius') as double;
    final borderWidth = styles.getStyles('research_card.general.border_width') as double;
    final bgGradient = styles.getStyles('research_card.general.background_color') as LinearGradient;
    final strokeGradient = styles.getStyles('research_card.general.stroke_color') as LinearGradient;

    // Crop-specific styles
    final defaultNameColor = styles.getStyles('research_card.crop_item.default_name.color') as Color;
    final defaultNameSize = styles.getStyles('research_card.crop_item.default_name.font_size') as double;
    final defaultNameWeight = styles.getStyles('research_card.crop_item.default_name.font_weight') as FontWeight;

    final langNameColor = styles.getStyles('research_card.crop_item.language_specific_name.color') as Color;
    final langNameSize = styles.getStyles('research_card.crop_item.language_specific_name.font_size') as double;
    final langNameWeight = styles.getStyles('research_card.crop_item.language_specific_name.font_weight') as FontWeight;

    final descColor = styles.getStyles('research_card.crop_item.description.color') as Color;
    final descSize = styles.getStyles('research_card.crop_item.description.font_size') as double;
    final descWeight = styles.getStyles('research_card.crop_item.description.font_weight') as FontWeight;

    // Requirements styles
    final reqColor = styles.getStyles('research_card.general.requirements.color') as Color;
    final reqSize = styles.getStyles('research_card.general.requirements.font_size') as double;
    final reqWeight = styles.getStyles('research_card.general.requirements.font_weight') as FontWeight;
    final reqIconWidth = styles.getStyles('research_card.general.requirements.item.icon.width') as double;
    final reqIconHeight = styles.getStyles('research_card.general.requirements.item.icon.height') as double;
    final reqQtyColor = styles.getStyles('research_card.general.requirements.item.quantity_label.color') as Color;
    final reqQtySize = styles.getStyles('research_card.general.requirements.item.quantity_label.font_size') as double;
    final reqQtyWeight = styles.getStyles('research_card.general.requirements.item.quantity_label.font_weight') as FontWeight;

    // Get display names
    final displayName = item.getNameForLanguage(widget.currentLanguage);

    return Container(
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
        child: Stack(
          fit: StackFit.loose,
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Crop icon + default name below
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: item.icon.isNotEmpty
                            ? Image.asset(
                                item.icon,
                                width: 48,
                                height: 48,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.image_not_supported, size: 48);
                                },
                              )
                            : const Icon(Icons.agriculture, size: 48),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 64,
                        child: Text(
                          item.defaultName,
                          style: TextStyle(
                            color: defaultNameColor,
                            fontSize: defaultNameSize,
                            fontWeight: defaultNameWeight,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          displayName,
                          style: TextStyle(
                            color: langNameColor,
                            fontSize: langNameSize,
                            fontWeight: langNameWeight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.description,
                          style: TextStyle(
                            color: descColor,
                            fontSize: descSize,
                            fontWeight: descWeight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Requirements
                        if (item.requirements.isNotEmpty) ...[
                          Text(
                            'Requirements',
                            style: TextStyle(
                              color: reqColor,
                              fontSize: reqSize,
                              fontWeight: reqWeight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: item.requirements.entries.map((entry) {
                              final itemIcon = ResearchItemsSchema.instance.getInventoryIcon(entry.key);
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (itemIcon != null)
                                    Image.asset(
                                      itemIcon,
                                      width: reqIconWidth,
                                      height: reqIconHeight,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(Icons.inventory, size: reqIconWidth);
                                      },
                                    )
                                  else
                                    Icon(Icons.inventory, size: reqIconWidth),
                                  const SizedBox(width: 4),
                                  Text(
                                    'x${entry.value}',
                                    style: TextStyle(
                                      color: reqQtyColor,
                                      fontSize: reqQtySize,
                                      fontWeight: reqQtyWeight,
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Action button
                  if (state == CropResearchState.toBeResearched)
                    _buildResearchButton(item),
                  if (state == CropResearchState.purchase)
                    _buildPurchaseSection(item),
                ],
              ),
            ),
            // Locked overlay
            if (state == CropResearchState.locked)
              _buildLockedOverlay(borderRadius - borderWidth),
            // Available badge
            if (state == CropResearchState.purchase)
              _buildAvailableBadge(borderRadius - borderWidth),
          ],
        ),
      ),
    );
  }

  Widget _buildResearchButton(CropResearchItemSchema item) {
    final styles = AppStyles();
    final buttonWidth = styles.getStyles('research_card.general.research_button.width') as double;
    final buttonHeight = styles.getStyles('research_card.general.research_button.height') as double;
    final borderRadius = styles.getStyles('research_card.general.research_button.border_radius') as double;
    final borderWidth = styles.getStyles('research_card.general.research_button.border_width') as double;
    final bgGradient = styles.getStyles('research_card.general.research_button.background_color') as LinearGradient;
    final strokeGradient = styles.getStyles('research_card.general.research_button.stroke_color') as LinearGradient;
    final textColor = styles.getStyles('research_card.general.research_button.text.color') as Color;
    final fontSize = styles.getStyles('research_card.general.research_button.text.font_size') as double;
    final fontWeight = styles.getStyles('research_card.general.research_button.text.font_weight') as FontWeight;

    // Check if requirements are met
    final canResearch = widget.userData != null && 
        ResearchRequirements.areRequirementsMet(item.requirements, widget.userData!.toJson());
    
    return GestureDetector(
      onTap: canResearch ? () {
        if (widget.onResearchCompleted != null) {
          widget.onResearchCompleted!(item.id, item.requirements);
        }
      } : null,
      child: Opacity(
        opacity: canResearch ? 1.0 : 0.5,
        child: Container(
          width: buttonWidth,
          height: buttonHeight,
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
            alignment: Alignment.center,
            child: Text(
              'Research',
              style: TextStyle(
                color: textColor,
                fontSize: fontSize,
                fontWeight: fontWeight,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLockedOverlay(double borderRadius) {
    final styles = AppStyles();
    final lockIcon = styles.getStyles('research_card.general.locked_overlay.icon.image') as String;
    final lockIconWidth = styles.getStyles('research_card.general.locked_overlay.icon.width') as double;
    final lockIconHeight = styles.getStyles('research_card.general.locked_overlay.icon.height') as double;
    final bgColor = styles.getStyles('research_card.general.locked_overlay.background.color') as Color;
    final bgOpacity = styles.getStyles('research_card.general.locked_overlay.background.opacity') as double;
    final blurSigma = styles.getStyles('research_card.general.locked_overlay.background.blur_sigma') as double;
    final strokeGradient = styles.getStyles('research_card.general.locked_overlay.stroke_color') as LinearGradient;
    final strokeThickness = styles.getStyles('research_card.general.locked_overlay.stroke_thickness') as double;
    final labelColor = styles.getStyles('research_card.general.locked_overlay.locked_label.color') as Color;
    final labelSize = styles.getStyles('research_card.general.locked_overlay.locked_label.font_size') as double;
    final labelWeight = styles.getStyles('research_card.general.locked_overlay.locked_label.font_weight') as FontWeight;

    return Positioned.fill(
      child: GlassEffect(
        background: bgColor,
        opacity: bgOpacity,
        blurSigma: blurSigma,
        strokeGradient: strokeGradient,
        strokeThickness: strokeThickness,
        borderRadius: borderRadius,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              lockIcon,
              width: lockIconWidth,
              height: lockIconHeight,
            ),
            const SizedBox(height: 8),
            Text(
              'Locked',
              style: TextStyle(
                color: labelColor,
                fontSize: labelSize,
                fontWeight: labelWeight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableBadge(double borderRadius) {
    final styles = AppStyles();
    final badgeWidth = styles.getStyles('research_card.general.available_badge.width') as double;
    final badgeHeight = styles.getStyles('research_card.general.available_badge.height') as double;
    final badgeRadius = styles.getStyles('research_card.general.available_badge.border_radius') as double;
    final badgeGradient = styles.getStyles('research_card.general.available_badge.background_color') as LinearGradient;
    final badgeTextColor = styles.getStyles('research_card.general.available_badge.text.color') as Color;
    final badgeFontSize = styles.getStyles('research_card.general.available_badge.text.font_size') as double;
    final badgeFontWeight = styles.getStyles('research_card.general.available_badge.text.font_weight') as FontWeight;

    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        width: badgeWidth,
        height: badgeHeight,
        decoration: BoxDecoration(
          gradient: badgeGradient,
          borderRadius: BorderRadius.circular(badgeRadius),
        ),
        alignment: Alignment.center,
        child: Text(
          'Available',
          style: TextStyle(
            color: badgeTextColor,
            fontSize: badgeFontSize,
            fontWeight: badgeFontWeight,
          ),
        ),
      ),
    );
  }

  Widget _buildPurchaseSection(CropResearchItemSchema item) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Add extra top spacing so purchase controls don't overlap the 'Available' badge
        const SizedBox(height: 36),

        // Multiplier selector
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMultiplierButton(item.id, 1),
            const SizedBox(width: 4),
            _buildMultiplierButton(item.id, 10),
            const SizedBox(width: 4),
            _buildMultiplierButton(item.id, 100),
          ],
        ),
        const SizedBox(height: 4),
        
        // Purchase button
        _buildPurchaseButton(item),
      ],
    );
  }

  Widget _buildMultiplierButton(String itemId, int multiplier) {
    final styles = AppStyles();
    final isSelected = _getMultiplier(itemId) == multiplier;
    
    final height = styles.getStyles('research_card.crop_item.purchase_multipliers.general.height') as double;
    final borderRadius = styles.getStyles('research_card.crop_item.purchase_multipliers.general.border_radius') as double;
    final borderWidth = styles.getStyles('research_card.crop_item.purchase_multipliers.general.border_width') as double;
    
    if (isSelected) {
      final bgGradient = styles.getStyles('research_card.crop_item.purchase_multipliers.selected.background_color') as LinearGradient;
      final strokeGradient = styles.getStyles('research_card.crop_item.purchase_multipliers.selected.stroke_color') as LinearGradient;
      final textColor = styles.getStyles('research_card.crop_item.purchase_multipliers.selected.text.color') as Color;
      final fontSize = styles.getStyles('research_card.crop_item.purchase_multipliers.selected.text.font_size') as double;
      final fontWeight = styles.getStyles('research_card.crop_item.purchase_multipliers.selected.text.font_weight') as FontWeight;
      
      return GestureDetector(
        onTap: () => _setMultiplier(itemId, multiplier),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            gradient: strokeGradient,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Padding(
            padding: EdgeInsets.all(borderWidth),
            child: Container(
              decoration: BoxDecoration(
                gradient: bgGradient,
                borderRadius: BorderRadius.circular(borderRadius - borderWidth),
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '${multiplier}x',
                style: TextStyle(
                  color: textColor,
                  fontSize: fontSize,
                  fontWeight: fontWeight,
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      final bgColor = styles.getStyles('research_card.crop_item.purchase_multipliers.unselected.background_color') as Color;
      final strokeGradient = styles.getStyles('research_card.crop_item.purchase_multipliers.unselected.stroke_color') as LinearGradient;
      final textColor = styles.getStyles('research_card.crop_item.purchase_multipliers.unselected.text.color') as Color;
      final fontSize = styles.getStyles('research_card.crop_item.purchase_multipliers.unselected.text.font_size') as double;
      final fontWeight = styles.getStyles('research_card.crop_item.purchase_multipliers.unselected.text.font_weight') as FontWeight;
      
      return GestureDetector(
        onTap: () => _setMultiplier(itemId, multiplier),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            gradient: strokeGradient,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Padding(
            padding: EdgeInsets.all(borderWidth),
            child: Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(borderRadius - borderWidth),
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '${multiplier}x',
                style: TextStyle(
                  color: textColor,
                  fontSize: fontSize,
                  fontWeight: fontWeight,
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildPurchaseButton(CropResearchItemSchema item) {
    final styles = AppStyles();
    final buttonWidth = styles.getStyles('research_card.crop_item.purchase_button.width') as double;
    final buttonHeight = styles.getStyles('research_card.crop_item.purchase_button.height') as double;
    final borderRadius = styles.getStyles('research_card.crop_item.purchase_button.border_radius') as double;
    final borderWidth = styles.getStyles('research_card.crop_item.purchase_button.border_width') as double;
    final bgGradient = styles.getStyles('research_card.crop_item.purchase_button.background_color') as LinearGradient;
    final strokeGradient = styles.getStyles('research_card.crop_item.purchase_button.stroke_color') as LinearGradient;
    final textColor = styles.getStyles('research_card.crop_item.purchase_button.text.color') as Color;
    final fontSize = styles.getStyles('research_card.crop_item.purchase_button.text.font_size') as double;
    final fontWeight = styles.getStyles('research_card.crop_item.purchase_button.text.font_weight') as FontWeight;
    final iconImage = styles.getStyles('research_card.crop_item.purchase_button.icon.image') as String;
    final iconWidth = styles.getStyles('research_card.crop_item.purchase_button.icon.width') as double;
    final iconHeight = styles.getStyles('research_card.crop_item.purchase_button.icon.height') as double;

    final multiplier = _getMultiplier(item.id);
    final totalCost = item.purchaseAmount * multiplier;
    final canAfford = widget.userData?.canAfford(totalCost) ?? false;
    
    return GestureDetector(
      onTap: canAfford ? () => _handlePurchase(item, multiplier) : null,
      child: Opacity(
        opacity: canAfford ? 1.0 : 0.5,
        child: Container(
          width: buttonWidth,
          height: buttonHeight,
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
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Buy',
                  style: TextStyle(
                    color: textColor,
                    fontSize: fontSize,
                    fontWeight: fontWeight,
                  ),
                ),
                const SizedBox(width: 4),
                Image.asset(
                  iconImage,
                  width: iconWidth,
                  height: iconHeight,
                ),
                const SizedBox(width: 2),
                Text(
                  '$totalCost',
                  style: TextStyle(
                    color: textColor,
                    fontSize: fontSize,
                    fontWeight: fontWeight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handlePurchase(CropResearchItemSchema item, int multiplier) async {
    final userData = widget.userData;
    if (userData == null) return;

    final totalCost = item.purchaseAmount * multiplier;
    
    // Build items map with quantities
    final items = <String, int>{};
    for (final itemId in item.itemPurchases) {
      items[itemId] = multiplier; // Each purchase gives 1 item, so multiply by multiplier
    }
    
    // Attempt purchase
    final success = await userData.purchaseWithCoins(
      cost: totalCost,
      items: items,
    );
    
    if (success && mounted) {
      if (widget.notificationController != null) {
        widget.notificationController!.showSuccess(
          'Purchased ${item.itemPurchases.join(", ")} x$multiplier for $totalCost coins!',
        );
      } else {
          debugPrint('Purchase: Purchased ${item.itemPurchases.join(", ")} x$multiplier for $totalCost coins!');
      }
    } else if (mounted) {
      if (widget.notificationController != null) {
        widget.notificationController!.showError('Purchase failed. Insufficient coins.');
      } else {
          debugPrint('Purchase failed. Insufficient coins.');
      }
    }
  }
}
