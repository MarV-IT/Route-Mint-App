import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class BatteryOptimizationService {
  static const _channel = MethodChannel('route_mint_app/battery_optimization');

  Future<bool?> isIgnoringBatteryOptimizations() async {
    if (kIsWeb) return null;
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
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<void>('openBatteryOptimizationSettings');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[BatteryOptimization] open settings failed: $e');
      }
    }
  }
}
