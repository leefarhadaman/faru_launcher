# Privacy Policy — Faru Launcher

**Effective Date:** October 21, 2026

## 1. Overview

Faru Launcher (`dev.faru.faru_launcher`) is a minimalist Android Home screen replacement designed with strict on-device privacy.

## 2. Data Accessed On-Device

To function as an Android Home launcher, Faru Launcher queries the Android `PackageManager` for installed applications that expose a launchable activity (`android.intent.action.MAIN` with category `android.intent.category.LAUNCHER`).

- **Installed Application List:** Displayed locally on your screen so you can search and launch your apps. This list is never transmitted off your device.
- **Local Preferences & Pinned Favorites:** Pinned favorite package names, clock display preferences, and optional recent search terms (if explicitly enabled by the user in Settings) are stored strictly in local device storage. Users can disable or clear recent search history at any time in Settings.

## 3. Permissions & Package Visibility

- **Targeted Package Visibility (`<queries>`):** Faru Launcher declares a targeted `<queries>` intent filter for `ACTION_MAIN` + `CATEGORY_LAUNCHER` rather than requesting broad `QUERY_ALL_PACKAGES` permissions unless required by future user-facing features.
- **No Network or Analytics Transmission:** The release configuration of Faru Launcher does not include third-party advertising, analytics, or telemetry SDKs and does not upload any user or device data to external servers.

## 4. Third-Party Dependencies

Faru Launcher relies solely on the official Flutter SDK and Android Jetpack/platform libraries shipped with the standard Flutter Android embedding.

## 5. Contact

For questions regarding privacy or data handling, contact the Faru Launcher maintainer via the repository issue tracker.
