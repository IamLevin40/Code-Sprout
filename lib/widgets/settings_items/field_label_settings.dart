import 'package:flutter/material.dart';
import '../../models/styles_schema.dart';

/// A reusable field label widget that displays the field name and its type
class FieldLabelSettings extends StatelessWidget {
  final String fieldName;
  final String fieldType;
  final bool showTypeBadge;
  final bool isRequired;

  const FieldLabelSettings({
    super.key,
    required this.fieldName,
    required this.fieldType,
    this.showTypeBadge = true,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();
    
    return Row(
      children: [
        Text(
          fieldName,
          style: TextStyle(
            fontWeight: styles.getStyles('settings_page.field_label.font_weight') as FontWeight,
            fontSize: styles.getStyles('settings_page.field_label.font_size') as double,
            color: styles.getStyles('settings_page.field_label.color') as Color,
          ),
        ),
        if (showTypeBadge) ...[
          SizedBox(width: styles.getStyles('settings_page.field_label.spacing') as double),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: styles.getStyles('settings_page.field_label.type_badge.padding_horizontal') as double,
              vertical: styles.getStyles('settings_page.field_label.type_badge.padding_vertical') as double,
            ),
            decoration: BoxDecoration(
              color: styles.getStyles('settings_page.field_label.type_badge.background_color') as Color,
              borderRadius: BorderRadius.circular(
                styles.getStyles('settings_page.field_label.type_badge.border_radius') as double,
              ),
              border: Border.all(
                color: styles.getStyles('settings_page.field_label.type_badge.stroke_color') as Color,
                width: styles.getStyles('settings_page.field_label.type_badge.border_width') as double,
              ),
            ),
            child: Text(
              fieldType,
              style: TextStyle(
                fontSize: styles.getStyles('settings_page.field_label.type_badge.text.font_size') as double,
                color: styles.getStyles('settings_page.field_label.type_badge.text.color') as Color,
                fontWeight: styles.getStyles('settings_page.field_label.type_badge.text.font_weight') as FontWeight,
              ),
            ),
          ),
        ],
        if (isRequired) ...[
          SizedBox(width: styles.getStyles('settings_page.field_label.required_spacing') as double),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: styles.getStyles('settings_page.field_label.required_badge.padding_horizontal') as double,
              vertical: styles.getStyles('settings_page.field_label.required_badge.padding_vertical') as double,
            ),
            decoration: BoxDecoration(
              color: styles.getStyles('settings_page.field_label.required_badge.background_color') as Color,
              borderRadius: BorderRadius.circular(
                styles.getStyles('settings_page.field_label.required_badge.border_radius') as double,
              ),
              border: Border.all(
                color: styles.getStyles('settings_page.field_label.required_badge.stroke_color') as Color,
                width: styles.getStyles('settings_page.field_label.required_badge.border_width') as double,
              ),
            ),
            child: Text(
              'required',
              style: TextStyle(
                fontSize: styles.getStyles('settings_page.field_label.required_badge.text.font_size') as double,
                color: styles.getStyles('settings_page.field_label.required_badge.text.color') as Color,
                fontWeight: styles.getStyles('settings_page.field_label.required_badge.text.font_weight') as FontWeight,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
