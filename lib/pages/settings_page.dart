import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/styles_schema.dart';
import '../models/user_data.dart';
import '../models/user_data_schema.dart';
import '../services/local_storage_service.dart';

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
  
  bool _isSaving = false;
  bool _isReloadingSchema = false;
  
  UserData? _currentUserData;
  UserDataSchema? _schema;
  String? _uid;
  List<String> _sections = [];

  @override
  void initState() {
    super.initState();
    _loadSchemaAndData();
    LocalStorageService.instance.userDataNotifier.addListener(_onUserDataChanged);
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    LocalStorageService.instance.userDataNotifier.removeListener(_onUserDataChanged);
    super.dispose();
  }

  void _onUserDataChanged() {
    final ud = LocalStorageService.instance.userDataNotifier.value;
    if (!mounted) return;
    setState(() {
      _currentUserData = ud;
    });
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
      });
    } catch (e) {
      if (!mounted) return;
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

  Future<void> _reloadSchema() async {
    if (_isReloadingSchema || _uid == null) return;

    setState(() {
      _isReloadingSchema = true;
    });

    try {
      // Force reload the schema
      await UserData.reloadSchema();
      
      // Clear existing controllers and field values
      for (final controller in _controllers.values) {
        controller.dispose();
      }
      _controllers.clear();
      _fieldValues.clear();
      
      // Reload everything with new schema
      await _loadSchemaAndData();
      
      if (!mounted) return;
      
      setState(() {
        _isReloadingSchema = false;
      });
      
      _showSuccessSnackBar('Schema reloaded successfully!');
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isReloadingSchema = false;
      });
      
      _showErrorSnackBar('Failed to reload schema: $e');
    }
  }

  void _showSaveSuccessDialog() {
    final styles = AppStyles();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(styles.getStyles('register_page.success_dialog.border_radius') as double),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: styles.getStyles('register_page.success_dialog.background_color') as Color,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: styles.getStyles('register_page.success_dialog.icon.color') as Color,
                  size: styles.getStyles('settings_page.success_dialog.icon.width') as double,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Saved!',
                style: TextStyle(
                  fontSize: styles.getStyles('register_page.success_dialog.title.font_size') as double,
                  fontWeight: styles.getStyles('register_page.success_dialog.title.font_weight') as FontWeight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your changes were saved successfully.',
                style: TextStyle(
                  fontSize: styles.getStyles('register_page.success_dialog.message.font_size') as double,
                  color: styles.getStyles('register_page.success_dialog.message.color') as Color,
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
                    backgroundColor: styles.getStyles('register_page.success_dialog.button.background_color') as Color,
                    foregroundColor: styles.getStyles('register_page.success_dialog.button.text.color') as Color,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(styles.getStyles('register_page.success_dialog.button.border_radius') as double),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'OK',
                    style: TextStyle(
                      fontSize: styles.getStyles('register_page.success_dialog.button.text.font_size') as double,
                      fontWeight: styles.getStyles('register_page.success_dialog.button.text.font_weight') as FontWeight,
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
        backgroundColor: styles.getStyles('home_page.logout_button.background_color') as Color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    final styles = AppStyles();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: styles.getStyles('settings_page.save_button.background_color') as Color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();

    return Container(
      color: styles.getStyles('global.background.color') as Color,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'User Data Configuration',
                style: TextStyle(
                  fontSize: styles.getStyles('settings_page.title.font_size') as double,
                  fontWeight: styles.getStyles('settings_page.title.font_weight') as FontWeight,
                  color: styles.getStyles('settings_page.title.color') as Color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Dynamically generated from schema',
                style: TextStyle(
                  fontSize: styles.getStyles('settings_page.subtitle.font_size') as double,
                  fontWeight: styles.getStyles('settings_page.subtitle.font_weight') as FontWeight,
                  color: styles.getStyles('settings_page.subtitle.color') as Color,
                ),
              ),
              const SizedBox(height: 8),

              // Action Buttons Row
              Row(
                children: [
                  // Save Button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveUserData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: styles.getStyles('settings_page.save_button.background_color') as Color,
                        foregroundColor: styles.getStyles('settings_page.save_button.text.color') as Color,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(styles.getStyles('settings_page.save_button.border_radius') as double),
                        ),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: styles.getStyles('settings_page.save_button.progress_indicator.width') as double,
                                  height: styles.getStyles('settings_page.save_button.progress_indicator.height') as double,
                                  child: CircularProgressIndicator(
                                    strokeWidth: styles.getStyles('settings_page.save_button.progress_indicator.stroke_weight') as double,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        styles.getStyles('settings_page.save_button.text.color') as Color),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Saving...',
                                  style: TextStyle(
                                    fontSize: styles.getStyles('settings_page.save_button.text.font_size') as double,
                                    fontWeight: styles.getStyles('settings_page.save_button.text.font_weight') as FontWeight,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: styles.getStyles('settings_page.save_button.text.font_size') as double,
                                fontWeight: styles.getStyles('settings_page.save_button.text.font_weight') as FontWeight,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Reload Schema Button
                  Expanded(
                    flex: 1,
                    child: ElevatedButton.icon(
                      onPressed: _isReloadingSchema ? null : _reloadSchema,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: styles.getStyles('settings_page.subtitle.color') as Color,
                        foregroundColor: styles.getStyles('settings_page.save_button.text.color') as Color,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(styles.getStyles('settings_page.save_button.border_radius') as double),
                        ),
                        elevation: 0,
                      ),
                      icon: _isReloadingSchema
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    styles.getStyles('settings_page.save_button.text.color') as Color),
                              ),
                            )
                          : const Icon(Icons.refresh, size: 20),
                      label: Text(
                        _isReloadingSchema ? 'Reloading...' : 'Reload Schema',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: styles.getStyles('settings_page.save_button.text.font_weight') as FontWeight,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Dynamically build sections
              ..._buildSections(),

              const SizedBox(height: 16),

              // Info Text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: styles.getStyles('settings_page.info_container.background_color') as Color,
                  borderRadius: BorderRadius.circular(styles.getStyles('settings_page.info_container.border_radius') as double),
                  border: Border.all(
                    color: styles.getStyles('settings_page.info_container.border.color') as Color,
                    width: styles.getStyles('settings_page.info_container.border.width') as double,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: styles.getStyles('settings_page.info_container.icon.color') as Color,
                      size: styles.getStyles('settings_page.info_container.icon.width') as double,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'UI is generated from schema. Update assets/schemas/user_data_schema.txt to modify structure.',
                        style: TextStyle(color: styles.getStyles('settings_page.info_container.text.color') as Color),
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
    final styles = AppStyles();
    // Convert camelCase to Title Case
    final displayTitle = _camelCaseToTitle(title);
    
    return Row(
      children: [
        Container(
          width: styles.getStyles('settings_page.section_header.indicator.width') as double,
          height: styles.getStyles('settings_page.section_header.indicator.height') as double,
          decoration: BoxDecoration(
            gradient: styles.getStyles('settings_page.section_header.indicator.background_color') as LinearGradient,
            borderRadius: BorderRadius.circular(styles.getStyles('settings_page.section_header.indicator.border_radius') as double),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          displayTitle,
          style: TextStyle(
            fontSize: styles.getStyles('settings_page.section_header.title.font_size') as double,
            fontWeight: styles.getStyles('settings_page.section_header.title.font_weight') as FontWeight,
            color: styles.getStyles('settings_page.section_header.title.color') as Color,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(String section, Map<String, SchemaField> fields) {
    final styles = AppStyles();
    // Get the full structure including nested maps
    final structure = _schema!.getStructureAtPath(section);
    final fieldWidgets = _buildStructureWidgets(section, structure);
    
    return Container(
      margin: const EdgeInsets.only(left: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: styles.getStyles('settings_page.section_card.background_color') as Color,
        borderRadius: BorderRadius.circular(styles.getStyles('settings_page.section_card.border_radius') as double),
        border: Border.all(
          color: styles.getStyles('settings_page.section_card.border.color') as Color,
          width: styles.getStyles('settings_page.section_card.border.width') as double,
        ),
        boxShadow: [
          BoxShadow(
            color: styles.withOpacity(
              'settings_page.section_card.shadow.color',
              'settings_page.section_card.shadow.opacity',
            ),
            blurRadius: styles.getStyles('settings_page.section_card.shadow.blur_radius') as double,
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
        // If this is a reference field (e.g. "reference (inventory_schema.txt)"),
        // expand it into its referenced structure so it becomes editable in the UI.
        if (value.dataType.toLowerCase() == 'reference') {
          // Resolve the expanded structure for this reference path
          final nestedStructure = _schema!.getStructureAtPath(currentPath);

          widgets.add(_buildNestedMapHeader(key, depth));
          widgets.add(const SizedBox(height: 12));

          final nestedWidgets = _buildStructureWidgets(currentPath, nestedStructure, depth + 1);

          final styles = AppStyles();
          widgets.add(Container(
            margin: EdgeInsets.only(left: (depth + 1) * 16.0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: styles.getStyles('settings_page.nested_container.background_color') as Color,
              borderRadius: BorderRadius.circular(styles.getStyles('settings_page.nested_container.border_radius') as double),
              border: Border.all(
                color: styles.getStyles('settings_page.nested_container.border.color') as Color,
                width: styles.getStyles('settings_page.nested_container.border.width') as double,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: nestedWidgets,
            ),
          ));
        } else {
          // Regular simple field
          widgets.add(_buildField(key, value, currentPath, depth));
        }
      } else if (value is Map<String, dynamic>) {
        // It's a nested map structure.
        widgets.add(_buildNestedMapHeader(key, depth));
        widgets.add(const SizedBox(height: 12));

        // Two possibilities:
        // - The map's values are already SchemaField objects (expanded reference)
        // - The map is a plain nested structure and we should query the schema
        Map<String, dynamic> nestedStructure;
        final hasSchemaFieldValues = value.values.any((v) => v is SchemaField || (v is Map && v.values.any((vv) => vv is SchemaField)));
        if (hasSchemaFieldValues) {
          // Use the inline map directly. Example: inventory -> { itemId: {isLocked: SchemaField, ...}, ... }
          nestedStructure = value.map((k, v) => MapEntry(k, v));
        } else {
          nestedStructure = _schema!.getStructureAtPath(currentPath);
        }

        final nestedWidgets = _buildStructureWidgets(currentPath, nestedStructure, depth + 1);

        final styles = AppStyles();
        widgets.add(Container(
          margin: EdgeInsets.only(left: (depth + 1) * 16.0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: styles.getStyles('settings_page.nested_container.background_color') as Color,
            borderRadius: BorderRadius.circular(styles.getStyles('settings_page.nested_container.border_radius') as double),
            border: Border.all(
              color: styles.getStyles('settings_page.nested_container.border.color') as Color,
              width: styles.getStyles('settings_page.nested_container.border.width') as double,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: nestedWidgets,
          ),
        ));
      }
      
      if (i < keys.length - 1) {
        final styles = AppStyles();
        widgets.add(Divider(
          height: styles.getStyles('settings_page.divider.height') as double,
          color: styles.getStyles('settings_page.divider.color') as Color,
        ));
      }
    }
    
    return widgets;
  }

  Widget _buildNestedMapHeader(String name, int depth) {
    final styles = AppStyles();
    return Padding(
      padding: EdgeInsets.only(left: depth * 16.0),
      child: Row(
        children: [
          Icon(
            Icons.folder_outlined,
            size: styles.getStyles('settings_page.nested_map_header.icon.width') as double,
            color: styles.getStyles('settings_page.nested_map_header.icon.color') as Color,
          ),
          const SizedBox(width: 8),
          Text(
            _camelCaseToTitle(name),
            style: TextStyle(
              fontSize: styles.getStyles('settings_page.nested_map_header.title.font_size') as double,
              fontWeight: styles.getStyles('settings_page.nested_map_header.title.font_weight') as FontWeight,
              color: styles.getStyles('settings_page.nested_map_header.title.color') as Color,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: styles.getStyles('settings_page.nested_map_header.badge.background_color') as Color,
              borderRadius: BorderRadius.circular(styles.getStyles('settings_page.nested_map_header.badge.border_radius') as double),
              border: Border.all(
                color: styles.getStyles('settings_page.nested_map_header.badge.border.color') as Color,
                width: styles.getStyles('settings_page.nested_map_header.badge.border.width') as double,
              ),
            ),
            child: Text(
              'map',
              style: TextStyle(
                fontSize: styles.getStyles('settings_page.nested_map_header.badge.text.font_size') as double,
                fontWeight: styles.getStyles('settings_page.nested_map_header.badge.text.font_weight') as FontWeight,
                color: styles.getStyles('settings_page.nested_map_header.badge.text.color') as Color,
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
    final styles = AppStyles();
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
              color: styles.getStyles('settings_page.text_field.icon.color') as Color,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(styles.getStyles('settings_page.text_field.border_radius') as double),
              borderSide: BorderSide(
                color: styles.getStyles('settings_page.text_field.border.color') as Color,
                width: styles.getStyles('settings_page.text_field.border.width') as double,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(styles.getStyles('settings_page.text_field.border_radius') as double),
              borderSide: BorderSide(
                color: styles.getStyles('settings_page.text_field.border.color') as Color,
                width: styles.getStyles('settings_page.text_field.border.width') as double,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(styles.getStyles('settings_page.text_field.border_radius') as double),
              borderSide: BorderSide(
                color: styles.getStyles('settings_page.text_field.focused_border.color') as Color,
                width: styles.getStyles('settings_page.text_field.focused_border.width') as double,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(styles.getStyles('settings_page.text_field.border_radius') as double),
              borderSide: BorderSide(
                color: styles.getStyles('settings_page.text_field.error_border.color') as Color,
                width: styles.getStyles('settings_page.text_field.error_border.width') as double,
              ),
            ),
            filled: true,
            fillColor: styles.getStyles('settings_page.text_field.background_color') as Color,
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
    final styles = AppStyles();
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
              color: styles.getStyles('settings_page.text_field.icon.color') as Color,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(styles.getStyles('settings_page.text_field.border_radius') as double),
              borderSide: BorderSide(
                color: styles.getStyles('settings_page.text_field.border.color') as Color,
                width: styles.getStyles('settings_page.text_field.border.width') as double,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(styles.getStyles('settings_page.text_field.border_radius') as double),
              borderSide: BorderSide(
                color: styles.getStyles('settings_page.text_field.border.color') as Color,
                width: styles.getStyles('settings_page.text_field.border.width') as double,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(styles.getStyles('settings_page.text_field.border_radius') as double),
              borderSide: BorderSide(
                color: styles.getStyles('settings_page.text_field.focused_border.color') as Color,
                width: styles.getStyles('settings_page.text_field.focused_border.width') as double,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(styles.getStyles('settings_page.text_field.border_radius') as double),
              borderSide: BorderSide(
                color: styles.getStyles('settings_page.text_field.error_border.color') as Color,
                width: styles.getStyles('settings_page.text_field.error_border.width') as double,
              ),
            ),
            filled: true,
            fillColor: styles.getStyles('settings_page.text_field.background_color') as Color,
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
    final styles = AppStyles();
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
                  fontSize: styles.getStyles('settings_page.switch_field.value_text.font_size') as double,
                  color: styles.getStyles('settings_page.switch_field.value_text.color') as Color,
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
          activeTrackColor: styles.getStyles('settings_page.switch_field.active_track_color') as Color,
        ),
      ],
    );
  }

  Widget _buildTimestampField(String fieldName, SchemaField field, String path) {
    final styles = AppStyles();
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
            padding: EdgeInsets.all(styles.getStyles('settings_page.timestamp_field.padding') as double),
            decoration: BoxDecoration(
              color: styles.getStyles('settings_page.timestamp_field.background_color') as Color,
              borderRadius: BorderRadius.circular(styles.getStyles('settings_page.timestamp_field.border_radius') as double),
              border: Border.all(
                color: styles.getStyles('settings_page.timestamp_field.border.color') as Color,
                width: styles.getStyles('settings_page.timestamp_field.border.width') as double,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: styles.getStyles('settings_page.timestamp_field.icon.color') as Color,
                  size: styles.getStyles('settings_page.timestamp_field.icon.size') as double,
                ),
                const SizedBox(width: 4),
                Text(
                  dateTime != null
                      ? '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}'
                      : 'Select date',
                  style: TextStyle(
                    fontSize: styles.getStyles('settings_page.timestamp_field.text.font_size') as double,
                    color: dateTime != null 
                        ? styles.getStyles('settings_page.timestamp_field.text.color') as Color
                        : styles.getStyles('settings_page.timestamp_field.text.placeholder_color') as Color,
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
    final styles = AppStyles();
    final value = _fieldValues[path];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(fieldName, field.dataType, field.isRequired),
        const SizedBox(height: 8),
        Container(
          padding: EdgeInsets.all(styles.getStyles('settings_page.generic_field.padding') as double),
          decoration: BoxDecoration(
            color: styles.getStyles('settings_page.generic_field.background_color') as Color,
            borderRadius: BorderRadius.circular(styles.getStyles('settings_page.generic_field.border_radius') as double),
            border: Border.all(
              color: styles.getStyles('settings_page.generic_field.border.color') as Color,
              width: styles.getStyles('settings_page.generic_field.border.width') as double,
            ),
          ),
          child: Text(
            value?.toString() ?? 'null',
            style: TextStyle(
              fontSize: styles.getStyles('settings_page.generic_field.value_text.font_size') as double,
              color: styles.getStyles('settings_page.generic_field.value_text.color') as Color,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Type "${field.dataType}" is not editable in this UI',
          style: TextStyle(
            fontSize: styles.getStyles('settings_page.generic_field.note_text.font_size') as double,
            color: styles.getStyles('settings_page.generic_field.note_text.color') as Color,
          ),
        ),
      ],
    );
  }

  Widget _buildEnumField(String fieldName, SchemaField field, String path) {
    final styles = AppStyles();
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
              color: styles.getStyles('settings_page.dropdown_field.icon.color') as Color,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(styles.getStyles('settings_page.dropdown_field.border_radius') as double),
              borderSide: BorderSide(
                color: styles.getStyles('settings_page.dropdown_field.border.color') as Color,
                width: styles.getStyles('settings_page.dropdown_field.border.width') as double,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(styles.getStyles('settings_page.dropdown_field.border_radius') as double),
              borderSide: BorderSide(
                color: styles.getStyles('settings_page.dropdown_field.border.color') as Color,
                width: styles.getStyles('settings_page.dropdown_field.border.width') as double,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(styles.getStyles('settings_page.dropdown_field.border_radius') as double),
              borderSide: BorderSide(
                color: styles.getStyles('settings_page.dropdown_field.focused_border.color') as Color,
                width: styles.getStyles('settings_page.dropdown_field.focused_border.width') as double,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(styles.getStyles('settings_page.dropdown_field.border_radius') as double),
              borderSide: BorderSide(
                color: styles.getStyles('settings_page.dropdown_field.error_border.color') as Color,
                width: styles.getStyles('settings_page.dropdown_field.error_border.width') as double,
              ),
            ),
            filled: true,
            fillColor: styles.getStyles('settings_page.dropdown_field.background_color') as Color,
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
    final styles = AppStyles();
    return Row(
      children: [
        Text(
          fieldName,
          style: TextStyle(
            fontSize: styles.getStyles('settings_page.field_label.font_size') as double,
            fontWeight: styles.getStyles('settings_page.field_label.font_weight') as FontWeight,
            color: styles.getStyles('settings_page.field_label.color') as Color,
          ),
        ),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: styles.getStyles('settings_page.field_label.type_badge.background_color') as Color,
            borderRadius: BorderRadius.circular(styles.getStyles('settings_page.field_label.type_badge.border_radius') as double),
            border: Border.all(
              color: styles.getStyles('settings_page.field_label.type_badge.border.color') as Color,
              width: styles.getStyles('settings_page.field_label.type_badge.border.width') as double,
            ),
          ),
          child: Text(
            dataType,
            style: TextStyle(
              fontSize: styles.getStyles('settings_page.field_label.type_badge.text.font_size') as double,
              fontWeight: styles.getStyles('settings_page.field_label.type_badge.text.font_weight') as FontWeight,
              color: styles.getStyles('settings_page.field_label.type_badge.text.color') as Color,
            ),
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: styles.getStyles('settings_page.field_label.required_badge.background_color') as Color,
              borderRadius: BorderRadius.circular(styles.getStyles('settings_page.field_label.required_badge.border_radius') as double),
              border: Border.all(
                color: styles.getStyles('settings_page.field_label.required_badge.border.color') as Color,
                width: styles.getStyles('settings_page.field_label.required_badge.border.width') as double,
              ),
            ),
            child: Text(
              'required',
              style: TextStyle(
                fontSize: styles.getStyles('settings_page.field_label.required_badge.text.font_size') as double,
                fontWeight: styles.getStyles('settings_page.field_label.required_badge.text.font_weight') as FontWeight,
                color: styles.getStyles('settings_page.field_label.required_badge.text.color') as Color,
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
}
