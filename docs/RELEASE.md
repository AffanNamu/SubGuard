# Releasing UniMarkLy

Two GitHub Actions workflows build the app.

| Workflow | Runs on | What it does |
|---|---|---|
| `build.yml` / Analyze and test | every push and pull request | `flutter analyze`, `flutter test`, and a check that the generated drift code is current |
| `build.yml` / Android release | pushes to `main` | builds an app bundle and an APK; signs them and uploads to Play internal testing when the Android secrets exist |
| `ios.yml` | pushes to `main` that touch `lib/`, `ios/`, `assets/` or the pubspec files | builds the iOS app; with the Apple secrets it signs an IPA and uploads it to TestFlight, without them it builds unsigned |

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

The secret names match the ones used in the eSportlyic repository, so they can be copied across.
Signing is skipped when `IOS_DIST_CERT_P12_B64` is empty.

| Secret | Value |
|---|---|
| `IOS_DIST_CERT_P12_B64` | Apple Distribution certificate (.p12), base64 encoded |
| `IOS_DIST_CERT_PASSWORD` | the .p12 password |
| `IOS_PROVISION_PROFILE_B64` | App Store provisioning profile for `com.nassaracoretech.unimarkly`, base64 encoded |
| `IOS_PROVISION_PROFILE_NAME` | the profile's **name** as shown in the Apple developer portal (not the file name) |
| `IOS_EXPORT_TEAM_ID` | Apple Developer Team ID |
| `KEYCHAIN_PASSWORD` | any random string; protects the temporary keychain on the runner |
| `ASC_API_KEY_ID`, `ASC_API_ISSUER_ID`, `ASC_API_KEY_P8_B64` | App Store Connect API key; the last is the .p8 file, base64 encoded. Without all three the IPA is kept as an artifact and not uploaded |

The profile must be created for the bundle ID above, which is different from the eSportlyic one,
so the existing profile and its secrets cannot be reused as they are.

Lessons carried over from the eSportlyic workflow, which hit each of these:

- It runs on `macos-26`. App Store Connect rejects uploads built with an SDK older than iOS 26.
- The Xcode project signs with the "iPhone Developer" identity by default. The workflow overrides it
  to Manual signing with "Apple Distribution", and writes the profile name into the Runner target only.
  A project-wide profile setting breaks every CocoaPods library target.
- The build number is the GitHub run number, so App Store Connect never sees the same build twice.

The signing and upload steps have not been run against a real Apple account. Run the workflow once
with the secrets set and read the log, which prints the signing identities and profile identifiers.

**Flutter version.** Both workflows pin Flutter 3.32.0. The eSportlyic workflow pins 3.47.1 and
builds with Xcode 26. Whether 3.32.0 builds cleanly with Xcode 26 is not yet known. If the iOS run
fails while compiling, raising `FLUTTER_VERSION` in both workflows is the first thing to try.
Android must be rebuilt and checked at the same time.

### Privacy manifest

`ios/Runner/PrivacyInfo.xcprivacy` declares no tracking and no collected data, which is true while
everything stays on the phone. When accounts and sync are added, declare the email address and user
content. `tool/register_ios_privacy_manifest.rb` adds the file to the Runner target; it is already
registered in the committed project.

## Version numbers

`version:` in `pubspec.yaml` is the version users see (for example `1.0.0`). The workflow passes
the GitHub run number as the build number, so every upload has a higher build number than the last.

## Changing the database

See the notes at the top of `lib/data/database/migrations.dart`. Never change a released schema
without bumping `latestSchemaVersion`, adding a numbered migration, and running
`tool/generate_schema.sh`.

## Changing the icon

Replace `design/icon/source.png`, then run `tool/generate_icons.sh`.
