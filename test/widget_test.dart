import 'dart:async';
import 'package:faru_launcher/app/faru_launcher_app.dart';
import 'package:faru_launcher/launcher/launcher_controller.dart';
import 'package:faru_launcher/services/launcher_service.dart';
import 'package:faru_launcher/services/preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders loading state, alphabetical list, search filter, and launches tapped app',
      (WidgetTester tester) async {
    const channel = MethodChannel('dev.faru.launcher/test_widget_1');
    final completer = Completer<List<Map<String, String>>>();
    String? launchedPackage;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getApps') {
        return completer.future;
      }
      if (call.method == 'launchApp') {
        final args = call.arguments as Map<Object?, Object?>;
        launchedPackage = args['packageName'] as String?;
        return true;
      }
      return null;
    });

    final controller = LauncherController(
      launcherService: LauncherService(channel: channel),
      preferencesService: PreferencesService(),
    );

    await tester.pumpWidget(FaruLauncherApp(controller: controller));
    await tester.pump();

    // Verify loading state
    expect(find.text('Loading applications...'), findsOneWidget);

    completer.complete(<Map<String, String>>[
      <String, String>{'label': 'Messages', 'packageName': 'com.samsung.android.messaging'},
      <String, String>{'label': 'Browser', 'packageName': 'com.sec.android.app.sbrowser'},
      <String, String>{'label': 'Clock', 'packageName': 'com.sec.android.app.clockpackage'},
    ]);
    await tester.pumpAndSettle();

    // Verify alphabetical apps and count
    expect(find.text('Browser'), findsOneWidget);
    expect(find.text('Clock'), findsOneWidget);
    expect(find.text('Messages'), findsOneWidget);
    expect(find.text('3 apps'), findsOneWidget);

    // Filter apps via search
    await tester.enterText(find.byKey(const Key('app_search_field')), 'clo');
    await tester.pumpAndSettle();

    expect(find.text('Clock'), findsOneWidget);
    expect(find.text('Browser'), findsNothing);
    expect(find.text('1 app'), findsOneWidget);

    // Tap visible app to launch
    await tester.tap(find.text('Clock'));
    await tester.pumpAndSettle();
    expect(launchedPackage, 'com.sec.android.app.clockpackage');
  });

  testWidgets('renders error state and retries successfully', (WidgetTester tester) async {
    const channel = MethodChannel('dev.faru.launcher/test_widget_error');
    var shouldFail = true;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getApps') {
        if (shouldFail) {
          throw PlatformException(
            code: 'APP_DISCOVERY_FAILED',
            message: 'PackageManager query failed',
          );
        }
        return <Map<String, String>>[
          <String, String>{'label': 'Settings', 'packageName': 'com.android.settings'},
        ];
      }
      return true;
    });

    final controller = LauncherController(
      launcherService: LauncherService(channel: channel),
      preferencesService: PreferencesService(),
    );

    await tester.pumpWidget(FaruLauncherApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('PackageManager query failed'), findsOneWidget);
    expect(find.byKey(const Key('retry_load_apps_button')), findsOneWidget);

    shouldFail = false;
    await tester.tap(find.byKey(const Key('retry_load_apps_button')));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('supports narrow screen and large font scale without overflow',
      (WidgetTester tester) async {
    const channel = MethodChannel('dev.faru.launcher/test_widget_a11y');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getApps') {
        return <Map<String, String>>[
          <String, String>{
            'label': 'Samsung Internet Browser With Very Long Application Name',
            'packageName': 'com.sec.android.app.sbrowser',
          },
        ];
      }
      return true;
    });

    final controller = LauncherController(
      launcherService: LauncherService(channel: channel),
      preferencesService: PreferencesService(),
    );

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 640),
          textScaler: TextScaler.linear(1.6),
        ),
        child: FaruLauncherApp(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.text('Samsung Internet Browser With Very Long Application Name'),
      findsOneWidget,
    );
  });
}
