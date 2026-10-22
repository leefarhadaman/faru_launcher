import 'package:flutter/services.dart';

class ToggleStates {
  const ToggleStates({
    this.wifi = false,
    this.bluetooth = false,
    this.torch = false,
    this.airplane = false,
    this.brightness = 128,
  });

  final bool wifi;
  final bool bluetooth;
  final bool torch;
  final bool airplane;
  final int brightness;

  factory ToggleStates.fromMap(Map<Object?, Object?> m) => ToggleStates(
        wifi: m['wifi'] == true,
        bluetooth: m['bluetooth'] == true,
        torch: m['torch'] == true,
        airplane: m['airplane'] == true,
        brightness: (m['brightness'] as int?) ?? 128,
      );
}

class ToggleService {
  static const _ch = MethodChannel('dev.faru.launcher/toggles');

  static Future<ToggleStates> getStates() async {
    try {
      final raw = await _ch.invokeMapMethod<Object?, Object?>('getStates');
      return raw != null ? ToggleStates.fromMap(raw) : const ToggleStates();
    } catch (_) {
      return const ToggleStates();
    }
  }

  static Future<void> toggleWifi()      async => _ch.invokeMethod('toggleWifi');
  static Future<void> toggleBluetooth() async => _ch.invokeMethod('toggleBluetooth');
  static Future<void> toggleTorch()     async => _ch.invokeMethod('toggleTorch');
  static Future<void> toggleAirplane()  async => _ch.invokeMethod('toggleAirplane');
  static Future<void> toggleDnd()       async => _ch.invokeMethod('toggleDnd');
  static Future<void> setBrightness(int v) async =>
      _ch.invokeMethod('setBrightness', {'value': v});
}
