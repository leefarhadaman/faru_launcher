# Faru Launcher — Architecture Documentation

## 1. Layered Overview

Faru Launcher separates UI presentation, state management, local persistence, and Android platform integration into distinct layers:

1. **Presentation Layer (`lib/app/`, `lib/launcher/`, `lib/settings/`):**
   - `FaruLauncherApp` (`lib/app/faru_launcher_app.dart`) and `FaruTheme` (`lib/app/theme.dart`) configure the high-contrast dark theme and root navigation.
   - `HomeScreen` (`lib/launcher/home_screen.dart`) renders the Faru header, optional live date/time clock, search bar, opt-in recent searches, app counts, and state transitions (loading, error/retry, empty, and loaded). It also observes `AppLifecycleState.resumed` via `WidgetsBindingObserver` to refresh the app list when returning Home.
   - `AppListView` and `AppListTile` (`lib/launcher/app_list_screen.dart`) render pinned favorites and the alphabetically sorted app list with TalkBack semantics and >=48dp touch targets.
   - `SettingsScreen` (`lib/settings/settings_screen.dart`) manages clock visibility, opt-in recent search history, history clearing, and manual app-list refresh.

2. **State & Controller Layer (`lib/launcher/launcher_controller.dart`, `lib/launcher/launcher_state.dart`):**
   - `LauncherState` is an immutable value object holding `status`, `allApps`, `filteredApps`, `favoritePackages`, `recentSearches`, `recentSearchEnabled`, `showClock`, `searchQuery`, and error messages.
   - `LauncherController` (`ChangeNotifier`) coordinates app loading, case-insensitive filtering (`filterApps`), app launching, favorite pinning/unpinning, automatic cleanup of uninstalled favorite packages, and preference persistence.

3. **Service & Model Layer (`lib/models/launcher_app.dart`, `lib/services/`):**
   - `LauncherApp` represents an installed launchable application (`label`, `packageName`) with case-insensitive sorting and map serialization.
   - `LauncherService` encapsulates `MethodChannel('dev.faru.launcher/apps')` and translates `PlatformException` / `MissingPluginException` into typed `LauncherException` instances.
   - `PreferencesService` provides local JSON persistence for favorites, recent searches, and display settings.

4. **Android Native Bridge (`android/app/src/main/kotlin/dev/faru/faru_launcher/MainActivity.kt`):**
   - Hosts `MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dev.faru.launcher/apps")`.
   - `getApps`: queries `PackageManager.queryIntentActivities` for `Intent.ACTION_MAIN` + `Intent.CATEGORY_LAUNCHER` (using `PackageManager.ResolveInfoFlags.of(0L)` on Android 13 / API 33+ and compatible flags on older versions), deduplicates by `packageName`, and sorts case-insensitively by label.
   - `launchApp`: resolves `packageManager.getLaunchIntentForPackage(packageName)` and calls `startActivity(intent)`, returning structured error codes (`INVALID_ARGUMENT`, `APP_NOT_LAUNCHABLE`, `LAUNCH_FAILED`) on failure.

## 2. MethodChannel Contract

| Method | Direction | Arguments | Return Payload | Error Codes |
|---|---|---|---|---|
| `getApps` | Dart -> Kotlin | `null` | `List<Map<String, String>>` (`[{"label": "...", "packageName": "..."}]`) | `APP_DISCOVERY_FAILED` |
| `launchApp` | Dart -> Kotlin | `{"packageName": "<String>"}` | `Boolean` (`true`) | `INVALID_ARGUMENT`, `APP_NOT_LAUNCHABLE`, `LAUNCH_FAILED` |
