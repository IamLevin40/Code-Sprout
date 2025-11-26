import 'package:flutter/material.dart' show IconData, Icons;

/// String manipulation utilities for UI display
class StringManipUtils {
  /// Convert camelCase to Title Case
  /// Example: "userName" -> "User Name"
  static String camelCaseToTitle(String text) {
    if (text.isEmpty) return text;
    
    // Convert camelCase to Title Case
    final result = text.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(0)}',
    ).trim();
    
    return result[0].toUpperCase() + result.substring(1);
  }

  /// Convert snake_case to Title Case
  /// Example: "user_name" -> "User Name"
  static String snakeCaseToTitle(String text) {
    if (text.isEmpty) return text;
    
    return text.split('_').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Truncate string with ellipsis
  /// Example: truncate("Long text here", 10) -> "Long te..."
  static String truncate(String text, int maxLength, {String ellipsis = '...'}) {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength - ellipsis.length) + ellipsis;
  }

  /// Capitalize first letter
  /// Example: "hello" -> "Hello"
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Get icon for field name (used in field labels)
  static IconData getIconForField(String fieldName) {
    final lower = fieldName.toLowerCase();
    if (lower.contains('username') || lower.contains('name')) {
      return Icons.person_outline;
    } else if (lower.contains('email')) {
      return Icons.email_outlined;
    } else if (lower.contains('phone')) {
      return Icons.phone_outlined;
    } else if (lower.contains('address')) {
      return Icons.location_on_outlined;
    } else if (lower.contains('age') || lower.contains('birth')) {
      return Icons.cake_outlined;
    } else if (lower.contains('password')) {
      return Icons.lock_outline;
    } else if (lower.contains('date') || lower.contains('time')) {
      return Icons.calendar_today_outlined;
    } else {
      return Icons.text_fields;
    }
  }
}
