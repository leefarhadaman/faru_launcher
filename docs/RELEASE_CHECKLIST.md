# Faru Launcher — Release & Device Verification Checklist

## 1. Automated Quality Checks (Mac)

- [x] `AndroidManifest.xml` includes `<queries>` for `ACTION_MAIN` + `CATEGORY_LAUNCHER` outside `<application>`.
- [x] `AndroidManifest.xml` includes `MAIN` + `HOME` + `DEFAULT` intent filter alongside `MAIN` + `LAUNCHER`.
- [x] `MainActivity.kt` implements `dev.faru.launcher/apps` (`getApps` and `launchApp`) with Android 13+ (`SDK_INT >= 33`) compatibility.
- [x] UI, state, models, and services are cleanly separated under `lib/`.
- [x] Unit and widget tests implemented under `test/launcher_unit_test.dart` and `test/widget_test.dart`.
- [x] Privacy policy (`PRIVACY.md`) matches shipped code and permission inventory.

## 2. Physical Device Verification (Samsung Galaxy F54 — On Hold Until Connected)

- [ ] Enable Developer options and USB debugging on Samsung Galaxy F54.
- [ ] Verify phone is listed in `flutter devices`.
- [ ] Run `flutter run` and confirm app starts from its normal launcher icon.
- [ ] Open Samsung **Settings > Apps > Choose default apps > Home app** and confirm **Faru Launcher** is selectable.
- [ ] Select **Faru Launcher** as default Home app and verify pressing/gesturing Home returns to Faru Launcher.
- [ ] Verify case-insensitive search, app launching, favorite pinning, and manual/resume refresh.
- [ ] Switch default Home app back to **One UI Home** and verify normal restoration.
- [ ] Configure release signing in `android/app/build.gradle.kts` (using untracked `key.properties`) and build release artifacts:
  ```bash
  flutter build apk --release
  flutter build appbundle --release
  ```
