# Data-Driven User Data System

## Overview

This implementation provides a fully **data-driven approach** to user data management in the Code Sprout Flutter app. The system automatically adapts to schema changes without requiring code modifications, making it easy to add, remove, or modify user data fields.

## Key Components

### 1. Schema Definition (`assets/user_data_schema.txt`)

The schema file defines the structure of all user data. It uses a simple, human-readable format:

```
"fieldName": "data_type (default_value) [required]"
```

**Supported Data Types:**
- `string` - Text values
- `number` - Numeric values (int or double)
- `boolean` - True/false values
- `timestamp` - Date/time values (Firestore Timestamp)
- `geopoint` - Geographic coordinates (Firestore GeoPoint)
- `reference` - Document references (Firestore DocumentReference)
- `array` - List of values
- `map` - Nested objects
- `null` - Null values

**Format Rules:**
- `data_type`: One of the supported types above
- `default_value`: The value used when creating new user data (omit parentheses for null)
- `[required]`: Optional marker indicating the field must have a value

**Example Schema:**
```json
{
  "accountInformation": {
    "username": "string (null) [required]",
    "email": "string (null)",
    "displayName": "string (User)"
  },
  "interaction": {
    "hasPlayedTutorial": "boolean (false)",
    "completedLessons": "number (0)"
  },
  "preferences": {
    "theme": "string (light)",
    "notificationsEnabled": "boolean (true)"
  }
}
```

### 2. Schema Parser (`lib/models/user_data_schema.dart`)

The `UserDataSchema` class:
- Loads and parses the schema from the asset file
- Validates field definitions
- Provides utility methods for schema inspection
- Handles data migration logic

**Key Methods:**
```dart
// Load schema from file
final schema = await UserDataSchema.load();

// Get all sections
List<String> sections = schema.getSections();

// Get fields in a section
Map<String, SchemaField> fields = schema.getFieldsInSection('accountInformation');

// Create default data structure
Map<String, dynamic> defaultData = schema.createDefaultData();

// Validate data against schema
List<String> errors = schema.validate(userData);

// Migrate old data to new schema
Map<String, dynamic> migratedData = schema.migrateData(oldData);
```

### 3. Dynamic UserData Model (`lib/models/user_data.dart`)

The refactored `UserData` class:
- Stores data in a flexible map structure
- Provides dot-notation access to nested fields
- Automatically validates against schema
- Handles migrations transparently

**Usage Examples:**
```dart
// Create new user data
final userData = await UserData.create(
  uid: 'user123',
  initialData: {
    'accountInformation': {
      'username': 'john_doe',
    },
  },
);

// Get field value using dot notation
String? username = userData.get('accountInformation.username');

// Set field value
userData.set('interaction.hasPlayedTutorial', true);

// Update single field in Firestore
await userData.updateField('accountInformation.email', 'new@email.com');

// Update multiple fields at once
await userData.updateFields({
  'interaction.hasPlayedTutorial': true,
  'interaction.completedLessons': 5,
});

// Load data (with automatic migration)
final loadedData = await UserData.load('user123');

// Validate current data
List<String> errors = await userData.validate();

// Manually trigger migration
final migratedData = await userData.migrate();

// Backwards compatibility - old getters still work
String? username = userData.username;
bool played = userData.hasPlayedTutorial;
```

### 4. Updated Firestore Service (`lib/services/firestore_service.dart`)

Enhanced with schema-aware operations:
```dart
// Get user data (auto-migrates if needed)
final userData = await FirestoreService.getUserData(uid);

// Force refresh from Firestore
final freshData = await FirestoreService.getUserData(uid, forceRefresh: true);

// Update user data
await FirestoreService.updateUserData(updatedUserData);

// Manually trigger migration for a user
await FirestoreService.migrateUserData(uid);

// Reload schema and migrate
await FirestoreService.reloadSchemaAndMigrate(uid);
```

### 5. Dynamic Settings UI (`lib/pages/settings_page.dart`)

The Settings page now:
- **Automatically renders UI** based on the schema
- **No code changes needed** when schema changes
- Supports multiple field types with appropriate controls:
  - Text fields for strings
  - Number inputs for numbers
  - Switches for booleans
  - Date pickers for timestamps
- Validates required fields
- Shows field types and required markers

**Features:**
- Section-based layout matching schema structure
- Automatic field naming (camelCase → Title Case)
- Smart icon selection based on field names
- Refresh button to reload schema
- Full validation on save

## How It Works

### Schema Loading and Caching
1. Schema is loaded from assets on first access
2. Cached in memory for performance
3. Can be manually reloaded when needed

### Data Migration
1. When user data is loaded, it's validated against current schema
2. If validation fails, automatic migration occurs:
   - Existing field values are preserved (if types match)
   - New fields are added with default values
   - Obsolete fields are removed
3. Migrated data is saved back to Firestore
4. Cache is updated with migrated data

### UI Generation
1. Settings page loads schema on initialization
2. Iterates through sections and fields
3. Generates appropriate UI widgets based on field types
4. Binds controllers and state to field values
5. Updates on save trigger validation and Firestore sync

## Migration Scenarios

### Adding New Fields
**Schema Before:**
```json
{
  "accountInformation": {
    "username": "string (null) [required]"
  }
}
```

**Schema After:**
```json
{
  "accountInformation": {
    "username": "string (null) [required]",
    "email": "string (null)"
  }
}
```

**Result:** Existing users get `email: null` added to their data.

### Removing Fields
**Schema Before:**
```json
{
  "accountInformation": {
    "username": "string (null) [required]",
    "oldField": "string (null)"
  }
}
```

**Schema After:**
```json
{
  "accountInformation": {
    "username": "string (null) [required]"
  }
}
```

**Result:** `oldField` is removed from user data on next load.

### Reordering Fields
Fields can be reordered in the schema without data loss. The system uses field paths (dot notation) to match existing data.

### Adding Sections
New sections are treated like new fields - they're created with default values.

### Renaming Fields
⚠️ **Warning:** Renaming a field is treated as removing the old field and adding a new one. Data is not automatically transferred. To rename:
1. Add new field
2. Manually migrate data with a script
3. Remove old field

## Best Practices

### Schema Design
1. **Use clear, descriptive field names** in camelCase
2. **Provide sensible defaults** for all non-required fields
3. **Mark truly essential fields** as `[required]`
4. **Group related fields** into logical sections
5. **Document schema changes** in version control

### Testing Schema Changes
1. **Test in development** before deploying
2. **Use the extended example** in `assets/user_data_schema_extended_example.txt`
3. **Verify migration** with existing user accounts
4. **Check UI rendering** for all field types

### Performance
1. Schema is **cached in memory** - minimal performance impact
2. Migration happens **once per schema change** per user
3. Use **cache-first strategy** to minimize Firestore reads
4. **Batch updates** when modifying multiple fields

### Error Handling
1. Always **check validation errors** before saving
2. **Handle schema loading failures** gracefully
3. **Log migration issues** for debugging
4. **Provide user feedback** for validation failures

## Testing

### Unit Tests
Run schema tests:
```bash
flutter test test/user_data_schema_test.dart
```

### Manual Testing
1. Run the app: `flutter run`
2. Login/register
3. Go to Settings
4. Modify values and save
5. Verify data persistence

### Schema Update Testing
1. Modify `assets/user_data_schema.txt`
2. Hot restart the app
3. Click refresh icon in Settings
4. Verify UI updates correctly
5. Check data migration

See `TESTING_GUIDE.md` for detailed testing scenarios.

## Troubleshooting

### "Schema file not found"
- Ensure `assets/user_data_schema.txt` exists
- Check `pubspec.yaml` includes the asset
- Run `flutter pub get`

### "Validation failed"
- Check required fields are filled
- Verify data types match schema
- Review error messages for details

### UI not updating after schema change
- Click the refresh icon in Settings
- Perform a hot restart (not hot reload)
- Check for schema syntax errors

### Data not migrating
- Verify schema is valid JSON
- Check Firestore connectivity
- Review logs for migration errors

## Advanced Usage

### Custom Field Types
To add support for custom types:
1. Update `SchemaField.validateValue()` method
2. Add type conversion in `toFirestoreValue()`
3. Create UI widget in Settings page's `_buildField()` method

### Programmatic Schema Updates
```dart
// Get current schema
final schema = await UserData.getSchema();

// Inspect structure
print(schema.toString());

// Get all field paths
final paths = schema.getFieldPaths();

// Check if field exists
final field = schema.getField('accountInformation.username');
if (field != null) {
  print('Field type: ${field.dataType}');
  print('Default: ${field.defaultValue}');
  print('Required: ${field.isRequired}');
}
```

### Batch Migration
To migrate all users (admin function):
```dart
// Get all user documents
final users = await FirebaseFirestore.instance.collection('users').get();

// Migrate each
for (final doc in users.docs) {
  await FirestoreService.migrateUserData(doc.id);
}
```

## Backwards Compatibility

Old code using direct properties still works:
```dart
// These still work
String? username = userData.username;
bool played = userData.hasPlayedTutorial;
await userData.updateUsername('new_name');
await userData.updateHasPlayedTutorial(true);
```

New code can use dynamic access:
```dart
// More flexible
String? username = userData.get('accountInformation.username');
await userData.updateField('accountInformation.username', 'new_name');
```

## Security Considerations

1. **Firestore Rules:** Update security rules to match schema structure
2. **Validation:** Schema validation happens client-side AND should be enforced server-side
3. **Required Fields:** Firestore rules should enforce required fields
4. **Type Safety:** Consider adding server-side type checking

## Future Enhancements

Potential improvements:
- [ ] Schema versioning system
- [ ] Automatic Firestore rules generation from schema
- [ ] Schema validation tool/linter
- [ ] Migration history tracking
- [ ] Support for array item types
- [ ] Nested map field editors in UI
- [ ] Schema diff tool
- [ ] Rollback capability

## License

Part of Code Sprout project.

## Support

For issues or questions, refer to:
- `TESTING_GUIDE.md` - Detailed testing procedures
- `assets/user_data_schema_extended_example.txt` - Example extended schema
- Project documentation
