import 'package:flutter/material.dart';
import 'field_label_settings.dart';

/// A widget for editing string fields in user settings
class StringFieldSettings extends StatefulWidget {
  final String fieldName;
  final String displayName;
  final String? currentValue;
  final bool isEditable;
  final bool isPassword;
  final String fieldType;
  final String? Function(String?)? validator;
  final void Function(String value) onSave;
  final VoidCallback? onCancel;

  const StringFieldSettings({
    super.key,
    required this.fieldName,
    required this.displayName,
    this.currentValue,
    this.isEditable = true,
    this.isPassword = false,
    this.fieldType = 'string',
    this.validator,
    required this.onSave,
    this.onCancel,
  });

  @override
  State<StringFieldSettings> createState() => _StringFieldSettingsState();
}

class _StringFieldSettingsState extends State<StringFieldSettings> {
  late TextEditingController _controller;
  bool _isEditing = false;
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentValue ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onSave(_controller.text);
      setState(() {
        _isEditing = false;
      });
    }
  }

  void _handleCancel() {
    _controller.text = widget.currentValue ?? '';
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
                    fieldType: widget.fieldType,
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
                      obscureText: widget.isPassword && _obscurePassword,
                      validator: widget.validator,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText: 'Enter ${widget.displayName.toLowerCase()}',
                        suffixIcon: widget.isPassword
                            ? IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              )
                            : null,
                      ),
                      autofocus: true,
                    )
                  : Text(
                      widget.isPassword
                          ? '••••••••'
                          : (widget.currentValue?.isEmpty ?? true)
                              ? 'Not set'
                              : widget.currentValue!,
                      style: TextStyle(
                        fontSize: 16,
                        color: (widget.currentValue?.isEmpty ?? true)
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
