import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_data.dart';
import '../models/user_data_schema.dart';

/// Settings page for user data manipulation and testing
/// Dynamically renders UI based on the schema definition
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, dynamic> _fieldValues = {};
  
  bool _isLoading = true;
  bool _isSaving = false;
  
  UserData? _currentUserData;
  UserDataSchema? _schema;
  String? _uid;
  List<String> _sections = [];

  @override
  void initState() {
    super.initState();
    _loadSchemaAndData();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSchemaAndData() async {
    final authService = AuthService();
    _uid = authService.currentUser?.uid;
    
    if (_uid == null) {
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
      }
      return;
    }

    try {
      // Load schema first
      _schema = await UserData.getSchema();
      _sections = _schema!.getSections();
      
      // Load user data
      final userData = await FirestoreService.getUserData(_uid!);
      if (!mounted) return;
      
      // Initialize field values and controllers
      for (final section in _sections) {
        final fields = _schema!.getFieldsInSection(section);
        fields.forEach((fieldName, schemaField) {
          final path = '$section.$fieldName';
          final value = userData?.get(path);
          _fieldValues[path] = value ?? schemaField.getDefaultValue();
          
          // Create text controllers for string and number fields
          if (schemaField.dataType == 'string' || schemaField.dataType == 'number') {
            _controllers[path] = TextEditingController(
              text: value?.toString() ?? schemaField.getDefaultValue()?.toString() ?? '',
            );
          }
        });
      }
      
      setState(() {
        _currentUserData = userData;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load user data: $e');
    }
  }

  Future<void> _saveUserData() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isSaving) return;

    if (_uid == null || _currentUserData == null || _schema == null) {
      _showErrorSnackBar('No user loaded to save. Please reload the page.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Build update map from current field values
      final updates = <String, dynamic>{};
      _fieldValues.forEach((path, value) {
        updates[path] = value;
      });
      
      // Create updated user data
      var updatedUserData = _currentUserData!.copyWith(updates);
      
      // IMPORTANT: Migrate to ensure schema structure is enforced
      // This removes obsolete fields and ensures the data matches current schema
      updatedUserData = await updatedUserData.migrate();
      
      // Validate before saving
      final errors = await updatedUserData.validate();
      if (errors.isNotEmpty) {
        throw Exception('Validation failed: ${errors.join(", ")}');
      }

      // Update using FirestoreService
      await FirestoreService.updateUserData(updatedUserData);

      if (!mounted) return;
      
      setState(() {
        _currentUserData = updatedUserData;
        _isSaving = false;
      });
      
      await Future.delayed(const Duration(milliseconds: 50));
      
      if (!mounted) return;
      
      _showSaveSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isSaving = false;
      });
      
      _showErrorSnackBar('Failed to save user data: $e');
    }
  }

  void _showSaveSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green.shade600,
                  size: 60,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Saved!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your changes were saved successfully.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green.shade600,
                Colors.purple.shade600,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Reload Schema',
            onPressed: () async {
              setState(() {
                _isLoading = true;
              });
              await UserData.reloadSchema();
              await _loadSchemaAndData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Schema reloaded successfully'),
                    backgroundColor: Colors.green.shade600,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () => _showLogoutDialog(context, authService),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      'User Data Configuration',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Dynamically generated from schema',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Dynamically build sections
                    ..._buildSections(),

                    const SizedBox(height: 40),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveUserData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.0,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Saving...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Info Text
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'UI is generated from schema. Update assets/user_data_schema.txt to modify structure.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  List<Widget> _buildSections() {
    final widgets = <Widget>[];
    
    for (int i = 0; i < _sections.length; i++) {
      final section = _sections[i];
      final fields = _schema!.getFieldsInSection(section);
      
      widgets.add(_buildSectionHeader(section));
      widgets.add(const SizedBox(height: 16));
      widgets.add(_buildSectionCard(section, fields));
      
      if (i < _sections.length - 1) {
        widgets.add(const SizedBox(height: 32));
      }
    }
    
    return widgets;
  }

  Widget _buildSectionHeader(String title) {
    // Convert camelCase to Title Case
    final displayTitle = _camelCaseToTitle(title);
    
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green.shade600,
                Colors.purple.shade600,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          displayTitle,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(String section, Map<String, SchemaField> fields) {
    final fieldWidgets = <Widget>[];
    final fieldNames = fields.keys.toList()..sort();
    
    for (int i = 0; i < fieldNames.length; i++) {
      final fieldName = fieldNames[i];
      final field = fields[fieldName]!;
      final path = '$section.$fieldName';
      
      fieldWidgets.add(_buildField(fieldName, field, path));
      
      if (i < fieldNames.length - 1) {
        fieldWidgets.add(Divider(
          height: 32,
          color: Colors.grey.shade200,
        ));
      }
    }
    
    return Container(
      margin: const EdgeInsets.only(left: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: fieldWidgets,
      ),
    );
  }

  Widget _buildField(String fieldName, SchemaField field, String path) {
    switch (field.dataType.toLowerCase()) {
      case 'string':
        return _buildStringField(fieldName, field, path);
      case 'number':
        return _buildNumberField(fieldName, field, path);
      case 'boolean':
        return _buildBooleanField(fieldName, field, path);
      case 'timestamp':
        return _buildTimestampField(fieldName, field, path);
      default:
        return _buildGenericField(fieldName, field, path);
    }
  }

  Widget _buildStringField(String fieldName, SchemaField field, String path) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(fieldName, field.dataType, field.isRequired),
        const SizedBox(height: 8),
        TextFormField(
          controller: _controllers[path],
          decoration: InputDecoration(
            hintText: 'Enter ${_camelCaseToTitle(fieldName).toLowerCase()}',
            prefixIcon: Icon(
              _getIconForField(fieldName),
              color: Colors.grey.shade600,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.green.shade600,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.red.shade400,
              ),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: (value) {
            if (field.isRequired && (value == null || value.trim().isEmpty)) {
              return '${_camelCaseToTitle(fieldName)} is required';
            }
            return null;
          },
          onChanged: (value) {
            _fieldValues[path] = value;
          },
        ),
      ],
    );
  }

  Widget _buildNumberField(String fieldName, SchemaField field, String path) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(fieldName, field.dataType, field.isRequired),
        const SizedBox(height: 8),
        TextFormField(
          controller: _controllers[path],
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter ${_camelCaseToTitle(fieldName).toLowerCase()}',
            prefixIcon: Icon(
              Icons.numbers,
              color: Colors.grey.shade600,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.green.shade600,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.red.shade400,
              ),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: (value) {
            if (field.isRequired && (value == null || value.trim().isEmpty)) {
              return '${_camelCaseToTitle(fieldName)} is required';
            }
            if (value != null && value.isNotEmpty && num.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
          onChanged: (value) {
            final numValue = num.tryParse(value);
            _fieldValues[path] = numValue ?? value;
          },
        ),
      ],
    );
  }

  Widget _buildBooleanField(String fieldName, SchemaField field, String path) {
    final value = _fieldValues[path] as bool? ?? false;
    
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFieldLabel(fieldName, field.dataType, field.isRequired),
              const SizedBox(height: 4),
              Text(
                value ? 'true' : 'false',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: (newValue) {
            setState(() {
              _fieldValues[path] = newValue;
            });
          },
          activeTrackColor: Colors.green.shade600,
        ),
      ],
    );
  }

  Widget _buildTimestampField(String fieldName, SchemaField field, String path) {
    final value = _fieldValues[path];
    DateTime? dateTime;
    
    if (value is Timestamp) {
      dateTime = value.toDate();
    } else if (value is DateTime) {
      dateTime = value;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(fieldName, field.dataType, field.isRequired),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: dateTime ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            
            if (picked != null) {
              setState(() {
                _fieldValues[path] = Timestamp.fromDate(picked);
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade300,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 12),
                Text(
                  dateTime != null
                      ? '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}'
                      : 'Select date',
                  style: TextStyle(
                    color: dateTime != null ? Colors.grey.shade800 : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenericField(String fieldName, SchemaField field, String path) {
    final value = _fieldValues[path];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(fieldName, field.dataType, field.isRequired),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade300,
            ),
          ),
          child: Text(
            value?.toString() ?? 'null',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Type "${field.dataType}" is not editable in this UI',
          style: TextStyle(
            fontSize: 11,
            color: Colors.orange.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String fieldName, String dataType, bool isRequired) {
    return Row(
      children: [
        Text(
          fieldName,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Colors.purple.shade200,
            ),
          ),
          child: Text(
            dataType,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.purple.shade700,
            ),
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: Colors.red.shade200,
              ),
            ),
            child: Text(
              'required',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.red.shade700,
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _camelCaseToTitle(String text) {
    // Convert camelCase to Title Case
    final result = text.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(0)}',
    ).trim();
    return result[0].toUpperCase() + result.substring(1);
  }

  IconData _getIconForField(String fieldName) {
    final lower = fieldName.toLowerCase();
    if (lower.contains('username') || lower.contains('name')) {
      return Icons.person_outline;
    } else if (lower.contains('email')) {
      return Icons.email_outlined;
    } else if (lower.contains('phone')) {
      return Icons.phone_outlined;
    } else if (lower.contains('address')) {
      return Icons.location_on_outlined;
    } else if (lower.contains('age')) {
      return Icons.cake_outlined;
    } else {
      return Icons.text_fields;
    }
  }

  void _showLogoutDialog(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(
            color: Color(0xFF718096),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await authService.signOut();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade500,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Logout',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
