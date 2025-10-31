# Enum Fields Feature

## Overview
The schema-driven user data system now supports enum fields, allowing you to restrict string values to a predefined set of options.

## Format

### Enum Field Definition
```
"fieldName": "string (|Value1|Value2|Value3|)"
```

### Key Rules
1. **Must be string type**: Only works with `string` data type
2. **Pipe delimiters**: Must start with `|` and end with `|`
3. **Separation**: Values separated by `|`
4. **Default value**: First enum value is automatically the default
5. **Required marker**: Can still use `[required]` marker

## Examples

### Example 1: Difficulty Level
```json
{
    "gameSettings": {
        "difficulty": "string (|Easy|Normal|Hard|)"
    }
}
```
- Default value: "Easy"
- Allowed values: "Easy", "Normal", "Hard"
- UI: Dropdown menu

### Example 2: Connection Mode (Required)
```json
{
    "networkSettings": {
        "mode": "string (|Offline|Online|) [required]"
    }
}
```
- Default value: "Offline"
- Allowed values: "Offline", "Online"
- Required field (cannot be null)
- UI: Dropdown menu

### Example 3: Multiple Enum Fields
```json
{
    "userPreferences": {
        "theme": "string (|Light|Dark|Auto|)",
        "language": "string (|English|Spanish|French|German|)",
        "fontSize": "string (|Small|Medium|Large|)"
    }
}
```

## Validation

### Automatic Validation
The system automatically validates enum values:

```dart
// Valid
userData.set('interaction.difficulty', 'Easy');    // ✓
userData.set('interaction.difficulty', 'Normal');  // ✓
userData.set('interaction.difficulty', 'Hard');    // ✓

// Invalid
userData.set('interaction.difficulty', 'Medium');  // ✗ Not in enum list
userData.set('interaction.difficulty', 'easy');    // ✗ Case-sensitive
```

### Validation Error Messages
```dart
final errors = await userData.validate();
// Returns: ["Field 'interaction.difficulty' has invalid type. Expected string"]
```

### UI Validation
The Settings page automatically:
1. Renders enum fields as dropdown menus
2. Shows only valid options
3. Validates on form submission
4. Displays error if invalid value exists

## UI Rendering

### Dropdown Appearance
- **Label**: Shows field name with "(enum)" indicator
- **Icon**: Based on field name (same as regular fields)
- **Style**: Consistent with other form fields
- **Validation**: Real-time validation on change

### User Experience
1. User clicks dropdown
2. Sees list of valid options
3. Selects one option
4. Value saved immediately to local state
5. Validated on form submission

## Migration Behavior

### Adding Enum to Existing Field
When converting a regular string field to enum:
```json
// Before
"difficulty": "string (medium)"

// After
"difficulty": "string (|Easy|Normal|Hard|)"
```

**What happens:**
- Existing value "medium" remains in database
- Validation will fail on next load
- User must select valid enum value
- On save, migrated to first enum value if invalid

### Removing Enum Constraint
When converting enum to regular string:
```json
// Before
"difficulty": "string (|Easy|Normal|Hard|)"

// After
"difficulty": "string (null)"
```

**What happens:**
- Existing enum value remains valid
- Field now accepts any string
- No migration needed

## Implementation Details

### SchemaField Class
```dart
class SchemaField {
  final List<String>? enumValues;
  
  bool get isEnum => enumValues != null && enumValues!.isNotEmpty;
  
  bool validateValue(dynamic value) {
    if (isEnum) {
      if (value is! String) return false;
      return enumValues!.contains(value);
    }
    // ... other validations
  }
}
```

### Parser Logic
```dart
// Detects enum pattern: |Value1|Value2|
if (defaultStr.startsWith('|') && defaultStr.endsWith('|')) {
  final enumStr = defaultStr.substring(1, defaultStr.length - 1);
  enumValues = enumStr.split('|').where((s) => s.isNotEmpty).toList();
  defaultValue = enumValues.isNotEmpty ? enumValues.first : null;
}
```

### UI Component
```dart
DropdownButtonFormField<String>(
  value: currentValue,
  items: field.enumValues!.map((value) => 
    DropdownMenuItem(value: value, child: Text(value))
  ).toList(),
  validator: (value) {
    if (!field.enumValues!.contains(value)) {
      return 'Invalid value. Must be one of: ${field.enumValues!.join(", ")}';
    }
    return null;
  },
)
```

## Best Practices

### Do's ✓
- Use clear, descriptive enum values
- Keep enum lists short (2-10 options)
- Use consistent casing (PascalCase recommended)
- Document enum meanings in comments
- Use for predefined categories

### Don'ts ✗
- Don't use for dynamic/user-generated values
- Don't include empty strings in enum list
- Don't use special characters in enum values
- Don't make enum lists too long
- Don't change enum values without migration plan

## Testing

### Test Cases
```dart
// 1. Valid enum value
test('accepts valid enum value', () async {
  final field = SchemaField.parse('string (|Easy|Normal|Hard|)');
  expect(field.validateValue('Easy'), true);
  expect(field.validateValue('Normal'), true);
  expect(field.validateValue('Hard'), true);
});

// 2. Invalid enum value
test('rejects invalid enum value', () async {
  final field = SchemaField.parse('string (|Easy|Normal|Hard|)');
  expect(field.validateValue('Medium'), false);
  expect(field.validateValue('easy'), false);
});

// 3. Enum detection
test('detects enum fields', () async {
  final field = SchemaField.parse('string (|Easy|Normal|Hard|)');
  expect(field.isEnum, true);
  expect(field.enumValues, ['Easy', 'Normal', 'Hard']);
});

// 4. Default value
test('uses first enum value as default', () async {
  final field = SchemaField.parse('string (|Easy|Normal|Hard|)');
  expect(field.defaultValue, 'Easy');
});
```

## Troubleshooting

### Issue: Dropdown shows "null" option
**Cause**: Current value not in enum list  
**Solution**: Update database value to match enum options

### Issue: Validation fails after schema update
**Cause**: Existing values don't match new enum list  
**Solution**: Run migration or update values manually

### Issue: Case-sensitive validation errors
**Cause**: Enum values are case-sensitive  
**Solution**: Ensure consistent casing in schema and data

### Issue: Empty enum list
**Cause**: Incorrect format (missing values between pipes)  
**Solution**: Ensure format is `|Value1|Value2|` with values

## Future Enhancements

Potential improvements:
1. Support for number enums
2. Enum value aliases/display names
3. Enum groups/categories
4. Dynamic enum loading from Firestore
5. Multi-select enum fields
6. Enum value deprecation system
