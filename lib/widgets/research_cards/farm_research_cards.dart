import 'package:flutter/material.dart';
import '../../models/styles_schema.dart';
import '../../models/research_data.dart';
import '../../models/user_data.dart';

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

  /// Get placeholder farm research items
  List<FarmResearchItem> _getFarmResearchItems() {
    return [
      FarmResearchItem(
        id: 'farm_basic_plot',
        name: 'Basic Farm Plot',
        description: 'Unlock the basic 5x5 farm grid.',
        farmFeature: 'basic_plot',
        predecessorIds: [], // Available from start
        requirements: {},
      ),
      FarmResearchItem(
        id: 'farm_expansion_1',
        name: 'Farm Expansion I',
        description: 'Expand farm to 7x7 grid.',
        farmFeature: 'expansion_1',
        predecessorIds: ['farm_basic_plot'],
        requirements: {
          'inventory.crops.wheat': 500,
        },
      ),
      FarmResearchItem(
        id: 'farm_irrigation',
        name: 'Irrigation System',
        description: 'Unlock automatic watering for adjacent plots.',
        farmFeature: 'irrigation',
        predecessorIds: ['farm_basic_plot'],
        requirements: {
          'inventory.crops.wheat': 300,
          'inventory.crops.carrot': 200,
        },
      ),
      FarmResearchItem(
        id: 'farm_expansion_2',
        name: 'Farm Expansion II',
        description: 'Expand farm to 10x10 grid.',
        farmFeature: 'expansion_2',
        predecessorIds: ['farm_expansion_1', 'farm_irrigation'],
        requirements: {
          'inventory.crops.potato': 800,
          'inventory.crops.carrot': 1000,
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final items = _getFarmResearchItems();
    
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

  Widget _buildFarmCard(FarmResearchItem item, FarmResearchState state) {
    final styles = AppStyles();
    
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
                  // Farm icon placeholder
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.landscape,
                      size: 40,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Farm info
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

  Widget _buildResearchButton(FarmResearchItem item) {
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
