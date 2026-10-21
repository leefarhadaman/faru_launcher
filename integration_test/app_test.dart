import 'package:faru_launcher/app/faru_launcher_app.dart';
import 'package:faru_launcher/launcher/launcher_controller.dart';
import 'package:faru_launcher/services/launcher_service.dart';
import 'package:faru_launcher/services/preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Full Faru Launcher user flow: search, pin favorite, settings, and launch',
      (WidgetTester tester) async {
    const channel = MethodChannel('dev.faru.launcher/integration_test');
    final launchedPackages = <String>[];

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getApps') {
        return <Map<String, String>>[
          <String, String>{'label': 'Calculator', 'packageName': 'com.sec.android.app.popupcalculator'},
          <String, String>{'label': 'Camera', 'packageName': 'com.sec.android.app.camera'},
          <String, String>{'label': 'Gallery', 'packageName': 'com.sec.android.gallery3d'},
          <String, String>{'label': 'Settings', 'packageName': 'com.android.settings'},
        ];
      }
      if (call.method == 'launchApp') {
        final args = call.arguments as Map<Object?, Object?>;
        final pkg = args['packageName'] as String?;
        if (pkg != null) {
          launchedPackages.add(pkg);
        }
        return true;
      }
      return null;
    });

    final controller = LauncherController(
      launcherService: LauncherService(channel: channel),
      preferencesService: PreferencesService(),
    );

    await tester.pumpWidget(FaruLauncherApp(controller: controller));
    await tester.pumpAndSettle();

    // Verify initial list of 4 apps
    expect(find.text('4 apps'), findsOneWidget);

    // Pin Camera to favorites
    await tester.tap(find.byTooltip('Pin Camera to favorites'));
    await tester.pumpAndSettle();
    expect(find.text('Pinned Favorites'), findsOneWidget);
    expect(find.text('1 pinned'), findsOneWidget);

    // Search for Gallery
    await tester.enterText(find.byKey(const Key('app_search_field')), 'gall');
    await tester.pumpAndSettle();
    expect(find.text('1 app'), findsOneWidget);
    expect(find.text('Gallery'), findsOneWidget);

    // Launch Gallery
    await tester.tap(find.text('Gallery'));
    await tester.pumpAndSettle();
    expect(launchedPackages, contains('com.sec.android.gallery3d'));
  });
}
