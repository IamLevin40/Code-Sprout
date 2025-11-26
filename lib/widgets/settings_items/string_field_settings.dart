import 'package:flutter/material.dart';
import 'field_label_settings.dart';
import '../../models/styles_schema.dart';
import '../../miscellaneous/string_manip_utils.dart';

/// A widget for editing string fields in user settings
class StringFieldSettings extends StatefulWidget {
  final String fieldName;
  final String displayName;
  final String? currentValue;
  final bool isEditable;
  final bool isPassword;
  final String fieldType;
  final bool isRequired;
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
    this.isRequired = false,
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
    final styles = AppStyles();
    
    return Container(
      margin: EdgeInsets.symmetric(
        vertical: (styles.getStyles('settings_page.divider.height') as double) / 3,
      ),
      decoration: BoxDecoration(
        color: styles.getStyles('settings_page.section_card.background_color') as Color,
        borderRadius: BorderRadius.circular(
          styles.getStyles('settings_page.section_card.border_radius') as double,
        ),
        border: Border.all(
          color: styles.getStyles('settings_page.section_card.stroke_color') as Color,
          width: styles.getStyles('settings_page.section_card.border_width') as double,
        ),
        boxShadow: [
          BoxShadow(
            color: (styles.getStyles('settings_page.section_card.shadow.color') as Color)
                .withOpacity((styles.getStyles('settings_page.section_card.shadow.opacity') as double) / 100),
            blurRadius: styles.getStyles('settings_page.section_card.shadow.blur_radius') as double,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(
          styles.getStyles('settings_page.text_field.padding') as double? ?? 16.0,
        ),
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
                    isRequired: widget.isRequired,
                  ),
                  if (widget.isEditable)
                    _isEditing
                        ? Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.check,
                                  color: styles.getStyles('settings_page.text_field.focused_stroke_color') as Color,
                                ),
                                onPressed: _handleSave,
                                tooltip: 'Save',
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.close,
                                  color: styles.getStyles('settings_page.text_field.error_border') as Color,
                                ),
                                onPressed: _handleCancel,
                                tooltip: 'Cancel',
                              ),
                            ],
                          )
                        : IconButton(
                            icon: Icon(
                              Icons.edit,
                              color: styles.getStyles('settings_page.text_field.icon.color') as Color,
                              size: styles.getStyles('settings_page.text_field.icon.width') as double,
                            ),
                            onPressed: () {
                              setState(() {
                                _isEditing = true;
                              });
                            },
                            tooltip: 'Edit',
                          ),
                ],
              ),
              SizedBox(height: styles.getStyles('settings_page.field_label.spacing') as double),
              _isEditing
                  ? TextFormField(
                      controller: _controller,
                      obscureText: widget.isPassword && _obscurePassword,
                      validator: widget.validator,
                      style: TextStyle(
                        color: styles.getStyles('global.text.primary.color') as Color,
                        fontSize: styles.getStyles('global.text.primary.font_size') as double,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: styles.getStyles('settings_page.text_field.background_color') as Color,
                        hintText: 'Enter ${widget.displayName.toLowerCase()}',
                        hintStyle: TextStyle(
                          color: styles.getStyles('global.text.secondary.color') as Color,
                        ),
                        prefixIcon: Icon(
                          StringManipUtils.getIconForField(widget.fieldName),
                          color: styles.getStyles('settings_page.text_field.icon.color') as Color,
                          size: styles.getStyles('settings_page.text_field.icon.width') as double,
                        ),
                        suffixIcon: widget.isPassword
                            ? IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                  color: styles.getStyles('settings_page.text_field.icon.color') as Color,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              )
                            : null,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            styles.getStyles('settings_page.text_field.border_radius') as double,
                          ),
                          borderSide: BorderSide(
                            color: styles.getStyles('settings_page.text_field.normal_stroke_color') as Color,
                            width: styles.getStyles('settings_page.text_field.border_width') as double,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            styles.getStyles('settings_page.text_field.border_radius') as double,
                          ),
                          borderSide: BorderSide(
                            color: styles.getStyles('settings_page.text_field.focused_stroke_color') as Color,
                            width: styles.getStyles('settings_page.text_field.border_width') as double,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            styles.getStyles('settings_page.text_field.border_radius') as double,
                          ),
                          borderSide: BorderSide(
                            color: styles.getStyles('settings_page.text_field.error_border') as Color,
                            width: styles.getStyles('settings_page.text_field.border_width') as double,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            styles.getStyles('settings_page.text_field.border_radius') as double,
                          ),
                          borderSide: BorderSide(
                            color: styles.getStyles('settings_page.text_field.error_border') as Color,
                            width: styles.getStyles('settings_page.text_field.border_width') as double,
                          ),
                        ),
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
                        fontSize: styles.getStyles('global.text.primary.font_size') as double,
                        color: (widget.currentValue?.isEmpty ?? true)
                            ? styles.getStyles('global.text.secondary.color') as Color
                            : styles.getStyles('global.text.primary.color') as Color,
                        fontWeight: styles.getStyles('global.text.primary.font_weight') as FontWeight,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
