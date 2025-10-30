# Firestore Database Integration - Implementation Guide

## Overview
Successfully implemented Cloud Firestore integration for user data management with a structured JSON-based approach.

## What Was Implemented

### 1. **Firestore Database Structure**
The database follows this JSON structure for each user:

```json
{
  "accountInformation": {
    "username": "string (alphanumeric, 8+ chars)"
  },
  "interaction": {
    "hasPlayedTutorial": false,
    "hasLearnedModule": false
  }
}
```

### 2. **Collection Structure**
- **Collection Name**: `users`
- **Document ID**: User UID from Firebase Authentication
- **Auto-creation**: Collection is automatically created when the first user registers

### 3. **Files Created**

#### `lib/models/user_data.dart` - User Data Model
A comprehensive model class that handles all user data operations:

**Features:**
- ✅ Structured data model matching the JSON schema
- ✅ Firestore serialization/deserialization
- ✅ Individual getter methods for specific fields
- ✅ Update methods for each field
- ✅ Save and load operations

**Available Methods:**
```dart
// Static methods
UserData.load(String uid)                    // Load user data by UID
UserData.getUsername(String uid)             // Get username only
UserData.getHasPlayedTutorial(String uid)    // Get tutorial status
UserData.getHasLearnedModule(String uid)     // Get module status

// Instance methods
userData.save()                              // Save/update to Firestore
userData.updateUsername(String newUsername)  // Update username
userData.updateHasPlayedTutorial(bool value) // Update tutorial status
userData.updateHasLearnedModule(bool value)  // Update module status
userData.copyWith(...)                       // Create modified copy
```

#### `lib/services/firestore_service.dart` - Firestore Service
Service class for centralized Firestore operations:

**Features:**
- ✅ Create user documents automatically on registration
- ✅ Check username uniqueness before registration
- ✅ Get, update, and delete user data
- ✅ Error handling for all operations

**Available Methods:**
```dart
FirestoreService.createUserDocument(uid, username)  // Create new user doc
FirestoreService.usernameExists(String username)    // Check if username taken
FirestoreService.getUserData(String uid)            // Get user data
FirestoreService.updateUserData(UserData userData)  // Update user data
FirestoreService.deleteUserDocument(String uid)     // Delete user doc
```

### 4. **Updated Files**

#### `pubspec.yaml`
Added Firestore dependency:
```yaml
cloud_firestore: ^6.0.3
```

#### `lib/pages/register_page.dart`
**New Features:**
- ✅ Username input field (before email field)
- ✅ Username validation:
  - Must be at least 8 characters
  - Alphanumeric only (letters and numbers)
  - No spaces allowed
  - Checks for uniqueness in database
- ✅ Automatic Firestore document creation on successful registration
- ✅ Sets `hasPlayedTutorial` and `hasLearnedModule` to false by default
- ✅ Error handling for Firestore operations

**Username Validation Rules:**
```dart
✓ Minimum 8 characters
✓ Letters (a-z, A-Z) and numbers (0-9) only
✓ No spaces
✓ Must be unique across all users
✓ Examples of valid usernames: "user12345", "JohnDoe99", "Alpha2024"
```

### 5. **Registration Flow**

1. User fills in:
   - Username (8+ chars, alphanumeric, no spaces)
   - Email
   - Password
   - Confirm Password

2. System validates:
   - All fields are filled correctly
   - Passwords match
   - Username doesn't already exist

3. Firebase Authentication:
   - Creates user account with email/password

4. Firestore Database:
   - Creates document in `users` collection
   - Document ID = User's UID
   - Sets username from form
   - Sets `hasPlayedTutorial` = false
   - Sets `hasLearnedModule` = false

5. Navigation:
   - Shows success dialog
   - Navigates to Home page

### 6. **Error Handling**

The system handles these scenarios:
- ✅ Username already exists
- ✅ Invalid username format
- ✅ Firestore connection errors
- ✅ Document creation failures
- ✅ Authentication errors

## Usage Examples

### Creating a User (Automatic on Registration)
```dart
// This happens automatically in register_page.dart
await FirestoreService.createUserDocument(
  uid: uid,
  username: 'JohnDoe123',
);
```

### Loading User Data
```dart
// Get complete user data
UserData? userData = await UserData.load(uid);
print(userData?.username);
print(userData?.hasPlayedTutorial);

// Get specific field
String? username = await UserData.getUsername(uid);
bool hasPlayed = await UserData.getHasPlayedTutorial(uid);
```

### Updating User Data
```dart
// Load user data
UserData? userData = await UserData.load(uid);

// Update tutorial status
await userData?.updateHasPlayedTutorial(true);

// Update module status
await userData?.updateHasLearnedModule(true);
```

### Checking Username Availability
```dart
bool exists = await FirestoreService.usernameExists('JohnDoe123');
if (!exists) {
  // Username is available
}
```

## Firebase Console Setup

**IMPORTANT:** Before testing, enable Firestore in Firebase Console:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: **code-sprout-f213a**
3. Navigate to **Firestore Database**
4. Click **Create database**
5. Choose **Start in test mode** (for development)
   - Test mode rules (auto-generated):
   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /{document=**} {
         allow read, write: if request.time < timestamp.date(2025, 12, 1);
       }
     }
   }
   ```
6. Select your preferred location (e.g., us-central1)
7. Click **Enable**

**For Production:** Update Firestore rules to:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own document
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Database Structure in Firebase Console

After registration, you'll see this structure:

```
📁 Firestore Database
  └── 📁 users (collection)
       └── 📄 [USER_UID] (document)
            ├── 📁 accountInformation (map)
            │    └── username: "JohnDoe123"
            └── 📁 interaction (map)
                 ├── hasPlayedTutorial: false
                 └── hasLearnedModule: false
```

## Testing Checklist

- [ ] Enable Firestore Database in Firebase Console
- [ ] Try registering with valid username (8+ alphanumeric chars)
- [ ] Try registering with invalid username (less than 8 chars) - should show error
- [ ] Try registering with invalid username (contains spaces) - should show error
- [ ] Try registering with same username twice - should show "username already exists"
- [ ] Check Firebase Console to verify document created with correct structure
- [ ] Verify document ID matches the user's UID
- [ ] Verify all fields are present and correctly initialized

## Code Quality Features

✅ **Type Safety**: Full type annotations throughout  
✅ **Error Handling**: Comprehensive try-catch blocks  
✅ **Null Safety**: Proper null checks and nullable types  
✅ **Documentation**: Clear comments and method documentation  
✅ **Validation**: Client-side and database-level validation  
✅ **Separation of Concerns**: Model, Service, and UI layers separated  
✅ **Reusability**: Methods can be called from anywhere in the app  

## Next Steps / Future Enhancements

1. **Profile Page**: Display and edit username
2. **Tutorial System**: Use `hasPlayedTutorial` flag
3. **Module System**: Use `hasLearnedModule` flag
4. **Username Search**: Find users by username
5. **Profile Pictures**: Add to `accountInformation`
6. **Additional Fields**: Extend structure as needed

## Important Notes

- The `users` collection is automatically created on first user registration
- Each user document uses the Firebase Authentication UID as the document ID
- Default values for interaction fields are set to `false`
- Username uniqueness is enforced at the application level
- All Firestore operations include error handling
- The model class is self-contained with all CRUD operations

## Dependencies Added

```yaml
cloud_firestore: ^6.0.3
```

## Files Structure

```
lib/
├── models/
│   └── user_data.dart          # User data model with Firestore operations
├── services/
│   ├── auth_service.dart       # Firebase Authentication service
│   └── firestore_service.dart  # Firestore operations service
└── pages/
    ├── register_page.dart      # Updated with username field
    ├── login_page.dart         # Login page
    └── home_page.dart          # Home page
```
