import 'package:flutter/material.dart';

/// A reusable, data-driven painter that draws a background (Color or LinearGradient)
/// and an optional stroke (LinearGradient or Color) in a single pass.
class SinglePassBackgroundPainter extends CustomPainter {
  /// Background may be a [Color] or [LinearGradient].
  final dynamic background;

  /// Stroke can be a [LinearGradient] or a [Color]
  /// If null, no stroke is drawn
  final LinearGradient? strokeGradient;
  final Color? strokeColor;

  /// Rounded radius for the outer rect
  final double borderRadius;

  /// Stroke thickness in logical pixels
  final double strokeThickness;

  /// If true, paints the background; otherwise only stroke is painted
  final bool drawBackground;

  const SinglePassBackgroundPainter({
    required this.background,
    this.strokeGradient,
    this.strokeColor,
    required this.borderRadius,
    required this.strokeThickness,
    this.drawBackground = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    // Deflate by half stroke so stroke centers on the edge of the painted rrect
    final RRect rrect = RRect.fromRectAndRadius(rect.deflate(strokeThickness / 2), Radius.circular(borderRadius));

    if (drawBackground) {
      final Paint bgPaint = Paint();
      if (background is LinearGradient) {
        bgPaint.shader = (background as LinearGradient).createShader(rrect.outerRect);
      } else if (background is Color) {
        bgPaint.color = background as Color;
      }
      canvas.drawRRect(rrect, bgPaint);
    }

    if (strokeGradient != null || strokeColor != null) {
      final Paint strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeThickness;
      if (strokeGradient != null) {
        strokePaint.shader = strokeGradient!.createShader(rect);
      } else if (strokeColor != null) {
        strokePaint.color = strokeColor!;
      }
      canvas.drawRRect(rrect, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant SinglePassBackgroundPainter oldDelegate) {
    return oldDelegate.background != background ||
        oldDelegate.strokeGradient != strokeGradient ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.strokeThickness != strokeThickness ||
        oldDelegate.drawBackground != drawBackground;
  }
}
