/// Centralized validation functions for account-related fields
/// Used across login, register, settings, and admin config pages

class AccountValidation {
  /// Validates username field
  /// Requirements: at least 8 characters, alphanumeric only (no spaces)
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a username';
    }
    if (value.length < 8) {
      return 'Username must be at least 8 characters';
    }
    // Check if alphanumeric (letters and numbers only, no spaces)
    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
      return 'Username must be alphanumeric (letters and numbers only)';
    }
    return null;
  }

  /// Validates email field
  /// Requirements: must contain @
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!value.contains('@')) {
      return 'Please enter a valid email';
    }
    // More robust email validation
    if (!RegExp(r'^[\w\.\-]+@[\w\-]+\.[\w\-]+').hasMatch(value)) {
      return 'Please enter a valid email format';
    }
    return null;
  }

  /// Validates password field
  /// Requirements: at least 6 characters
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Validates confirm password field
  /// Requirements: must not be empty (matching is checked separately)
  static String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    return null;
  }

  /// Checks if two passwords match
  static bool passwordsMatch(String password, String confirmPassword) {
    return password == confirmPassword;
  }

  /// Validates required string field (generic)
  static String? validateRequiredString(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Please enter $fieldName';
    }
    return null;
  }

  /// Validates required number field (generic)
  static String? validateRequiredNumber(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Please enter $fieldName';
    }
    final number = num.tryParse(value);
    if (number == null) {
      return 'Please enter a valid number';
    }
    return null;
  }

  /// Validates number field with min/max constraints
  static String? validateNumberRange(String? value, String fieldName, {num? min, num? max}) {
    if (value == null || value.isEmpty) {
      return 'Please enter $fieldName';
    }
    final number = num.tryParse(value);
    if (number == null) {
      return 'Please enter a valid number';
    }
    if (min != null && number < min) {
      return '$fieldName must be at least $min';
    }
    if (max != null && number > max) {
      return '$fieldName must be at most $max';
    }
    return null;
  }
}
