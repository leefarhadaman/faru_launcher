# Faru Launcher — Google Play Store Listing & Release Metadata

## 1. App Identity

- **Public App Name:** Faru Launcher
- **Application ID / Package Name:** `dev.faru.faru_launcher`
- **Category:** Personalization / Productivity
- **Primary Accent Color:** `#7CC4FA` on `#0D0F12` dark canvas
- **Target Device Baseline:** Samsung Galaxy F54 (Android 13 / 14+ One UI)

## 2. Short Description (Under 80 Characters)

Minimal, text-first Android home launcher built for focus, speed, and privacy.

## 3. Full Store Description

Faru Launcher is a calm, distraction-free Android Home replacement designed for people who want to reach their apps quickly without visual noise or icon clutter.

### Key Features
- **Minimal Text-First Interface:** Clean, alphabetically sorted application list with high-contrast typography and generous touch targets.
- **Instant Search:** Case-insensitive search filters your installed apps as you type.
- **Pinned Favorites:** Pin your essential daily apps to the top of your home screen, with automatic cleanup when apps are uninstalled.
- **Opt-In Recent Searches:** Optional local search history with a single-tap Clear action.
- **Locale-Aware Clock Header:** Displays the current time and date respecting your Android 12/24-hour system format.
- **Strict On-Device Privacy:** Faru Launcher operates completely offline. Your installed app list, favorites, and search terms never leave your device. No analytics SDKs, no ads, and no broad `QUERY_ALL_PACKAGES` permission.

## 4. Release Signing Instructions

1. Copy `android/key.properties.example` to `android/key.properties` (never commit `key.properties` or `.jks` keystore files to Git).
2. Generate an upload keystore if you do not have one:
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
3. Build release artifacts from the project root:
   ```bash
   flutter build apk --release
   flutter build appbundle --release
   ```
