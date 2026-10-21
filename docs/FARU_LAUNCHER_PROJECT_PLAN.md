# Faru Launcher — Complete Project Blueprint

**Document purpose:** This is the single source of truth for building, testing, maintaining, and publishing Faru Launcher. It is written so a new developer, teammate, or AI coding assistant can understand the product, current architecture, implementation phases, constraints, and definition of done without needing the original conversation.

**Project status:** Implemented MVP + Refactored Architecture + Productivity Features + Automated Tests

**Target device for development:** Samsung Galaxy F54

**Development computer:** Mac (`macos_arm64`, macOS 26.7.1)

**Primary technology:** Flutter/Dart for UI, Kotlin for Android-specific APIs

**Product goal:** A polished, productivity-focused Android launcher with a minimal text-based app list, suitable for personal use first and eventual public release.

---

## Recorded Toolchain & Project Baseline Versions (Phase 0 & 1)

- **Flutter SDK:** `3.47.6` (channel `stable`, framework revision `5fc346839b`, engine revision `692136cb65`)
- **Dart SDK:** `3.13.5` (stable)
- **DevTools:** `2.60.0`
- **Gradle Wrapper:** `9.3.1` (`gradle-9.3.1-all.zip`)
- **Android Gradle Plugin (AGP):** `9.1.0`
- **Kotlin Android Plugin:** `2.4.0`
- **Java / JVM Target:** `JavaVersion.VERSION_17` (`JvmTarget.JVM_17`)
- **Application ID / Namespace:** `dev.faru.faru_launcher`
- **MethodChannel Name:** `dev.faru.launcher/apps`

---

## 1. Product summary

Faru Launcher is an alternative Android Home app. Its design should reduce visual noise and help users reach apps quickly. The default experience is intentionally text-first rather than icon-heavy.

### Product principles

1. **Productivity before decoration:** prioritize search, speed, clarity, and predictable behavior.
2. **Minimal by default:** typography, spacing, and a restrained accent color do most of the visual work.
3. **Privacy-first:** installed-app information stays on-device unless a future feature has a clear, disclosed reason to transmit data.
4. **Reliable Android behavior:** returning Home should return to Faru Launcher when it is selected as the default Home app.
5. **Accessible:** support readable text, TalkBack labels, sufficient contrast, and touch targets that are easy to use.
6. **Incremental delivery:** each phase must be testable before the next phase begins.
7. **No false completeness:** the starter code is a foundation, not a complete production launcher. Features must not be described as finished until implemented and tested.

### Target users

People who prefer a distraction-free Android home screen and want to search for and launch apps quickly.

### Initial experience

- A calm home screen with the Faru name/brand.
- A prominent search field.
- A minimal, alphabetically sorted text list of launchable apps.
- Tap an app name to open it.
- Refresh the app list.
- Clear loading, empty, and error states.
- Android can select Faru Launcher as the default Home app.

### Explicit non-goals for the first milestone

- Replacing Android or Samsung One UI system apps.
- Root access or modifying the operating system.
- Recreating all Samsung One UI features.
- Full widget hosting, advanced gesture customization, icon packs, or cloud sync in the MVP.
- Collecting analytics or uploading the user's installed-app list.

---

## 2. Technology and architecture

### Technology stack

- **Flutter/Dart:** all primary launcher screens, UI state, search, settings UI, animations, and user-facing interactions.
- **Kotlin:** Android-specific app discovery, app launching, Home-app integration, and future platform features not exposed by Flutter.
- **Flutter MethodChannel:** initial communication bridge between Dart and Kotlin (`dev.faru.launcher/apps`).
- **Local Preferences Service:** lightweight local key-value store with JSON persistence for favorites, recent searches, and display settings.
- **Git:** version control; use structured phase commits.

### Architecture overview

```text
Flutter UI (Dart)
  ├── FaruLauncherApp (lib/app/faru_launcher_app.dart)
  ├── FaruTheme (lib/app/theme.dart)
  ├── HomeScreen (lib/launcher/home_screen.dart)
  ├── AppListScreen (lib/launcher/app_list_screen.dart)
  ├── SettingsScreen (lib/settings/settings_screen.dart)
  ├── LauncherController & LauncherState (lib/launcher/)
  └── Services (lib/services/)
          ├── PreferencesService (favorites, recent searches, settings)
          └── LauncherService
                  │
                  │ MethodChannel: dev.faru.launcher/apps
                  ▼
Android Kotlin bridge (MainActivity.kt)
  ├── getApps()   -> query launchable activities
  └── launchApp() -> start selected app's launch intent
          │
          ▼
Android PackageManager and Activity APIs
```

---

## 3. Phase roadmap: Step 0 to release

- **Phase 0 — Define scope and protect the baseline:** Completed (Initial Flutter scaffold & project plan committed).
- **Phase 1 — Development environment and device setup:** Scaffold created on Mac (`--org dev.faru faru_launcher`). Physical Samsung Galaxy F54 verification held until USB connection.
- **Phase 2 — Register Faru Launcher as an Android Home app:** Completed (`MAIN` + `HOME` + `DEFAULT` intent filter added alongside `MAIN` + `LAUNCHER`).
- **Phase 3 — Native app discovery and app launching:** Completed (`<queries>` declaration in `AndroidManifest.xml` and `MethodChannel` bridge in `MainActivity.kt`).
- **Phase 4 — Build the first usable Flutter home screen (MVP):** Completed (Faru branding, real-time search, alphabetical app list, counts, refresh, loading/error/empty states).
- **Phase 5 — Refactor into maintainable code:** Completed (separated into `models/`, `services/`, `launcher/`, `app/`, `settings/`).
- **Phase 6 — Productivity features:** Completed (Pinned favorites, optional recent searches with clear control, live date/time header, TalkBack semantics, preferences screen).
- **Phase 7 — Native launcher capabilities and lifecycle robustness:** Completed (`WidgetsBindingObserver` lifecycle resume refresh and safe error handling).
- **Phase 8 — Testing and quality assurance:** Completed (Unit tests and widget tests verified via `flutter analyze` and `flutter test`; physical F54 checklist documented).
- **Phase 9 — Privacy, security, and policy review:** Completed (`PRIVACY.md` and permission inventory audited).
- **Phase 10 — Release preparation:** Completed (`README.md`, `CHANGELOG.md`, `docs/ARCHITECTURE.md`, and `docs/RELEASE_CHECKLIST.md`).
