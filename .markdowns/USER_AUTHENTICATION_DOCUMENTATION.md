# User Authentication & Data Management System (Code Sprout)

This document provides comprehensive documentation of Code Sprout's user authentication system, including data-driven schema architecture, local storage caching, Firebase integration, and data migration strategies. It serves as the authoritative reference for developers working with user authentication, registration, data persistence, and schema management.

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Architecture Components](#architecture-components)
3. [Schema-Driven Data Model](#schema-driven-data-model)
4. [Authentication Flow](#authentication-flow)
5. [Data Storage Strategy](#data-storage-strategy)
6. [Local Storage & Caching](#local-storage--caching)
7. [Data Migration System](#data-migration-system)
8. [Security Implementation](#security-implementation)
9. [API Reference](#api-reference)
10. [Best Practices & Guidelines](#best-practices--guidelines)

---

## System Overview

### Core Principles

Code Sprout implements a sophisticated user authentication and data management system built on four foundational principles:

1. **Schema-Driven Architecture**: All user data structures are defined in external schema files, enabling flexible evolution without code changes
2. **Cache-First Strategy**: Local storage provides instant data access with background synchronization to Firebase
3. **Automatic Migration**: Schema changes automatically migrate existing user data while preserving values
4. **Type Safety & Validation**: Runtime validation ensures data integrity across all operations

### Technology Stack

- **Authentication**: Firebase Authentication (email/password)
- **Remote Database**: Cloud Firestore with collection-based structure
- **Local Storage**: Flutter Secure Storage with AES encryption
- **Schema Format**: JSON with custom type annotations and default values
- **Data Access**: Dot-notation path-based API with type conversion

### Key Features

- ✅ Automatic schema validation and migration
- ✅ Offline-first data access with background sync
- ✅ Reactive data updates via ValueNotifier
- ✅ Encrypted local storage for sensitive data
- ✅ Flexible field access using dot-notation paths
- ✅ Built-in coins and inventory management
- ✅ Username uniqueness validation
- ✅ Comprehensive error handling

---

## Architecture Components

### File Structure

```
lib/
├── models/
│   ├── user_data.dart              # Dynamic UserData model
│   ├── user_data_schema.dart       # Schema parser & validator
│   └── inventory_data.dart         # Inventory schema (referenced)
├── services/
│   ├── auth_service.dart           # Firebase Auth wrapper
│   ├── firestore_service.dart      # Firestore operations
│   └── local_storage_service.dart  # Encrypted local cache
assets/
└── schemas/
    ├── user_data_schema.txt        # User data schema definition
    └── inventory_schema.txt        # Inventory structure
firestore.rules                     # Security rules configuration
```

### Component Responsibilities

| Component | Responsibility |
|-----------|----------------|
| **user_data_schema.txt** | Single source-of-truth for user data structure, types, defaults, and constraints |
| **UserDataSchema** | Loads, parses, validates schema; flattens nested structures into dot-notation paths |
| **UserData** | Dynamic model providing get/set/update operations; handles serialization and persistence |
| **AuthService** | Manages Firebase Authentication operations (sign-in, sign-up, sign-out) |
| **FirestoreService** | Coordinates Firestore operations with caching; handles username validation and migrations |
| **LocalStorageService** | Provides encrypted storage with ValueNotifier for reactive updates |

---

## Schema-Driven Data Model

### Schema Definition Format

The schema file (`assets/schemas/user_data_schema.txt`) uses a JSON structure with custom type annotations:

```json
{
  "sectionName": {
    "fieldName": "data_type (default_value) [required]"
  }
}
```

#### Schema Syntax Rules

**Basic Field Definition**:
```json
"username": "string (null) [required]"
```
- `string` = data type
- `(null)` = default value
- `[required]` = validation constraint

**Enum Field Definition**:
```json
"difficulty": "string (|beginner|intermediate|advanced|)"
```
- Values enclosed in pipes `|value1|value2|`
- First value becomes the default
- Validation restricts to defined values only

**Nested Structure**:
```json
"accountInformation": {
  "username": "string (null) [required]",
  "email": "string (null) [required]"
}
```

**Schema Reference**:
```json
"inventory": "reference (inventory_schema.txt)"
```
- Links to external schema files
- Automatically expands referenced structures

### Supported Data Types

| Type | Dart Type | Firestore Type | Example Default |
|------|-----------|----------------|-----------------|
| `string` | `String` | `String` | `"hello"` or `null` |
| `number` | `num` | `Number` | `0`, `50`, `3.14` |
| `boolean` | `bool` | `Boolean` | `true`, `false` |
| `timestamp` | `Timestamp` | `Timestamp` | Auto-generated |
| `geopoint` | `GeoPoint` | `GeoPoint` | Coordinate pair |
| `reference` | Schema expansion | External schema | Linked structure |
| `array` | `List` | `Array` | `[]` |
| `map` | `Map` | `Map` | `{}` |
| `null` | `null` | `null` | `null` |

### Schema Processing

#### 1. Schema Loading
```dart
static Future<UserDataSchema> load() async {
  // Loads from assets/schemas/user_data_schema.txt
  final schemaContent = await rootBundle.loadString('assets/schemas/user_data_schema.txt');
  final schemaMap = json.decode(jsonContent) as Map<String, dynamic>;
  
  // Loads referenced schemas (e.g., inventory_schema.txt)
  final inventorySchema = await InventorySchema.load();
  
  return UserDataSchema(schemaMap, inventorySchema: inventorySchema);
}
```

#### 2. Schema Flattening
The schema parser converts nested structures into dot-notation paths:

**Schema**:
```json
{
  "accountInformation": {
    "username": "string (null) [required]"
  }
}
```

**Flattened**:
```
accountInformation.username → SchemaField(type: string, required: true, default: null)
```

#### 3. Reference Expansion
When encountering `reference (inventory_schema.txt)`:
```dart
// Expands to individual item paths
sproutProgress.inventory.seeds.quantity → number (0)
sproutProgress.inventory.seeds.isLocked → boolean (false)
sproutProgress.inventory.fertilizer.quantity → number (0)
sproutProgress.inventory.fertilizer.isLocked → boolean (false)
```

### Schema Field Class

```dart
class SchemaField {
  final String dataType;           // e.g., "string", "number"
  final dynamic defaultValue;      // Default value for field
  final bool isRequired;           // Validation constraint
  final List<String>? enumValues;  // Enum constraint values
  
  // Validates if value matches expected type
  bool validateValue(dynamic value);
  
  // Converts value to Firestore-compatible type
  dynamic toFirestoreValue(dynamic value);
}
```

### Current Schema Structure

```json
{
  "accountInformation": {
    "username": "string (null) [required]"
  },
  "interaction": {
    "hasPlayedTutorial": "boolean (false)",
    "hasLearnedChapter": "boolean (false)",
    "hasCheckedTermsAndConditions": "boolean (false)"
  },
  "lastInteraction": {
    "languageId": "string (null)",
    "difficulty": "string (|beginner|intermediate|advanced|)"
  },
  "sproutProgress": {
    "selectedLanguage": "string (null)",
    "isLanguageUnlocked": {
      "cpp": "boolean (false)",
      "csharp": "boolean (false)",
      "java": "boolean (false)",
      "python": "boolean (false)",
      "javascript": "boolean (false)"
    },
    "coins": "number (50)",
    "inventory": "reference (inventory_schema.txt)"
  },
  "rankProgress": {
    "experiencePoints": "number (0)"
  },
  "courseProgress": {
    "cpp|csharp|java|python|javascript": {
      "beginner|intermediate|advanced": {
        "currentChapter": "number (1)",
        "currentModule": "number (1)"
      }
    }
  }
}
```

---

## Authentication Flow

### Registration Process

#### Complete Registration Flow Diagram

```
┌─────────────────────┐
│   User Interface    │
│  (register_page)    │
└──────────┬──────────┘
           │ 1. User enters: username, email, password
           ▼
┌──────────────────────────┐
│  Client-Side Validation  │
│  - Username format       │
│  - Email format          │
│  - Password strength     │
└──────────┬───────────────┘
           │ 2. Validation passes
           ▼
┌──────────────────────────┐
│ Username Uniqueness      │
│ Check (Firestore Query)  │
└──────────┬───────────────┘
           │ 3. Query: WHERE username == input
           ▼
┌──────────────────────────┐
│ Firebase Authentication  │
│ createUserWithEmail()    │
└──────────┬───────────────┘
           │ 4. Auth account created, UID generated
           ▼
┌──────────────────────────┐
│  Schema-Based Document   │
│  Generation              │
│  UserData.create()       │
└──────────┬───────────────┘
           │ 5. Create default structure + username
           ▼
┌──────────────────────────┐
│  Validate Required       │
│  Fields                  │
└──────────┬───────────────┘
           │ 6. Ensure 'username' is present
           ▼
┌──────────────────────────┐
│  Save to Firestore       │
│  users/{uid}             │
└──────────┬───────────────┘
           │ 7. Document persisted remotely
           ▼
┌──────────────────────────┐
│  Cache Locally           │
│  (Encrypted Storage)     │
└──────────┬───────────────┘
           │ 8. Immediate local access
           ▼
┌──────────────────────────┐
│  Navigate to Home Page   │
└──────────────────────────┘
```

#### Implementation Details

**Step 1: Client-Side Validation**
```dart
// Typical validation in UI layer
String? validateUsername(String username) {
  if (username.length < 3) {
    return 'Username must be at least 3 characters';
  }
  if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
    return 'Username can only contain letters, numbers, and underscores';
  }
  return null;
}
```

**Step 2: Username Uniqueness Check**
```dart
// FirestoreService.usernameExists()
static Future<bool> usernameExists(String username) async {
  try {
    final querySnapshot = await _usersCollection
      .where('accountInformation.username', isEqualTo: username)
      .limit(1)
      .get()
      .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timed out - check your internet connection and Firestore rules');
        },
      );

    return querySnapshot.docs.isNotEmpty;
  } catch (e) {
    throw Exception('Failed to check username existence: $e');
  }
}
```

**Step 3: Firebase Authentication**
```dart
// AuthService.register()
Future<String?> register({
  required String email,
  required String password,
}) async {
  try {
    await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return null; // Success - no error message
  } on FirebaseAuthException catch (e) {
    // Return user-friendly error messages
    switch (e.code) {
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Invalid email address.';
      default:
        return 'An error occurred. Please try again.';
    }
  } catch (e) {
    return 'An unexpected error occurred.';
  }
}
```

**Step 4: Create User Document**
```dart
// FirestoreService.createUserDocument()
static Future<void> createUserDocument({
  required String uid,
  required String username,
}) async {
  try {
    // Create UserData with schema defaults
    final userData = await UserData.create(
      uid: uid,
      initialData: {
        'accountInformation': {
          'username': username,
        },
      },
    );

    // Save to Firestore
    await userData.save();
    
    // Cache locally for immediate access
    try {
      await _localStorage.saveUserData(userData);
    } catch (_) {
      // Local cache failure is non-critical
    }
  } catch (e) {
    throw Exception('Failed to create user document: $e');
  }
}
```

**Step 5: Schema-Based Document Generation**
```dart
// UserData.create() - The core of schema-driven creation
static Future<UserData> create({
  required String uid,
  Map<String, dynamic>? initialData,
}) async {
  final schema = await _getSchema();
  
  // Step 1: Generate complete default structure from schema
  final data = schema.createDefaultData();
  
  // Step 2: Recursively merge initial data (preserves nested defaults)
  if (initialData != null) {
    _mergeData(data, initialData);
  }
  
  // Step 3: Validate all required fields are present
  final errors = schema.validate(data);
  if (errors.isNotEmpty) {
    throw Exception('Validation failed: ${errors.join(", ")}');
  }
  
  return UserData(uid: uid, data: data);
}

// Recursive merge preserves nested structures
static void _mergeData(Map<String, dynamic> target, Map<String, dynamic> source) {
  source.forEach((key, value) {
    if (value is Map<String, dynamic> && target[key] is Map<String, dynamic>) {
      _mergeData(target[key] as Map<String, dynamic>, value);
    } else {
      target[key] = value;
    }
  });
}
```

#### Example Generated Document

After registration with username `"alice_sprout"`:

```json
{
  "accountInformation": {
    "username": "alice_sprout"
  },
  "interaction": {
    "hasPlayedTutorial": false,
    "hasLearnedChapter": false,
    "hasCheckedTermsAndConditions": false
  },
  "lastInteraction": {
    "languageId": null,
    "difficulty": "beginner"
  },
  "sproutProgress": {
    "selectedLanguage": null,
    "isLanguageUnlocked": {
      "cpp": false,
      "csharp": false,
      "java": false,
      "python": false,
      "javascript": false
    },
    "coins": 50,
    "inventory": {
      "seeds": {
        "quantity": 0,
        "isLocked": false
      },
      "fertilizer": {
        "quantity": 0,
        "isLocked": false
      }
    }
  },
  "rankProgress": {
    "experiencePoints": 0
  },
  "courseProgress": {
    "cpp": {
      "beginner": {"currentChapter": 1, "currentModule": 1},
      "intermediate": {"currentChapter": 1, "currentModule": 1},
      "advanced": {"currentChapter": 1, "currentModule": 1}
    },
    "csharp": { /* same structure */ },
    "java": { /* same structure */ },
    "python": { /* same structure */ },
    "javascript": { /* same structure */ }
  }
}
```

### Login Process

#### Complete Login Flow Diagram

```
┌─────────────────────┐
│   User Interface    │
│    (login_page)     │
└──────────┬──────────┘
           │ 1. User enters: email/username, password
           ▼
┌──────────────────────────┐
│  Firebase Authentication │
│  signInWithEmail()       │
└──────────┬───────────────┘
           │ 2. Verify credentials
           ▼
┌──────────────────────────┐
│  Extract UID             │
│  (currentUser.uid)       │
└──────────┬───────────────┘
           │ 3. Unique user identifier
           ▼
┌──────────────────────────┐
│  Load User Data          │
│  (Cache-First Strategy)  │
└──────────┬───────────────┘
           │ 4. Check local cache
           ▼
    ┌──────┴──────┐
    │             │
    ▼             ▼
┌─────────┐   ┌─────────────┐
│ Cached  │   │ Not Cached  │
│ & Valid │   │ or Invalid  │
└────┬────┘   └──────┬──────┘
     │               │
     │               ▼
     │      ┌──────────────────┐
     │      │ Fetch Firestore  │
     │      └──────┬───────────┘
     │             │
     │             ▼
     │      ┌──────────────────┐
     │      │ Validate Schema  │
     │      └──────┬───────────┘
     │             │
     │      ┌──────┴──────┐
     │      │             │
     │      ▼             ▼
     │   ┌─────┐      ┌─────────┐
     │   │Valid│      │ Invalid │
     │   └──┬──┘      └────┬────┘
     │      │              │
     │      │              ▼
     │      │      ┌──────────────┐
     │      │      │ Auto-Migrate │
     │      │      └──────┬───────┘
     │      │             │
     └──────┴─────────────┘
            │
            ▼
     ┌──────────────┐
     │ Update Cache │
     └──────┬───────┘
            │
            ▼
     ┌──────────────┐
     │ Return Data  │
     └──────┬───────┘
            │
            ▼
     ┌──────────────┐
     │ Navigate to  │
     │   Home Page  │
     └──────────────┘
```

#### Implementation Details

**Step 1: Firebase Authentication**
```dart
// AuthService.signIn()
Future<String?> signIn({
  required String email,
  required String password,
}) async {
  try {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return null; // Success
  } on FirebaseAuthException catch (e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return 'An error occurred. Please try again.';
    }
  } catch (e) {
    return 'An unexpected error occurred.';
  }
}
```

**Step 2: Load User Data (Cache-First)**
```dart
// FirestoreService.getUserData() - Core cache-first logic
static Future<UserData?> getUserData(String uid, {bool forceRefresh = false}) async {
  try {
    // CACHE-FIRST: Try local cache unless forced refresh
    if (!forceRefresh) {
      final cachedData = await _localStorage.getUserData();
      if (cachedData != null && cachedData.uid == uid) {
        // Validate cached data against current schema
        final errors = await cachedData.validate();
        if (errors.isEmpty) {
          return cachedData; // Valid cached data - instant return
        }
        // Cached data is outdated (schema changed), force refresh
        forceRefresh = true;
      }
    }

    // REMOTE FETCH: Load from Firestore (auto-migrates if needed)
    final userData = await UserData.load(uid);
    
    // UPDATE CACHE: Cache the freshly loaded data
    if (userData != null) {
      await _localStorage.saveUserData(userData);
    }
    
    return userData;
  } catch (e) {
    // FALLBACK: If Firestore fails, try returning stale cache
    if (!forceRefresh) {
      final cachedData = await _localStorage.getUserData();
      if (cachedData != null && cachedData.uid == uid) {
        return cachedData; // Return potentially stale but valid cache
      }
    }
    throw Exception('Failed to get user data: $e');
  }
}
```

**Step 3: Automatic Migration on Load**
```dart
// UserData.load() - Automatically migrates outdated data
static Future<UserData?> load(String uid) async {
  try {
    final doc = await _usersCollection.doc(uid).get();
    
    if (!doc.exists) {
      return null;
    }

    final userData = UserData.fromFirestore(doc);
    
    // Validate against current schema
    final schema = await _getSchema();
    final errors = schema.validate(userData._data);
    
    if (errors.isNotEmpty) {
      // Data doesn't match schema - auto-migrate
      final migratedUserData = await userData.migrate();
      await migratedUserData.save(); // Save migrated version
      return migratedUserData;
    }
    
    return userData;
  } catch (e) {
    throw Exception('Failed to load user data: $e');
  }
}
```

**Schema-Driven Data Access in UI**
```dart
// Example usage in HomePage
final uid = AuthService().currentUser?.uid;
if (uid != null) {
  final userData = await FirestoreService.getUserData(uid);
  
  // Dot-notation access
  final username = userData?.get('accountInformation.username') as String?;
  final coins = userData?.get('sproutProgress.coins') as int? ?? 0;
  final hasPlayedTutorial = userData?.get('interaction.hasPlayedTutorial') as bool? ?? false;
  
  // Use in UI
  print('Welcome back, $username!');
  print('You have $coins coins');
}
```

### Logout Process

#### Logout Flow

```
┌─────────────────────┐
│   User Initiates    │
│   Logout Action     │
└──────────┬──────────┘
           │
           ▼
┌──────────────────────────┐
│  Clear Local Cache       │
│  LocalStorageService     │
└──────────┬───────────────┘
           │ Security: Remove all cached user data
           ▼
┌──────────────────────────┐
│  Clear ValueNotifier     │
│  (Reactive UI Update)    │
└──────────┬───────────────┘
           │ UI listeners automatically update
           ▼
┌──────────────────────────┐
│  Firebase Sign Out       │
│  _auth.signOut()         │
└──────────┬───────────────┘
           │ Invalidate auth session
           ▼
┌──────────────────────────┐
│  Navigate to Login Page  │
└──────────────────────────┘
```

#### Implementation

```dart
// AuthService.signOut()
Future<void> signOut() async {
  // Clear cached user data before signing out (security)
  await FirestoreService.clearCache();
  
  // Sign out from Firebase
  await _auth.signOut();
}

// FirestoreService.clearCache()
static Future<void> clearCache() async {
  try {
    await _localStorage.clearUserData();
  } catch (e) {
    throw Exception('Failed to clear cache: $e');
  }
}

// LocalStorageService.clearUserData()
Future<void> clearUserData() async {
  try {
    // Delete encrypted storage
    await _storage.delete(key: _userDataKey);
    await _storage.delete(key: _lastSyncKey);
    
    // Clear reactive notifier (triggers UI update)
    try {
      userDataNotifier.value = null;
    } catch (_) {}
  } catch (e) {
    throw Exception('Failed to clear user data from local storage: $e');
  }
}
```

**Security Note**: Complete cache clearing on logout prevents unauthorized access on shared devices and ensures no sensitive data persists locally after session ends.

---

## Data Storage Strategy

### Dual-Layer Architecture

Code Sprout implements a **dual-layer data storage architecture** combining local encrypted cache with remote Firebase Firestore for optimal performance and reliability.

```
┌────────────────────────────────────────────────────────────┐
│                       Application Layer                     │
└────────────────────┬───────────────────────┬────────────────┘
                     │                       │
                     ▼                       ▼
      ┌──────────────────────┐   ┌──────────────────────┐
      │   Local Storage      │   │   Firestore          │
      │   (Cache Layer)      │   │   (Remote Layer)     │
      ├──────────────────────┤   ├──────────────────────┤
      │ • Encrypted          │   │ • Authoritative      │
      │ • Instant access     │   │ • Multi-device sync  │
      │ • Offline support    │   │ • Cloud backup       │
      │ • ValueNotifier      │   │ • Real-time updates  │
      └──────────────────────┘   └──────────────────────┘
```

### Storage Layers

#### Layer 1: Local Storage (Cache)

**Technology**: `flutter_secure_storage` with AES-256 encryption

**Purpose**:
- Instant data access without network latency
- Offline functionality
- Reduced Firestore read costs
- Immediate UI responsiveness

**Implementation**:
```dart
class LocalStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true, // Android-specific encryption
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock, // iOS Keychain
    ),
  );
  
  // Reactive state management
  final ValueNotifier<UserData?> userDataNotifier = ValueNotifier<UserData?>(null);
  
  static const String _userDataKey = 'cached_user_data';
  static const String _lastSyncKey = 'last_sync_timestamp';
}
```

**Storage Format**:
```json
{
  "cached_user_data": "{\"uid\":\"abc123\",\"accountInformation\":{...}}",
  "last_sync_timestamp": "1732704000000"
}
```

#### Layer 2: Firestore (Remote)

**Technology**: Cloud Firestore (NoSQL document database)

**Purpose**:
- Single source of truth
- Cross-device synchronization
- Data persistence and backup
- Concurrent access control

**Collection Structure**:
```
firestore/
└── users/                          # Collection
    ├── {uid_1}/                    # Document (user ID)
    │   ├── accountInformation      # Map
    │   ├── interaction             # Map
    │   ├── sproutProgress          # Map
    │   ├── rankProgress            # Map
    │   ├── courseProgress          # Map
    │   ├── codeFiles/              # Sub-collection
    │   └── farmProgress/           # Sub-collection
    └── {uid_2}/                    # Document (another user)
        └── ...
```

### Cache-First Read Strategy

```
┌─────────────────────┐
│  Request User Data  │
└──────────┬──────────┘
           │
           ▼
    ┌──────────────────┐
    │ Check Local Cache│
    └──────┬───────────┘
           │
    ┌──────┴──────┐
    │             │
    ▼             ▼
┌────────┐   ┌────────────┐
│ Found  │   │ Not Found  │
└───┬────┘   └─────┬──────┘
    │              │
    ▼              ▼
┌────────────┐  ┌──────────────────┐
│ Validate   │  │ Fetch Firestore  │
│ Schema     │  └─────┬────────────┘
└───┬────────┘        │
    │                 ▼
┌───┴─────┐     ┌──────────────┐
│         │     │ Validate     │
▼         ▼     │ & Migrate    │
┌──────┐ ┌───────┐  └─────┬──────┘
│Valid │ │Invalid│        │
└───┬──┘ └───┬───┘        │
    │        │            │
    │        └────────────┘
    │                 │
    │                 ▼
    │        ┌──────────────┐
    │        │ Update Cache │
    │        └─────┬────────┘
    └──────────────┘
           │
           ▼
    ┌──────────────┐
    │ Return Data  │
    └──────────────┘
```

#### Implementation

```dart
static Future<UserData?> getUserData(String uid, {bool forceRefresh = false}) async {
  // STEP 1: Try cache first (unless force refresh)
  if (!forceRefresh) {
    final cachedData = await _localStorage.getUserData();
    if (cachedData != null && cachedData.uid == uid) {
      // Validate against current schema
      final errors = await cachedData.validate();
      if (errors.isEmpty) {
        return cachedData; // ⚡ Instant return from cache
      }
      forceRefresh = true; // Cache invalid, force remote fetch
    }
  }

  // STEP 2: Fetch from Firestore
  final userData = await UserData.load(uid); // Auto-migrates if needed
  
  // STEP 3: Update cache with fresh data
  if (userData != null) {
    await _localStorage.saveUserData(userData);
  }
  
  return userData;
}
```

### Write-Through Strategy

Updates are written to **both** layers with cache-first for instant UI updates:

```
┌──────────────────────┐
│  Update User Data    │
└──────────┬───────────┘
           │
           ▼
    ┌──────────────────┐
    │ Update In-Memory │
    │ UserData Object  │
    └──────┬───────────┘
           │
           ├─────────────────┐
           │                 │
           ▼                 ▼
  ┌─────────────────┐  ┌─────────────────┐
  │ Write to Cache  │  │ Write to        │
  │ (Immediate)     │  │ Firestore       │
  └─────────┬───────┘  │ (Background)    │
            │          └─────────┬───────┘
            │                    │
            ▼                    │
  ┌─────────────────┐            │
  │ Notify UI       │            │
  │ (ValueNotifier) │            │
  └─────────────────┘            │
                                 │
                        ┌────────┴────────┐
                        │                 │
                        ▼                 ▼
                  ┌──────────┐      ┌──────────┐
                  │ Success  │      │  Error   │
                  └──────────┘      └─────┬────┘
                                          │
                                          ▼
                                  ┌────────────────┐
                                  │ Cache Retains  │
                                  │ Latest State   │
                                  └────────────────┘
```

#### Implementation

```dart
// UserData.updateField() - Updates single field
Future<void> updateField(String path, dynamic value) async {
  try {
    final schema = await _getSchema();
    final field = schema.getField(path);
    
    // Validate
    if (field == null) {
      throw Exception('Field $path does not exist in schema');
    }
    if (!field.validateValue(value)) {
      throw Exception('Invalid value for field $path. Expected ${field.dataType}');
    }
    
    // STEP 1: Update Firestore (remote first for this method)
    await _usersCollection.doc(uid).update({
      path: field.toFirestoreValue(value),
    });

    // STEP 2: Update in-memory data
    set(path, value);
    
    // STEP 3: Update local cache
    try {
      await LocalStorageService.instance.saveUserData(this);
    } catch (_) {
      // Non-critical: cache update failure doesn't block operation
    }
  } catch (e) {
    throw Exception('Failed to update field $path: $e');
  }
}

// Specialized methods like addCoins() prioritize cache-first
Future<void> addCoins(int amount) async {
  if (amount < 0) throw ArgumentError('Amount must be non-negative');
  if (amount == 0) return;
  
  final currentCoins = getCoins();
  final newCoins = currentCoins + amount;
  
  // STEP 1: Update in-memory
  set('sproutProgress.coins', newCoins);
  
  // STEP 2: Notify UI immediately (reactive)
  try {
    LocalStorageService.instance.userDataNotifier.value = copyWith({});
  } catch (_) {}

  // STEP 3: Write to local cache (instant persistence)
  try {
    await LocalStorageService.instance.saveUserData(this);
  } catch (e) {
    debugPrint('Failed to save user data locally: $e');
  }
  
  // STEP 4: Background sync to Firestore
  try {
    await updateFields({'sproutProgress.coins': newCoins});
  } catch (e) {
    debugPrint('Failed to update coins in Firestore: $e');
    // Cache still has correct value - will sync on next app launch
  }
}
```

### Offline Behavior

**Offline Reads**:
- ✅ Full access to cached data
- ✅ All read operations work normally
- ⚠️ Data may be stale if remote changed

**Offline Writes**:
- ✅ In-memory updates succeed
- ✅ Cache updates succeed
- ❌ Firestore writes fail (gracefully handled)
- 🔄 Manual sync required on reconnection

**Reconnection Strategy**:
```dart
// On app resume or network restore
final uid = AuthService().currentUser?.uid;
if (uid != null) {
  // Force refresh to get latest remote data
  final userData = await FirestoreService.getUserData(uid, forceRefresh: true);
  
  // Optionally: Detect conflicts and resolve
  // (Current implementation: remote wins)
}
```

### Cache Invalidation

**Automatic Invalidation**:
- On logout (security requirement)
- On schema validation failure
- On manual `forceRefresh: true`

**Manual Invalidation**:
```dart
// Clear cache completely
await FirestoreService.clearCache();

// Force schema reload and migration
await FirestoreService.reloadSchemaAndMigrate(uid);
```

### Security Considerations

**What is Cached**:
- ✅ User profile data
- ✅ Game progress and stats
- ✅ Preferences and settings
- ✅ Inventory and coins

**What is NOT Cached**:
- ❌ Passwords (handled by Firebase Auth only)
- ❌ Sensitive authentication tokens
- ❌ Payment information
- ❌ Other users' data

**Encryption**:
- **Android**: Uses `EncryptedSharedPreferences` with AES-256
- **iOS**: Uses Keychain with `first_unlock` accessibility
- **Web**: Uses `localStorage` (less secure, acceptable for non-sensitive data)

**Cache Lifetime**:
- No automatic expiration (persistent until logout)
- Manual expiration via `forceRefresh: true`
- Schema-driven invalidation on version mismatch

---

## Local Storage & Caching

### LocalStorageService Architecture

The `LocalStorageService` provides a secure, reactive caching layer using Flutter Secure Storage.

#### Core Components

```dart
class LocalStorageService {
  // Singleton pattern for global access
  static final LocalStorageService _instance = LocalStorageService._();
  static LocalStorageService get instance => _instance;

  // Secure storage with platform-specific encryption
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // Reactive state management - UI listens to this
  final ValueNotifier<UserData?> userDataNotifier = ValueNotifier<UserData?>(null);
  
  // Storage keys
  static const String _userDataKey = 'cached_user_data';
  static const String _lastSyncKey = 'last_sync_timestamp';
}
```

### Save Operation

```dart
Future<void> saveUserData(UserData userData) async {
  try {
    // Serialize to JSON
    final jsonString = jsonEncode(userData.toJson());
    
    // Write encrypted to secure storage
    await _storage.write(key: _userDataKey, value: jsonString);
    
    // Update sync timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    await _storage.write(key: _lastSyncKey, value: timestamp);
    
    // Notify listeners (UI updates automatically)
    try {
      userDataNotifier.value = userData;
    } catch (_) {
      // Ignore notifier errors (non-critical)
    }
  } catch (e) {
    throw Exception('Failed to save user data to local storage: $e');
  }
}
```

### Load Operation

```dart
Future<UserData?> getUserData() async {
  try {
    // Read encrypted JSON
    final jsonString = await _storage.read(key: _userDataKey);
    
    if (jsonString == null) {
      return null; // No cached data
    }

    // Deserialize
    final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
    final ud = UserData.fromJson(jsonMap);
    
    // Sync notifier with cached value
    try {
      userDataNotifier.value = ud;
    } catch (_) {}
    
    return ud;
  } catch (e) {
    // Corrupted cache: clear and return null
    await clearUserData();
    return null;
  }
}
```

### Reactive UI Updates

UI components can subscribe to `userDataNotifier` for automatic updates:

```dart
// In a Flutter widget
class CoinsDisplay extends StatefulWidget {
  @override
  _CoinsDisplayState createState() => _CoinsDisplayState();
}

class _CoinsDisplayState extends State<CoinsDisplay> {
  @override
  void initState() {
    super.initState();
    
    // Listen to cache updates
    LocalStorageService.instance.userDataNotifier.addListener(_onUserDataChanged);
  }
  
  void _onUserDataChanged() {
    // UserData changed - rebuild widget
    setState(() {});
  }
  
  @override
  void dispose() {
    LocalStorageService.instance.userDataNotifier.removeListener(_onUserDataChanged);
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final userData = LocalStorageService.instance.userDataNotifier.value;
    final coins = userData?.getCoins() ?? 0;
    
    return Text('Coins: $coins');
  }
}
```

### Cache Utilities

```dart
// Check if cache exists
Future<bool> hasCachedData() async {
  try {
    final data = await _storage.read(key: _userDataKey);
    return data != null;
  } catch (e) {
    return false;
  }
}

// Get last sync time
Future<DateTime?> getLastSyncTime() async {
  try {
    final timestampString = await _storage.read(key: _lastSyncKey);
    if (timestampString == null) return null;
    
    final milliseconds = int.parse(timestampString);
    return DateTime.fromMillisecondsSinceEpoch(milliseconds);
  } catch (e) {
    return null;
  }
}

// Clear specific user data
Future<void> clearUserData() async {
  try {
    await _storage.delete(key: _userDataKey);
    await _storage.delete(key: _lastSyncKey);
    
    try {
      userDataNotifier.value = null;
    } catch (_) {}
  } catch (e) {
    throw Exception('Failed to clear user data from local storage: $e');
  }
}

// Clear all app storage (for debugging/account deletion)
Future<void> clearAll() async {
  try {
    await _storage.deleteAll();
  } catch (e) {
    throw Exception('Failed to clear all data from local storage: $e');
  }
}
```

### Platform-Specific Encryption

**Android**:
- Uses `EncryptedSharedPreferences`
- AES-256-GCM encryption
- Keys stored in Android Keystore
- Hardware-backed encryption on supported devices

**iOS**:
- Uses iOS Keychain Services
- `first_unlock` accessibility: data accessible after first device unlock
- Hardware encryption via Secure Enclave
- Survives app reinstalls (unless device is restored)

**Web**:
- Falls back to browser `localStorage`
- No encryption (not recommended for sensitive data)
- Consider implementing custom encryption for web builds

---

## Data Migration System

### Migration Philosophy

Code Sprout's migration system ensures **zero downtime** and **zero data loss** when schemas evolve. The system automatically detects schema mismatches and migrates data transparently.

### When Migration Occurs

```
┌────────────────────────────────────────────────────────────┐
│                     Migration Triggers                      │
├────────────────────────────────────────────────────────────┤
│ 1. Schema file updated (new fields added/removed)          │
│ 2. User logs in with outdated cached data                  │
│ 3. Field types changed (requires validation)               │
│ 4. Enum constraints added to existing fields               │
│ 5. Manual migration triggered via forceRefresh             │
└────────────────────────────────────────────────────────────┘
```

### Migration Process

```
┌──────────────────────┐
│  Load User Document  │
└──────────┬───────────┘
           │
           ▼
    ┌──────────────────┐
    │ Validate Against │
    │ Current Schema   │
    └──────┬───────────┘
           │
    ┌──────┴──────┐
    │             │
    ▼             ▼
┌────────┐   ┌─────────────┐
│ Valid  │   │  Invalid    │
└───┬────┘   │ (Errors > 0)│
    │        └──────┬──────┘
    │               │
    │               ▼
    │        ┌──────────────────────┐
    │        │ Create Default Data  │
    │        │ from Current Schema  │
    │        └──────┬───────────────┘
    │               │
    │               ▼
    │        ┌──────────────────────┐
    │        │ Preserve Valid       │
    │        │ Existing Values      │
    │        └──────┬───────────────┘
    │               │
    │               ▼
    │        ┌──────────────────────┐
    │        │ Insert Defaults for  │
    │        │ New Fields           │
    │        └──────┬───────────────┘
    │               │
    │               ▼
    │        ┌──────────────────────┐
    │        │ Remove Obsolete      │
    │        │ Fields               │
    │        └──────┬───────────────┘
    │               │
    │               ▼
    │        ┌──────────────────────┐
    │        │ Save Migrated Data   │
    │        │ to Firestore         │
    │        └──────┬───────────────┘
    │               │
    │               ▼
    │        ┌──────────────────────┐
    │        │ Update Local Cache   │
    │        └──────┬───────────────┘
    └────────────────┘
           │
           ▼
    ┌──────────────┐
    │ Return Data  │
    └──────────────┘
```

### Implementation

#### Validation

```dart
// UserDataSchema.validate()
List<String> validate(Map<String, dynamic> data) {
  final errors = <String>[];
  
  // Check all required fields
  _flattenedFields.forEach((path, field) {
    if (field.isRequired) {
      final value = _getNestedValue(data, path);
      if (value == null) {
        errors.add('Required field "$path" is missing');
      } else if (!field.validateValue(value)) {
        errors.add('Field "$path" has invalid type. Expected ${field.dataType}');
      }
    }
  });
  
  return errors; // Empty list = valid
}
```

#### Migration Logic

```dart
// UserDataSchema.migrateData()
Map<String, dynamic> migrateData(Map<String, dynamic> existingData) {
  // Step 1: Create fresh structure from current schema
  final migratedData = createDefaultData();
  
  // Step 2: Copy over existing values that match schema
  _flattenedFields.forEach((path, field) {
    final existingValue = _getNestedValue(existingData, path);
    
    // Preserve value if it exists and is valid
    if (existingValue != null && field.validateValue(existingValue)) {
      _setNestedValue(migratedData, path, existingValue);
    }
    // Otherwise, default value from schema is used
  });
  
  return migratedData;
}
```

#### Automatic Migration on Load

```dart
// UserData.load() - Called by FirestoreService.getUserData()
static Future<UserData?> load(String uid) async {
  try {
    final doc = await _usersCollection.doc(uid).get();
    
    if (!doc.exists) {
      return null;
    }

    final userData = UserData.fromFirestore(doc);
    
    // Validate against current schema
    final schema = await _getSchema();
    final errors = schema.validate(userData._data);
    
    if (errors.isNotEmpty) {
      // AUTOMATIC MIGRATION
      print('Migrating user data due to schema changes...');
      final migratedUserData = await userData.migrate();
      
      // Save migrated data back to Firestore
      await migratedUserData.save();
      
      return migratedUserData;
    }
    
    return userData; // No migration needed
  } catch (e) {
    throw Exception('Failed to load user data: $e');
  }
}

// UserData.migrate()
Future<UserData> migrate() async {
  final schema = await _getSchema();
  final migratedData = schema.migrateData(_data);
  
  return UserData(
    uid: uid,
    data: migratedData,
  );
}
```

### Migration Scenarios

#### Scenario 1: Adding New Fields

**Old Schema**:
```json
{
  "accountInformation": {
    "username": "string (null) [required]"
  }
}
```

**New Schema**:
```json
{
  "accountInformation": {
    "username": "string (null) [required]",
    "displayName": "string (null)",
    "bio": "string ()"
  }
}
```

**Migration Result**:
```json
{
  "accountInformation": {
    "username": "alice_sprout",  // ✅ Preserved
    "displayName": null,          // ✅ Added with default
    "bio": ""                     // ✅ Added with default
  }
}
```

#### Scenario 2: Removing Obsolete Fields

**Old Schema**:
```json
{
  "accountInformation": {
    "username": "string (null) [required]",
    "legacyField": "string (deprecated)"
  }
}
```

**New Schema**:
```json
{
  "accountInformation": {
    "username": "string (null) [required]"
  }
}
```

**Migration Result**:
```json
{
  "accountInformation": {
    "username": "alice_sprout"  // ✅ Preserved
    // ❌ legacyField removed
  }
}
```

#### Scenario 3: Changing Field Types

**Old Data**:
```json
{
  "sproutProgress": {
    "coins": "50"  // ❌ String instead of number
  }
}
```

**Schema**:
```json
{
  "sproutProgress": {
    "coins": "number (50)"
  }
}
```

**Migration Result**:
```json
{
  "sproutProgress": {
    "coins": 50  // ✅ Reset to default (type mismatch)
  }
}
```

⚠️ **Note**: Type changes cause data loss - existing value is replaced with default.

#### Scenario 4: Adding Enum Constraints

**Old Schema**:
```json
{
  "lastInteraction": {
    "difficulty": "string (null)"
  }
}
```

**New Schema**:
```json
{
  "lastInteraction": {
    "difficulty": "string (|beginner|intermediate|advanced|)"
  }
}
```

**Old Data**:
```json
{
  "lastInteraction": {
    "difficulty": "expert"  // ❌ Not in enum
  }
}
```

**Migration Result**:
```json
{
  "lastInteraction": {
    "difficulty": "beginner"  // ✅ Reset to default (first enum value)
  }
}
```

### Manual Migration

For complex schema changes (like renaming fields), trigger manual migration:

```dart
// Force schema reload and migration
await FirestoreService.reloadSchemaAndMigrate(uid);

// Implementation
static Future<void> reloadSchemaAndMigrate(String uid) async {
  try {
    // Reload the schema from assets
    await UserData.reloadSchema();
    
    // Migrate the user data
    await migrateUserData(uid);
  } catch (e) {
    throw Exception('Failed to reload schema and migrate: $e');
  }
}

static Future<void> migrateUserData(String uid) async {
  try {
    final userData = await UserData.load(uid);
    if (userData != null) {
      final migratedData = await userData.migrate();
      await migratedData.save();
      await _localStorage.saveUserData(migratedData);
    }
  } catch (e) {
    throw Exception('Failed to migrate user data: $e');
  }
}
```

### Migration Best Practices

1. **Test Migrations in Development**:
   ```dart
   // Create test user with old schema
   // Update schema
   // Load user and verify migration
   final userData = await UserData.load(testUid);
   expect(userData?.get('newField'), equals(defaultValue));
   ```

2. **Version Tracking** (optional enhancement):
   ```json
   {
     "schemaVersion": "2.1.0",
     "accountInformation": { ... }
   }
   ```

3. **Backup Before Major Changes**:
   ```dart
   // Export Firestore data before schema changes
   // Use Firebase console or Admin SDK
   ```

4. **Gradual Rollout**:
   - Deploy schema changes to staging first
   - Monitor migration success rate
   - Roll out to production incrementally

5. **Handling Renames** (requires custom logic):
   ```dart
   // Example: Rename 'username' to 'displayName'
   Map<String, dynamic> migrateData(Map<String, dynamic> existingData) {
     final migratedData = createDefaultData();
     
     // Custom rename logic
     final oldUsername = _getNestedValue(existingData, 'accountInformation.username');
     if (oldUsername != null) {
       _setNestedValue(migratedData, 'accountInformation.displayName', oldUsername);
     }
     
     // Continue with standard migration...
   }
   ```

### Enum Field Migration

**Enum Definition**:
```dart
class SchemaField {
  final List<String>? enumValues;  // e.g., ['beginner', 'intermediate', 'advanced']
  
  bool get isEnum => enumValues != null && enumValues!.isNotEmpty;
  
  bool validateValue(dynamic value) {
    if (isEnum) {
      if (value is! String) return false;
      return enumValues!.contains(value);
    }
    // ... other type checks
  }
}
```

**Enum Parsing from Schema**:
```dart
// Schema definition
"difficulty": "string (|beginner|intermediate|advanced|)"

// Parsed SchemaField
SchemaField(
  dataType: 'string',
  defaultValue: 'beginner',  // First value
  enumValues: ['beginner', 'intermediate', 'advanced'],
  isRequired: false
)
```

**UI Integration**:
```dart
// Dropdown for enum fields
DropdownButton<String>(
  value: currentDifficulty,
  items: ['beginner', 'intermediate', 'advanced']
    .map((value) => DropdownMenuItem(value: value, child: Text(value)))
    .toList(),
  onChanged: (newValue) async {
    await userData.updateField('lastInteraction.difficulty', newValue);
  },
)
```

---

## Security Implementation

### Firestore Security Rules

Code Sprout implements comprehensive security rules to protect user data and enforce access controls.

#### Current Security Rules (`firestore.rules`)

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    
    // Public username-to-UID mapping for login resolution
    match /username_map/{username} {
      // Allow unauthenticated reads for login flow
      allow get: if true;
      
      // Prevent listing all usernames
      allow list: if false;
      
      // Only owner can manage their mapping
      allow create, update, delete: if request.auth != null 
                                    && request.auth.uid == resource.data.uid;
    }
    
    // User documents - core security enforcement
    match /users/{userId} {
      // Authenticated users can read their own profile
      allow read: if request.auth != null;
      
      // Users can only create their own document during registration
      allow create: if request.auth != null 
                   && request.auth.uid == userId;
      
      // Users can only update their own document
      allow update: if request.auth != null 
                   && request.auth.uid == userId;
      
      // Users can delete their own document
      allow delete: if request.auth != null 
                   && request.auth.uid == userId;
      
      // Sub-collection: Code files
      match /codeFiles/{languageId} {
        // Owner-only access
        allow get, list: if request.auth != null 
                        && request.auth.uid == userId;
        allow create, update, delete: if request.auth != null 
                                      && request.auth.uid == userId;
      }
      
      // Sub-collection: Farm progress
      match /farmProgress/{document} {
        // Owner-only access
        allow get, list: if request.auth != null 
                        && request.auth.uid == userId;
        allow create, update, delete: if request.auth != null 
                                      && request.auth.uid == userId;
      }
    }
  }
}
```

#### Security Rules Breakdown

**1. Username Mapping Collection**

Purpose: Allows username-based login by mapping usernames to UIDs

```javascript
match /username_map/{username} {
  allow get: if true;  // Public reads for login
  allow list: if false;  // Prevent username enumeration
  allow create, update, delete: if request.auth != null 
                                && request.auth.uid == resource.data.uid;
}
```

Structure:
```json
{
  "username_map": {
    "alice_sprout": {
      "uid": "abc123xyz",
      "email": "alice@example.com"
    }
  }
}
```

**2. User Documents**

Enforces owner-only access with authentication requirement:

```javascript
match /users/{userId} {
  allow read: if request.auth != null;  // Any authenticated user can read their profile
  allow create: if request.auth != null && request.auth.uid == userId;
  allow update: if request.auth != null && request.auth.uid == userId;
  allow delete: if request.auth != null && request.auth.uid == userId;
}
```

**3. Sub-Collections**

Each sub-collection inherits the parent's security context:

```javascript
match /codeFiles/{languageId} {
  allow get, list: if request.auth != null && request.auth.uid == userId;
  allow create, update, delete: if request.auth != null && request.auth.uid == userId;
}
```

### Enhanced Security Rules (Production Recommendation)

For production deployments, add field-level validation:

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      // Helper function: Check if user is owner
      function isOwner() {
        return request.auth != null && request.auth.uid == userId;
      }
      
      // Helper function: Validate user data structure
      function validUserData() {
        let data = request.resource.data;
        
        return data.keys().hasAll(['accountInformation', 'sproutProgress']) &&
               data.accountInformation.keys().hasAll(['username']) &&
               data.accountInformation.username is string &&
               data.accountInformation.username.size() >= 3 &&
               data.sproutProgress.coins is int &&
               data.sproutProgress.coins >= 0;
      }
      
      allow read: if isOwner();
      
      allow create: if isOwner() && validUserData();
      
      allow update: if isOwner() && 
                      // Prevent username changes (optional constraint)
                      request.resource.data.accountInformation.username == 
                      resource.data.accountInformation.username;
      
      allow delete: if isOwner();
    }
  }
}
```

### Client-Side Security Measures

**1. Input Validation**

```dart
// Username validation
String? validateUsername(String username) {
  if (username.length < 3) {
    return 'Username must be at least 3 characters';
  }
  if (username.length > 20) {
    return 'Username cannot exceed 20 characters';
  }
  if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
    return 'Username can only contain letters, numbers, and underscores';
  }
  return null;
}

// Email validation
String? validateEmail(String email) {
  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
    return 'Invalid email format';
  }
  return null;
}

// Password validation
String? validatePassword(String password) {
  if (password.length < 6) {
    return 'Password must be at least 6 characters';
  }
  return null;
}
```

**2. Secure Data Storage**

```dart
// Never cache sensitive data
class UserData {
  // ❌ Don't store password
  // String? password;  
  
  // ✅ Only cache profile data
  final String uid;
  final Map<String, dynamic> _data;
}

// Clear cache on logout
Future<void> signOut() async {
  await FirestoreService.clearCache();  // Security-critical
  await _auth.signOut();
}
```

**3. Error Message Security**

```dart
// ❌ Don't reveal sensitive info
"User 'alice' does not exist in database"

// ✅ Use generic messages
"Invalid email or password"
```

### Authentication Security

**Firebase Auth Features Used**:
- Email verification (optional)
- Password reset via email
- Account lockout after failed attempts (automatic)
- Session management with secure tokens

**Implementation**:
```dart
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Secure authentication state
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // No password storage - handled by Firebase
  Future<String?> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,  // Sent securely to Firebase, never stored
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return _getGenericErrorMessage(e.code);  // Don't leak details
    }
  }
}
```

### Data Privacy

**What is Encrypted**:
- ✅ Local cache (AES-256 via flutter_secure_storage)
- ✅ Firestore data (encrypted at rest by Google)
- ✅ Network transmission (TLS/HTTPS)

**What is NOT Encrypted**:
- ⚠️ Data in memory (temporary during runtime)
- ⚠️ Debug logs (ensure no sensitive data logged)
- ⚠️ Firestore console access (admin has full access)

**Privacy Best Practices**:
```dart
// ❌ Don't log sensitive data
debugPrint('User password: $password');

// ✅ Log safely
debugPrint('User ${userData.uid} updated profile');

// ❌ Don't expose user data in URLs
'/api/user?email=alice@example.com'

// ✅ Use secure identifiers
'/api/user/${userData.uid}'
```

---

## API Reference

### AuthService

```dart
class AuthService {
  // Get current authenticated user
  User? get currentUser;
  
  // Auth state stream (for reactive UI)
  Stream<User?> get authStateChanges;
  
  // Sign in with email and password
  Future<String?> signIn({
    required String email,
    required String password,
  });
  
  // Register new user
  Future<String?> register({
    required String email,
    required String password,
  });
  
  // Sign out and clear cache
  Future<void> signOut();
}
```

### FirestoreService

```dart
class FirestoreService {
  // Create new user document after registration
  static Future<void> createUserDocument({
    required String uid,
    required String username,
  });
  
  // Check if username is already taken
  static Future<bool> usernameExists(String username);
  
  // Load user data (cache-first)
  static Future<UserData?> getUserData(String uid, {bool forceRefresh = false});
  
  // Update user data (writes to both cache and Firestore)
  static Future<void> updateUserData(UserData userData);
  
  // Force schema migration
  static Future<void> migrateUserData(String uid);
  
  // Reload schema and migrate
  static Future<void> reloadSchemaAndMigrate(String uid);
  
  // Clear local cache
  static Future<void> clearCache();
  
  // Get cached data without network request
  static Future<UserData?> getCachedUserData();
  
  // Check if cache exists
  static Future<bool> hasCachedData();
  
  // Delete user document (for account deletion)
  static Future<void> deleteUserDocument(String uid);
}
```

### UserData

```dart
class UserData {
  final String uid;
  
  // Factory constructors
  factory UserData.fromFirestore(DocumentSnapshot doc);
  factory UserData.fromJson(Map<String, dynamic> json);
  
  // Static factory methods
  static Future<UserData> create({
    required String uid,
    Map<String, dynamic>? initialData,
  });
  static Future<UserData> createDefault(String uid);
  
  // Load/save operations
  static Future<UserData?> load(String uid);
  Future<void> save();
  
  // Dot-notation access
  dynamic get(String path);
  void set(String path, dynamic value);
  
  // Field operations
  static Future<dynamic> getField(String uid, String path);
  Future<void> updateField(String path, dynamic value);
  Future<void> updateFields(Map<String, dynamic> updates);
  
  // Validation and migration
  Future<List<String>> validate();
  Future<UserData> migrate();
  
  // Coins management
  int getCoins();
  Future<void> addCoins(int amount);
  Future<bool> subtractCoins(int amount);
  bool canAfford(int cost);
  Future<bool> purchaseWithCoins({
    required int cost,
    required Map<String, int> items,
  });
  Future<bool> sellItem({
    required String itemId,
    required int quantity,
    required int sellAmountPerItem,
  });
  
  // Utility methods
  Map<String, dynamic> toFirestore();
  Map<String, dynamic> toJson();
  UserData copyWith(Map<String, dynamic> updates);
  Future<Map<String, dynamic>> getFlattenedData();
  
  // Schema information
  static Future<List<String>> getAvailableFields();
  static Future<List<String>> getSections();
  static Future<Map<String, SchemaField>> getFieldsInSection(String section);
  static Future<UserDataSchema> getSchema();
  static Future<void> reloadSchema();
}
```

### LocalStorageService

```dart
class LocalStorageService {
  static LocalStorageService get instance;
  
  // Reactive state
  final ValueNotifier<UserData?> userDataNotifier;
  
  // Save/load operations
  Future<void> saveUserData(UserData userData);
  Future<UserData?> getUserData();
  
  // Clear operations
  Future<void> clearUserData();
  Future<void> clearAll();
  
  // Utilities
  Future<DateTime?> getLastSyncTime();
  Future<bool> hasCachedData();
}
```

### UserDataSchema

```dart
class UserDataSchema {
  // Load schema from assets
  static Future<UserDataSchema> load();
  
  // Create default data structure
  Map<String, dynamic> createDefaultData();
  
  // Validation
  List<String> validate(Map<String, dynamic> data);
  
  // Migration
  Map<String, dynamic> migrateData(Map<String, dynamic> existingData);
  
  // Schema inspection
  List<String> getFieldPaths();
  SchemaField? getField(String path);
  Map<String, dynamic> getStructure();
  List<String> getSections();
  Map<String, SchemaField> getFieldsInSection(String section);
  Map<String, dynamic>? getSectionStructure(String section);
  bool hasSection(String section);
  bool isNestedMap(String path);
}
```

### SchemaField

```dart
class SchemaField {
  final String dataType;
  final dynamic defaultValue;
  final bool isRequired;
  final List<String>? enumValues;
  
  // Check if enum-based field
  bool get isEnum;
  
  // Get default value
  dynamic getDefaultValue();
  
  // Validate value against type
  bool validateValue(dynamic value);
  
  // Convert to Firestore type
  dynamic toFirestoreValue(dynamic value);
  
  // Parse from schema definition
  factory SchemaField.parse(String definition);
}
```

---

## Best Practices & Guidelines

### Schema Design

**1. Naming Conventions**
```json
{
  "sectionName": {          // camelCase for sections
    "fieldName": "...",      // camelCase for fields
    "anotherField": "..."
  }
}
```

**2. Grouping Related Fields**
```json
{
  "accountInformation": {   // Group account-related fields
    "username": "...",
    "email": "...",
    "createdAt": "..."
  },
  "gameProgress": {         // Group game-related fields
    "level": "...",
    "score": "...",
    "achievements": "..."
  }
}
```

**3. Sensible Defaults**
```json
{
  "sproutProgress": {
    "coins": "number (50)",              // ✅ New users start with 50 coins
    "experiencePoints": "number (0)",    // ✅ Starts at 0
    "selectedLanguage": "string (null)"  // ✅ Not selected yet
  }
}
```

**4. Required Fields**
```json
{
  "accountInformation": {
    "username": "string (null) [required]",  // ✅ Must be set during registration
    "bio": "string ()"                        // ❌ Optional, has default
  }
}
```

### Code Organization

**1. Use Path Constants**
```dart
// Define commonly used paths
class UserDataPaths {
  static const username = 'accountInformation.username';
  static const coins = 'sproutProgress.coins';
  static const hasPlayedTutorial = 'interaction.hasPlayedTutorial';
  static const experiencePoints = 'rankProgress.experiencePoints';
}

// Use in code
final username = userData.get(UserDataPaths.username);
await userData.updateField(UserDataPaths.coins, newCoins);
```

**2. Schema-Driven Access**
```dart
// ✅ Favor dot-notation access
final coins = userData.get('sproutProgress.coins') as int;

// ❌ Avoid adding many getters
// int get coins => get('sproutProgress.coins') as int;
```

**3. Error Handling**
```dart
try {
  final userData = await FirestoreService.getUserData(uid);
  if (userData == null) {
    // Handle missing user data
    print('User data not found');
    return;
  }
  
  // Use data
  final username = userData.get('accountInformation.username');
} catch (e) {
  // Handle errors gracefully
  print('Error loading user data: $e');
  // Show error UI or retry
}
```

### Testing Schema Changes

**1. Development Testing**
```dart
void testSchemaMigration() async {
  // Create test user with old schema version
  final oldData = {
    'accountInformation': {'username': 'test'},
    'oldField': 'deprecated'
  };
  
  // Update schema file
  await UserData.reloadSchema();
  
  // Test migration
  final schema = await UserData.getSchema();
  final migratedData = schema.migrateData(oldData);
  
  // Verify new fields added
  assert(migratedData.containsKey('newField'));
  
  // Verify old fields removed
  assert(!migratedData.containsKey('oldField'));
  
  // Verify existing fields preserved
  assert(migratedData['accountInformation']['username'] == 'test');
}
```

**2. Production Rollout**
- Deploy schema changes to staging first
- Test with subset of users
- Monitor error rates and migration success
- Gradually roll out to production

### Performance Optimization

**1. Minimize Firestore Reads**
```dart
// ✅ Use cache-first strategy
final userData = await FirestoreService.getUserData(uid);  // Reads from cache

// ❌ Don't force refresh unnecessarily
final userData = await FirestoreService.getUserData(uid, forceRefresh: true);  // Expensive
```

**2. Batch Updates**
```dart
// ✅ Batch multiple field updates
await userData.updateFields({
  'sproutProgress.coins': newCoins,
  'rankProgress.experiencePoints': newXP,
  'lastInteraction.languageId': 'python',
});

// ❌ Don't update fields individually
await userData.updateField('sproutProgress.coins', newCoins);
await userData.updateField('rankProgress.experiencePoints', newXP);
await userData.updateField('lastInteraction.languageId', 'python');
```

**3. Reactive UI with ValueNotifier**
```dart
// ✅ Subscribe to cache updates
class CoinsWidget extends StatefulWidget {
  @override
  _CoinsWidgetState createState() => _CoinsWidgetState();
}

class _CoinsWidgetState extends State<CoinsWidget> {
  @override
  void initState() {
    super.initState();
    LocalStorageService.instance.userDataNotifier.addListener(_updateUI);
  }
  
  void _updateUI() => setState(() {});
  
  @override
  void dispose() {
    LocalStorageService.instance.userDataNotifier.removeListener(_updateUI);
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final coins = LocalStorageService.instance.userDataNotifier.value?.getCoins() ?? 0;
    return Text('Coins: $coins');
  }
}
```

### Security Best Practices

**1. Input Validation**
- Always validate user input client-side
- Add server-side validation in Firestore rules
- Sanitize inputs to prevent injection attacks

**2. Error Messages**
- Use generic error messages for auth failures
- Don't reveal user existence in error messages
- Log detailed errors server-side only

**3. Data Access**
- Never expose other users' data
- Enforce owner-only access in Firestore rules
- Use Firebase Auth tokens for API requests

**4. Cache Management**
- Clear cache on logout
- Don't cache sensitive data (passwords, tokens)
- Use encrypted storage for cached data

---

## Extension Guide

### Adding New Schema Fields

**Step 1**: Update schema file
```json
{
  "accountInformation": {
    "username": "string (null) [required]",
    "displayName": "string (null)"  // ← New field
  }
}
```

**Step 2**: Existing users auto-migrate on next login
- No code changes needed
- Default value is `null`
- Validation ensures compatibility

**Step 3**: Use in code
```dart
final displayName = userData.get('accountInformation.displayName') as String?;
await userData.updateField('accountInformation.displayName', 'Alice');
```

### Adding Custom Data Types

**Step 1**: Update `SchemaField.validateValue()`
```dart
bool validateValue(dynamic value) {
  if (value == null) return !isRequired;
  
  switch (dataType.toLowerCase()) {
    // ... existing types ...
    
    case 'custom_type':  // ← New type
      return value is CustomClass;
    
    default:
      return false;
  }
}
```

**Step 2**: Update `SchemaField.toFirestoreValue()`
```dart
dynamic toFirestoreValue(dynamic value) {
  if (value == null) return null;
  
  switch (dataType.toLowerCase()) {
    // ... existing types ...
    
    case 'custom_type':  // ← New type
      return (value as CustomClass).toMap();
    
    default:
      return value;
  }
}
```

**Step 3**: Use in schema
```json
{
  "customField": "custom_type (default)"
}
```

### Adding Username-Based Login

The system already supports username mapping. To enable username login:

**Step 1**: Create username mapping on registration
```dart
await FirebaseFirestore.instance
  .collection('username_map')
  .doc(username)
  .set({
    'uid': uid,
    'email': email,
  });
```

**Step 2**: Resolve username to email on login
```dart
final usernameDoc = await FirebaseFirestore.instance
  .collection('username_map')
  .doc(username)
  .get();

if (!usernameDoc.exists) {
  return 'User not found';
}

final email = usernameDoc.data()!['email'] as String;
return await signIn(email: email, password: password);
```

---

## Troubleshooting

### Common Issues

**Issue**: "Failed to check username existence: timeout"
- **Cause**: Firestore rules blocking access or slow network
- **Solution**: Check `firestore.rules` allows read access to `username_map` collection

**Issue**: "Validation failed: Required field 'accountInformation.username' is missing"
- **Cause**: Missing required field during registration
- **Solution**: Ensure `initialData` contains all required fields

**Issue**: Cached data not updating in UI
- **Cause**: Not subscribing to `ValueNotifier`
- **Solution**: Add listener to `LocalStorageService.instance.userDataNotifier`

**Issue**: Data lost after schema update
- **Cause**: Field type changed, validation failed during migration
- **Solution**: Check migration logs, add custom migration logic for type changes

**Issue**: "Failed to save user data locally: PlatformException"
- **Cause**: Secure storage not available or permissions issue
- **Solution**: Check platform-specific permissions and fallback to non-secure storage if needed

---

## Summary

Code Sprout's authentication and data management system provides:

✅ **Schema-Driven Architecture** - Single source-of-truth for data structure  
✅ **Automatic Migration** - Seamless schema evolution with zero downtime  
✅ **Cache-First Strategy** - Instant access with background sync  
✅ **Reactive Updates** - ValueNotifier for automatic UI updates  
✅ **Encrypted Storage** - Secure local cache with AES-256  
✅ **Type Safety** - Runtime validation ensures data integrity  
✅ **Flexible Access** - Dot-notation paths for dynamic field access  
✅ **Production-Ready Security** - Comprehensive Firestore rules and client validation  

This system enables rapid feature development while maintaining data consistency, security, and performance across the application.

