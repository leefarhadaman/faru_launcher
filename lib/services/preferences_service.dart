import 'dart:convert';
import 'dart:io';

class PreferencesData {
  const PreferencesData({
    this.favoritePackages = const <String>[],
    this.recentSearches = const <String>[],
    this.recentSearchEnabled = false,
    this.showClock = true,
  });

  final List<String> favoritePackages;
  final List<String> recentSearches;
  final bool recentSearchEnabled;
  final bool showClock;

  PreferencesData copyWith({
    List<String>? favoritePackages,
    List<String>? recentSearches,
    bool? recentSearchEnabled,
    bool? showClock,
  }) {
    return PreferencesData(
      favoritePackages: favoritePackages ?? this.favoritePackages,
      recentSearches: recentSearches ?? this.recentSearches,
      recentSearchEnabled: recentSearchEnabled ?? this.recentSearchEnabled,
      showClock: showClock ?? this.showClock,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'favoritePackages': favoritePackages,
        'recentSearches': recentSearches,
        'recentSearchEnabled': recentSearchEnabled,
        'showClock': showClock,
      };

  factory PreferencesData.fromJson(Map<String, Object?> json) {
    final rawFavorites = json['favoritePackages'];
    final rawSearches = json['recentSearches'];
    return PreferencesData(
      favoritePackages: rawFavorites is List
          ? rawFavorites
              .map((e) => e?.toString().trim() ?? '')
              .where((e) => e.isNotEmpty)
              .toSet()
              .toList()
          : const <String>[],
      recentSearches: rawSearches is List
          ? rawSearches
              .map((e) => e?.toString().trim() ?? '')
              .where((e) => e.isNotEmpty)
              .toList()
          : const <String>[],
      recentSearchEnabled: json['recentSearchEnabled'] == true,
      showClock: json['showClock'] is bool ? json['showClock']! as bool : true,
    );
  }
}

class PreferencesService {
  PreferencesService({this._storageFile});

  final File? _storageFile;
  PreferencesData _cache = const PreferencesData();

  Future<PreferencesData> load() async {
    final file = _storageFile;
    if (file == null) {
      return _cache;
    }
    try {
      if (await file.exists()) {
        final content = await file.readAsString();
        final decoded = jsonDecode(content);
        if (decoded is Map<String, Object?>) {
          _cache = PreferencesData.fromJson(decoded);
        }
      }
    } catch (_) {
      // Keep safe defaults if local file is unreadable or corrupted.
    }
    return _cache;
  }

  Future<void> save(PreferencesData data) async {
    _cache = data;
    final file = _storageFile;
    if (file == null) {
      return;
    }
    try {
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(data.toJson()));
    } catch (_) {
      // Ignore write failures in restricted test environments.
    }
  }
}
