# Faru Launcher

Faru Launcher is a minimal, text-first, privacy-conscious Android Home launcher built with Flutter (UI/state) and Kotlin (Android `PackageManager` and `Activity` integration).

## Features

- **Minimal Text-First Home Screen:** Alphabetically sorted list of launchable apps with zero icon clutter.
- **Instant Case-Insensitive Search:** Real-time filtering by app label or package name as you type.
- **Pinned Favorites:** Pin/unpin frequently used apps to the top of your home screen, with automatic cleanup when apps are uninstalled.
- **Optional Local Recent Searches:** Opt-in local recent search chips with a single-tap Clear action.
- **Locale-Aware Date & Time Header:** Respects Android 12/24-hour system settings and can be toggled in Settings.
- **Lifecycle Auto-Refresh:** Automatically refreshes the installed app list when returning to Faru Launcher (`AppLifecycleState.resumed`), alongside a manual Refresh button.
- **Accessible & Resilient:** TalkBack semantic labels, >=48dp touch targets, font scaling support, and clear loading, empty, and error/retry states.
- **Strict On-Device Privacy:** Uses a targeted `<queries>` declaration (`ACTION_MAIN` + `CATEGORY_LAUNCHER`), zero network permissions, and zero analytics SDKs.

## Repository Structure

```text
faru_launcher/
├── README.md
├── CHANGELOG.md
├── PRIVACY.md
├── docs/
│   ├── FARU_LAUNCHER_PROJECT_PLAN.md
│   ├── ARCHITECTURE.md
│   └── RELEASE_CHECKLIST.md
├── lib/
│   ├── main.dart
│   ├── app/
│   │   ├── faru_launcher_app.dart
│   │   └── theme.dart
│   ├── launcher/
│   │   ├── home_screen.dart
│   │   ├── app_list_screen.dart
│   │   ├── launcher_controller.dart
│   │   └── launcher_state.dart
│   ├── models/
│   │   └── launcher_app.dart
│   ├── services/
│   │   ├── launcher_service.dart
│   │   └── preferences_service.dart
│   └── settings/
│       └── settings_screen.dart
├── android/
│   └── app/src/main/
│       ├── AndroidManifest.xml
│       └── kotlin/dev/faru/faru_launcher/MainActivity.kt
└── test/
    ├── launcher_unit_test.dart
    └── widget_test.dart
```

## Running on Samsung Galaxy F54

1. On your Samsung Galaxy F54, open **Settings > About phone > Software information** and tap **Build number** 7 times to enable Developer options.
2. Open **Settings > Developer options** and enable **USB debugging**.
3. Connect the Galaxy F54 to your Mac via USB and accept the USB debugging authorization prompt on the phone.
4. From the project root (`Downloads/Freelance/faru_launcher`), run:
   ```bash
   flutter devices
   flutter run
   ```
5. To test Home app behavior on the Galaxy F54, open **Settings > Apps > Choose default apps > Home app** and select **Faru Launcher** (you can switch back to **One UI Home** at any time).
