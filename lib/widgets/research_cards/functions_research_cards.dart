import 'package:flutter/material.dart';
import '../../models/styles_schema.dart';
import '../../models/research_data.dart';
import '../../models/user_data.dart';

/// Widget that displays functions research cards
class FunctionsResearchCards extends StatelessWidget {
  final ResearchState researchState;
  final UserData? userData;
  final Function(String researchId, Map<String, int> requirements)? onResearchCompleted;

  const FunctionsResearchCards({
    super.key,
    required this.researchState,
    required this.userData,
    this.onResearchCompleted,
  });

  /// Get placeholder functions research items
  List<FunctionsResearchItem> _getFunctionsResearchItems() {
    return [
      FunctionsResearchItem(
        id: 'func_move',
        name: 'move()',
        description: 'Move the drone one step forward.',
        functionName: 'move',
        predecessorIds: [], // Available from start
        requirements: {},
      ),
      FunctionsResearchItem(
        id: 'func_turn_left',
        name: 'turnLeft()',
        description: 'Turn the drone 90° counter-clockwise.',
        functionName: 'turnLeft',
        predecessorIds: [], // Available from start
        requirements: {},
      ),
      FunctionsResearchItem(
        id: 'func_plant',
        name: 'plant()',
        description: 'Plant a seed at the current plot.',
        functionName: 'plant',
        predecessorIds: ['func_move'],
        requirements: {
          'sproutProgress.inventory.wheat.quantity': 100,
        },
      ),
      FunctionsResearchItem(
        id: 'func_till',
        name: 'till()',
        description: 'Till the soil at the current plot.',
        functionName: 'till',
        predecessorIds: ['func_plant'],
        requirements: {
          'sproutProgress.inventory.wheat.quantity': 200,
          'sproutProgress.inventory.carrot.quantity': 150,
        },
      ),
      FunctionsResearchItem(
        id: 'func_water',
        name: 'water()',
        description: 'Water the current plot.',
        functionName: 'water',
        predecessorIds: ['func_till'],
        requirements: {
          'sproutProgress.inventory.carrot.quantity': 300,
          'sproutProgress.inventory.potato.quantity': 200,
        },
      ),
      FunctionsResearchItem(
        id: 'func_harvest',
        name: 'harvest()',
        description: 'Harvest crops from the current plot.',
        functionName: 'harvest',
        predecessorIds: ['func_plant', 'func_water'],
        requirements: {
          'sproutProgress.inventory.potato.quantity': 400,
          'sproutProgress.inventory.beetroot.quantity': 250,
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final items = _getFunctionsResearchItems();
    
    return Column(
      children: items.map((item) {
        final state = researchState.getFunctionsResearchState(item);
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildFunctionsCard(item, state),
        );
      }).toList(),
    );
  }

  Widget _buildFunctionsCard(FunctionsResearchItem item, FunctionsResearchState state) {
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
                  // Function icon placeholder
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.functions,
                      size: 40,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Function info
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
                  if (state == FunctionsResearchState.toBeResearched)
                    _buildResearchButton(item),
                ],
              ),
            ),
            // Locked overlay
            if (state == FunctionsResearchState.locked)
              _buildLockedOverlay(borderRadius - borderWidth),
            // Unlocked badge
            if (state == FunctionsResearchState.unlocked)
              _buildUnlockedBadge(borderRadius - borderWidth),
          ],
        ),
      ),
    );
  }

  Widget _buildResearchButton(FunctionsResearchItem item) {
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
