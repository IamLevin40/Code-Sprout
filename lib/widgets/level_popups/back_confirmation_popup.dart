import 'package:flutter/material.dart';
import '../../models/styles_schema.dart';

class BackConfirmationPopup {
  /// Shows a slide-up confirmation dialog asking user to leave the module.
  /// Returns `true` if user confirms Leave, otherwise `false`.
  static Future<bool> show(BuildContext context) async {
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

    final popupHeight = styles.getStyles('module_pages.level_popups.back_confirmation_popup.height') as double;
    final iconPath = styles.getStyles('module_pages.level_popups.back_confirmation_popup.icon') as String;

    final leaveButtonWidth = styles.getStyles('module_pages.level_popups.global.button.width') as double;
    final leaveButtonHeight = styles.getStyles('module_pages.level_popups.global.button.height') as double;
    final leaveButtonBorderRadius = styles.getStyles('module_pages.level_popups.global.button.border_radius') as double;
    final leaveButtonBorderWidth = styles.getStyles('module_pages.level_popups.global.button.border_width') as double;
    final leaveButtonBackground = styles.getStyles('module_pages.level_popups.back_confirmation_popup.leave_button.background_color') as Color;
    final leaveButtonStroke = styles.getStyles('module_pages.level_popups.back_confirmation_popup.leave_button.stroke_color') as LinearGradient;

    final cancelButtonWidth = styles.getStyles('module_pages.level_popups.global.button.width') as double;
    final cancelButtonHeight = styles.getStyles('module_pages.level_popups.global.button.height') as double;
    final cancelButtonBorderRadius = styles.getStyles('module_pages.level_popups.global.button.border_radius') as double;
    final cancelButtonBorderWidth = styles.getStyles('module_pages.level_popups.global.button.border_width') as double;
    final cancelButtonBackground = styles.getStyles('module_pages.level_popups.back_confirmation_popup.cancel_button.background_color') as LinearGradient;
    final cancelButtonStroke = styles.getStyles('module_pages.level_popups.back_confirmation_popup.cancel_button.stroke_color') as LinearGradient;
    final leaveButtonTextColor = styles.getStyles('module_pages.level_popups.global.button.text.color') as Color;
    final leaveButtonTextFontSize = styles.getStyles('module_pages.level_popups.global.button.text.font_size') as double;
    final leaveButtonTextFontWeight = styles.getStyles('module_pages.level_popups.global.button.text.font_weight') as FontWeight;
    final cancelButtonTextColor = styles.getStyles('module_pages.level_popups.global.button.text.color') as Color;
    final cancelButtonTextFontSize = styles.getStyles('module_pages.level_popups.global.button.text.font_size') as double;
    final cancelButtonTextFontWeight = styles.getStyles('module_pages.level_popups.global.button.text.font_weight') as FontWeight;

    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'BackConfirmationPopup',
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
                        return Text('Proceed to Leave?', style: base.copyWith(fontSize: titleFontSize, color: titleColor, fontWeight: titleFontWeight));
                      }),
                      const SizedBox(height: 4),

                      // Subtitle
                      Builder(builder: (ctx) {
                        final base = Theme.of(ctx).textTheme.bodyMedium ?? DefaultTextStyle.of(ctx).style;
                        return Text('Your progress in this module may not be saved.', style: base.copyWith(fontSize: subtitleFontSize, color: subtitleColor, fontWeight: subtitleFontWeight), textAlign: TextAlign.center);
                      }),
                      const SizedBox(height: 8),
                      
                      // Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Leave button
                          SizedBox(
                            width: leaveButtonWidth,
                            height: leaveButtonHeight,
                            child: Container(
                              decoration: BoxDecoration(gradient: leaveButtonStroke, borderRadius: BorderRadius.circular(leaveButtonBorderRadius)),
                              child: Padding(
                                padding: EdgeInsets.all(leaveButtonBorderWidth),
                                child: Material(
                                  color: leaveButtonBackground,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular((leaveButtonBorderRadius - leaveButtonBorderWidth).clamp(0, leaveButtonBorderRadius))),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular((leaveButtonBorderRadius - leaveButtonBorderWidth).clamp(0, leaveButtonBorderRadius)),
                                    onTap: () => Navigator.of(context).pop(true),
                                    child: Builder(builder: (ctx) {
                                      final base = Theme.of(ctx).textTheme.labelLarge ?? DefaultTextStyle.of(ctx).style;
                                      return Center(child: Text('Leave', style: base.copyWith(color: leaveButtonTextColor, fontSize: leaveButtonTextFontSize, fontWeight: leaveButtonTextFontWeight)));
                                    }),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          // Cancel button
                          SizedBox(
                            width: cancelButtonWidth,
                            height: cancelButtonHeight,
                            child: Container(
                              decoration: BoxDecoration(gradient: cancelButtonStroke, borderRadius: BorderRadius.circular(cancelButtonBorderRadius)),
                              child: Padding(
                                padding: EdgeInsets.all(cancelButtonBorderWidth),
                                child: Container(
                                  decoration: BoxDecoration(gradient: cancelButtonBackground, borderRadius: BorderRadius.circular((cancelButtonBorderRadius - cancelButtonBorderWidth).clamp(0, cancelButtonBorderRadius))),
                                  child: Material(
                                    color: Colors.transparent,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular((cancelButtonBorderRadius - cancelButtonBorderWidth).clamp(0, cancelButtonBorderRadius))),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular((cancelButtonBorderRadius - cancelButtonBorderWidth).clamp(0, cancelButtonBorderRadius)),
                                      onTap: () => Navigator.of(context).pop(false),
                                      child: Center(child: Text('Cancel', style: TextStyle(color: cancelButtonTextColor, fontSize: cancelButtonTextFontSize, fontWeight: cancelButtonTextFontWeight))),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
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

    return result ?? false;
  }
}
