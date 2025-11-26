import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'field_label_settings.dart';
import '../../models/styles_schema.dart';

/// A widget for editing timestamp fields in user settings
class TimestampFieldSettings extends StatefulWidget {
  final String fieldName;
  final String displayName;
  final Timestamp? currentValue;
  final bool isEditable;
  final void Function(Timestamp value) onSave;
  final VoidCallback? onCancel;

  const TimestampFieldSettings({
    super.key,
    required this.fieldName,
    required this.displayName,
    this.currentValue,
    this.isEditable = true,
    required this.onSave,
    this.onCancel,
  });

  @override
  State<TimestampFieldSettings> createState() => _TimestampFieldSettingsState();
}

class _TimestampFieldSettingsState extends State<TimestampFieldSettings> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.currentValue != null) {
      final dateTime = widget.currentValue!.toDate();
      _selectedDate = dateTime;
      _selectedTime = TimeOfDay.fromDateTime(dateTime);
    }
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _selectTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  void _handleSave() {
    if (_selectedDate != null && _selectedTime != null) {
      final dateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
      widget.onSave(Timestamp.fromDate(dateTime));
      setState(() {
        _isEditing = false;
      });
    }
  }

  void _handleCancel() {
    if (widget.currentValue != null) {
      final dateTime = widget.currentValue!.toDate();
      _selectedDate = dateTime;
      _selectedTime = TimeOfDay.fromDateTime(dateTime);
    } else {
      _selectedDate = null;
      _selectedTime = null;
    }
    setState(() {
      _isEditing = false;
    });
    widget.onCancel?.call();
  }

  String _formatDateTime() {
    if (_selectedDate == null) return 'Not set';

    final date =
        '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
    final time = _selectedTime != null
        ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
        : '00:00';

    return '$date $time';
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
          styles.getStyles('settings_page.timestamp_field.padding') as double,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FieldLabelSettings(
                  fieldName: widget.displayName,
                  fieldType: 'timestamp',
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
                            color: styles.getStyles('settings_page.timestamp_field.icon.color') as Color,
                            size: styles.getStyles('settings_page.timestamp_field.icon.width') as double,
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
            SizedBox(height: styles.getStyles('settings_page.timestamp_field.spacing') as double),
            _isEditing
                ? Container(
                    padding: EdgeInsets.all(
                      styles.getStyles('settings_page.timestamp_field.padding') as double,
                    ),
                    decoration: BoxDecoration(
                      color: styles.getStyles('settings_page.timestamp_field.background_color') as Color,
                      borderRadius: BorderRadius.circular(
                        styles.getStyles('settings_page.timestamp_field.border_radius') as double,
                      ),
                      border: Border.all(
                        color: styles.getStyles('settings_page.timestamp_field.stroke_color') as Color,
                        width: styles.getStyles('settings_page.timestamp_field.border_width') as double,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: styles.getStyles('settings_page.timestamp_field.icon.color') as Color,
                              size: styles.getStyles('settings_page.timestamp_field.icon.width') as double,
                            ),
                            SizedBox(width: styles.getStyles('settings_page.timestamp_field.icon_spacing') as double),
                            Expanded(
                              child: TextButton(
                                onPressed: _selectDate,
                                child: Text(
                                  _selectedDate != null
                                      ? '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'
                                      : 'Select Date',
                                  style: TextStyle(
                                    color: _selectedDate != null
                                        ? styles.getStyles('settings_page.timestamp_field.text.color') as Color
                                        : styles.getStyles('settings_page.timestamp_field.text.placeholder_color') as Color,
                                    fontSize: styles.getStyles('settings_page.timestamp_field.text.font_size') as double,
                                    fontWeight: styles.getStyles('settings_page.timestamp_field.text.font_weight') as FontWeight,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: styles.getStyles('settings_page.timestamp_field.spacing') as double),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              color: styles.getStyles('settings_page.timestamp_field.icon.color') as Color,
                              size: styles.getStyles('settings_page.timestamp_field.icon.width') as double,
                            ),
                            SizedBox(width: styles.getStyles('settings_page.timestamp_field.icon_spacing') as double),
                            Expanded(
                              child: TextButton(
                                onPressed: _selectTime,
                                child: Text(
                                  _selectedTime != null
                                      ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                                      : 'Select Time',
                                  style: TextStyle(
                                    color: _selectedTime != null
                                        ? styles.getStyles('settings_page.timestamp_field.text.color') as Color
                                        : styles.getStyles('settings_page.timestamp_field.text.placeholder_color') as Color,
                                    fontSize: styles.getStyles('settings_page.timestamp_field.text.font_size') as double,
                                    fontWeight: styles.getStyles('settings_page.timestamp_field.text.font_weight') as FontWeight,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : Text(
                    _formatDateTime(),
                    style: TextStyle(
                      fontSize: styles.getStyles('settings_page.timestamp_field.text.font_size') as double,
                      color: _selectedDate == null
                          ? styles.getStyles('settings_page.timestamp_field.text.placeholder_color') as Color
                          : styles.getStyles('settings_page.timestamp_field.text.color') as Color,
                      fontWeight: styles.getStyles('settings_page.timestamp_field.text.font_weight') as FontWeight,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
