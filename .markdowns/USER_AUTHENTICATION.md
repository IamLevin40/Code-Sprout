# User Authentication with Data-Driven Schema (Code Sprout)

This document describes how Code Sprout handles user authentication together with the data-driven user data system and schema approach. It's a compact, single-source reference for developers who want to understand or extend authentication, registration, user data storage, caching, migration and security.

---

## Quick summary

- Authentication is done via Firebase Authentication (email/password).
- User profile data is stored in Cloud Firestore under the `users` collection where each document ID is the Firebase UID.
- The shape of user documents is driven entirely by the schema file: `assets/schemas/user_data_schema.txt`.
- A schema parser (`lib/models/user_data_schema.dart`) and dynamic model (`lib/models/user_data.dart`) provide generic get/set, validation, migration and serialization.
- `lib/services/firestore_service.dart` centralizes Firestore operations and integrates caching (`LocalStorageService`) so reads are cache-first and writes sync in background.

---

## Files you'll want to look at

- `assets/schemas/user_data_schema.txt` — single source-of-truth schema for user data (JSON form with type annotations and defaults).
- `lib/models/user_data_schema.dart` — schema loader, parser, validator and migration helper.
- `lib/models/user_data.dart` — dynamic UserData model with dot-notation access, validation, migrate/save/load/update helpers.
- `lib/services/firestore_service.dart` — service that creates user documents on registration, loads user data (with optional forceRefresh), updates fields, and migrates when needed.
- `lib/services/auth_service.dart` — authentication helper (sign-in, sign-out, currentUser access).
- `lib/services/local_storage_service.dart` — secure cache (uses `flutter_secure_storage`) and integrates with Firestore service to provide cache-first reads.

---

## Schema basics

The schema file defines sections and fields using this simple form:

```
"section": {
  "fieldName": "data_type (default_value) [required]",
  ...
}
```

Supported types include: `string`, `number`, `boolean`, `timestamp`, `geopoint`, `reference`, `array`, `map`, and `null`.

Enum fields use a pipe-delimited default value: `string (|Value1|Value2|)`, and the parser treats the first enum entry as the default.

The schema parser flattens nested maps into dot paths (e.g. `accountInformation.username`), builds default maps, validates values and can migrate existing documents to the latest schema.

---

## Registration & document creation (high level)

1. User registers with email/password in UI (`register_page.dart`).
2. App creates Firebase Authentication account.
3. After successful auth, `FirestoreService.createUserDocument(uid, initialData)` is called.
   - This uses the schema to create a default document structure (via `UserData.createDefault`) and merges provided initial values (e.g., username).
   - Document ID = Firebase UID; collection = `users`.
4. The created document has `accountInformation`, `interaction`, etc., as defined in the schema. Interaction defaults (e.g., `hasPlayedTutorial: false`) are set by the schema defaults.

Example (simplified):

```
// After auth
await FirestoreService.createUserDocument(
  uid: uid,
  initialData: {
    'accountInformation': {'username': chosenUsername}
  }
);
```

The service also validates username uniqueness and enforces client-side username rules (e.g., minimum length, alphanumeric) before creating the document.

---

## Loading user data (login → home flow)

- On login, services use `AuthService.currentUser?.uid` to get the UID.
- `FirestoreService.getUserData(uid)` loads the document using a cache-first strategy:
  - If cached and valid → return cached `UserData` (fast).
  - Otherwise fetch from Firestore, validate against schema and migrate if necessary, then cache and return.
- The UI should use schema-driven access, for example:

```
final userData = await FirestoreService.getUserData(uid);
final username = userData?.get('accountInformation.username') as String?;
```

This keeps the code schema-driven and avoids adding many trivial getters to the model.

---

## Caching & offline behavior

- `LocalStorageService` (backed by `flutter_secure_storage`) stores serialized `UserData.toJson()` securely and provides a cache-first API in `FirestoreService`.
- On reads: check cache → return if present; otherwise fetch from Firestore and cache.
- On writes: update cache first (instant UI), then sync to Firestore in background. If Firestore write fails, cache still contains the latest local state.
- Auth interactions: on sign-out, `AuthService.signOut()` clears the local cache for security and navigates back to login.

Security note: sensitive credentials (passwords) are never cached; only user profile data that the app needs is cached, and it's stored encrypted.

---

## Data migration

- When `UserData.load(uid)` or `getUserData` detects data that doesn't match the current schema, the system:
  1. Builds a migrated map using `UserDataSchema.migrateData()` — preserving existing, valid values and inserting defaults for new fields.
  2. Saves the migrated document back to Firestore.
  3. Updates cache and returns migrated `UserData` to the app.

Migration preserves values by dot-path matches. Removing fields in schema causes those keys to be dropped in the migrated document. Renaming fields is not automatic — treat as removal+addition and migrate manually if needed.

---

## Enum fields

- Enum fields are supported via the schema parser. Example field:

```
"interaction": { "difficulty": "string (|easy|normal|hard|)" }
```

- The parser captures the enum values. UI renders enum fields as dropdowns; validation only allows values in the enum set. When adding an enum constraint to an existing free-text field, existing invalid values will fail validation and require user correction or migration.

---

## Firestore security rules (recommended)

For production, ensure rules enforce that users can only read/write their own document and that required fields are present and of appropriate types. Example minimal rule:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

Add server-side validations to mirror schema requirements as needed.

---

## Best practices & recommendations

- Keep schema names stable and descriptive (camelCase). Use section grouping for related fields (e.g., `accountInformation`).
- Provide sensible defaults for non-required fields.
- Mark truly essential fields as `[required]` in the schema and enforce them both client- and server-side.
- Use short constants for common schema paths to avoid typos, e.g.

```
const usernamePath = 'accountInformation.username';
```

- Favor schema-driven access (`get('path')`) instead of adding many getter wrappers in `UserData`.
- Test schema changes in development before applying to production users. For renames, provide an explicit migration script.

---

## Example flows (condensed)

Registration

1. User fills registration form (username, email, password).
2. Client validates username rules, then calls Firebase Auth to create account.
3. On success, call `FirestoreService.createUserDocument(uid, {accountInformation.username})` which uses the schema to create defaults and write the document.

Login / Home Load

1. App checks `AuthService.currentUser`.
2. If logged in, call `FirestoreService.getUserData(uid)` → returns `UserData` (cache-first).
3. Use `userData.get('accountInformation.username')` in UI.

Logout

1. `AuthService.signOut()`
2. Clear local cache
3. Navigate to login

---

## Where to extend

- Add new schema fields in `assets/schemas/user_data_schema.txt`.
- UI will automatically include them in Settings if they are one of the supported types.
- For new custom types, update `SchemaField.validateValue()` and `toFirestoreValue()`, and implement UI widgets in `pages/settings_page.dart`.

