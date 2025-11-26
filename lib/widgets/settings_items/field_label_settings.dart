import 'package:flutter/material.dart';

/// A reusable field label widget that displays the field name and its type
class FieldLabelSettings extends StatelessWidget {
  final String fieldName;
  final String fieldType;
  final bool showTypeBadge;

  const FieldLabelSettings({
    super.key,
    required this.fieldName,
    required this.fieldType,
    this.showTypeBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          fieldName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        if (showTypeBadge) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getTypeColor(fieldType).withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              fieldType,
              style: TextStyle(
                fontSize: 11,
                color: _getTypeColor(fieldType),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'string':
        return Colors.blue;
      case 'number':
        return Colors.green;
      case 'boolean':
        return Colors.orange;
      case 'timestamp':
        return Colors.purple;
      case 'enum':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}
