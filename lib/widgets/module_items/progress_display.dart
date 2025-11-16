import 'package:flutter/material.dart';
import '../../models/styles_schema.dart';

class ProgressDisplay extends StatelessWidget {
  final String stylePath;
  final double progress; // 0.0 - 1.0

  const ProgressDisplay({super.key, required this.stylePath, required this.progress});

  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();

    final progWidth = styles.getStyles('$stylePath.width') as double;
    final progHeight = styles.getStyles('$stylePath.height') as double;
    final progBorderRadius = styles.getStyles('$stylePath.border_radius') as double;
    final progBorderWidth = styles.getStyles('$stylePath.border_width') as double;
    final progBgGradient = styles.getStyles('$stylePath.background_color') as LinearGradient;
    final progStrokeGradient = styles.getStyles('$stylePath.stroke_color') as LinearGradient;

    final progIconBg = styles.getStyles('$stylePath.progress_icons.background') as String;
    final progIconFill = styles.getStyles('$stylePath.progress_icons.fill') as String;
    final progIconWidth = styles.getStyles('$stylePath.progress_icons.width') as double;
    final progIconHeight = styles.getStyles('$stylePath.progress_icons.height') as double;

    final progTextColor = styles.getStyles('$stylePath.progress_text.color') as Color;
    final progTextFontSize = styles.getStyles('$stylePath.progress_text.font_size') as double;
    final progTextFontWeight = styles.getStyles('$stylePath.progress_text.font_weight') as FontWeight;

    final fillFactor = progress.clamp(0.0, 1.0);

    return Container(
      width: progWidth,
      height: progHeight,
      decoration: BoxDecoration(
        gradient: progStrokeGradient,
        borderRadius: BorderRadius.circular(progBorderRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(progBorderWidth),
        child: Container(
          decoration: BoxDecoration(
            gradient: progBgGradient,
            borderRadius: BorderRadius.circular((progBorderRadius - progBorderWidth).clamp(0.0, double.infinity)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              SizedBox(
                width: progIconWidth,
                height: progIconHeight,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(progIconBg, width: progIconWidth, height: progIconHeight, fit: BoxFit.contain),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: ClipRect(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          heightFactor: fillFactor,
                          child: Image.asset(progIconFill, width: progIconWidth, height: progIconHeight, fit: BoxFit.contain),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Builder(builder: (ctx) {
                final base = Theme.of(ctx).textTheme.titleLarge ?? DefaultTextStyle.of(ctx).style;
                return Text('${(progress * 100).toStringAsFixed(2)}%', style: base.copyWith(color: progTextColor, fontSize: progTextFontSize, fontWeight: progTextFontWeight));
              }),
            ],
          ),
        ),
      ),
    );
  }
}
