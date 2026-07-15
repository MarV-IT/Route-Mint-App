import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Battery optimization exemptions are an Android-only concept; the native
/// handler lives in MainActivity.kt. Other platforms report "unrestricted"
/// so reliability checks don't flag a setting that doesn't exist.
class BatteryOptimizationService {
  static const _channel = MethodChannel('route_mint_app/battery_optimization');

  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<bool?> isIgnoringBatteryOptimizations() async {
    if (!isSupported) return true;
    try {
      return await _channel.invokeMethod<bool>(
        'isIgnoringBatteryOptimizations',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[BatteryOptimization] status failed: $e');
      }
      return null;
    }
  }

  Future<void> openBatteryOptimizationSettings() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>('openBatteryOptimizationSettings');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[BatteryOptimization] open settings failed: $e');
      }
    }
  }
}
