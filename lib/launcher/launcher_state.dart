import '../models/launcher_app.dart';

enum LauncherStatus {
  initial,
  loading,
  loaded,
  error,
}

class LauncherState {
  const LauncherState({
    this.status = LauncherStatus.initial,
    this.allApps = const <LauncherApp>[],
    this.filteredApps = const <LauncherApp>[],
    this.favoritePackages = const <String>[],
    this.recentSearches = const <String>[],
    this.recentSearchEnabled = false,
    this.showClock = true,
    this.searchQuery = '',
    this.errorMessage,
    this.launchErrorMessage,
  });

  final LauncherStatus status;
  final List<LauncherApp> allApps;
  final List<LauncherApp> filteredApps;
  final List<String> favoritePackages;
  final List<String> recentSearches;
  final bool recentSearchEnabled;
  final bool showClock;
  final String searchQuery;
  final String? errorMessage;
  final String? launchErrorMessage;

  bool get isLoading => status == LauncherStatus.loading;
  bool get hasError => status == LauncherStatus.error;

  /// Resolves favorite apps against currently installed apps so uninstalled
  /// packages never crash or clutter the launcher.
  List<LauncherApp> get favoriteApps {
    if (favoritePackages.isEmpty || allApps.isEmpty) {
      return const <LauncherApp>[];
    }
    final favoriteSet = favoritePackages.toSet();
    return allApps
        .where((app) => favoriteSet.contains(app.packageName))
        .toList(growable: false);
  }

  bool isFavorite(String packageName) => favoritePackages.contains(packageName);

  LauncherState copyWith({
    LauncherStatus? status,
    List<LauncherApp>? allApps,
    List<LauncherApp>? filteredApps,
    List<String>? favoritePackages,
    List<String>? recentSearches,
    bool? recentSearchEnabled,
    bool? showClock,
    String? searchQuery,
    String? errorMessage,
    bool clearError = false,
    String? launchErrorMessage,
    bool clearLaunchError = false,
  }) {
    return LauncherState(
      status: status ?? this.status,
      allApps: allApps ?? this.allApps,
      filteredApps: filteredApps ?? this.filteredApps,
      favoritePackages: favoritePackages ?? this.favoritePackages,
      recentSearches: recentSearches ?? this.recentSearches,
      recentSearchEnabled: recentSearchEnabled ?? this.recentSearchEnabled,
      showClock: showClock ?? this.showClock,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      launchErrorMessage: clearLaunchError
          ? null
          : (launchErrorMessage ?? this.launchErrorMessage),
    );
  }
}
