import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'field_label_settings.dart';

/// A widget for editing number fields in user settings
class NumberFieldSettings extends StatefulWidget {
  final String fieldName;
  final String displayName;
  final num? currentValue;
  final bool isEditable;
  final String? Function(String?)? validator;
  final void Function(num value) onSave;
  final VoidCallback? onCancel;
  final num? minValue;
  final num? maxValue;

  const NumberFieldSettings({
    super.key,
    required this.fieldName,
    required this.displayName,
    this.currentValue,
    this.isEditable = true,
    this.validator,
    required this.onSave,
    this.onCancel,
    this.minValue,
    this.maxValue,
  });

  @override
  State<NumberFieldSettings> createState() => _NumberFieldSettingsState();
}

class _NumberFieldSettingsState extends State<NumberFieldSettings> {
  late TextEditingController _controller;
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.currentValue?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_formKey.currentState?.validate() ?? false) {
      final value = num.tryParse(_controller.text);
      if (value != null) {
        widget.onSave(value);
        setState(() {
          _isEditing = false;
        });
      }
    }
  }

  void _handleCancel() {
    _controller.text = widget.currentValue?.toString() ?? '';
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FieldLabelSettings(
                    fieldName: widget.displayName,
                    fieldType: 'number',
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
                  ? TextFormField(
                      controller: _controller,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^-?\d*\.?\d*'),
                        ),
                      ],
                      validator: widget.validator,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText: 'Enter ${widget.displayName.toLowerCase()}',
                        helperText: widget.minValue != null || widget.maxValue != null
                            ? 'Range: ${widget.minValue ?? "any"} to ${widget.maxValue ?? "any"}'
                            : null,
                      ),
                      autofocus: true,
                    )
                  : Text(
                      widget.currentValue?.toString() ?? 'Not set',
                      style: TextStyle(
                        fontSize: 16,
                        color: widget.currentValue == null
                            ? Colors.grey
                            : Colors.black87,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
