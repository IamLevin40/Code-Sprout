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

    return current;
  }

  /// Get a Color from the schema path
  /// Supports:
  /// - Hex colors: "#FFFFFF"
  /// - ARGB strings: "(255, 255, 255, 255)"
  Color getColor(String path) {
    final value = getValue(path);
    
    if (value is String) {
      if (value.startsWith('#')) {
        // Hex color
        return _parseHexColor(value);
      } else if (value.startsWith('(') && value.endsWith(')')) {
        // ARGB color
        return _parseARGBColor(value);
      }
    }

    throw Exception('Invalid color format at path "$path": $value');
  }

  /// Parse hex color string to Color
  Color _parseHexColor(String hex) {
    hex = hex.replaceAll('#', '');
    
    if (hex.length == 6) {
      // Add full opacity if not specified
      hex = 'FF$hex';
    }
    
    return Color(int.parse(hex, radix: 16));
  }

  /// Parse ARGB color string to Color
  Color _parseARGBColor(String argb) {
    // Remove parentheses and split by comma
    final values = argb
        .replaceAll('(', '')
        .replaceAll(')', '')
        .split(',')
        .map((s) => int.parse(s.trim()))
        .toList();

    if (values.length != 4) {
      throw Exception('Invalid ARGB format: $argb');
    }

    return Color.fromARGB(values[0], values[1], values[2], values[3]);
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

  /// Parse color from a value (can be hex or ARGB string)
  Color _parseColorFromValue(dynamic value) {
    if (value is String) {
      if (value.startsWith('#')) {
        return _parseHexColor(value);
      } else if (value.startsWith('(') && value.endsWith(')')) {
        return _parseARGBColor(value);
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

  /// Get image path from schema path
  String getImagePath(String path) {
    final value = getValue(path);
    
    if (value is String) {
      return value;
    }
    
    throw Exception('Invalid image_path format at path "$path": $value');
  }

  /// Try to get a color, or return a default color if the path doesn't exist
  Color getColorOrDefault(String path, Color defaultColor) {
    try {
      return getColor(path);
    } catch (e) {
      return defaultColor;
    }
  }

  /// Try to get a gradient, or return null if the path doesn't exist
  LinearGradient? getLinearGradientOrNull(String path) {
    try {
      return getLinearGradient(path);
    } catch (e) {
      return null;
    }
  }

  /// Try to get font size, or return a default value if the path doesn't exist
  double getFontSizeOrDefault(String path, double defaultSize) {
    try {
      return getFontSize(path);
    } catch (e) {
      return defaultSize;
    }
  }

  /// Try to get font weight, or return a default value if the path doesn't exist
  FontWeight getFontWeightOrDefault(String path, FontWeight defaultWeight) {
    try {
      return getFontWeight(path);
    } catch (e) {
      return defaultWeight;
    }
  }

  /// Try to get border radius, or return a default value if the path doesn't exist
  double getBorderRadiusOrDefault(String path, double defaultRadius) {
    try {
      return getBorderRadius(path);
    } catch (e) {
      return defaultRadius;
    }
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
