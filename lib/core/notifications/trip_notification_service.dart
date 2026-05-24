import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';

import '../../shared/utils/distance_utils.dart';
import '../localization/app_strings.dart';
import '../preferences/preferences_service.dart';

class TripNotificationService {
  TripNotificationService._();

  static final TripNotificationService instance = TripNotificationService._();

  static const _channelId = 'trip_saved';
  static const _channelName = 'Trip saved';
  static const _channelDescription =
      'Notifications shown when a trip is recorded.';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static const _settingsChannel = MethodChannel(
    'route_mint_app/notification_settings',
  );
  Future<void>? _initialization;

  Future<void> initialize() {
    if (kIsWeb) return Future.value();
    return _initialization ??= _initialize();
  }

  Future<void> _initialize() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('app_notification_icon'),
      iOS: DarwinInitializationSettings(),
      macOS: DarwinInitializationSettings(),
    );

    await _plugin.initialize(settings);
  }

  /// Requests the OS notification permission.
  ///
  /// Must be called from within the widget tree (after [runApp]) so the
  /// Android activity is visible and can host the system permission dialog.
  Future<void> requestPermission() async {
    if (kIsWeb) return;
    try {
      await initialize();
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[TripNotification] requestPermission failed: $e');
      }
    }
  }

  Future<bool?> areNotificationsEnabled() async {
    if (kIsWeb) return null;
    try {
      await initialize();
      return await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.areNotificationsEnabled();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[TripNotification] status check failed: $e');
      }
      return null;
    }
  }

  Future<void> openNotificationSettings() async {
    if (kIsWeb) return;
    try {
      await _settingsChannel.invokeMethod<void>('openNotificationSettings');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[TripNotification] open settings failed: $e');
      }
    }
  }

  Future<void> showTripSavedForReview({double? distanceKm}) async {
    if (kIsWeb) return;

    try {
      await initialize();

      final prefs = await PreferencesService().loadPreferences();
      final strings = AppStrings(prefs.language);
      final distanceText = distanceKm == null
          ? null
          : formatDistance(distanceKm, prefs.unit);
      final body = distanceText == null
          ? strings.detectedTripSavedForReview
          : '${strings.detectedTripSavedForReview} - $distanceText';

      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        'MarV Route',
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.status,
            visibility: NotificationVisibility.public,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
          macOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: 'trips',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[TripNotification] failed to show notification: $e');
      }
    }
  }
}
