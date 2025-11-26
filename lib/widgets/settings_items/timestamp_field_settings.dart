import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'field_label_settings.dart';

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
                  fieldType: 'timestamp',
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
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                _selectedDate != null
                                    ? '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'
                                    : 'Select Date',
                              ),
                              onPressed: _selectDate,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.access_time),
                              label: Text(
                                _selectedTime != null
                                    ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                                    : 'Select Time',
                              ),
                              onPressed: _selectTime,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Text(
                    _formatDateTime(),
                    style: TextStyle(
                      fontSize: 16,
                      color: _selectedDate == null
                          ? Colors.grey
                          : Colors.black87,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
