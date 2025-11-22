import 'package:flutter/material.dart';
import '../../models/styles_schema.dart';
import '../../models/research_data.dart';
import '../../models/user_data.dart';

/// Widget that displays crop research cards
class CropResearchCards extends StatelessWidget {
  final ResearchState researchState;
  final UserData? userData;
  final Function(String researchId, Map<String, int> requirements)? onResearchCompleted;

  const CropResearchCards({
    super.key,
    required this.researchState,
    required this.userData,
    this.onResearchCompleted,
  });

  /// Get placeholder crop research items
  List<CropResearchItem> _getCropResearchItems() {
    return [
      CropResearchItem(
        id: 'crop_wheat',
        name: 'Wheat',
        description: 'Grows in 5 seconds.',
        cropType: 'wheat',
        predecessorIds: [], // No prerequisites
        requirements: {}, // No requirements for first crop
      ),
      CropResearchItem(
        id: 'crop_carrot',
        name: 'Carrot',
        description: 'Grows in 7 seconds. Gives 2-3 per harvest.',
        cropType: 'carrot',
        predecessorIds: ['crop_wheat'], // No prerequisites
        requirements: {
          'inventory.crops.wheat': 250,
        },
      ),
      CropResearchItem(
        id: 'crop_potato',
        name: 'Potato',
        description: 'Grows in 5 seconds. 2% chance to become a poisonous potato.',
        cropType: 'potato',
        predecessorIds: ['crop_carrot'],
        requirements: {
          'inventory.crops.wheat': 350,
          'inventory.crops.carrot': 800,
        },
      ),
      CropResearchItem(
        id: 'crop_beetroot',
        name: 'Beetroot',
        description: 'Grows in 12.5 seconds. Will get damaged if lasts for 20 seconds.',
        cropType: 'beetroot',
        predecessorIds: ['crop_potato'],
        requirements: {
          'inventory.crops.carrot': 1050,
          'inventory.crops.potato': 350,
        },
      ),
      CropResearchItem(
        id: 'crop_radish',
        name: 'Radish',
        description: 'Grows in 5 seconds. Only grows in spring and winter.',
        cropType: 'radish',
        predecessorIds: ['crop_beetroot'],
        requirements: {
          'inventory.crops.beetroot': 600,
          'inventory.crops.potato': 650,
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final items = _getCropResearchItems();
    
    return Column(
      children: items.map((item) {
        final state = researchState.getCropResearchState(item);
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildCropCard(item, state),
        );
      }).toList(),
    );
  }

  Widget _buildCropCard(CropResearchItem item, CropResearchState state) {
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
                  // Crop icon placeholder
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.brown.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        item.cropType.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown.shade700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Crop info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.name,
                          style: TextStyle(
                            color: titleColor,
                            fontSize: titleSize,
                            fontWeight: titleWeight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.description,
                          style: TextStyle(
                            color: descColor,
                            fontSize: descSize,
                          ),
                        ),
                        if (item.requirements.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Requirements',
                            style: TextStyle(
                              color: titleColor,
                              fontSize: descSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ...item.requirements.entries.map((entry) {
                            return Text(
                              '🌾 x${entry.value}',
                              style: TextStyle(
                                color: descColor,
                                fontSize: descSize * 0.9,
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                  // Action button
                  if (state == CropResearchState.toBeResearched)
                    _buildResearchButton(item),
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

  Widget _buildResearchButton(CropResearchItem item) {
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
    final canResearch = userData != null && item.areRequirementsMet(userData!.toJson());
    
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
}
