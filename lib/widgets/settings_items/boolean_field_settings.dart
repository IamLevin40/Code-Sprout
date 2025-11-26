import 'package:flutter/material.dart';
import 'field_label_settings.dart';
import '../../models/styles_schema.dart';

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
          styles.getStyles('settings_page.text_field.padding') as double? ?? 16.0,
        ),
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
                        SizedBox(height: (styles.getStyles('settings_page.field_label.spacing') as double) / 2),
                        Text(
                          widget.description!,
                          style: TextStyle(
                            fontSize: styles.getStyles('global.text.primary.font_size') as double,
                            color: styles.getStyles('global.text.secondary.color') as Color,
                            fontWeight: styles.getStyles('global.text.primary.font_weight') as FontWeight,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Row(
                  children: [
                    Text(
                      _value ? 'On' : 'Off',
                      style: TextStyle(
                        fontSize: styles.getStyles('settings_page.switch_field.value_text.font_size') as double,
                        fontWeight: styles.getStyles('settings_page.switch_field.value_text.font_weight') as FontWeight,
                        color: styles.getStyles('settings_page.switch_field.value_text.color') as Color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: _value,
                      onChanged: widget.isEditable ? _handleChange : null,
                      activeThumbColor: styles.getStyles('settings_page.switch_field.active_track_color') as Color,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
