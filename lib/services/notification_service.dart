import 'package:flutter/services.dart';

class AppNotification {
  const AppNotification({
    required this.key,
    required this.packageName,
    required this.appLabel,
    required this.title,
    required this.text,
    required this.postTime,
    this.ongoing = false,
  });

  final String key;
  final String packageName;
  final String appLabel;
  final String title;
  final String text;
  final int postTime;
  final bool ongoing;

  factory AppNotification.fromMap(Map<Object?, Object?> m) => AppNotification(
        key: m['key']?.toString() ?? '',
        packageName: m['packageName']?.toString() ?? '',
        appLabel: m['appLabel']?.toString() ?? '',
        title: m['title']?.toString() ?? '',
        text: m['text']?.toString() ?? '',
        postTime: (m['postTime'] as int?) ?? 0,
        ongoing: m['ongoing'] == true,
      );
}

class NotificationService {
  static const _channel = MethodChannel('dev.faru.launcher/notifications');

  static void setChangedListener(VoidCallback? cb) {
    if (cb == null) {
      _channel.setMethodCallHandler(null);
      return;
    }
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onNotificationsChanged') cb();
    });
  }

  static Future<bool> isPermissionGranted() async {
    try {
      return await _channel.invokeMethod<bool>('isPermissionGranted') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> requestPermission() async {
    try {
      await _channel.invokeMethod('requestPermission');
    } catch (_) {}
  }

  static Future<List<AppNotification>> getNotifications() async {
    try {
      final raw = await _channel.invokeListMethod<Object?>('getNotifications');
      return (raw ?? [])
          .whereType<Map<Object?, Object?>>()
          .map(AppNotification.fromMap)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> dismiss(String key) async {
    try {
      await _channel.invokeMethod('dismissNotification', {'key': key});
    } catch (_) {}
  }
}
