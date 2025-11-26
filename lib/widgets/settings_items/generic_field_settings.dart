import 'package:flutter/material.dart';
import 'field_label_settings.dart';

/// A widget for displaying unsupported or complex field types in user settings
/// This is a read-only display for types that don't have dedicated editors
class GenericFieldSettings extends StatelessWidget {
  final String fieldName;
  final String displayName;
  final String fieldType;
  final dynamic currentValue;
  final String? description;

  const GenericFieldSettings({
    super.key,
    required this.fieldName,
    required this.displayName,
    required this.fieldType,
    this.currentValue,
    this.description,
  });

  String _formatValue() {
    if (currentValue == null) return 'null';
    if (currentValue is Map) {
      return 'Map with ${(currentValue as Map).length} entries';
    }
    if (currentValue is List) {
      return 'List with ${(currentValue as List).length} items';
    }
    return currentValue.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FieldLabelSettings(
                        fieldName: displayName,
                        fieldType: fieldType,
                      ),
                      if (description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          description!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.info_outline,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatValue(),
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[700],
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This field type is not editable in user settings',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
