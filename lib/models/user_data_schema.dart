import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a field definition in the schema
class SchemaField {
  final String dataType;
  final dynamic defaultValue;
  final bool isRequired;
  final bool isMap;
  final Map<String, SchemaField>? nestedFields;
  final List<String>? enumValues;

  SchemaField({
    required this.dataType,
    this.defaultValue,
    this.isRequired = false,
    this.isMap = false,
    this.nestedFields,
    this.enumValues,
  });

  /// Check if this field is an enum-based field
  bool get isEnum => enumValues != null && enumValues!.isNotEmpty;

  /// Parse a field definition string
  /// Format: "data_type (default_value) [required]"
  /// For enum: "string (|Value1|Value2|Value3|) [required]"
  factory SchemaField.parse(String definition) {
    final trimmed = definition.trim();
    
    // Check if required
    final isRequired = trimmed.contains('[required]');
    var working = trimmed.replaceAll('[required]', '').trim();
    
    // Extract default value (inside parentheses)
    dynamic defaultValue;
    String dataType;
    List<String>? enumValues;
    
    final defaultValueMatch = RegExp(r'\(([^)]*)\)').firstMatch(working);
    if (defaultValueMatch != null) {
      final defaultStr = defaultValueMatch.group(1)!.trim();
      working = working.replaceAll(defaultValueMatch.group(0)!, '').trim();
      
      // Check if this is an enum definition (starts and ends with |)
      if (defaultStr.startsWith('|') && defaultStr.endsWith('|')) {
        // Parse enum values
        final enumStr = defaultStr.substring(1, defaultStr.length - 1);
        enumValues = enumStr.split('|').where((s) => s.isNotEmpty).toList();
        
        // Default value is the first enum value
        defaultValue = enumValues.isNotEmpty ? enumValues.first : null;
      } else {
        // Parse default value based on type
        if (defaultStr == 'null' || defaultStr.isEmpty) {
          defaultValue = null;
        } else if (defaultStr == 'true') {
          defaultValue = true;
        } else if (defaultStr == 'false') {
          defaultValue = false;
        } else if (double.tryParse(defaultStr) != null) {
          defaultValue = num.parse(defaultStr);
        } else {
          // String value
          defaultValue = defaultStr;
        }
      }
    }
    
    dataType = working.trim();
    
    return SchemaField(
      dataType: dataType,
      defaultValue: defaultValue,
      isRequired: isRequired,
      enumValues: enumValues,
    );
  }

  /// Get the actual default value, considering nullability
  dynamic getDefaultValue() {
    if (defaultValue == null && !isRequired) {
      return null;
    }
    return defaultValue;
  }

  /// Validate a value against this field's type
  bool validateValue(dynamic value) {
    if (value == null) {
      return !isRequired;
    }

    // Check enum values first if this is an enum field
    if (isEnum) {
      if (value is! String) return false;
      return enumValues!.contains(value);
    }

    switch (dataType.toLowerCase()) {
      case 'string':
        return value is String;
      case 'number':
        return value is num;
      case 'boolean':
        return value is bool;
      case 'timestamp':
        return value is Timestamp || value is DateTime;
      case 'geopoint':
        return value is GeoPoint;
      case 'array':
        return value is List;
      case 'map':
        return value is Map;
      case 'null':
        return value == null;
      case 'reference':
        return value is DocumentReference;
      default:
        return false;
    }
  }

  /// Convert a value to the appropriate Firestore type
  dynamic toFirestoreValue(dynamic value) {
    if (value == null) return null;

    switch (dataType.toLowerCase()) {
      case 'timestamp':
        if (value is DateTime) {
          return Timestamp.fromDate(value);
        }
        return value;
      case 'number':
        if (value is String) {
          return num.tryParse(value);
        }
        return value;
      case 'boolean':
        if (value is String) {
          return value.toLowerCase() == 'true';
        }
        return value;
      default:
        return value;
    }
  }
}

/// Represents the complete user data schema
class UserDataSchema {
  final Map<String, dynamic> _schema;
  final Map<String, SchemaField> _flattenedFields = <String, SchemaField>{};
  
  UserDataSchema(this._schema) {
    _flattenSchema();
  }

  /// Load schema from assets file
  static Future<UserDataSchema> load() async {
    try {
      final schemaContent = await rootBundle.loadString('assets/user_data_schema.txt');
      
      // Find the JSON part (after the comments)
      final jsonStart = schemaContent.indexOf('{');
      if (jsonStart == -1) {
        throw Exception('No JSON structure found in schema file');
      }
      
      final jsonContent = schemaContent.substring(jsonStart).trim();
      final schemaMap = json.decode(jsonContent) as Map<String, dynamic>;
      
      return UserDataSchema(schemaMap);
    } catch (e) {
      throw Exception('Failed to load user data schema: $e');
    }
  }

  /// Flatten nested schema into dot notation paths
  void _flattenSchema([String prefix = '', Map<String, dynamic>? schema]) {
    final schemaToProcess = schema ?? _schema;
    
    schemaToProcess.forEach((key, value) {
      final path = prefix.isEmpty ? key : '$prefix.$key';
      
      if (value is String) {
        // This is a field definition (e.g., "string (null) [required]")
        _flattenedFields[path] = SchemaField.parse(value);
      } else if (value is Map<String, dynamic>) {
        // This is a nested structure (map within map)
        // Recursively flatten it
        _flattenSchema(path, value);
      }
    });
  }

  /// Get all field paths in dot notation (in schema order)
  List<String> getFieldPaths() {
    return _flattenedFields.keys.toList();
  }

  /// Get field definition by path
  SchemaField? getField(String path) {
    return _flattenedFields[path];
  }

  /// Get the nested structure of the schema
  Map<String, dynamic> getStructure() {
    return Map<String, dynamic>.from(_schema);
  }

  /// Create a default user data map based on schema
  Map<String, dynamic> createDefaultData() {
    return _buildNestedMap(_schema);
  }

  Map<String, dynamic> _buildNestedMap(Map<String, dynamic> schema) {
    final result = <String, dynamic>{};
    
    schema.forEach((key, value) {
      if (value is String) {
        // This is a field definition
        final field = SchemaField.parse(value);
        result[key] = field.getDefaultValue();
      } else if (value is Map<String, dynamic>) {
        // This is a nested map, recursively build it
        result[key] = _buildNestedMap(value);
      }
    });
    
    return result;
  }

  /// Validate a user data map against the schema
  List<String> validate(Map<String, dynamic> data) {
    final errors = <String>[];
    
    // Check all required fields
    _flattenedFields.forEach((path, field) {
      if (field.isRequired) {
        final value = _getNestedValue(data, path);
        if (value == null) {
          errors.add('Required field "$path" is missing');
        } else if (!field.validateValue(value)) {
          errors.add('Field "$path" has invalid type. Expected ${field.dataType}');
        }
      }
    });
    
    return errors;
  }

  /// Get a nested value using dot notation path
  dynamic _getNestedValue(Map<String, dynamic> data, String path) {
    final keys = path.split('.');
    dynamic current = data;
    
    for (final key in keys) {
      if (current is Map) {
        current = current[key];
      } else {
        return null;
      }
    }
    
    return current;
  }

  /// Set a nested value using dot notation path
  void _setNestedValue(Map<String, dynamic> data, String path, dynamic value) {
    final keys = path.split('.');
    Map<String, dynamic> current = data;
    
    for (int i = 0; i < keys.length - 1; i++) {
      final key = keys[i];
      if (!current.containsKey(key) || current[key] is! Map) {
        current[key] = <String, dynamic>{};
      }
      current = current[key] as Map<String, dynamic>;
    }
    
    current[keys.last] = value;
  }

  /// Migrate existing user data to match the current schema
  /// Preserves existing values, adds new fields with defaults, removes obsolete fields
  Map<String, dynamic> migrateData(Map<String, dynamic> existingData) {
    final migratedData = createDefaultData();
    
    // Copy over existing values that match the schema
    _flattenedFields.forEach((path, field) {
      final existingValue = _getNestedValue(existingData, path);
      if (existingValue != null && field.validateValue(existingValue)) {
        _setNestedValue(migratedData, path, existingValue);
      }
    });
    
    return migratedData;
  }

  /// Get all fields in a specific section (e.g., "accountInformation")
  Map<String, SchemaField> getFieldsInSection(String section) {
    final fields = <String, SchemaField>{};
    
    _flattenedFields.forEach((path, field) {
      if (path.startsWith('$section.')) {
        final fieldName = path.substring(section.length + 1);
        // Only include direct children (no nested dots)
        if (!fieldName.contains('.')) {
          fields[fieldName] = field;
        }
      }
    });
    
    return fields;
  }

  /// Get all top-level sections (in schema order)
  List<String> getSections() {
    return _schema.keys.toList();
  }

  /// Check if a section exists
  bool hasSection(String section) {
    return _schema.containsKey(section);
  }

  /// Get the structure of a specific section
  Map<String, dynamic>? getSectionStructure(String section) {
    return _schema[section] as Map<String, dynamic>?;
  }

  /// Get all fields in a path (including nested maps)
  /// Returns a map where keys are field names and values are either:
  /// - SchemaField for actual fields
  /// - Map<String, dynamic> for nested structures
  Map<String, dynamic> getStructureAtPath(String path) {
    final result = <String, dynamic>{};
    final parts = path.split('.');
    dynamic current = _schema;
    
    // Navigate to the target path
    for (final part in parts) {
      if (current is Map<String, dynamic> && current.containsKey(part)) {
        current = current[part];
      } else {
        return {};
      }
    }
    
    // Process the current level
    if (current is Map<String, dynamic>) {
      current.forEach((key, value) {
        if (value is String) {
          // It's a field definition
          result[key] = SchemaField.parse(value);
        } else if (value is Map<String, dynamic>) {
          // It's a nested structure
          result[key] = value;
        }
      });
    }
    
    return result;
  }

  /// Check if a path represents a nested map structure
  bool isNestedMap(String path) {
    final parts = path.split('.');
    dynamic current = _schema;
    
    for (final part in parts) {
      if (current is Map<String, dynamic> && current.containsKey(part)) {
        current = current[part];
      } else {
        return false;
      }
    }
    
    return current is Map<String, dynamic> && current.values.any((v) => v is Map || v is String);
  }

  /// Convert schema to a readable string format
  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('User Data Schema:');
    buffer.writeln('Total fields: ${_flattenedFields.length}');
    buffer.writeln('Sections: ${getSections().join(", ")}');
    buffer.writeln('\nFields:');
    
    _flattenedFields.forEach((path, field) {
      buffer.writeln('  $path: ${field.dataType} (default: ${field.defaultValue}, required: ${field.isRequired})');
    });
    
    return buffer.toString();
  }
}
