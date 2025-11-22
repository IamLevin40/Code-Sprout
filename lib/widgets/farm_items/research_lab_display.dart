import 'package:flutter/material.dart';
import '../../models/styles_schema.dart';
import '../../models/research_data.dart';
import '../../models/user_data.dart';
import '../research_cards/crop_research_cards.dart';
import '../research_cards/farm_research_cards.dart';
import '../research_cards/functions_research_cards.dart';

/// Enum for research lab tabs
enum ResearchTab {
  crops,
  farm,
  functions,
}

/// Research lab display widget that shows research cards based on selected tab
class ResearchLabDisplay extends StatefulWidget {
  final ResearchState researchState;
  final UserData? userData;
  final VoidCallback onClose;
  final Function(String researchId, Map<String, int> requirements)? onResearchCompleted;

  const ResearchLabDisplay({
    super.key,
    required this.researchState,
    required this.userData,
    required this.onClose,
    this.onResearchCompleted,
  });

  @override
  State<ResearchLabDisplay> createState() => _ResearchLabDisplayState();
}

class _ResearchLabDisplayState extends State<ResearchLabDisplay> {
  ResearchTab _selectedTab = ResearchTab.crops;

  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();
    
    // Use language selection styles as base (similar popup design)
    final height = styles.getStyles('sprout_page.language_selection.height') as double;
    final borderRadius = styles.getStyles('sprout_page.language_selection.border_radius') as double;
    final bgColor = styles.getStyles('sprout_page.language_selection.background_color') as Color;
    
    final titleColor = styles.getStyles('sprout_page.language_selection.title.color') as Color;
    final titleSize = styles.getStyles('sprout_page.language_selection.title.font_size') as double;
    final titleWeight = styles.getStyles('sprout_page.language_selection.title.font_weight') as FontWeight;
    
    final closeIcon = styles.getStyles('sprout_page.language_selection.close_button.icon') as String;
    final closeW = styles.getStyles('sprout_page.language_selection.close_button.width') as double;
    final closeH = styles.getStyles('sprout_page.language_selection.close_button.height') as double;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Column(
        children: [
          // Header with title and close button
          _buildHeader(titleColor, titleSize, titleWeight, closeIcon, closeW, closeH, borderRadius),
          
          // Tab content (scrollable research cards)
          Expanded(
            child: _buildTabContent(),
          ),
          
          // Bottom tab buttons
          _buildTabButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader(Color titleColor, double titleSize, FontWeight titleWeight,
      String closeIcon, double closeW, double closeH, double borderRadius) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(borderRadius),
          topRight: Radius.circular(borderRadius),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Research Lab',
            style: TextStyle(
              color: titleColor,
              fontSize: titleSize,
              fontWeight: titleWeight,
            ),
          ),
          GestureDetector(
            onTap: widget.onClose,
            child: Container(
              width: closeW,
              height: closeH,
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.asset(
                closeIcon,
                width: closeW * 0.6,
                height: closeH * 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: _getTabContent(),
      ),
    );
  }

  Widget _getTabContent() {
    switch (_selectedTab) {
      case ResearchTab.crops:
        return CropResearchCards(
          researchState: widget.researchState,
          userData: widget.userData,
          onResearchCompleted: widget.onResearchCompleted,
        );
      case ResearchTab.farm:
        return FarmResearchCards(
          researchState: widget.researchState,
          userData: widget.userData,
          onResearchCompleted: widget.onResearchCompleted,
        );
      case ResearchTab.functions:
        return FunctionsResearchCards(
          researchState: widget.researchState,
          userData: widget.userData,
          onResearchCompleted: widget.onResearchCompleted,
        );
    }
  }

  Widget _buildTabButtons() {
    final styles = AppStyles();
    
    // Use control button styles for tabs
    final height = styles.getStyles('farm_page.control_buttons.start_button.height') as double;
    final borderRadius = styles.getStyles('farm_page.control_buttons.start_button.border_radius') as double;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              icon: Icons.agriculture,
              label: 'Crops',
              tab: ResearchTab.crops,
              height: height,
              borderRadius: borderRadius,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTabButton(
              icon: Icons.landscape,
              label: 'Farm',
              tab: ResearchTab.farm,
              height: height,
              borderRadius: borderRadius,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTabButton(
              icon: Icons.functions,
              label: 'Functions',
              tab: ResearchTab.functions,
              height: height,
              borderRadius: borderRadius,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required IconData icon,
    required String label,
    required ResearchTab tab,
    required double height,
    required double borderRadius,
  }) {
    final styles = AppStyles();
    final isSelected = _selectedTab == tab;
    
    // Selected tab uses start button colors, unselected uses muted colors
    final bgGradient = isSelected
        ? styles.getStyles('farm_page.control_buttons.start_button.background_color') as LinearGradient
        : const LinearGradient(
            colors: [Color(0xFFE0E0E0), Color(0xFFF5F5F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
    
    final strokeGradient = isSelected
        ? styles.getStyles('farm_page.control_buttons.start_button.stroke_color') as LinearGradient
        : const LinearGradient(
            colors: [Color(0xFFBDBDBD), Color(0xFF9E9E9E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
    
    final textColor = isSelected
        ? styles.getStyles('farm_page.control_buttons.start_button.text.color') as Color
        : const Color(0xFF757575);
    
    final borderWidth = styles.getStyles('farm_page.control_buttons.start_button.border_width') as double;
    final fontSize = styles.getStyles('farm_page.control_buttons.start_button.text.font_size') as double;
    final fontWeight = styles.getStyles('farm_page.control_buttons.start_button.text.font_weight') as FontWeight;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = tab;
        });
      },
      child: Container(
        height: height,
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textColor, size: fontSize * 1.2),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: fontSize * 0.7,
                  fontWeight: fontWeight,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
