import 'dart:convert';
import 'package:flutter/services.dart';

/// Represents a single section in the Terms and Conditions
class TermsSection {
  final String title;
  final List<String> content;

  TermsSection({
    required this.title,
    required this.content,
  });

  factory TermsSection.fromJson(Map<String, dynamic> json) {
    return TermsSection(
      title: json['title'] as String? ?? '',
      content: (json['content'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
    };
  }
}

/// Schema loader for Terms and Conditions
class TermsAndConditionsSchema {
  static TermsAndConditionsSchema? _instance;
  
  final List<TermsSection> _sections = [];

  TermsAndConditionsSchema._();

  static TermsAndConditionsSchema get instance {
    _instance ??= TermsAndConditionsSchema._();
    return _instance!;
  }

  /// Load terms and conditions from schema file
  Future<void> loadSchema() async {
    try {
      final String schemaText = await rootBundle.loadString(
        'assets/schemas/terms_and_conditions_schema.txt',
      );
      final Map<String, dynamic> schemaJson = json.decode(schemaText);
      
      _sections.clear();
      
      // Sort sections by key (section_1, section_2, etc.) to maintain order
      final sortedKeys = schemaJson.keys.toList()
        ..sort((a, b) {
          // Extract numbers from section keys for proper sorting
          final aNum = int.tryParse(a.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          final bNum = int.tryParse(b.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          return aNum.compareTo(bNum);
        });
      
      for (final key in sortedKeys) {
        final value = schemaJson[key];
        if (value is Map<String, dynamic>) {
          _sections.add(TermsSection.fromJson(value));
        }
      }
    } catch (e) {
      throw Exception('Failed to load terms and conditions schema: $e');
    }
  }

  /// Get all sections
  List<TermsSection> getSections() {
    return List.unmodifiable(_sections);
  }

  /// Get a specific section by index
  TermsSection? getSection(int index) {
    if (index >= 0 && index < _sections.length) {
      return _sections[index];
    }
    return null;
  }

  /// Get total number of sections
  int getSectionCount() {
    return _sections.length;
  }

  /// Check if schema is loaded
  bool isLoaded() {
    return _sections.isNotEmpty;
  }

  /// Reload schema (useful for testing or updates)
  Future<void> reload() async {
    await loadSchema();
  }
}
