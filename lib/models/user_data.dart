import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_data_schema.dart';

/// UserData model class that represents user information stored in Firestore.
/// This class is dynamically driven by the schema defined in assets/schemas/user_data_schema.txt
/// 
/// The structure automatically adapts to changes in the schema file, allowing
/// for flexible data management without code changes.

class UserData {
  final String uid;
  final Map<String, dynamic> _data;
  static UserDataSchema? _cachedSchema;

  UserData({
    required this.uid,
    required Map<String, dynamic> data,
  }) : _data = Map<String, dynamic>.from(data);

  /// Get the schema (loads once and caches)
  static Future<UserDataSchema> _getSchema() async {
    _cachedSchema ??= await UserDataSchema.load();
    return _cachedSchema!;
  }

  /// Force reload the schema (useful after schema updates)
  static Future<void> reloadSchema() async {
    _cachedSchema = await UserDataSchema.load();
  }

  // Reference to Firestore users collection
  static CollectionReference get _usersCollection =>
      FirebaseFirestore.instance.collection('users');

  /// Create UserData from Firestore document snapshot
  factory UserData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    
    if (data == null) {
      throw Exception('Document data is null');
    }

    return UserData(
      uid: doc.id,
      data: data,
    );
  }

  /// Create a new UserData instance with default values from schema
  static Future<UserData> createDefault(String uid) async {
    final schema = await _getSchema();
    final defaultData = schema.createDefaultData();
    
    return UserData(
      uid: uid,
      data: defaultData,
    );
  }

  /// Create UserData with required fields (for registration)
  static Future<UserData> create({
    required String uid,
    Map<String, dynamic>? initialData,
  }) async {
    final schema = await _getSchema();
    final data = schema.createDefaultData();
    
    // Override with initial data if provided
    if (initialData != null) {
      _mergeData(data, initialData);
    }
    
    // Validate required fields
    final errors = schema.validate(data);
    if (errors.isNotEmpty) {
      throw Exception('Validation failed: ${errors.join(", ")}');
    }
    
    return UserData(
      uid: uid,
      data: data,
    );
  }

  /// Merge source data into target data recursively
  static void _mergeData(Map<String, dynamic> target, Map<String, dynamic> source) {
    source.forEach((key, value) {
      if (value is Map<String, dynamic> && target[key] is Map<String, dynamic>) {
        _mergeData(target[key] as Map<String, dynamic>, value);
      } else {
        target[key] = value;
      }
    });
  }

  /// Convert UserData to Firestore document format
  Map<String, dynamic> toFirestore() {
    return Map<String, dynamic>.from(_data);
  }

  /// Convert UserData to JSON for local storage
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      ..._data,
    };
  }

  /// Create UserData from JSON (for local storage)
  factory UserData.fromJson(Map<String, dynamic> json) {
    final uid = json['uid'] as String;
    final data = Map<String, dynamic>.from(json);
    data.remove('uid');
    
    return UserData(
      uid: uid,
      data: data,
    );
  }

  /// Get a value using dot notation path (e.g., "accountInformation.username")
  dynamic get(String path) {
    final keys = path.split('.');
    dynamic current = _data;
    
    for (final key in keys) {
      if (current is Map) {
        current = current[key];
      } else {
        return null;
      }
    }
    
    return current;
  }

  /// Set a value using dot notation path
  void set(String path, dynamic value) {
    final keys = path.split('.');
    Map<String, dynamic> current = _data;
    
    for (int i = 0; i < keys.length - 1; i++) {
      final key = keys[i];
      if (!current.containsKey(key) || current[key] is! Map) {
        current[key] = <String, dynamic>{};
      }
      current = current[key] as Map<String, dynamic>;
    }
    
    current[keys.last] = value;
  }

  /// Get all data as a flat map with dot notation keys
  Future<Map<String, dynamic>> getFlattenedData() async {
    final schema = await _getSchema();
    final flattened = <String, dynamic>{};
    
    for (final path in schema.getFieldPaths()) {
      flattened[path] = get(path);
    }
    
    return flattened;
  }

  /// Update data from a flat map with dot notation keys
  Future<void> updateFromFlattened(Map<String, dynamic> flatData) async {
    final schema = await _getSchema();
    
    flatData.forEach((path, value) {
      final field = schema.getField(path);
      if (field != null && field.validateValue(value)) {
        set(path, value);
      }
    });
  }

  /// Validate the current data against the schema
  Future<List<String>> validate() async {
    final schema = await _getSchema();
    return schema.validate(_data);
  }

  /// Migrate data to match current schema (preserves existing values)
  Future<UserData> migrate() async {
    final schema = await _getSchema();
    final migratedData = schema.migrateData(_data);
    
    return UserData(
      uid: uid,
      data: migratedData,
    );
  }

  /// Save user data to Firestore (creates or updates document)
  Future<void> save() async {
    try {
      // Validate before saving
      final errors = await validate();
      if (errors.isNotEmpty) {
        throw Exception('Validation failed: ${errors.join(", ")}');
      }
      
      await _usersCollection.doc(uid).set(toFirestore());
    } catch (e) {
      throw Exception('Failed to save user data: $e');
    }
  }

  /// Load user data from Firestore by UID
  static Future<UserData?> load(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      
      if (!doc.exists) {
        return null;
      }

      final userData = UserData.fromFirestore(doc);
      
      // Automatically migrate if needed
      final schema = await _getSchema();
      final errors = schema.validate(userData._data);
      
      if (errors.isNotEmpty) {
        // Data doesn't match schema, migrate it
        final migratedUserData = await userData.migrate();
        await migratedUserData.save();
        return migratedUserData;
      }
      
      return userData;
    } catch (e) {
      throw Exception('Failed to load user data: $e');
    }
  }

  /// Generic get method for any field using path
  static Future<dynamic> getField(String uid, String path) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      
      if (!doc.exists) {
        return null;
      }

      final userData = UserData.fromFirestore(doc);
      return userData.get(path);
    } catch (e) {
      throw Exception('Failed to get field $path: $e');
    }
  }

  /// Generic update method for any field using path
  Future<void> updateField(String path, dynamic value) async {
    try {
      final schema = await _getSchema();
      final field = schema.getField(path);
      
      if (field == null) {
        throw Exception('Field $path does not exist in schema');
      }
      
      if (!field.validateValue(value)) {
        throw Exception('Invalid value for field $path. Expected ${field.dataType}');
      }
      
      // Convert to Firestore path (with dots)
      await _usersCollection.doc(uid).update({
        path: field.toFirestoreValue(value),
      });
    } catch (e) {
      throw Exception('Failed to update field $path: $e');
    }
  }

  /// Batch update multiple fields
  Future<void> updateFields(Map<String, dynamic> updates) async {
    try {
      final schema = await _getSchema();
      final firestoreUpdates = <String, dynamic>{};
      
      updates.forEach((path, value) {
        final field = schema.getField(path);
        if (field == null) {
          throw Exception('Field $path does not exist in schema');
        }
        
        if (!field.validateValue(value)) {
          throw Exception('Invalid value for field $path. Expected ${field.dataType}');
        }
        
        firestoreUpdates[path] = field.toFirestoreValue(value);
      });
      
      await _usersCollection.doc(uid).update(firestoreUpdates);
    } catch (e) {
      throw Exception('Failed to update fields: $e');
    }
  }

  /// Create a copy of UserData with updated fields
  UserData copyWith(Map<String, dynamic> updates) {
    final newData = Map<String, dynamic>.from(_data);
    
    updates.forEach((path, value) {
      final keys = path.split('.');
      Map<String, dynamic> current = newData;
      
      for (int i = 0; i < keys.length - 1; i++) {
        final key = keys[i];
        if (!current.containsKey(key) || current[key] is! Map) {
          current[key] = <String, dynamic>{};
        }
        current = current[key] as Map<String, dynamic>;
      }
      
      current[keys.last] = value;
    });
    
    return UserData(
      uid: uid,
      data: newData,
    );
  }

  /// Get all available field paths from schema
  static Future<List<String>> getAvailableFields() async {
    final schema = await _getSchema();
    return schema.getFieldPaths();
  }

  /// Get schema sections
  static Future<List<String>> getSections() async {
    final schema = await _getSchema();
    return schema.getSections();
  }

  /// Get fields in a specific section
  static Future<Map<String, SchemaField>> getFieldsInSection(String section) async {
    final schema = await _getSchema();
    return schema.getFieldsInSection(section);
  }

  /// Get the current schema
  static Future<UserDataSchema> getSchema() async {
    return await _getSchema();
  }

  @override
  String toString() {
    return 'UserData(uid: $uid, data: $_data)';
  }
}
