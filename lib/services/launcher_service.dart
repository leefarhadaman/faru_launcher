import 'package:flutter/services.dart';
import '../models/launcher_app.dart';

class LauncherException implements Exception {
  const LauncherException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'LauncherException($code): $message';
}

class LauncherService {
  LauncherService({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(channelName);

  static const String channelName = 'dev.faru.launcher/apps';

  final MethodChannel _channel;

  /// Registers a callback invoked when Android broadcasts package installation,
  /// removal, or replacement while Faru Launcher is active.
  void setPackagesChangedListener(VoidCallback? onPackagesChanged) {
    if (onPackagesChanged == null) {
      _channel.setMethodCallHandler(null);
      return;
    }
    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'onPackagesChanged') {
        onPackagesChanged();
      }
      return null;
    });
  }

  /// Raw MethodChannel call matching the starter contract in Section 4.3.
  Future<List<Map<Object?, Object?>>> getApps() async {
    try {
      final result = await _channel.invokeListMethod<Object?>('getApps');
      return (result ?? <Object?>[]).whereType<Map<Object?, Object?>>().toList();
    } on PlatformException catch (e) {
      throw LauncherException(
        e.code,
        e.message ?? 'Failed to load installed applications.',
      );
    } on MissingPluginException {
      throw const LauncherException(
        'CHANNEL_UNAVAILABLE',
        'Native app discovery channel is not available on this platform.',
      );
    }
  }

  /// Parses, deduplicates by packageName, and sorts launchable apps case-insensitively.
  Future<List<LauncherApp>> fetchApps() async {
    final rawMaps = await getApps();
    return parseAndSortApps(rawMaps);
  }

  static List<LauncherApp> parseAndSortApps(
    Iterable<Map<Object?, Object?>> rawMaps,
  ) {
    final seenPackages = <String>{};
    final apps = <LauncherApp>[];

    for (final raw in rawMaps) {
      try {
        final app = LauncherApp.fromMap(raw);
        if (seenPackages.add(app.packageName)) {
          apps.add(app);
        }
      } on FormatException {
        // Ignore malformed entries without crashing discovery.
      }
    }

    apps.sort((a, b) => a.compareTo(b));
    return List<LauncherApp>.unmodifiable(apps);
  }

  Future<void> launchApp(String packageName) async {
    final trimmed = packageName.trim();
    if (trimmed.isEmpty) {
      throw const LauncherException(
        'INVALID_ARGUMENT',
        'Package name cannot be empty.',
      );
    }

    try {
      await _channel.invokeMethod<bool>(
        'launchApp',
        <String, String>{'packageName': trimmed},
      );
    } on PlatformException catch (e) {
      throw LauncherException(
        e.code,
        e.message ?? 'Unable to launch $trimmed.',
      );
    } on MissingPluginException {
      throw const LauncherException(
        'CHANNEL_UNAVAILABLE',
        'Native app launch channel is not available on this platform.',
      );
    }
  }
}
