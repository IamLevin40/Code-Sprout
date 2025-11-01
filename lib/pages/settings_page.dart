import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/styles_schema.dart';
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
      
      // Initialize field values and controllers for all fields (including nested)
      final allFieldPaths = _schema!.getFieldPaths();
      for (final path in allFieldPaths) {
        final field = _schema!.getField(path);
        if (field != null) {
          final value = userData?.get(path);
          _fieldValues[path] = value ?? field.getDefaultValue();
          
          // Create text controllers for string and number fields
          if (field.dataType == 'string' || field.dataType == 'number') {
            _controllers[path] = TextEditingController(
              text: value?.toString() ?? field.getDefaultValue()?.toString() ?? '',
            );
          }
        }
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
    final styles = AppStyles();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(styles.getBorderRadius('register_page.success_dialog.border_radius')),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: styles.getColor('register_page.success_dialog.background.color'),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: styles.getColor('register_page.success_dialog.icon.color'),
                  size: 60,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Saved!',
                style: TextStyle(
                  fontSize: styles.getFontSize('register_page.success_dialog.title.font_size'),
                  fontWeight: styles.getFontWeight('register_page.success_dialog.title.font_weight'),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your changes were saved successfully.',
                style: TextStyle(
                  fontSize: styles.getFontSize('register_page.success_dialog.message.font_size'),
                  color: styles.getColor('register_page.success_dialog.message.color'),
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
                    backgroundColor: styles.getColor('register_page.success_dialog.button.background.color'),
                    foregroundColor: styles.getColor('register_page.success_dialog.button.text.color'),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(styles.getBorderRadius('register_page.success_dialog.button.border_radius')),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'OK',
                    style: TextStyle(
                      fontSize: styles.getFontSize('register_page.success_dialog.button.text.font_size'),
                      fontWeight: styles.getFontWeight('register_page.success_dialog.button.text.font_weight'),
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
    final styles = AppStyles();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: styles.getColor('home_page.logout_button.background.color'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final styles = AppStyles();

    return Scaffold(
      backgroundColor: styles.getColor('common.background.color'),
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            fontWeight: styles.getFontWeight('appbar.title.font_weight'),
            color: styles.getColor('appbar.title.color'),
            fontSize: styles.getFontSize('appbar.title.font_size'),
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: styles.getLinearGradient('appbar.background.linear_gradient'),
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: styles.getColor('appbar.icon.color')),
            tooltip: 'Reload Schema',
            onPressed: () async {
              setState(() {
                _isLoading = true;
              });
              await UserData.reloadSchema();
              await _loadSchemaAndData();
              if (!mounted) return;
            },
          ),
          IconButton(
            icon: Icon(Icons.logout, color: styles.getColor('appbar.icon.color')),
            tooltip: 'Logout',
            onPressed: () => _showLogoutDialog(context, authService),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(styles.getColor('appbar.background.linear_gradient.begin.color')),
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
                        fontSize: styles.getFontSize('settings_page.title.font_size'),
                        fontWeight: styles.getFontWeight('settings_page.title.font_weight'),
                        color: styles.getColor('settings_page.title.color'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Dynamically generated from schema',
                      style: TextStyle(
                        fontSize: styles.getFontSize('common.text.secondary.font_size'),
                        color: styles.getColor('common.text.secondary.color'),
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
                          backgroundColor: styles.getColor('settings_page.save_button.background.color'),
                          foregroundColor: styles.getColor('settings_page.save_button.text.color'),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(styles.getBorderRadius('settings_page.save_button.border_radius')),
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
                                          styles.getColor('settings_page.save_button.text.color')),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
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
                              'UI is generated from schema. Update assets/schemas/user_data_schema.txt to modify structure.',
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
    // Get the full structure including nested maps
    final structure = _schema!.getStructureAtPath(section);
    final fieldWidgets = _buildStructureWidgets(section, structure);
    
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

  /// Recursively build widgets for a structure (handles nested maps)
  List<Widget> _buildStructureWidgets(String parentPath, Map<String, dynamic> structure, [int depth = 0]) {
    final widgets = <Widget>[];
    final keys = structure.keys.toList();
    
    for (int i = 0; i < keys.length; i++) {
      final key = keys[i];
      final value = structure[key];
      final currentPath = '$parentPath.$key';
      
      if (value is SchemaField) {
        // It's an actual field
        widgets.add(_buildField(key, value, currentPath, depth));
      } else if (value is Map<String, dynamic>) {
        // It's a nested map structure
        widgets.add(_buildNestedMapHeader(key, depth));
        widgets.add(const SizedBox(height: 12));
        
        // Recursively build nested structure
        final nestedStructure = _schema!.getStructureAtPath(currentPath);
        final nestedWidgets = _buildStructureWidgets(currentPath, nestedStructure, depth + 1);
        
        widgets.add(Container(
          margin: EdgeInsets.only(left: (depth + 1) * 16.0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade200,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: nestedWidgets,
          ),
        ));
      }
      
      if (i < keys.length - 1) {
        widgets.add(Divider(
          height: 24,
          color: Colors.grey.shade200,
        ));
      }
    }
    
    return widgets;
  }

  Widget _buildNestedMapHeader(String name, int depth) {
    return Padding(
      padding: EdgeInsets.only(left: depth * 16.0),
      child: Row(
        children: [
          Icon(
            Icons.folder_outlined,
            size: 18,
            color: Colors.orange.shade600,
          ),
          const SizedBox(width: 8),
          Text(
            _camelCaseToTitle(name),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.orange.shade800,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: Colors.orange.shade200,
              ),
            ),
            child: Text(
              'map',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.orange.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String fieldName, SchemaField field, String path, [int depth = 0]) {
    Widget fieldWidget;
    
    // Check if this is an enum field first
    if (field.isEnum) {
      fieldWidget = _buildEnumField(fieldName, field, path);
    } else {
      switch (field.dataType.toLowerCase()) {
        case 'string':
          fieldWidget = _buildStringField(fieldName, field, path);
          break;
        case 'number':
          fieldWidget = _buildNumberField(fieldName, field, path);
          break;
        case 'boolean':
          fieldWidget = _buildBooleanField(fieldName, field, path);
          break;
        case 'timestamp':
          fieldWidget = _buildTimestampField(fieldName, field, path);
          break;
        default:
          fieldWidget = _buildGenericField(fieldName, field, path);
      }
    }
    
    // Add left padding based on depth
    if (depth > 0) {
      return Padding(
        padding: EdgeInsets.only(left: depth * 16.0),
        child: fieldWidget,
      );
    }
    
    return fieldWidget;
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

  Widget _buildEnumField(String fieldName, SchemaField field, String path) {
    final currentValue = _fieldValues[path] ?? field.defaultValue;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(fieldName, '${field.dataType} (enum)', field.isRequired),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: field.enumValues!.contains(currentValue) ? currentValue : field.enumValues!.first,
          decoration: InputDecoration(
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
          items: field.enumValues!.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          validator: (value) {
            if (field.isRequired && value == null) {
              return '${_camelCaseToTitle(fieldName)} is required';
            }
            if (value != null && !field.enumValues!.contains(value)) {
              return 'Invalid value. Must be one of: ${field.enumValues!.join(", ")}';
            }
            return null;
          },
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _fieldValues[path] = newValue;
              });
            }
          },
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
