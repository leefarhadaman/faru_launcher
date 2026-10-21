import 'package:flutter/foundation.dart';
import '../models/launcher_app.dart';
import '../services/launcher_service.dart';
import '../services/preferences_service.dart';
import 'launcher_state.dart';

class LauncherController extends ChangeNotifier {
  LauncherController({
    LauncherService? launcherService,
    PreferencesService? preferencesService,
  })  : _launcherService = launcherService ?? LauncherService(),
        _preferencesService = preferencesService ?? PreferencesService() {
    _launcherService.setPackagesChangedListener(() {
      loadApps(showLoadingIndicator: false);
    });
  }

  static const int maxRecentSearches = 5;

  final LauncherService _launcherService;
  final PreferencesService _preferencesService;

  LauncherState _state = const LauncherState();
  LauncherState get state => _state;

  @override
  void dispose() {
    _launcherService.setPackagesChangedListener(null);
    super.dispose();
  }

  Future<void> initialize() async {
    final prefs = await _preferencesService.load();
    _state = _state.copyWith(
      favoritePackages: prefs.favoritePackages,
      recentSearches: prefs.recentSearches,
      recentSearchEnabled: prefs.recentSearchEnabled,
      showClock: prefs.showClock,
    );
    notifyListeners();
    await loadApps();
  }

  Future<void> loadApps({bool showLoadingIndicator = true}) async {
    if (showLoadingIndicator) {
      _state = _state.copyWith(
        status: LauncherStatus.loading,
        clearError: true,
        clearLaunchError: true,
      );
      notifyListeners();
    }

    try {
      final apps = await _launcherService.fetchApps();
      final installedPackages = apps.map((e) => e.packageName).toSet();
      final validFavorites = _state.favoritePackages
          .where(installedPackages.contains)
          .toList(growable: false);

      if (validFavorites.length != _state.favoritePackages.length) {
        await _persistPreferences(favoritePackages: validFavorites);
      }

      _state = _state.copyWith(
        status: LauncherStatus.loaded,
        allApps: apps,
        filteredApps: filterApps(apps, _state.searchQuery),
        favoritePackages: validFavorites,
        clearError: true,
      );
    } on LauncherException catch (e) {
      _state = _state.copyWith(
        status: LauncherStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      _state = _state.copyWith(
        status: LauncherStatus.error,
        errorMessage: 'Failed to load installed applications.',
      );
    }
    notifyListeners();
  }

  void updateSearchQuery(String query) {
    final filtered = filterApps(_state.allApps, query);
    _state = _state.copyWith(
      searchQuery: query,
      filteredApps: filtered,
      clearLaunchError: true,
    );
    notifyListeners();
  }

  void clearSearch() {
    updateSearchQuery('');
  }

  static List<LauncherApp> filterApps(
    List<LauncherApp> apps,
    String rawQuery,
  ) {
    final normalized = rawQuery.trim().toLowerCase();
    if (normalized.isEmpty) {
      return apps;
    }
    return apps
        .where(
          (app) =>
              app.label.toLowerCase().contains(normalized) ||
              app.packageName.toLowerCase().contains(normalized),
        )
        .toList(growable: false);
  }

  Future<bool> launchApp(LauncherApp app) async {
    _state = _state.copyWith(clearLaunchError: true);
    try {
      final trimmedQuery = _state.searchQuery.trim();
      if (_state.recentSearchEnabled && trimmedQuery.isNotEmpty) {
        await _recordRecentSearch(trimmedQuery);
      }
      await _launcherService.launchApp(app.packageName);
      return true;
    } on LauncherException catch (e) {
      _state = _state.copyWith(launchErrorMessage: e.message);
      notifyListeners();
      return false;
    } catch (_) {
      _state = _state.copyWith(
        launchErrorMessage: 'Could not open ${app.label}.',
      );
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleFavorite(String packageName) async {
    final current = List<String>.from(_state.favoritePackages);
    if (current.contains(packageName)) {
      current.remove(packageName);
    } else {
      current.add(packageName);
    }
    _state = _state.copyWith(favoritePackages: current);
    notifyListeners();
    await _persistPreferences(favoritePackages: current);
  }

  Future<void> setRecentSearchEnabled(bool enabled) async {
    final searches = enabled ? _state.recentSearches : const <String>[];
    _state = _state.copyWith(
      recentSearchEnabled: enabled,
      recentSearches: searches,
    );
    notifyListeners();
    await _persistPreferences(
      recentSearchEnabled: enabled,
      recentSearches: searches,
    );
  }

  Future<void> clearRecentSearches() async {
    _state = _state.copyWith(recentSearches: const <String>[]);
    notifyListeners();
    await _persistPreferences(recentSearches: const <String>[]);
  }

  Future<void> setShowClock(bool show) async {
    _state = _state.copyWith(showClock: show);
    notifyListeners();
    await _persistPreferences(showClock: show);
  }

  Future<void> _recordRecentSearch(String query) async {
    final updated = <String>[
      query,
      ..._state.recentSearches.where(
        (item) => item.toLowerCase() != query.toLowerCase(),
      ),
    ].take(maxRecentSearches).toList(growable: false);

    _state = _state.copyWith(recentSearches: updated);
    notifyListeners();
    await _persistPreferences(recentSearches: updated);
  }

  Future<void> _persistPreferences({
    List<String>? favoritePackages,
    List<String>? recentSearches,
    bool? recentSearchEnabled,
    bool? showClock,
  }) async {
    await _preferencesService.save(
      PreferencesData(
        favoritePackages: favoritePackages ?? _state.favoritePackages,
        recentSearches: recentSearches ?? _state.recentSearches,
        recentSearchEnabled:
            recentSearchEnabled ?? _state.recentSearchEnabled,
        showClock: showClock ?? _state.showClock,
      ),
    );
  }
}
