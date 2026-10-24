# Releasing UniMarkLy

The GitHub Actions workflow in `.github/workflows/build.yml` does three jobs.

| Job | Runs on | What it does |
|---|---|---|
| Analyze and test | every push and pull request | `flutter analyze`, `flutter test`, and a check that the generated drift code is current |
| Android release | pushes to `main` | builds an app bundle and an APK; signs them and uploads to Play internal testing when the secrets below exist |
| iOS release | pushes to `main` | always builds the iOS app without signing; signs, builds an IPA and uploads to TestFlight when the secrets below exist |

Without any secrets the workflow still builds both apps. They are just not signed for the stores.

## Identity

| | |
|---|---|
| App name | UniMarkLy |
| Android application ID | `com.nassaracoretech.unimarkly` |
| iOS bundle ID | `com.nassaracoretech.unimarkly` |

Store IDs cannot be changed after the first upload. Decide before the first release.

## Repository secrets

### Android (Play internal testing)

Create an upload key once and keep a copy somewhere safe:

```
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
base64 -w0 upload-keystore.jks     # paste the output into ANDROID_KEYSTORE_BASE64
```

| Secret | Value |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | the keystore, base64 encoded |
| `ANDROID_KEYSTORE_PASSWORD` | keystore password |
| `ANDROID_KEY_ALIAS` | `upload` (or the alias you chose) |
| `ANDROID_KEY_PASSWORD` | key password |
| `PLAY_SERVICE_ACCOUNT_JSON` | Google Play service account JSON, with release permission on the app |

The app must already exist in Play Console, and the first bundle must be uploaded by hand once.

### iOS (TestFlight)

| Secret | Value |
|---|---|
| `IOS_CERTIFICATE_P12_BASE64` | Apple Distribution certificate (.p12), base64 encoded |
| `IOS_CERTIFICATE_PASSWORD` | the .p12 password |
| `IOS_PROVISIONING_PROFILE_BASE64` | App Store provisioning profile for the bundle ID, base64 encoded |
| `IOS_PROVISIONING_PROFILE_NAME` | the profile's name, exactly as in the Apple developer portal |
| `IOS_KEYCHAIN_PASSWORD` | any random string; protects the temporary keychain on the runner |
| `IOS_TEAM_ID` | Apple developer team ID |
| `APPSTORE_API_KEY_ID`, `APPSTORE_API_ISSUER_ID`, `APPSTORE_API_PRIVATE_KEY` | App Store Connect API key (the .p8 contents) |

The signing and upload steps were written without access to a Mac or an Apple account.
Run the workflow once with the secrets set and read the log before relying on it.

## Version numbers

`version:` in `pubspec.yaml` is the version users see (for example `1.0.0`). The workflow passes
the GitHub run number as the build number, so every upload has a higher build number than the last.

## Changing the database

See the notes at the top of `lib/data/database/migrations.dart`. Never change a released schema
without bumping `latestSchemaVersion`, adding a numbered migration, and running
`tool/generate_schema.sh`.

## Changing the icon

Replace `design/icon/source.png`, then run `tool/generate_icons.sh`.
