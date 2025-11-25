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

  /// Universal function to get any style value from the schema
  /// Automatically detects and returns the appropriate type:
  /// - Color (from hex, rgb/rgba, hsl/hsla strings)
  ///   Method: `getStyles(path) as Color`
  /// - LinearGradient (from gradient map with begin/end positions and colors)
  ///   Method: `getStyles(path) as LinearGradient`
  /// - FontWeight (from token strings like 'w100'..'w900')
  ///   Method: `getStyles(path) as FontWeight`
  /// - double (numeric sizes, weights, radii, etc.)
  ///   Method: `getStyles(path) as double`
  /// - String (for image paths, positions, etc.)
  ///   Method: `getStyles(path) as String`
  /// - Map (for complex nested structures)

  dynamic getStyles(String path) {
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
      current = _resolveConstantValue(current);
    }

    // Auto-detect type and return appropriate value
    return _detectAndConvert(current, path);
  }

  /// Detect value type and convert to appropriate Flutter type
  dynamic _detectAndConvert(dynamic value, String path) {
    // Handle Map - could be a gradient or nested structure
    if (value is Map<String, dynamic>) {
      // If the map directly contains begin/end keys, treat it as a linear gradient
      if (value.containsKey('begin') && value.containsKey('end')) {
        return _parseLinearGradient(value, path);
      }

      // Otherwise, search any child map for a gradient descriptor (begin/end)
      for (final entry in value.entries) {
        final child = entry.value;
        if (child is Map<String, dynamic> && child.containsKey('begin') && child.containsKey('end')) {
          return _parseLinearGradient(child, '$path.${entry.key}');
        }
      }

      // If the map contains a color key, return that parsed color
      if (value.containsKey('color')) {
        final colorVal = value['color'];
        // Resolve constant reference if necessary
        final resolved = (colorVal is String && colorVal.startsWith('--'))
            ? _resolveConstantValue(colorVal)
            : colorVal;
        if (resolved is String && _isColorString(resolved)) {
          return _parseColor(resolved, path);
        }
      }

      // Return as-is for other maps
      return value;
    }

    // Handle String - could be color, image path, font-weight token, or position
    if (value is String) {
      // Check if it's a color
      if (_isColorString(value)) {
        return _parseColor(value, path);
      }

      // Detect font-weight token in the format 'w100'..'w900'
      final fwMatch = RegExp(r'^w(100|200|300|400|500|600|700|800|900)$').firstMatch(value.toLowerCase());
      if (fwMatch != null) {
        final weight = int.parse(fwMatch.group(1)!);
        return _numToFontWeight(weight);
      }

      // Return as string for paths, positions, etc.
      return value;
    }

    // Handle numeric values - convert to double by default.
    if (value is int || value is double) {
      return value is int ? value.toDouble() : value;
    }

    // Return as-is for any other type
    return value;
  }

  /// Check if a string is a color format
  bool _isColorString(String value) {
    final lower = value.toLowerCase().trim();
    return lower.startsWith('#') || 
           lower.startsWith('rgb') || 
           lower.startsWith('hsl');
  }

  /// Parse color from string (hex, rgb/rgba, hsl/hsla)
  Color _parseColor(String value, String path) {
    final lower = value.toLowerCase().trim();
    
    if (value.startsWith('#')) {
      return _parseHexColor(value);
    } else if (lower.startsWith('hsl')) {
      return _parseHslColor(value);
    } else if (lower.startsWith('rgb')) {
      return _parseRgbColor(value);
    }
    
    throw Exception('Invalid color format at path "$path": $value');
  }

  /// Resolve constant value reference (e.g., "--colors.white")
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

  /// Parse LinearGradient from map
  LinearGradient _parseLinearGradient(Map<String, dynamic> value, String path) {
    final beginData = value['begin'] as Map<String, dynamic>?;
    final endData = value['end'] as Map<String, dynamic>?;

    if (beginData == null || endData == null) {
      throw Exception('linear_gradient must have "begin" and "end" keys at path "$path"');
    }

    final beginPosition = _parseAlignmentPosition(beginData['position'] as String);
    final beginColor = _parseColor(
      beginData['color'] is String && (beginData['color'] as String).startsWith('--')
          ? _resolveConstantValue(beginData['color'])
          : beginData['color'],
      path,
    );
    
    final endPosition = _parseAlignmentPosition(endData['position'] as String);
    final endColor = _parseColor(
      endData['color'] is String && (endData['color'] as String).startsWith('--')
          ? _resolveConstantValue(endData['color'])
          : endData['color'],
      path,
    );

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

  /// Convert numeric 100-900 values into a FontWeight enum
  FontWeight _numToFontWeight(int weight) {
    switch (weight) {
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
        throw Exception('Invalid font_weight value: $weight. Must be 100-900 in increments of 100');
    }
  }

  /// Helper to get color with opacity applied
  Color withOpacity(String colorPath, String opacityPath) {
    final color = getStyles(colorPath) as Color;
    final opacityValue = getStyles(opacityPath);
    final opacity = opacityValue is int ? opacityValue / 100.0 : opacityValue as double;
    final a = (opacity.clamp(0.0, 1.0) * 255).round().clamp(0, 255);
    return color.withAlpha(a);
  }

  /// Testing helper: directly set styles data for unit tests to avoid asset loading.
  /// Not intended for production use.
  void setStylesForTesting(Map<String, dynamic> data) {
    _stylesData = data;
  }

  /// Check if a path exists in the schema
  bool hasPath(String path) {
    try {
      getStyles(path);
      return true;
    } catch (e) {
      return false;
    }
  }
}
