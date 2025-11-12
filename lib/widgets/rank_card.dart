import 'package:flutter/material.dart';
import '../models/styles_schema.dart';
import '../miscellaneous/single_pass_painters.dart';

/// RankCard widget
class RankCard extends StatelessWidget {
  final String title;
  final double progress; // 0.0 - 1.0
  final String displayText; // e.g. "10 / 50 XP" or "Max"
  final Widget? icon;
  final VoidCallback? onTap;

  const RankCard({super.key, required this.title, required this.progress, required this.displayText, this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();

    final cardWidth = styles.getStyles('rank_card.width') as double;
    final cardHeight = styles.getStyles('rank_card.height') as double;
    final iconWidth = styles.getStyles('rank_card.icon.width') as double;
    final iconHeight = styles.getStyles('rank_card.icon.height') as double;
    final iconImage = styles.getStyles('rank_card.icon.image') as String;
    final borderRadius = styles.getStyles('rank_card.border_radius') as double;
    final strokeThickness = styles.getStyles('rank_card.stroke_thickness') as double;
    final strokeColor = styles.getStyles('rank_card.stroke_color') as LinearGradient;
    final bg = styles.getStyles('rank_card.background_color') as LinearGradient;

    final progressBarHeight = styles.getStyles('rank_card.progress_bar.height') as double;
    final progressBarRadius = styles.getStyles('rank_card.progress_bar.border_radius') as double;
    final progressBarBg = styles.getStyles('rank_card.progress_bar.background_color') as LinearGradient;
    final progressBarFill = styles.getStyles('rank_card.progress_bar.fill_color') as LinearGradient;
    final progressBarFillBorderRadius = styles.getStyles('rank_card.progress_bar.fill_border_radius') as double;
    final progressInnerPadding = styles.getStyles('rank_card.progress_bar.inner_padding') as double;
    final progressBarStrokeThickness = styles.getStyles('rank_card.progress_bar.stroke_thickness') as double;

    return GestureDetector(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: cardWidth, maxHeight: cardHeight),
        child: Container(
          width: cardWidth,
          height: cardHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: strokeColor,
          ),
          padding: EdgeInsets.all(strokeThickness),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular((borderRadius - strokeThickness).clamp(0.0, borderRadius)),
              gradient: bg,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
                  SizedBox(
                    height: iconHeight,
                    width: iconWidth,
                    child: icon ?? Image.asset(iconImage, width: iconWidth, height: iconHeight, fit: BoxFit.contain),
                  ),

                  // Title
                  Builder(builder: (context) {
                    final fontSize = styles.getStyles('rank_card.rank_title.font_size') as double;
                    final fontWeight = styles.getStyles('rank_card.rank_title.font_weight') as FontWeight;
                    final color = styles.getStyles('rank_card.rank_title.color') as Color;
                    final double heightBox = fontSize * 1.3;

                    return SizedBox(
                      height: heightBox,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: fontWeight,
                            color: color,
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 4.0),

                  // Progress bar
                  SizedBox(
                    height: progressBarHeight + progressBarStrokeThickness,
                    child: CustomPaint(
                      painter: SinglePassBackgroundPainter(
                        background: progressBarBg,
                        strokeGradient: styles.getStyles('rank_card.progress_bar.stroke_gradient') as LinearGradient,
                        strokeColor: null,
                        borderRadius: progressBarRadius,
                        strokeThickness: progressBarStrokeThickness,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(0),
                        child: Stack(
                          children: [
                            Builder(builder: (context) {
                              final double pct = progress.clamp(0.0, 1.0);
                              final BorderRadius fillRadius = pct >= 1.0
                                  ? BorderRadius.circular(progressBarFillBorderRadius)
                                  : BorderRadius.only(
                                      topLeft: Radius.circular(progressBarFillBorderRadius),
                                      bottomLeft: Radius.circular(progressBarFillBorderRadius),
                                    );

                              return Positioned(
                                left: progressInnerPadding + progressBarStrokeThickness / 2,
                                right: progressInnerPadding + progressBarStrokeThickness / 2,
                                top: progressInnerPadding + progressBarStrokeThickness / 2,
                                bottom: progressInnerPadding + progressBarStrokeThickness / 2,
                                child: ClipRRect(
                                  borderRadius: fillRadius,
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: pct,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: progressBarFill,
                                        borderRadius: fillRadius,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Display text
                  Text(
                    displayText,
                    style: TextStyle(
                      fontSize: styles.getStyles('rank_card.progress_text.font_size') as double,
                      fontWeight: styles.getStyles('rank_card.progress_text.font_weight') as FontWeight,
                      color: styles.getStyles('rank_card.progress_text.color') as Color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
