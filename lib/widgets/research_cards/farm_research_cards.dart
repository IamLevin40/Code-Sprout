import 'package:flutter/material.dart';
import '../../models/styles_schema.dart';
import '../../models/research_data.dart';
import '../../models/user_data.dart';
import '../../models/research_items_schema.dart';

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
    
    final borderRadius = styles.getStyles('research_card.card.border_radius') as double;
    final borderWidth = styles.getStyles('research_card.card.border_width') as double;

    final bgGradient = styles.getStyles('research_card.card.background_color') as LinearGradient;
    final strokeGradient = styles.getStyles('research_card.card.stroke_color') as LinearGradient;

    final titleColor = styles.getStyles('research_card.card.title.color') as Color;
    final titleSize = styles.getStyles('research_card.card.title.font_size') as double;
    final titleWeight = styles.getStyles('research_card.card.title.font_weight') as FontWeight;

    final descColor = styles.getStyles('research_card.card.description.color') as Color;
    final descSize = styles.getStyles('research_card.card.description.font_size') as double;

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
    final buttonHeight = styles.getStyles('research_card.card.button.height') as double;
    final borderRadius = styles.getStyles('research_card.card.button.border_radius') as double;
    final borderWidth = styles.getStyles('research_card.card.button.border_width') as double;
    final bgGradient = styles.getStyles('research_card.card.button.background_color') as LinearGradient;
    final strokeGradient = styles.getStyles('research_card.card.button.stroke_color') as LinearGradient;
    final textColor = styles.getStyles('research_card.card.button.text.color') as Color;
    final fontSize = styles.getStyles('research_card.card.button.text.font_size') as double;
    final fontWeight = styles.getStyles('research_card.card.button.text.font_weight') as FontWeight;

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
    return Positioned.fill(
      child: Container(
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
      ),
    );
  }

  Widget _buildUnlockedBadge(double borderRadius) {
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
