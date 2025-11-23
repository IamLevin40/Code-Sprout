import 'package:flutter/material.dart';
import '../../models/styles_schema.dart';
import '../../models/research_data.dart';
import '../../models/user_data.dart';
import '../../models/research_items_schema.dart';

/// Widget that displays crop research cards
class CropResearchCards extends StatefulWidget {
  final ResearchState researchState;
  final UserData? userData;
  final String? currentLanguage;
  final Function(String researchId, Map<String, int> requirements)? onResearchCompleted;

  const CropResearchCards({
    super.key,
    required this.researchState,
    required this.userData,
    this.currentLanguage,
    this.onResearchCompleted,
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
    
    // Use research card styles
    final cardHeight = styles.getStyles('research_card.card.height') as double;
    final borderRadius = styles.getStyles('research_card.card.border_radius') as double;
    final borderWidth = styles.getStyles('research_card.card.border_width') as double;

    final bgGradient = styles.getStyles('research_card.card.background_color') as LinearGradient;
    final strokeGradient = styles.getStyles('research_card.card.stroke_color') as LinearGradient;

    final titleColor = styles.getStyles('research_card.card.title.color') as Color;
    final titleSize = styles.getStyles('research_card.card.title.font_size') as double;
    final titleWeight = styles.getStyles('research_card.card.title.font_weight') as FontWeight;

    final descColor = styles.getStyles('research_card.card.description.color') as Color;
    final descSize = styles.getStyles('research_card.card.description.font_size') as double;

    // Get language-specific name
    final displayName = item.getNameForLanguage(widget.currentLanguage);

    return Container(
      height: cardHeight,
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
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Crop icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: item.icon.isNotEmpty
                        ? Image.asset(
                            item.icon,
                            width: 64,
                            height: 64,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.image_not_supported, size: 48);
                            },
                          )
                        : const Icon(Icons.agriculture, size: 48),
                  ),
                  const SizedBox(width: 16),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          displayName,
                          style: TextStyle(
                            color: titleColor,
                            fontSize: titleSize,
                            fontWeight: titleWeight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.description,
                          style: TextStyle(
                            color: descColor,
                            fontSize: descSize,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        // Requirements
                        if (item.requirements.isNotEmpty) ...[
                          Text(
                            'Requirements',
                            style: TextStyle(
                              color: titleColor,
                              fontSize: descSize,
                              fontWeight: FontWeight.bold,
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
                                      width: 16,
                                      height: 16,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(Icons.inventory, size: 16);
                                      },
                                    )
                                  else
                                    const Icon(Icons.inventory, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    'x${entry.value}',
                                    style: TextStyle(
                                      color: descColor,
                                      fontSize: descSize * 0.9,
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
            // Purchase badge
            if (state == CropResearchState.purchase)
              _buildPurchaseBadge(borderRadius - borderWidth),
          ],
        ),
      ),
    );
  }

  Widget _buildResearchButton(CropResearchItemSchema item) {
    final styles = AppStyles();
    final buttonHeight = styles.getStyles('research_card.card.button.height') as double;
    final borderRadius = styles.getStyles('research_card.card.button.border_radius') as double;
    final borderWidth = styles.getStyles('research_card.card.button.border_width') as double;
    final bgGradient = styles.getStyles('research_card.card.button.background_color') as LinearGradient;
    final strokeGradient = styles.getStyles('research_card.card.button.stroke_color') as LinearGradient;
    final textColor = styles.getStyles('research_card.card.button.text.color') as Color;
    final fontSize = styles.getStyles('research_card.card.button.text.font_size') as double;
    final fontWeight = styles.getStyles('research_card.card.button.text.font_weight') as FontWeight;

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
          width: 120,
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
    final lockIcon = styles.getStyles('research_card.card.locked_overlay.icon.image') as String;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            lockIcon,
            width: 48,
            height: 48,
          ),
          const SizedBox(height: 8),
          const Text(
            'Locked',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseBadge(double borderRadius) {
    final styles = AppStyles();
    final badgeGradient = styles.getStyles('research_card.card.badge.background_color') as LinearGradient;
    final badgeTextColor = styles.getStyles('research_card.card.badge.text.color') as Color;
    final badgeFontSize = (styles.getStyles('research_card.card.badge.text.font_size') as num).toDouble();
    final badgeFontWeight = styles.getStyles('research_card.card.badge.text.font_weight') as FontWeight;
    final padH = styles.getStyles('research_card.card.badge.padding_horizontal') as int? ?? 12;
    final padV = styles.getStyles('research_card.card.badge.padding_vertical') as int? ?? 6;
    final badgeRadius = styles.getStyles('research_card.card.badge.border_radius') as int? ?? (borderRadius / 2).toInt();

    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: padH.toDouble(), vertical: padV.toDouble()),
        decoration: BoxDecoration(
          gradient: badgeGradient,
          borderRadius: BorderRadius.circular(badgeRadius.toDouble()),
        ),
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
        // Display purchasable items (icons only)
        if (item.itemPurchases.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: item.itemPurchases.map((itemId) {
              final itemIcon = ResearchItemsSchema.instance.getInventoryIcon(itemId);
              return Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: itemIcon != null
                    ? Image.asset(
                        itemIcon,
                        width: 20,
                        height: 20,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.inventory, size: 16);
                        },
                      )
                    : const Icon(Icons.inventory, size: 16),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],
        
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
        const SizedBox(height: 8),
        
        // Purchase button
        _buildPurchaseButton(item),
      ],
    );
  }

  Widget _buildMultiplierButton(String itemId, int multiplier) {
    final isSelected = _getMultiplier(itemId) == multiplier;
    
    return GestureDetector(
      onTap: () => _setMultiplier(itemId, multiplier),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected 
              ? Colors.blue.withValues(alpha: 0.8)
              : Colors.grey.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey,
            width: 1,
          ),
        ),
        child: Text(
          '${multiplier}x',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildPurchaseButton(CropResearchItemSchema item) {
    final styles = AppStyles();
    final buttonHeight = styles.getStyles('research_card.card.button.height') as double;
    final borderRadius = styles.getStyles('research_card.card.button.border_radius') as double;
    final borderWidth = styles.getStyles('research_card.card.button.border_width') as double;
    final bgGradient = styles.getStyles('research_card.card.button.background_color') as LinearGradient;
    final strokeGradient = styles.getStyles('research_card.card.button.stroke_color') as LinearGradient;
    final textColor = styles.getStyles('research_card.card.button.text.color') as Color;
    final fontSize = styles.getStyles('research_card.card.button.text.font_size') as double;
    final fontWeight = styles.getStyles('research_card.card.button.text.font_weight') as FontWeight;

    final multiplier = _getMultiplier(item.id);
    final totalCost = item.purchaseAmount * multiplier;
    final canAfford = widget.userData?.canAfford(totalCost) ?? false;
    
    return GestureDetector(
      onTap: canAfford ? () => _handlePurchase(item, multiplier) : null,
      child: Opacity(
        opacity: canAfford ? 1.0 : 0.5,
        child: Container(
          width: 120,
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Buy',
                  style: TextStyle(
                    color: textColor,
                    fontSize: fontSize,
                    fontWeight: fontWeight,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.monetization_on,
                      color: Colors.amber,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$totalCost',
                      style: TextStyle(
                        color: textColor,
                        fontSize: fontSize * 0.8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Purchased ${item.itemPurchases.join(", ")} x$multiplier for $totalCost coins!'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Purchase failed. Insufficient coins.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
