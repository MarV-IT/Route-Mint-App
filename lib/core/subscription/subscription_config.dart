import 'package:flutter/foundation.dart';

/// Where MarV Route Pro is sold.
class SubscriptionConfig {
  const SubscriptionConfig._();

  /// RevenueCat public SDK keys, one per store (`goog_...`, `appl_...`).
  /// They only identify the app to RevenueCat and are meant to ship inside
  /// it; they are not secrets.
  ///
  /// While a platform's key is empty, purchases stay switched off there and
  /// every Pro feature is open to everyone.
  static const androidApiKey = '';
  static const iosApiKey = '';

  /// Lets one build use another key without editing this file, for example
  /// a RevenueCat Test Store key:
  /// `--dart-define=REVENUECAT_API_KEY=test_...`
  static const _overrideKey = String.fromEnvironment('REVENUECAT_API_KEY');

  /// The RevenueCat entitlement that stands for Pro. Every product that
  /// should unlock Pro is attached to it in the RevenueCat dashboard.
  static const entitlementId = 'marv_route_pro';

  static bool get isTestStore => apiKey.startsWith('test_');

  static String get apiKey {
    if (_overrideKey.isNotEmpty) return _overrideKey;
    if (kIsWeb) return '';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => androidApiKey,
      TargetPlatform.iOS => iosApiKey,
      _ => '',
    };
  }

  /// Whether this build can sell the subscription.
  static bool get storeEnabled => apiKey.isNotEmpty;
}
