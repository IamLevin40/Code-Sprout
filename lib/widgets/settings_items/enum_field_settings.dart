import 'package:flutter/material.dart';
import 'field_label_settings.dart';
import '../../models/styles_schema.dart';

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
                .withValues(alpha: (styles.getStyles('settings_page.section_card.shadow.opacity') as double) / 100),
            blurRadius: styles.getStyles('settings_page.section_card.shadow.blur_radius') as double,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(
          styles.getStyles('settings_page.dropdown_field.padding') as double? ?? 16.0,
        ),
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
                              icon: Icon(
                                Icons.check,
                                color: styles.getStyles('settings_page.dropdown_field.focused_stroke_color') as Color,
                              ),
                              onPressed: _handleSave,
                              tooltip: 'Save',
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.close,
                                color: styles.getStyles('settings_page.dropdown_field.error_border') as Color,
                              ),
                              onPressed: _handleCancel,
                              tooltip: 'Cancel',
                            ),
                          ],
                        )
                      : IconButton(
                          icon: Icon(
                            Icons.edit,
                            color: styles.getStyles('settings_page.dropdown_field.icon.color') as Color,
                            size: styles.getStyles('settings_page.dropdown_field.icon.width') as double,
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
                ? DropdownButtonFormField<String>(
                    initialValue: _selectedValue,
                    style: TextStyle(
                      color: styles.getStyles('global.text.primary.color') as Color,
                      fontSize: styles.getStyles('global.text.primary.font_size') as double,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: styles.getStyles('settings_page.dropdown_field.background_color') as Color,
                      prefixIcon: Icon(
                        Icons.arrow_drop_down_circle,
                        color: styles.getStyles('settings_page.dropdown_field.icon.color') as Color,
                        size: styles.getStyles('settings_page.dropdown_field.icon.width') as double,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          styles.getStyles('settings_page.dropdown_field.border_radius') as double,
                        ),
                        borderSide: BorderSide(
                          color: styles.getStyles('settings_page.dropdown_field.normal_stroke_color') as Color,
                          width: styles.getStyles('settings_page.dropdown_field.border_width') as double,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          styles.getStyles('settings_page.dropdown_field.border_radius') as double,
                        ),
                        borderSide: BorderSide(
                          color: styles.getStyles('settings_page.dropdown_field.focused_stroke_color') as Color,
                          width: styles.getStyles('settings_page.dropdown_field.border_width') as double,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          styles.getStyles('settings_page.dropdown_field.border_radius') as double,
                        ),
                        borderSide: BorderSide(
                          color: styles.getStyles('settings_page.dropdown_field.error_border') as Color,
                          width: styles.getStyles('settings_page.dropdown_field.border_width') as double,
                        ),
                      ),
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
                    hint: Text(
                      'Select ${widget.displayName.toLowerCase()}',
                      style: TextStyle(
                        color: styles.getStyles('global.text.secondary.color') as Color,
                      ),
                    ),
                  )
                : Text(
                    _selectedValue ?? 'Not set',
                    style: TextStyle(
                      fontSize: styles.getStyles('global.text.primary.font_size') as double,
                      color: _selectedValue == null
                          ? styles.getStyles('global.text.secondary.color') as Color
                          : styles.getStyles('global.text.primary.color') as Color,
                      fontWeight: styles.getStyles('global.text.primary.font_weight') as FontWeight,
                    ),
                  ),
            if (_isEditing) ...[
              SizedBox(height: (styles.getStyles('settings_page.field_label.spacing') as double) / 2),
              Text(
                'Available options: ${widget.allowedValues.join(", ")}',
                style: TextStyle(
                  fontSize: styles.getStyles('global.text.primary.font_size') as double,
                  color: styles.getStyles('global.text.secondary.color') as Color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
