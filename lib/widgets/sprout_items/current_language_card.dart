import 'package:flutter/material.dart';
import '../../models/styles_schema.dart';
import '../course_cards/global_course_cards.dart';
import '../../miscellaneous/glass_effect.dart';

class CurrentLanguageCard extends StatelessWidget {
  final String? selectedLanguageId;
  final Map<String, String> languageNames;
  final List<String> availableLanguages;
  final ValueChanged<String> onLanguageSelected;

  const CurrentLanguageCard({
    super.key,
    required this.selectedLanguageId,
    required this.languageNames,
    required this.availableLanguages,
    required this.onLanguageSelected,
  });

  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();

    final height = styles.getStyles('sprout_page.current_language_card.height') as double;
    final borderRadius = styles.getStyles('sprout_page.current_language_card.border_radius') as double;
    final borderWidth = styles.getStyles('sprout_page.current_language_card.border_width') as double;

    final String? langId = selectedLanguageId;
    final String langDisplay = (langId != null) ? (languageNames[langId] ?? langId) : '—';

    if (langId == null || langId.isEmpty || availableLanguages.isEmpty) {
      final placeholderColor = styles.getStyles('sprout_page.current_language_card.placeholder.color') as Color;
      return Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: placeholderColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Center(child: SizedBox(child: CircularProgressIndicator(strokeWidth: borderWidth))),
      );
    }

    final bgGradient = styles.getStyles('course_cards.style_coding.$langId.background_color') as LinearGradient;
    final strokeGradient = styles.getStyles('course_cards.style_coding.$langId.stroke_color') as LinearGradient;

    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: strokeGradient,
      ),
      padding: EdgeInsets.all(borderWidth),
      child: Container(
        decoration: BoxDecoration(
          gradient: bgGradient,
          borderRadius: BorderRadius.circular(borderRadius - borderWidth),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Left column: static label, language name, change button
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Static label
                  Builder(builder: (ctx) {
                    final fontSize = styles.getStyles('sprout_page.current_language_card.static_label.font_size') as double;
                    final color = styles.getStyles('sprout_page.current_language_card.static_label.color') as Color;
                    final fontWeight = styles.getStyles('sprout_page.current_language_card.static_label.font_weight') as FontWeight;
                    return Text('Current Language', style: TextStyle(fontSize: fontSize, color: color, fontWeight: fontWeight));
                  }),

                  // Language name
                  Builder(builder: (ctx) {
                    const base = 'sprout_page.current_language_card.language_name';
                    final fontSize = styles.getStyles('$base.font_size') as double;
                    final fontWeight = styles.getStyles('$base.font_weight') as FontWeight;
                    final color = styles.getStyles('$base.color') as Color;

                    List<Shadow> textShadows = [];
                    try {
                      final Color baseColor = styles.getStyles('$base.shadow.color') as Color;
                      final sopRaw = styles.getStyles('$base.shadow.opacity');
                      final double sop = (sopRaw is num) ? sopRaw.toDouble() / 100.0 : (sopRaw as double);
                      final sblur = styles.getStyles('$base.shadow.blur_radius') as double;
                      textShadows = [Shadow(color: baseColor.withAlpha((sop * 255).round()), blurRadius: sblur)];
                    } catch (_) {
                      textShadows = [];
                    }

                    return Text(
                      langDisplay,
                      style: TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: color, shadows: textShadows),
                    );
                  }),

                  // Change button
                  Builder(builder: (ctx) {
                    const prefix = 'sprout_page.current_language_card.change_button';
                    final btnWidth = styles.getStyles('$prefix.width') as double;
                    final btnHeight = styles.getStyles('$prefix.height') as double;
                    final btnRadius = styles.getStyles('$prefix.border_radius') as double;
                    final btnBorder = styles.getStyles('$prefix.border_width') as double;
                    final btnBg = styles.getStyles('$prefix.background_color') as LinearGradient;
                    final btnStroke = styles.getStyles('$prefix.stroke_color') as LinearGradient;
                    final textColor = styles.getStyles('$prefix.text.color') as Color;
                    final textSize = styles.getStyles('$prefix.text.font_size') as double;
                    final textWeight = styles.getStyles('$prefix.text.font_weight') as FontWeight;

                    return GestureDetector(
                      onTap: () {
                        _showLanguagePicker(ctx);
                      },
                      child: Container(
                        width: btnWidth,
                        height: btnHeight,
                        decoration: BoxDecoration(
                          gradient: btnStroke,
                          borderRadius: BorderRadius.circular(btnRadius),
                        ),
                        padding: EdgeInsets.all(btnBorder),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: btnBg,
                            borderRadius: BorderRadius.circular(btnRadius - btnBorder),
                          ),
                          alignment: Alignment.center,
                          child: Text('Change', style: TextStyle(color: textColor, fontSize: textSize, fontWeight: textWeight)),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Right column: language icon
            Align(
              alignment: Alignment.centerRight,
              child: Builder(builder: (ctx) {
                final iconId = langId;
                return GlobalCourseCards.buildLanguageIcon(AppStyles(), iconId);
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    final styles = AppStyles();

    final transitionMs = styles.getStyles('sprout_page.language_selection.transition_duration') as int;
    final pickerHeight = styles.getStyles('sprout_page.language_selection.height') as double;
    final pickerRadius = styles.getStyles('sprout_page.language_selection.border_radius') as double;
    final pickerBg = styles.getStyles('sprout_page.language_selection.background_color') as Color;

    final titleColor = styles.getStyles('sprout_page.language_selection.title.color') as Color;
    final titleSize = styles.getStyles('sprout_page.language_selection.title.font_size') as double;
    final titleWeight = styles.getStyles('sprout_page.language_selection.title.font_weight') as FontWeight;

    final closeIcon = styles.getStyles('sprout_page.language_selection.close_button.icon') as String;
    final closeW = styles.getStyles('sprout_page.language_selection.close_button.width') as double;
    final closeH = styles.getStyles('sprout_page.language_selection.close_button.height') as double;

    final langCardHeight = styles.getStyles('sprout_page.language_selection.language_card.height') as double;
    final langCardRadius = styles.getStyles('sprout_page.language_selection.language_card.border_radius') as double;
    final langCardBorder = styles.getStyles('sprout_page.language_selection.language_card.border_width') as double;
    final langCardBg = styles.getStyles('sprout_page.language_selection.language_card.background_color') as LinearGradient;
    final langCardStroke = styles.getStyles('sprout_page.language_selection.language_card.stroke_color') as LinearGradient;

    final iconDisplayWidth = styles.getStyles('sprout_page.language_selection.language_card.icon_display.width') as double;
    final iconDisplayHeight = styles.getStyles('sprout_page.language_selection.language_card.icon_display.height') as double;
    final iconDisplayRadius = styles.getStyles('sprout_page.language_selection.language_card.icon_display.border_radius') as double;
    final iconDisplayBorder = styles.getStyles('sprout_page.language_selection.language_card.icon_display.border_width') as double;
    final iconDisplayBackground = styles.getStyles('sprout_page.language_selection.language_card.icon_display.background_color') as LinearGradient;

    final unlockedLabelColor = styles.getStyles('sprout_page.language_selection.language_card.unlocked_language_label.color') as Color;
    final unlockedLabelSize = styles.getStyles('sprout_page.language_selection.language_card.unlocked_language_label.font_size') as double;
    final unlockedLabelWeight = styles.getStyles('sprout_page.language_selection.language_card.unlocked_language_label.font_weight') as FontWeight;

    final lockedLabelColor = styles.getStyles('sprout_page.language_selection.language_card.locked_language_label.color') as Color;
    final lockedLabelSize = styles.getStyles('sprout_page.language_selection.language_card.locked_language_label.font_size') as double;
    final lockedLabelWeight = styles.getStyles('sprout_page.language_selection.language_card.locked_language_label.font_weight') as FontWeight;

    final lockedOverlayBg = styles.getStyles('sprout_page.language_selection.language_card.locked_overlay.background.color') as Color;
    final lockedOverlayOpacity = styles.getStyles('sprout_page.language_selection.language_card.locked_overlay.background.opacity') as double;
    final lockedOverlayBlur = styles.getStyles('sprout_page.language_selection.language_card.locked_overlay.background.blur_sigma') as double;
    final lockedOverlayStroke = styles.getStyles('sprout_page.language_selection.language_card.locked_overlay.stroke_color') as LinearGradient;
    final lockedOverlayStrokeThickness = styles.getStyles('sprout_page.language_selection.language_card.locked_overlay.stroke_thickness') as double;

    final Map<String, bool> lockMap = {for (var id in availableLanguages) id: false};

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Select language',
      barrierColor: Colors.black54,
      transitionDuration: Duration(milliseconds: transitionMs),
      pageBuilder: (ctx, a1, a2) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: double.infinity,
                height: pickerHeight,
                decoration: BoxDecoration(
                  color: pickerBg,
                  borderRadius: BorderRadius.circular(pickerRadius),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: Column(
                    children: [
                      // Header: title + close
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Programming Language', style: TextStyle(color: titleColor, fontSize: titleSize, fontWeight: titleWeight)),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () => Navigator.of(ctx).pop(),
                                child: Image.asset(closeIcon, width: closeW, height: closeH),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Language grid
                      Expanded(
                        child: GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            mainAxisExtent: langCardHeight,
                          ),
                          itemCount: availableLanguages.length,
                          itemBuilder: (gCtx, index) {
                            final id = availableLanguages[index];
                            final langIcon = styles.getStyles('course_cards.style_coding.$id.icon') as String;
                            final langStroke = styles.getStyles('course_cards.style_coding.$id.stroke_color') as LinearGradient;

                            final bool isLocked = lockMap[id] ?? false;
                            return GestureDetector(
                              onTap: isLocked
                                  ? null
                                  : () {
                                      Navigator.of(ctx).pop();
                                      onLanguageSelected(id);
                                    },
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: langCardStroke,
                                  borderRadius: BorderRadius.circular(langCardRadius),
                                ),
                                padding: EdgeInsets.all(langCardBorder),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: langCardBg,
                                    borderRadius: BorderRadius.circular(langCardRadius - langCardBorder),
                                  ),
                                  child: Stack(
                                    children: [
                                      if (isLocked)
                                        Positioned.fill(
                                          child: GlassEffect(
                                            background: lockedOverlayBg,
                                            opacity: lockedOverlayOpacity,
                                            blurSigma: lockedOverlayBlur,
                                            strokeGradient: lockedOverlayStroke,
                                            strokeThickness: lockedOverlayStrokeThickness,
                                            borderRadius: langCardRadius,
                                            padding: EdgeInsets.zero,
                                          ),
                                        ),

                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 1,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  // Language display
                                                  Container(
                                                    width: iconDisplayWidth,
                                                    height: iconDisplayHeight,
                                                    decoration: BoxDecoration(
                                                      gradient: langStroke,
                                                      borderRadius: BorderRadius.circular(iconDisplayRadius),
                                                    ),
                                                    child: Padding(
                                                      padding: EdgeInsets.all(iconDisplayBorder),
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                          gradient: iconDisplayBackground,
                                                          borderRadius: BorderRadius.circular((iconDisplayRadius - iconDisplayBorder).clamp(0.0, double.infinity)),
                                                        ),
                                                        padding: const EdgeInsets.all(4.0),
                                                        child: Image.asset(langIcon, width: iconDisplayWidth, height: iconDisplayHeight),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              flex: 3,
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    languageNames[id] ?? id,
                                                    style: TextStyle(color: unlockedLabelColor, fontSize: unlockedLabelSize, fontWeight: unlockedLabelWeight),
                                                  ),
                                                  if (isLocked)
                                                    Text('Locked', style: TextStyle(color: lockedLabelColor, fontSize: lockedLabelSize, fontWeight: lockedLabelWeight)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim, secAnim, child) {
        final curved = Curves.easeInOut.transform(anim.value);
        return Opacity(opacity: anim.value, child: Transform.scale(scale: 0.95 + 0.05 * curved, child: child));
      },
    );
  }
}
