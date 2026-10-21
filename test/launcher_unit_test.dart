import 'package:faru_launcher/launcher/launcher_controller.dart';
import 'package:faru_launcher/models/launcher_app.dart';
import 'package:faru_launcher/services/launcher_service.dart';
import 'package:faru_launcher/services/preferences_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LauncherApp model parsing & sorting', () {
    test('parses valid native map and trims whitespace', () {
      final app = LauncherApp.fromMap(<Object?, Object?>{
        'label': '  Calendar  ',
        'packageName': ' com.samsung.android.calendar ',
      });

      expect(app.label, 'Calendar');
      expect(app.packageName, 'com.samsung.android.calendar');
    });

    test('falls back to packageName when label is empty', () {
      final app = LauncherApp.fromMap(<Object?, Object?>{
        'label': '   ',
        'packageName': 'dev.faru.utility',
      });

      expect(app.label, 'dev.faru.utility');
      expect(app.packageName, 'dev.faru.utility');
    });

    test('throws FormatException when packageName is missing or blank', () {
      expect(
        () => LauncherApp.fromMap(<Object?, Object?>{'label': 'Notes'}),
        throwsFormatException,
      );
    });

    test('parseAndSortApps deduplicates by packageName and sorts case-insensitively', () {
      final raw = <Map<Object?, Object?>>[
        <Object?, Object?>{'label': 'zeta', 'packageName': 'com.example.zeta'},
        <Object?, Object?>{'label': 'Alpha', 'packageName': 'com.example.alpha'},
        <Object?, Object?>{'label': 'Alpha Duplicate', 'packageName': 'com.example.alpha'},
        <Object?, Object?>{'label': 'beta', 'packageName': 'com.example.beta'},
      ];

      final apps = LauncherService.parseAndSortApps(raw);
      expect(apps.map((e) => e.label).toList(), <String>['Alpha', 'beta', 'zeta']);
      expect(apps.length, 3);
    });
  });

  group('Search filtering & Favorites persistence', () {
    const sampleApps = <LauncherApp>[
      LauncherApp(label: 'Calculator', packageName: 'com.sec.android.app.popupcalculator'),
      LauncherApp(label: 'Camera', packageName: 'com.sec.android.app.camera'),
      LauncherApp(label: 'Gallery', packageName: 'com.sec.android.gallery3d'),
    ];

    test('filterApps matches case-insensitively, trims whitespace, and handles no-match', () {
      expect(
        LauncherController.filterApps(sampleApps, '  cAm  ').map((e) => e.label).toList(),
        <String>['Camera'],
      );
      expect(
        LauncherController.filterApps(sampleApps, 'popupcalculator').map((e) => e.label).toList(),
        <String>['Calculator'],
      );
      expect(LauncherController.filterApps(sampleApps, 'nonexistent'), isEmpty);
    });

    test('favorites persist and automatically clean up uninstalled packages', () async {
      const channel = MethodChannel('dev.faru.launcher/test_unit');
      var installedRaw = <Map<String, String>>[
        <String, String>{'label': 'Camera', 'packageName': 'com.sec.android.app.camera'},
        <String, String>{'label': 'Notes', 'packageName': 'com.samsung.android.app.notes'},
      ];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'getApps') {
          return installedRaw;
        }
        return true;
      });

      final prefs = PreferencesService();
      await prefs.save(
        const PreferencesData(
          favoritePackages: <String>[
            'com.sec.android.app.camera',
            'com.uninstalled.app',
          ],
        ),
      );

      final controller = LauncherController(
        launcherService: LauncherService(channel: channel),
        preferencesService: prefs,
      );

      await controller.initialize();

      // Uninstalled package is cleaned up automatically
      expect(controller.state.favoritePackages, <String>['com.sec.android.app.camera']);
      expect(controller.state.favoriteApps.map((e) => e.label).toList(), <String>['Camera']);

      // Toggle favorite on Notes
      await controller.toggleFavorite('com.samsung.android.app.notes');
      expect(
        controller.state.favoritePackages,
        <String>['com.sec.android.app.camera', 'com.samsung.android.app.notes'],
      );
    });
  });
}
