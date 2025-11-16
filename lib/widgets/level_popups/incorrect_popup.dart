import 'package:flutter/material.dart';
import '../../models/styles_schema.dart';

class IncorrectLevelPopup {
  /// Show the incorrect answer popup. Returns when user taps Continue.
  static Future<void> show(BuildContext context) {
    final styles = AppStyles();

    final transitionMs = styles.getStyles('module_pages.level_popups.global.transition_duration') as int;
    final overlayColor = styles.getStyles('module_pages.level_popups.global.overlay_color') as Color;
    final popupBg = styles.getStyles('module_pages.level_popups.global.background_color') as Color;
    final popupBorderRadius = styles.getStyles('module_pages.level_popups.global.border_radius') as double;
    final titleColor = styles.getStyles('module_pages.level_popups.global.title.color') as Color;
    final titleFontSize = styles.getStyles('module_pages.level_popups.global.title.font_size') as double;
    final titleFontWeight = styles.getStyles('module_pages.level_popups.global.title.font_weight') as FontWeight;
    final subtitleColor = styles.getStyles('module_pages.level_popups.global.subtitle.color') as Color;
    final subtitleFontSize = styles.getStyles('module_pages.level_popups.global.subtitle.font_size') as double;
    final subtitleFontWeight = styles.getStyles('module_pages.level_popups.global.subtitle.font_weight') as FontWeight;

    final popupHeight = styles.getStyles('module_pages.level_popups.incorrect_popup.height') as double;
    final iconPath = styles.getStyles('module_pages.level_popups.incorrect_popup.icon') as String;

    final continueButtonWidth = styles.getStyles('module_pages.level_popups.global.button.width') as double;
    final continueButtonHeight = styles.getStyles('module_pages.level_popups.global.button.height') as double;
    final continueButtonBorderRadius = styles.getStyles('module_pages.level_popups.global.button.border_radius') as double;
    final continueButtonBorderWidth = styles.getStyles('module_pages.level_popups.global.button.border_width') as double;
    final continueButtonBackground = styles.getStyles('module_pages.level_popups.incorrect_popup.continue_button.background_color') as Color;
    final continueButtonStroke = styles.getStyles('module_pages.level_popups.incorrect_popup.continue_button.stroke_color') as LinearGradient;
    final continueButtonTextColor = styles.getStyles('module_pages.level_popups.global.button.text.color') as Color;
    final continueButtonTextFontSize = styles.getStyles('module_pages.level_popups.global.button.text.font_size') as double;
    final continueButtonTextFontWeight = styles.getStyles('module_pages.level_popups.global.button.text.font_weight') as FontWeight;

    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'IncorrectPopup',
      barrierColor: Colors.transparent,
      transitionDuration: Duration(milliseconds: transitionMs),
      pageBuilder: (context, animation, secondaryAnimation) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, secondary, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOut);

        return Stack(
          children: [
            GestureDetector(
              onTap: () {},
              child: Opacity(
                opacity: 0.4 * curved.value,
                child: Container(color: overlayColor),
              ),
            ),

            Align(
              alignment: Alignment.bottomCenter,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(curved),
                child: Container(
                  height: popupHeight,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: popupBg,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(popupBorderRadius),
                      topRight: Radius.circular(popupBorderRadius),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Icon
                      Container(
                        width: styles.getStyles('module_pages.level_popups.global.icon.width') as double,
                        height: styles.getStyles('module_pages.level_popups.global.icon.height') as double,
                        decoration: const BoxDecoration(shape: BoxShape.circle),
                        child: Center(child: Image.asset(iconPath)),
                      ),
                      const SizedBox(height: 8),
                      
                      // Title
                      Builder(builder: (ctx) {
                        final base = Theme.of(ctx).textTheme.titleLarge ?? DefaultTextStyle.of(ctx).style;
                        return Text('Incorrect', style: base.copyWith(fontSize: titleFontSize, color: titleColor, fontWeight: titleFontWeight));
                      }),
                      const SizedBox(height: 4),

                      // Subtitle
                      Builder(builder: (ctx) {
                        final base = Theme.of(ctx).textTheme.bodyMedium ?? DefaultTextStyle.of(ctx).style;
                        return Text("Don't give up. Let's try again!", style: base.copyWith(fontSize: subtitleFontSize, color: subtitleColor, fontWeight: subtitleFontWeight), textAlign: TextAlign.center);
                      }),
                      const SizedBox(height: 8),
                      
                      // Continue button
                      SizedBox(
                        width: continueButtonWidth,
                        height: continueButtonHeight,
                        child: Container(
                          decoration: BoxDecoration(gradient: continueButtonStroke, borderRadius: BorderRadius.circular(continueButtonBorderRadius)),
                          child: Padding(
                            padding: EdgeInsets.all(continueButtonBorderWidth),
                            child: Material(
                              color: continueButtonBackground,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular((continueButtonBorderRadius - continueButtonBorderWidth).clamp(0, continueButtonBorderRadius))),
                              child: InkWell(
                                borderRadius: BorderRadius.circular((continueButtonBorderRadius - continueButtonBorderWidth).clamp(0, continueButtonBorderRadius)),
                                onTap: () => Navigator.of(context).pop(),
                                child: Builder(builder: (ctx) {
                                  final base = Theme.of(ctx).textTheme.labelLarge ?? DefaultTextStyle.of(ctx).style;
                                  return Center(child: Text('Continue', style: base.copyWith(color: continueButtonTextColor, fontSize: continueButtonTextFontSize, fontWeight: continueButtonTextFontWeight)));
                                }),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
