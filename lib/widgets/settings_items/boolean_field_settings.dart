import 'package:flutter/material.dart';
import 'field_label_settings.dart';

/// A widget for editing boolean fields in user settings
class BooleanFieldSettings extends StatefulWidget {
  final String fieldName;
  final String displayName;
  final bool currentValue;
  final bool isEditable;
  final void Function(bool value) onSave;
  final String? description;

  const BooleanFieldSettings({
    super.key,
    required this.fieldName,
    required this.displayName,
    required this.currentValue,
    this.isEditable = true,
    required this.onSave,
    this.description,
  });

  @override
  State<BooleanFieldSettings> createState() => _BooleanFieldSettingsState();
}

class _BooleanFieldSettingsState extends State<BooleanFieldSettings> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.currentValue;
  }

  void _handleChange(bool newValue) {
    if (widget.isEditable) {
      setState(() {
        _value = newValue;
      });
      widget.onSave(newValue);
    }
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
                        fieldName: widget.displayName,
                        fieldType: 'boolean',
                      ),
                      if (widget.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.description!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Switch(
                  value: _value,
                  onChanged: widget.isEditable ? _handleChange : null,
                  activeColor: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
