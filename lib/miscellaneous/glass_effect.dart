import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'single_pass_painters.dart';

/// A reusable "glass" effect container that applies a backdrop blur and
/// semi-transparent fill, and optionally draws a stroke on top
///
/// Usage:
/// GlassEffect(
///   background: Colors.white,
///   opacity: 0.6,
///   blurSigma: 8.0,
///   strokeGradient: myGradient,
///   strokeThickness: 2.0,
///   borderRadius: 12.0,
///   child: ...,
/// )
class GlassEffect extends StatelessWidget {
  /// Background can be a [Color] or [LinearGradient].
  final dynamic background;

  /// Opacity to apply to background (0.0-1.0 value or 0-100 percentage)
  /// If gradient is supplied, the colors will be adjusted to this opacity
  final double opacity;

  /// Blur sigma for backdrop filter
  final double blurSigma;

  /// Stroke options (gradient or color). If both null, no stroke drawn
  final LinearGradient? strokeGradient;
  final Color? strokeColor;
  final double strokeThickness;

  /// Corner radius for clipping and stroke
  final double borderRadius;

  /// Optional padding inside the glass container
  final EdgeInsetsGeometry? padding;

  /// Child widget to display on top of the glass fill
  final Widget? child;

  /// If true, the glass effect will not paint a background fill and
  /// only applies blur + stroke (useful for overlaying transparent content)
  final bool drawBackground;

  const GlassEffect({
    super.key,
    this.background = Colors.white,
    this.opacity = 0.6,
    this.blurSigma = 10.0,
    this.strokeGradient,
    this.strokeColor,
    this.strokeThickness = 1.0,
    this.borderRadius = 8.0,
    this.padding,
    this.child,
    this.drawBackground = true,
  });

  LinearGradient _applyOpacityToGradient(LinearGradient g, double opacity) {
    final colors = g.colors.map((c) {
      // compute new alpha based on original alpha and requested opacity
  // c.a gives the alpha as a 0.0-1.0 double; convert to 0-255 then apply opacity
  int origAlpha = ((c.a * 255.0).round() & 0xff);
  int newAlpha = (origAlpha * opacity).round();
  if (newAlpha < 0) newAlpha = 0;
  if (newAlpha > 255) newAlpha = 255;
      return c.withAlpha(newAlpha);
    }).toList();

    return LinearGradient(
      begin: g.begin,
      end: g.end,
      colors: colors,
      stops: g.stops,
      tileMode: g.tileMode,
      transform: g.transform,
    );
  }

  dynamic _backgroundWithOpacity(dynamic bg, double opacity) {
    if (bg is LinearGradient) {
      return _applyOpacityToGradient(bg, opacity);
    } else if (bg is Color) {
  int origAlpha = ((bg.a * 255.0).round() & 0xff);
  int newAlpha = (origAlpha * opacity).round();
  if (newAlpha < 0) newAlpha = 0;
  if (newAlpha > 255) newAlpha = 255;
  return bg.withAlpha(newAlpha);
    }
    return bg;
  }

  @override
  Widget build(BuildContext context) {
  // Normalize opacity: accept 0-1 or 0-100 percentage
  final double normOpacity = (opacity > 1.0) ? (opacity / 100.0) : opacity;
  final effectiveBg = drawBackground ? _backgroundWithOpacity(background, normOpacity) : Colors.transparent;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: CustomPaint(
          // Paint stroke on top
          foregroundPainter: SinglePassBackgroundPainter(
            background: Colors.transparent,
            strokeGradient: strokeGradient,
            strokeColor: strokeColor,
            borderRadius: borderRadius,
            strokeThickness: strokeThickness,
            drawBackground: false,
          ),
            child: Container(
            decoration: BoxDecoration(
              color: effectiveBg is Color ? effectiveBg : null,
              gradient: effectiveBg is LinearGradient ? effectiveBg : null,
            ),
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
