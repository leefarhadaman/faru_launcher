# Changelog

All notable changes to **Faru Launcher** are documented in this file.

## [0.1.0] - 2026-10-21

### Added
- **Phase 0 & 1:** Initial Flutter scaffold (`--org dev.faru`), recorded toolchain versions, and project blueprint (`docs/FARU_LAUNCHER_PROJECT_PLAN.md`).
- **Phase 2:** Registered `MainActivity` as an Android Home app (`MAIN` + `HOME` + `DEFAULT` intent filter) while preserving the `MAIN` + `LAUNCHER` filter for development.
- **Phase 3:** Added targeted Android 11+ `<queries>` declaration for `ACTION_MAIN` + `CATEGORY_LAUNCHER` and implemented `MethodChannel("dev.faru.launcher/apps")` in `MainActivity.kt` (`getApps` with Android 13+ `ResolveInfoFlags` support and `launchApp`).
- **Phase 4 & 5:** Built the dark-themed minimalist home screen and refactored into `models/`, `services/`, `launcher/`, `app/`, and `settings/`.
- **Phase 6 & 7:** Added pinned favorites with uninstalled-package cleanup, opt-in recent search history with clear controls, locale-aware 12/24h date/time display, TalkBack semantics, settings screen, and `WidgetsBindingObserver` resume refresh.
- **Phase 8–10:** Added unit tests (`test/launcher_unit_test.dart`), widget tests (`test/widget_test.dart`), privacy policy (`PRIVACY.md`), architecture guide (`docs/ARCHITECTURE.md`), and release checklist (`docs/RELEASE_CHECKLIST.md`).
