import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Service class to handle data-driven styles from styles_schema.txt
/// This allows centralized style management through a JSON schema file
class AppStyles {
  // Singleton pattern
  static final AppStyles _instance = AppStyles._internal();
  factory AppStyles() => _instance;
  AppStyles._internal();

  // Cache for loaded styles
  Map<String, dynamic>? _stylesData;

  /// Load styles from the schema file
  Future<void> loadStyles() async {
    if (_stylesData != null) return; // Already loaded

    try {
      final String jsonString = await rootBundle.loadString('assets/schemas/styles_schema.txt');
      _stylesData = jsonDecode(jsonString);
    } catch (e) {
      throw Exception('Failed to load styles schema: $e');
    }
  }

  /// Get a value from the styles schema using a dot-notation path
  /// Example: "login_page.title.color" or "appbar.background.linear_gradient"
  /// Supports constant value resolution: if value is a string starting with "--",
  /// it will be resolved from the constant_values map
  dynamic getValue(String path) {
    if (_stylesData == null) {
      throw Exception('Styles not loaded. Call loadStyles() first.');
    }

    final keys = path.split('.');
    dynamic current = _stylesData;

    for (final key in keys) {
      if (current is Map<String, dynamic> && current.containsKey(key)) {
        current = current[key];
      } else {
        throw Exception('Style path "$path" not found in schema');
      }
    }

    // Resolve constant values if the result is a string starting with "--"
    if (current is String && current.startsWith('--')) {
      return _resolveConstantValue(current);
    }

    return current;
  }

  /// Resolve constant value reference (e.g., "--colors.white")
  /// from the constant_values map in the schema
  dynamic _resolveConstantValue(String reference) {
    if (_stylesData == null) {
      throw Exception('Styles not loaded. Call loadStyles() first.');
    }

    // Remove the "--" prefix to get the path
    final path = reference.substring(2);
    final keys = path.split('.');
    
    // Start from constant_values
    if (!_stylesData!.containsKey('constant_values')) {
      throw Exception('constant_values not found in schema');
    }

    dynamic current = _stylesData!['constant_values'];

    for (final key in keys) {
      if (current is Map<String, dynamic> && current.containsKey(key)) {
        current = current[key];
      } else {
        throw Exception('Constant value path "$reference" not found in constant_values');
      }
    }

    return current;
  }

  /// Get a Color from the schema path
  /// Supports:
  /// - Hex colors: "#FFFFFF"
  /// - RGB/RGBA strings: "rgb(255, 255, 255)" or "rgba(255, 255, 255, 0.5)"
  /// - HSL/HSLA strings: "hsl(120, 100%, 50%)" or "hsla(120, 100%, 50%, 0.5)"
  Color getColor(String path) {
    final value = getValue(path);
    
    if (value is String) {
      if (value.startsWith('#')) {
        // Hex color
        return _parseHexColor(value);
      } else if (value.toLowerCase().startsWith('hsl')) {
        // HSL or HSLA color
        return _parseHslColor(value);
      } else if (value.toLowerCase().startsWith('rgb')) {
        // RGB or RGBA color (CSS-style)
        return _parseRgbColor(value);
      }
    }

    throw Exception('Invalid color format at path "$path": $value');
  }

  /// Parse hex color string to Color
  Color _parseHexColor(String hex) {
    var clean = hex.replaceAll('#', '');

    // Support 6-char hex (RRGGBB) -> assume full opacity
    if (clean.length == 6) {
      clean = 'FF$clean'; // AARRGGBB
    } else if (clean.length == 8) {
      // User-specified 8-char hex is treated as RRGGBBAA (RGBA)
      // Convert RRGGBBAA -> AARRGGBB for Flutter Color value
      final rrggbb = clean.substring(0, 6);
      final aa = clean.substring(6, 8);
      clean = aa + rrggbb;
    }

    return Color(int.parse(clean, radix: 16));
  }

  /// Parse RGB/RGBA CSS-style string to Color
  /// Accepts:
  /// - "rgb(r, g, b)" where r/g/b are 0..255 or percentages (e.g. "50%")
  /// - "rgba(r, g, b, a)" where a is 0..1, a percent like "50%", or 0..100 (treated as percent)
  Color _parseRgbColor(String rgb) {
    final lower = rgb.trim().toLowerCase();
    final match = RegExp(r'rgba?\(([^)]+)\)').firstMatch(lower);
    if (match == null) {
      throw Exception('Invalid rgb/rgba format: $rgb');
    }

    final parts = match.group(1)!.split(',').map((s) => s.trim()).toList();
    if (parts.length < 3) {
      throw Exception('Invalid rgb/rgba format: $rgb');
    }

    int parseChannel(String token) {
      if (token.endsWith('%')) {
        final pct = double.parse(token.replaceAll('%', '')) / 100.0;
        return (pct * 255).round().clamp(0, 255);
      }
      return int.parse(token).clamp(0, 255);
    }

    final r = parseChannel(parts[0]);
    final g = parseChannel(parts[1]);
    final b = parseChannel(parts[2]);

    double alpha = 1.0;
    if (parts.length >= 4) {
      final aRaw = parts[3];
      if (aRaw.endsWith('%')) {
        alpha = double.parse(aRaw.replaceAll('%', '')) / 100.0;
      } else {
        alpha = double.parse(aRaw);
        if (alpha > 1 && alpha <= 100) alpha = alpha / 100.0;
      }
    }

    final a = (alpha.clamp(0.0, 1.0) * 255).round();
    return Color.fromARGB(a, r, g, b);
  }

  /// Parse HSL or HSLA string to Color
  /// Accepts formats like:
  /// - "hsl(120, 100%, 50%)"
  /// - "hsla(120, 100%, 50%, 0.5)"
  /// - Alpha may be a 0..1 number or a percent like "50%" or (rarely) 0..100
  Color _parseHslColor(String hsl) {
    final lower = hsl.trim().toLowerCase();
    final match = RegExp(r'hsla?\(([^)]+)\)').firstMatch(lower);
    if (match == null) {
      throw Exception('Invalid HSL/HSLA format: $hsl');
    }

    final parts = match.group(1)!.split(',').map((s) => s.trim()).toList();
    if (parts.length < 3) {
      throw Exception('Invalid HSL/HSLA format: $hsl');
    }

    // Hue
    final hue = double.parse(parts[0]);

    // Saturation (may be percent)
    final satRaw = parts[1];
    final sat = satRaw.endsWith('%')
        ? double.parse(satRaw.replaceAll('%', '')) / 100.0
        : double.parse(satRaw);

    // Lightness (may be percent)
    final lightRaw = parts[2];
    final light = lightRaw.endsWith('%')
        ? double.parse(lightRaw.replaceAll('%', '')) / 100.0
        : double.parse(lightRaw);

    // Alpha (optional)
    double alpha = 1.0;
    if (parts.length >= 4) {
      final aRaw = parts[3];
      if (aRaw.endsWith('%')) {
        alpha = double.parse(aRaw.replaceAll('%', '')) / 100.0;
      } else {
        alpha = double.parse(aRaw);
        // If user supplied 0-100 without percent, treat >1 as percent
        if (alpha > 1 && alpha <= 100) alpha = alpha / 100.0;
      }
    }

    final hslColor = HSLColor.fromAHSL(
      alpha.clamp(0.0, 1.0),
      hue % 360.0,
      sat.clamp(0.0, 1.0),
      light.clamp(0.0, 1.0),
    );

    return hslColor.toColor();
  }

  /// Get a LinearGradient from the schema path
  /// Expected format:
  /// {
  ///   "begin": { "position": "top_left", "color": "#FFFFFF" },
  ///   "end": { "position": "bottom_right", "color": "#000000" }
  /// }
  LinearGradient getLinearGradient(String path) {
    final value = getValue(path);
    
    if (value is! Map<String, dynamic>) {
      throw Exception('Invalid linear_gradient format at path "$path"');
    }

    final beginData = value['begin'] as Map<String, dynamic>?;
    final endData = value['end'] as Map<String, dynamic>?;

    if (beginData == null || endData == null) {
      throw Exception('linear_gradient must have "begin" and "end" keys at path "$path"');
    }

    final beginPosition = _parseAlignmentPosition(beginData['position'] as String);
    final beginColor = _parseColorFromValue(beginData['color']);
    
    final endPosition = _parseAlignmentPosition(endData['position'] as String);
    final endColor = _parseColorFromValue(endData['color']);

    return LinearGradient(
      begin: beginPosition,
      end: endPosition,
      colors: [beginColor, endColor],
    );
  }

  /// Parse alignment position string
  Alignment _parseAlignmentPosition(String position) {
    switch (position.toLowerCase()) {
      case 'top_left':
        return Alignment.topLeft;
      case 'top_center':
        return Alignment.topCenter;
      case 'top_right':
        return Alignment.topRight;
      case 'center_left':
        return Alignment.centerLeft;
      case 'center':
        return Alignment.center;
      case 'center_right':
        return Alignment.centerRight;
      case 'bottom_left':
        return Alignment.bottomLeft;
      case 'bottom_center':
        return Alignment.bottomCenter;
      case 'bottom_right':
        return Alignment.bottomRight;
      default:
        throw Exception('Invalid alignment position: $position');
    }
  }

  /// Parse color from a value (can be hex, rgb/rgba, or hsl/hsla string)
  Color _parseColorFromValue(dynamic value) {
    if (value is String && value.startsWith('--')) {
      value = _resolveConstantValue(value);
    }

    if (value is String) {
      if (value.startsWith('#')) {
        return _parseHexColor(value);
      } else if (value.toLowerCase().startsWith('hsl')) {
        return _parseHslColor(value);
      } else if (value.toLowerCase().startsWith('rgb')) {
        return _parseRgbColor(value);
      }
    }

    throw Exception('Invalid color value: $value');
  }

  /// Get font size from schema path
  double getFontSize(String path) {
    final value = getValue(path);
    
    if (value is int) {
      return value.toDouble();
    } else if (value is double) {
      return value;
    }
    
    throw Exception('Invalid font_size format at path "$path": $value');
  }

  /// Get font weight from schema path
  /// Accepts values: 100, 200, 300, 400, 500, 600, 700, 800, 900
  FontWeight getFontWeight(String path) {
    final value = getValue(path);
    
    if (value is! int) {
      throw Exception('Invalid font_weight format at path "$path": $value');
    }

    switch (value) {
      case 100:
        return FontWeight.w100;
      case 200:
        return FontWeight.w200;
      case 300:
        return FontWeight.w300;
      case 400:
        return FontWeight.w400;
      case 500:
        return FontWeight.w500;
      case 600:
        return FontWeight.w600;
      case 700:
        return FontWeight.w700;
      case 800:
        return FontWeight.w800;
      case 900:
        return FontWeight.w900;
      default:
        throw Exception('Invalid font_weight value at path "$path": $value. Must be 100-900 in increments of 100');
    }
  }

  /// Get opacity from schema path (0-100)
  /// Returns value between 0.0 and 1.0
  double getOpacity(String path) {
    final value = getValue(path);
    
    if (value is int) {
      if (value < 0 || value > 100) {
        throw Exception('opacity must be between 0-100 at path "$path": $value');
      }
      return value / 100.0;
    } else if (value is double) {
      if (value < 0 || value > 100) {
        throw Exception('opacity must be between 0-100 at path "$path": $value');
      }
      return value / 100.0;
    }
    
    throw Exception('Invalid opacity format at path "$path": $value');
  }

  /// Get width from schema path (positive integer >= 1)
  double getWidth(String path) {
    final value = getValue(path);
    
    if (value is int) {
      if (value < 1) {
        throw Exception('width must be >= 1 at path "$path": $value');
      }
      return value.toDouble();
    } else if (value is double) {
      if (value < 1) {
        throw Exception('width must be >= 1 at path "$path": $value');
      }
      return value;
    }
    
    throw Exception('Invalid width format at path "$path": $value');
  }

  /// Get height from schema path (positive integer >= 1)
  double getHeight(String path) {
    final value = getValue(path);
    
    if (value is int) {
      if (value < 1) {
        throw Exception('height must be >= 1 at path "$path": $value');
      }
      return value.toDouble();
    } else if (value is double) {
      if (value < 1) {
        throw Exception('height must be >= 1 at path "$path": $value');
      }
      return value;
    }
    
    throw Exception('Invalid height format at path "$path": $value');
  }

  /// Get stroke weight from schema path (positive integer >= 1)
  /// Used for strokeWidth style parameter
  double getStrokeWeight(String path) {
    final value = getValue(path);
    
    if (value is int) {
      if (value < 1) {
        throw Exception('stroke_weight must be >= 1 at path "$path": $value');
      }
      return value.toDouble();
    } else if (value is double) {
      if (value < 1) {
        throw Exception('stroke_weight must be >= 1 at path "$path": $value');
      }
      return value;
    }
    
    throw Exception('Invalid stroke_weight format at path "$path": $value');
  }

  /// Get border radius from schema path
  double getBorderRadius(String path) {
    final value = getValue(path);
    
    if (value is int) {
      return value.toDouble();
    } else if (value is double) {
      return value;
    }
    
    throw Exception('Invalid border_radius format at path "$path": $value');
  }

  /// Get blur radius from schema path (positive integer >= 1)
  /// Used for blurRadius style parameter in shadows and blur effects
  double getBlurRadius(String path) {
    final value = getValue(path);
    
    if (value is int) {
      if (value < 1) {
        throw Exception('blur_radius must be >= 1 at path "$path": $value');
      }
      return value.toDouble();
    } else if (value is double) {
      if (value < 1) {
        throw Exception('blur_radius must be >= 1 at path "$path": $value');
      }
      return value;
    }
    
    throw Exception('Invalid blur_radius format at path "$path": $value');
  }

  /// Get image path from schema path
  String getImagePath(String path) {
    final value = getValue(path);
    
    if (value is String) {
      return value;
    }
    
    throw Exception('Invalid image_path format at path "$path": $value');
  }

  /// Get a Color with opacity applied
  /// First tries to get opacity from "{path}.opacity", then falls back to full opacity
  Color getColorWithOpacity(String colorPath, {String? opacityPath}) {
    final color = getColor(colorPath);
    
    if (opacityPath != null) {
      try {
  final opacity = getOpacity(opacityPath);
  return color.withValues(alpha: opacity);
      } catch (e) {
        return color;
      }
    }
    
    // Try to get opacity from same parent path
    try {
      final pathParts = colorPath.split('.');
      pathParts.removeLast(); // Remove 'color'
      pathParts.add('opacity');
      final defaultOpacityPath = pathParts.join('.');
  final opacity = getOpacity(defaultOpacityPath);
  return color.withValues(alpha: opacity);
    } catch (e) {
      return color;
    }
  }

  /// Check if a path exists in the schema
  bool hasPath(String path) {
    try {
      getValue(path);
      return true;
    } catch (e) {
      return false;
    }
  }
}
