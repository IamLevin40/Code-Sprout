import 'package:flutter/material.dart';
import '../../models/styles_schema.dart';
import '../../models/research_data.dart';
import '../../models/user_data.dart';
import '../../models/research_items_schema.dart';
import '../../miscellaneous/glass_effect.dart';

/// Widget that displays farm research cards
class FarmResearchCards extends StatelessWidget {
  final ResearchState researchState;
  final UserData? userData;
  final Function(String researchId, Map<String, int> requirements)? onResearchCompleted;

  const FarmResearchCards({
    super.key,
    required this.researchState,
    required this.userData,
    this.onResearchCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final items = ResearchItemsSchema.instance.getFarmResearchItems();
    
    return Column(
      children: items.map((item) {
        final state = researchState.getFarmResearchState(item);
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildFarmCard(item, state),
        );
      }).toList(),
    );
  }

  Widget _buildFarmCard(FarmResearchItemSchema item, FarmResearchState state) {
    final styles = AppStyles();
    
    // General card styles
    final borderRadius = styles.getStyles('research_card.general.border_radius') as double;
    final borderWidth = styles.getStyles('research_card.general.border_width') as double;
    final bgGradient = styles.getStyles('research_card.general.background_color') as LinearGradient;
    final strokeGradient = styles.getStyles('research_card.general.stroke_color') as LinearGradient;

    // Farm-specific styles
    final nameColor = styles.getStyles('research_card.farm_item.name.color') as Color;
    final nameSize = styles.getStyles('research_card.farm_item.name.font_size') as double;
    final nameWeight = styles.getStyles('research_card.farm_item.name.font_weight') as FontWeight;

    final descColor = styles.getStyles('research_card.farm_item.description.color') as Color;
    final descSize = styles.getStyles('research_card.farm_item.description.font_size') as double;
    final descWeight = styles.getStyles('research_card.farm_item.description.font_weight') as FontWeight;

    // Requirements styles
    final reqColor = styles.getStyles('research_card.general.requirements.color') as Color;
    final reqSize = styles.getStyles('research_card.general.requirements.font_size') as double;
    final reqWeight = styles.getStyles('research_card.general.requirements.font_weight') as FontWeight;
    final reqIconWidth = styles.getStyles('research_card.general.requirements.item.icon.width') as double;
    final reqIconHeight = styles.getStyles('research_card.general.requirements.item.icon.height') as double;
    final reqQtyColor = styles.getStyles('research_card.general.requirements.item.quantity_label.color') as Color;
    final reqQtySize = styles.getStyles('research_card.general.requirements.item.quantity_label.font_size') as double;
    final reqQtyWeight = styles.getStyles('research_card.general.requirements.item.quantity_label.font_weight') as FontWeight;

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
                  // Farm feature icon
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
                        : const Icon(Icons.grid_on, size: 48),
                  ),
                  const SizedBox(width: 8),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.name,
                          style: TextStyle(
                            color: nameColor,
                            fontSize: nameSize,
                            fontWeight: nameWeight,
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
                  if (state == FarmResearchState.toBeResearched)
                    _buildResearchButton(item),
                ],
              ),
            ),
            // Locked overlay
            if (state == FarmResearchState.locked)
              _buildLockedOverlay(borderRadius - borderWidth),
            // Unlocked badge
            if (state == FarmResearchState.unlocked)
              _buildUnlockedBadge(borderRadius - borderWidth),
          ],
        ),
      ),
    );
  }

  Widget _buildResearchButton(FarmResearchItemSchema item) {
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
    final canResearch = userData != null && 
        ResearchRequirements.areRequirementsMet(item.requirements, userData!.toJson());
    
    return GestureDetector(
      onTap: canResearch ? () {
        if (onResearchCompleted != null) {
          onResearchCompleted!(item.id, item.requirements);
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

  Widget _buildUnlockedBadge(double borderRadius) {
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
          'Unlocked',
          style: TextStyle(
            color: badgeTextColor,
            fontSize: badgeFontSize,
            fontWeight: badgeFontWeight,
          ),
        ),
      ),
    );
  }
}
