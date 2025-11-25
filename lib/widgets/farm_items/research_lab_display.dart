import 'package:flutter/material.dart';
import '../../models/styles_schema.dart';
import '../../models/research_data.dart';
import '../../models/user_data.dart';
import '../research_cards/crop_research_cards.dart';
import '../research_cards/farm_research_cards.dart';
import '../research_cards/functions_research_cards.dart';
import 'notification_display.dart';

/// Enum for research lab tabs
enum ResearchTab {
  crops,
  farm,
  functions,
}

/// Research lab display widget - Complete redesign matching crop_research_lab_ref.png
/// Layout: Background layer + Cards container (scrollable) + Tab buttons at bottom
class ResearchLabDisplay extends StatefulWidget {
  final ResearchState researchState;
  final UserData? userData;
  final String? currentLanguage;
  final VoidCallback onClose;
  final Function(String researchId, Map<String, int> requirements)? onResearchCompleted;
  final NotificationController? notificationController;

  const ResearchLabDisplay({
    super.key,
    required this.researchState,
    required this.userData,
    this.currentLanguage,
    required this.onClose,
    this.onResearchCompleted,
    this.notificationController,
  });

  @override
  State<ResearchLabDisplay> createState() => _ResearchLabDisplayState();
}

class _ResearchLabDisplayState extends State<ResearchLabDisplay> {
  ResearchTab _selectedTab = ResearchTab.crops;

  @override
  void initState() {
    super.initState();
    widget.researchState.addListener(_onResearchStateChanged);
  }

  @override
  void dispose() {
    widget.researchState.removeListener(_onResearchStateChanged);
    super.dispose();
  }

  void _onResearchStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();
    
    // Load all styling from farm_page.research_lab_display path
    final displayBorderRadius = styles.getStyles('farm_page.research_lab_display.border_radius') as double;
    final displayBgColor = styles.getStyles('farm_page.research_lab_display.background_color') as Color;
    
    final cardsContainerBorderRadius = styles.getStyles('farm_page.research_lab_display.cards_container.border_radius') as double;
    final cardsContainerBgColor = styles.getStyles('farm_page.research_lab_display.cards_container.background_color') as Color;
    
    final closeIconPath = styles.getStyles('farm_page.research_lab_display.close.icon.image') as String;
    final closeIconWidth = styles.getStyles('farm_page.research_lab_display.close.icon.width') as double;
    final closeIconHeight = styles.getStyles('farm_page.research_lab_display.close.icon.height') as double;
    final closeBgColor = styles.getStyles('farm_page.research_lab_display.close.background_color') as Color;
    final closeBorderRadius = styles.getStyles('farm_page.research_lab_display.close.border_radius') as double;
    final closeWidth = styles.getStyles('farm_page.research_lab_display.close.width') as double;
    final closeHeight = styles.getStyles('farm_page.research_lab_display.close.height') as double;
    
    final tabButtonWidth = styles.getStyles('farm_page.research_lab_display.tab_buttons.general.width') as double;
    final tabButtonHeight = styles.getStyles('farm_page.research_lab_display.tab_buttons.general.height') as double;
    final tabButtonBorderRadius = styles.getStyles('farm_page.research_lab_display.tab_buttons.general.border_radius') as double;
    final tabButtonBorderWidth = styles.getStyles('farm_page.research_lab_display.tab_buttons.general.border_width') as double;
    final tabButtonIconWidth = styles.getStyles('farm_page.research_lab_display.tab_buttons.general.icon.width') as double;
    final tabButtonIconHeight = styles.getStyles('farm_page.research_lab_display.tab_buttons.general.icon.height') as double;
    
    // Selected tab styling
    final selectedBgGradient = styles.getStyles('farm_page.research_lab_display.tab_buttons.selected.background_color') as LinearGradient;
    final selectedStrokeGradient = styles.getStyles('farm_page.research_lab_display.tab_buttons.selected.stroke_color') as LinearGradient;
    final selectedTextColor = styles.getStyles('farm_page.research_lab_display.tab_buttons.selected.text.color') as Color;
    final selectedTextFontSize = styles.getStyles('farm_page.research_lab_display.tab_buttons.selected.text.font_size') as double;
    final selectedTextFontWeight = styles.getStyles('farm_page.research_lab_display.tab_buttons.selected.text.font_weight') as FontWeight;
    final selectedCropIcon = styles.getStyles('farm_page.research_lab_display.tab_buttons.selected.icons.crop') as String;
    final selectedFarmIcon = styles.getStyles('farm_page.research_lab_display.tab_buttons.selected.icons.farm') as String;
    final selectedFunctionsIcon = styles.getStyles('farm_page.research_lab_display.tab_buttons.selected.icons.functions') as String;
    
    // Unselected tab styling
    final unselectedBgColor = styles.getStyles('farm_page.research_lab_display.tab_buttons.unselected.background_color') as Color;
    final unselectedStrokeGradient = styles.getStyles('farm_page.research_lab_display.tab_buttons.unselected.stroke_color') as LinearGradient;
    final unselectedTextColor = styles.getStyles('farm_page.research_lab_display.tab_buttons.unselected.text.color') as Color;
    final unselectedTextFontSize = styles.getStyles('farm_page.research_lab_display.tab_buttons.unselected.text.font_size') as double;
    final unselectedTextFontWeight = styles.getStyles('farm_page.research_lab_display.tab_buttons.unselected.text.font_weight') as FontWeight;
    final unselectedCropIcon = styles.getStyles('farm_page.research_lab_display.tab_buttons.unselected.icons.crop') as String;
    final unselectedFarmIcon = styles.getStyles('farm_page.research_lab_display.tab_buttons.unselected.icons.farm') as String;
    final unselectedFunctionsIcon = styles.getStyles('farm_page.research_lab_display.tab_buttons.unselected.icons.functions') as String;

    return Container(
      decoration: BoxDecoration(
        color: displayBgColor,
        borderRadius: BorderRadius.circular(displayBorderRadius),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Cards container (scrollable research cards)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: cardsContainerBgColor,
                borderRadius: BorderRadius.circular(cardsContainerBorderRadius),
              ),
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: _getTabContent(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Bottom tab buttons (centered)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Back button
              GestureDetector(
                onTap: widget.onClose,
                child: Container(
                  width: closeWidth,
                  height: closeHeight,
                  decoration: BoxDecoration(
                    color: closeBgColor,
                    borderRadius: BorderRadius.circular(closeBorderRadius),
                  ),
                  child: Center(
                    child: Image.asset(
                      closeIconPath,
                      width: closeIconWidth,
                      height: closeIconHeight,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Crops button
              _buildTabButton(
                label: 'Crops',
                tab: ResearchTab.crops,
                selectedIcon: selectedCropIcon,
                unselectedIcon: unselectedCropIcon,
                width: tabButtonWidth,
                height: tabButtonHeight,
                borderRadius: tabButtonBorderRadius,
                borderWidth: tabButtonBorderWidth,
                iconWidth: tabButtonIconWidth,
                iconHeight: tabButtonIconHeight,
                selectedBgGradient: selectedBgGradient,
                selectedStrokeGradient: selectedStrokeGradient,
                selectedTextColor: selectedTextColor,
                selectedTextFontSize: selectedTextFontSize,
                selectedTextFontWeight: selectedTextFontWeight,
                unselectedBgColor: unselectedBgColor,
                unselectedStrokeGradient: unselectedStrokeGradient,
                unselectedTextColor: unselectedTextColor,
                unselectedTextFontSize: unselectedTextFontSize,
                unselectedTextFontWeight: unselectedTextFontWeight,
              ),
              const SizedBox(width: 8),
              // Farm button
              _buildTabButton(
                label: 'Farm',
                tab: ResearchTab.farm,
                selectedIcon: selectedFarmIcon,
                unselectedIcon: unselectedFarmIcon,
                width: tabButtonWidth,
                height: tabButtonHeight,
                borderRadius: tabButtonBorderRadius,
                borderWidth: tabButtonBorderWidth,
                iconWidth: tabButtonIconWidth,
                iconHeight: tabButtonIconHeight,
                selectedBgGradient: selectedBgGradient,
                selectedStrokeGradient: selectedStrokeGradient,
                selectedTextColor: selectedTextColor,
                selectedTextFontSize: selectedTextFontSize,
                selectedTextFontWeight: selectedTextFontWeight,
                unselectedBgColor: unselectedBgColor,
                unselectedStrokeGradient: unselectedStrokeGradient,
                unselectedTextColor: unselectedTextColor,
                unselectedTextFontSize: unselectedTextFontSize,
                unselectedTextFontWeight: unselectedTextFontWeight,
              ),
              const SizedBox(width: 8),
              // Functions button
              _buildTabButton(
                label: 'Functions',
                tab: ResearchTab.functions,
                selectedIcon: selectedFunctionsIcon,
                unselectedIcon: unselectedFunctionsIcon,
                width: tabButtonWidth,
                height: tabButtonHeight,
                borderRadius: tabButtonBorderRadius,
                borderWidth: tabButtonBorderWidth,
                iconWidth: tabButtonIconWidth,
                iconHeight: tabButtonIconHeight,
                selectedBgGradient: selectedBgGradient,
                selectedStrokeGradient: selectedStrokeGradient,
                selectedTextColor: selectedTextColor,
                selectedTextFontSize: selectedTextFontSize,
                selectedTextFontWeight: selectedTextFontWeight,
                unselectedBgColor: unselectedBgColor,
                unselectedStrokeGradient: unselectedStrokeGradient,
                unselectedTextColor: unselectedTextColor,
                unselectedTextFontSize: unselectedTextFontSize,
                unselectedTextFontWeight: unselectedTextFontWeight,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _getTabContent() {
    switch (_selectedTab) {
      case ResearchTab.crops:
        return CropResearchCards(
          researchState: widget.researchState,
          userData: widget.userData,
          currentLanguage: widget.currentLanguage,
          onResearchCompleted: widget.onResearchCompleted,
          notificationController: widget.notificationController,
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
          currentLanguage: widget.currentLanguage,
          onResearchCompleted: widget.onResearchCompleted,
        );
    }
  }

  Widget _buildTabButton({
    required String label,
    required ResearchTab tab,
    required String selectedIcon,
    required String unselectedIcon,
    required double width,
    required double height,
    required double borderRadius,
    required double borderWidth,
    required double iconWidth,
    required double iconHeight,
    required LinearGradient selectedBgGradient,
    required LinearGradient selectedStrokeGradient,
    required Color selectedTextColor,
    required double selectedTextFontSize,
    required FontWeight selectedTextFontWeight,
    required Color unselectedBgColor,
    required LinearGradient unselectedStrokeGradient,
    required Color unselectedTextColor,
    required double unselectedTextFontSize,
    required FontWeight unselectedTextFontWeight,
  }) {
    final isSelected = _selectedTab == tab;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = tab;
        });
      },
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: isSelected ? selectedStrokeGradient : unselectedStrokeGradient,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        padding: EdgeInsets.all(borderWidth),
        child: Container(
          decoration: BoxDecoration(
            gradient: isSelected ? selectedBgGradient : null,
            color: isSelected ? null : unselectedBgColor,
            borderRadius: BorderRadius.circular(borderRadius - borderWidth),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                isSelected ? selectedIcon : unselectedIcon,
                width: iconWidth,
                height: iconHeight,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? selectedTextColor : unselectedTextColor,
                  fontSize: isSelected ? selectedTextFontSize : unselectedTextFontSize,
                  fontWeight: isSelected ? selectedTextFontWeight : unselectedTextFontWeight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
