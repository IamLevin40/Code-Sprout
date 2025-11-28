# APK Build Instructions (Windows PowerShell)

This project is prepared to support building a signed release APK.
Follow these steps to generate a keystore, provide signing properties, and build the APK.

Prerequisites
- Flutter installed and available on PATH.
- Android SDK installed and configured (ANDROID_HOME/ANDROID_SDK_ROOT set).
- JDK installed (for `keytool`) and available on PATH.

1) Generate a keystore (recommended)

Open PowerShell in the project root and run:

```powershell
# optionally customize alias, storepass, keypass, and dname
.\scripts\generate_keystore.ps1 -alias code_sprout_key -storepass YOUR_STORE_PASS -keypass YOUR_KEY_PASS -dname "CN=Your Name, OU=Dev, O=Organization, L=City, S=State, C=US"
```

This will create `android/app/keystore.jks` by default.

2) Create `key.properties` at the project root

Copy the template and edit values:

```powershell
Copy-Item key.properties.template key.properties
# then open key.properties in an editor and replace placeholder values
```

Make sure `storeFile` points to the keystore path (the template uses `android/app/keystore.jks`).

3) Build a release APK

Run the following commands in PowerShell:

```powershell
flutter clean; flutter pub get
flutter build apk --release
```

If `key.properties` exists at the project root, Gradle will pick it up and sign the APK with your keystore. The resulting APK will be in `build/app/outputs/flutter-apk/app-release.apk`.

Notes & troubleshooting
- The project `minSdk` has been set to API level 15 as requested. Some modern plugins might require a higher `minSdk`; if you see build errors complaining about newer APIs, consider increasing `minSdk`.
- Ensure the Android SDK `compileSdk` installed on your machine matches the project's `compileSdk` (the Flutter tooling normally handles this). If Gradle complains about missing SDK platforms, install the matching SDK via Android Studio SDK Manager.
- Keep `key.properties` private and do not commit it to version control. Add `key.properties` to `.gitignore` if you haven't already.

Optional: build an app bundle

```powershell
flutter build appbundle --release
```

This produces an AAB file suitable for Play Store upload.

Remote build (no local Android SDK required)

- Overview: You can build the Android APK on a remote CI runner (GitHub Actions, Codemagic, Bitrise, etc.). The repository contains a ready-made GitHub Actions workflow at `.github/workflows/build_apk.yml` which sets up Flutter and Android on an Ubuntu runner, prepares signing and Firebase configuration from repository secrets, builds the release APK, and uploads the APK as an artifact.

- Required repository secrets (case-sensitive):
	- `KEYSTORE_BASE64` — base64-encoded contents of your `keystore.jks` (or omit to let CI generate an ephemeral keystore).
	- `KEYSTORE_PASSWORD` — the keystore `storePassword`.
	- `KEY_PASSWORD` — the key `keyPassword`.
	- `KEY_ALIAS` — the key alias used when generating the keystore.
	- `GOOGLE_SERVICES_JSON` — the full contents of `google-services.json` (or use `GOOGLE_SERVICES_JSON_BASE64` and base64-decode in workflow; see notes).
	- Firebase config secrets (used to generate `lib/firebase_options.dart` on CI):
		- `FIREBASE_WEB_API_KEY`, `FIREBASE_WEB_APP_ID`, `FIREBASE_WEB_MESSAGING_SENDER_ID`, `FIREBASE_WEB_PROJECT_ID`, `FIREBASE_WEB_AUTH_DOMAIN`, `FIREBASE_WEB_STORAGE_BUCKET`, `FIREBASE_WEB_MEASUREMENT_ID`
		- `FIREBASE_ANDROID_API_KEY`, `FIREBASE_ANDROID_APP_ID`, `FIREBASE_ANDROID_MESSAGING_SENDER_ID`, `FIREBASE_ANDROID_PROJECT_ID`, `FIREBASE_ANDROID_STORAGE_BUCKET`
		- `FIREBASE_IOS_API_KEY`, `FIREBASE_IOS_APP_ID`, `FIREBASE_IOS_MESSAGING_SENDER_ID`, `FIREBASE_IOS_PROJECT_ID`, `FIREBASE_IOS_STORAGE_BUCKET`, `FIREBASE_IOS_BUNDLE_ID`

- How to create `KEYSTORE_BASE64` locally (PowerShell):
```powershell
.\scripts\encode_keystore.ps1 -keystorePath android/app/keystore.jks > keystore.b64
# open keystore.b64, copy its contents, and paste into GitHub secret 'KEYSTORE_BASE64'
```

- How to add `google-services.json` as a secret (recommended):
	- Download `google-services.json` from your Firebase Console for the Android app (ensure package name/applicationId matches `android/app/build.gradle`).
	- In GitHub: Repository → Settings → Secrets and variables → Actions → New repository secret
		- Name: `GOOGLE_SERVICES_JSON`
		- Value: paste the full JSON file contents (no extra quotes)

- Using base64 for google-services.json (optional, robust for multiline):
```powershell
# to create base64 value locally
$txt = Get-Content android\app\google-services.json -Raw
[Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($txt)) > google-services.json.b64
# copy the contents of google-services.json.b64 into secret named GOOGLE_SERVICES_JSON_BASE64
```

- How to add secrets using GitHub CLI (`gh`) (optional):
```powershell
# requires `gh` authenticated
#$keystore = Get-Content keystore.b64 -Raw
gh secret set KEYSTORE_BASE64 --body "$keystore"
gh secret set KEYSTORE_PASSWORD --body "YOUR_STORE_PASS"
gh secret set KEY_PASSWORD --body "YOUR_KEY_PASS"
gh secret set KEY_ALIAS --body "code_sprout_key"
# add google-services.json (raw)
$gsvc = Get-Content google-services.json -Raw
gh secret set GOOGLE_SERVICES_JSON --body "$gsvc"
# add firebase config secrets similarly
```

- Trigger the workflow:
	- From the GitHub UI: Actions → Build Android APK (remote) → Run workflow (or push a branch/commit to a monitored branch).
	- Or with `gh`: `gh workflow run build_apk.yml`
	- After the run completes, download the artifact named `app-release-apk`.

- Notes & security:
	- The workflow supports either decoding a provided keystore or generating an ephemeral keystore on the runner. Ephemeral keystores are fine for testing but cannot be used to update Play Store releases.
	- `GOOGLE_SERVICES_JSON` (or its base64 variant) must match the Firebase project and Android package name.
	- We generate `lib/firebase_options.dart` on CI from the FIREBASE_* secrets so you don't need to commit that file.
	- After adding secrets to GitHub, delete local `keystore.b64` and any copies of `google-services.json` you don't want stored locally. Add `key.properties`, `keystore.jks`, and `android/app/google-services.json` to `.gitignore` if needed.

If you need help creating the Firebase app or the `google-services.json`, I can walk you through the Firebase Console steps.
