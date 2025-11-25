import 'package:flutter/material.dart';
import '../../models/styles_schema.dart';
import '../module_items/progress_display.dart';

class ModuleAccomplishedPopup {
  /// Show the module accomplished popup. `progressPercent` is 0.0-100.0
  static Future<void> show(BuildContext context, {required double progressPercent}) {
    final styles = AppStyles();

    final transitionMs = (styles.getStyles('module_pages.level_popups.global.transition_duration') as num).toInt();
    final overlayColor = styles.getStyles('module_pages.level_popups.global.overlay_color') as Color;
    final popupBg = styles.getStyles('module_pages.level_popups.global.background_color') as Color;
    final popupBorderRadius = styles.getStyles('module_pages.level_popups.global.border_radius') as double;
    final titleColor = styles.getStyles('module_pages.level_popups.global.title.color') as Color;
    final titleFontSize = styles.getStyles('module_pages.level_popups.global.title.font_size') as double;
    final titleFontWeight = styles.getStyles('module_pages.level_popups.global.title.font_weight') as FontWeight;
    final subtitleColor = styles.getStyles('module_pages.level_popups.global.subtitle.color') as Color;
    final subtitleFontSize = styles.getStyles('module_pages.level_popups.global.subtitle.font_size') as double;
    final subtitleFontWeight = styles.getStyles('module_pages.level_popups.global.subtitle.font_weight') as FontWeight;

    final popupHeight = styles.getStyles('module_pages.level_popups.module_accomplished_popup.height') as double;
    final iconPath = styles.getStyles('module_pages.level_popups.module_accomplished_popup.icon') as String;

    const progressDisplayStylePath = 'module_pages.level_popups.module_accomplished_popup.progress_display';

    final completeButtonWidth = styles.getStyles('module_pages.level_popups.global.button.width') as double;
    final completeButtonHeight = styles.getStyles('module_pages.level_popups.global.button.height') as double;
    final completeButtonBorderRadius = styles.getStyles('module_pages.level_popups.global.button.border_radius') as double;
    final completeButtonBorderWidth = styles.getStyles('module_pages.level_popups.global.button.border_width') as double;
    final completeButtonBackground = styles.getStyles('module_pages.level_popups.module_accomplished_popup.complete_button.background_color') as Color;
    final completeButtonStroke = styles.getStyles('module_pages.level_popups.module_accomplished_popup.complete_button.stroke_color') as LinearGradient;
    final completeButtonTextColor = styles.getStyles('module_pages.level_popups.global.button.text.color') as Color;
    final completeButtonTextFontSize = styles.getStyles('module_pages.level_popups.global.button.text.font_size') as double;
    final completeButtonTextFontWeight = styles.getStyles('module_pages.level_popups.global.button.text.font_weight') as FontWeight;

    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'ModuleAccomplishedPopup',
      barrierColor: Colors.transparent,
      transitionDuration: Duration(milliseconds: transitionMs),
      pageBuilder: (context, animation, secondaryAnimation) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, secondary, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOut);

        return Stack(
          children: [
            // animated background overlay
            GestureDetector(
              onTap: () {},
              child: Opacity(
                opacity: 0.4 * curved.value,
                child: Container(color: overlayColor),
              ),
            ),

            // slide-up container aligned to bottom
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                        return Text('Module Accomplished!', style: base.copyWith(fontSize: titleFontSize, color: titleColor, fontWeight: titleFontWeight));
                      }),
                      const SizedBox(height: 4),

                      // Subtitle
                      Builder(builder: (ctx) {
                        final base = Theme.of(ctx).textTheme.bodyMedium ?? DefaultTextStyle.of(ctx).style;
                        return Text('You have successfully finished this module.', style: base.copyWith(fontSize: subtitleFontSize, color: subtitleColor, fontWeight: subtitleFontWeight), textAlign: TextAlign.center);
                      }),
                      const SizedBox(height: 16),

                      // Progress display
                      ProgressDisplay(stylePath: progressDisplayStylePath, progress: progressPercent),
                      const SizedBox(height: 16),
                      
                      // Complete button
                      SizedBox(
                        width: completeButtonWidth,
                        height: completeButtonHeight,
                        child: Container(
                          decoration: BoxDecoration(gradient: completeButtonStroke, borderRadius: BorderRadius.circular(completeButtonBorderRadius)),
                          child: Padding(
                            padding: EdgeInsets.all(completeButtonBorderWidth),
                            child: Material(
                              color: completeButtonBackground,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular((completeButtonBorderRadius - completeButtonBorderWidth).clamp(0, completeButtonBorderRadius))),
                              child: InkWell(
                                borderRadius: BorderRadius.circular((completeButtonBorderRadius - completeButtonBorderWidth).clamp(0, completeButtonBorderRadius)),
                                onTap: () => Navigator.of(context).pop(),
                                child: Builder(builder: (ctx) {
                                  final base = Theme.of(ctx).textTheme.labelLarge ?? DefaultTextStyle.of(ctx).style;
                                  return Center(child: Text('Complete', style: base.copyWith(color: completeButtonTextColor, fontSize: completeButtonTextFontSize, fontWeight: completeButtonTextFontWeight)));
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
