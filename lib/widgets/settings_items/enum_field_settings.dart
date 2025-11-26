import 'package:flutter/material.dart';
import 'field_label_settings.dart';

/// A widget for editing enum fields in user settings
class EnumFieldSettings extends StatefulWidget {
  final String fieldName;
  final String displayName;
  final String? currentValue;
  final List<String> allowedValues;
  final bool isEditable;
  final void Function(String value) onSave;
  final VoidCallback? onCancel;

  const EnumFieldSettings({
    super.key,
    required this.fieldName,
    required this.displayName,
    this.currentValue,
    required this.allowedValues,
    this.isEditable = true,
    required this.onSave,
    this.onCancel,
  });

  @override
  State<EnumFieldSettings> createState() => _EnumFieldSettingsState();
}

class _EnumFieldSettingsState extends State<EnumFieldSettings> {
  String? _selectedValue;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.currentValue;
  }

  void _handleSave() {
    if (_selectedValue != null) {
      widget.onSave(_selectedValue!);
      setState(() {
        _isEditing = false;
      });
    }
  }

  void _handleCancel() {
    _selectedValue = widget.currentValue;
    setState(() {
      _isEditing = false;
    });
    widget.onCancel?.call();
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
                FieldLabelSettings(
                  fieldName: widget.displayName,
                  fieldType: 'enum',
                ),
                if (widget.isEditable)
                  _isEditing
                      ? Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: _handleSave,
                              tooltip: 'Save',
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: _handleCancel,
                              tooltip: 'Cancel',
                            ),
                          ],
                        )
                      : IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            setState(() {
                              _isEditing = true;
                            });
                          },
                          tooltip: 'Edit',
                        ),
              ],
            ),
            const SizedBox(height: 12),
            _isEditing
                ? DropdownButtonFormField<String>(
                    value: _selectedValue,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: widget.allowedValues.map((value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedValue = newValue;
                      });
                    },
                    hint: Text('Select ${widget.displayName.toLowerCase()}'),
                  )
                : Text(
                    _selectedValue ?? 'Not set',
                    style: TextStyle(
                      fontSize: 16,
                      color: _selectedValue == null
                          ? Colors.grey
                          : Colors.black87,
                    ),
                  ),
            if (_isEditing) ...[
              const SizedBox(height: 8),
              Text(
                'Available options: ${widget.allowedValues.join(", ")}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
