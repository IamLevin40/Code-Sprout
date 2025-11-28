import 'package:flutter/material.dart';
import 'field_label_settings.dart';
import '../../models/styles_schema.dart';

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
          styles.getStyles('settings_page.generic_field.padding') as double,
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
                        fieldName: displayName,
                        fieldType: fieldType,
                      ),
                      if (description != null) ...[
                        SizedBox(height: styles.getStyles('settings_page.generic_field.note_spacing') as double),
                        Text(
                          description!,
                          style: TextStyle(
                            fontSize: styles.getStyles('settings_page.generic_field.note_text.font_size') as double,
                            color: styles.getStyles('settings_page.generic_field.note_text.color') as Color,
                            fontWeight: styles.getStyles('settings_page.generic_field.note_text.font_weight') as FontWeight,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.info_outline,
                  color: styles.getStyles('global.text.secondary.color') as Color,
                  size: 20,
                ),
              ],
            ),
            SizedBox(height: styles.getStyles('settings_page.generic_field.spacing') as double),
            Container(
              padding: EdgeInsets.all(
                styles.getStyles('settings_page.generic_field.padding') as double,
              ),
              decoration: BoxDecoration(
                color: styles.getStyles('settings_page.generic_field.background_color') as Color,
                borderRadius: BorderRadius.circular(
                  styles.getStyles('settings_page.generic_field.border_radius') as double,
                ),
                border: Border.all(
                  color: styles.getStyles('settings_page.generic_field.stroke_color') as Color,
                  width: styles.getStyles('settings_page.generic_field.border_width') as double,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatValue(),
                      style: TextStyle(
                        fontSize: styles.getStyles('settings_page.generic_field.value_text.font_size') as double,
                        color: styles.getStyles('settings_page.generic_field.value_text.color') as Color,
                        fontWeight: styles.getStyles('settings_page.generic_field.value_text.font_weight') as FontWeight,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: styles.getStyles('settings_page.generic_field.note_spacing') as double),
            Text(
              'This field type is not editable in user settings',
              style: TextStyle(
                fontSize: styles.getStyles('settings_page.generic_field.note_text.font_size') as double,
                color: styles.getStyles('settings_page.generic_field.note_text.color') as Color,
                fontWeight: styles.getStyles('settings_page.generic_field.note_text.font_weight') as FontWeight,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
