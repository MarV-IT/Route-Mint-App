import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart' show Geolocator;

import '../../shared/utils/distance_utils.dart';
import '../localization/app_strings.dart';
import '../preferences/preferences_service.dart';

class TripNotificationService {
  TripNotificationService._();

  static final TripNotificationService instance = TripNotificationService._();

  static const _channelId = 'trip_alerts_v2';
  static const _channelName = 'Trip alerts';
  static const _channelDescription =
      'Notifications shown when a trip is recorded.';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static const _settingsChannel = MethodChannel(
    'route_mint_app/notification_settings',
  );
  Future<void>? _initialization;
  bool _channelReady = false;

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
    await _ensureAndroidChannel();
  }

  bool get _isApple =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  /// Requests the OS notification permission.
  ///
  /// Must be called from within the widget tree (after [runApp]) so the
  /// Android activity is visible and can host the system permission dialog.
  Future<bool?> requestPermission() async {
    if (kIsWeb) return null;
    try {
      await initialize();
      if (_isApple) {
        return await _plugin
                .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin
                >()
                ?.requestPermissions(alert: true, badge: true, sound: true) ??
            await _plugin
                .resolvePlatformSpecificImplementation<
                  MacOSFlutterLocalNotificationsPlugin
                >()
                ?.requestPermissions(alert: true, badge: true, sound: true);
      }
      return await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[TripNotification] requestPermission failed: $e');
      }
      return null;
    }
  }

  Future<bool?> areNotificationsEnabled() async {
    if (kIsWeb) return null;
    try {
      await initialize();
      if (_isApple) {
        final ios = await _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.checkPermissions();
        if (ios != null) return ios.isEnabled;
        final macos = await _plugin
            .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin
            >()
            ?.checkPermissions();
        return macos?.isEnabled;
      }

      final nativeEnabled = await _nativeNotificationsEnabled();
      if (nativeEnabled != null) return nativeEnabled;

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
      if (_isApple) {
        // iOS has no dedicated notification-settings intent; the app's own
        // settings page contains the notification toggles.
        await Geolocator.openAppSettings();
        return;
      }
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
      await _ensureNotificationPermission();

      final prefs = await PreferencesService().loadPreferences();
      final strings = AppStrings(prefs.language);
      final distanceText = distanceKm == null
          ? null
          : formatDistance(distanceKm, prefs.unit);
      final body = distanceText == null
          ? strings.detectedTripSavedForReview
          : '${strings.detectedTripSavedForReview} - $distanceText';

      final nativeShown = await _showNativeNotification(
        title: 'MarV Route',
        body: body,
      );
      if (nativeShown == true || nativeShown == false) return;

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
            channelShowBadge: true,
            category: AndroidNotificationCategory.status,
            visibility: NotificationVisibility.public,
            playSound: true,
            enableVibration: true,
            ticker: 'Detected trip saved for review',
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

  Future<bool> showTestNotification() async {
    if (kIsWeb) return false;

    try {
      await initialize();
      await _ensureNotificationPermission();

      final prefs = await PreferencesService().loadPreferences();
      final strings = AppStrings(prefs.language);

      final nativeShown = await _showNativeNotification(
        title: 'MarV Route',
        body: strings.testNotificationBody,
      );
      if (nativeShown != null) return nativeShown;

      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        'MarV Route',
        strings.testNotificationBody,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            channelShowBadge: true,
            category: AndroidNotificationCategory.status,
            visibility: NotificationVisibility.public,
            playSound: true,
            enableVibration: true,
            ticker: 'MarV Route test notification',
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
        payload: 'test_notification',
      );
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[TripNotification] failed to show test notification: $e');
      }
      return false;
    }
  }

  Future<void> _ensureAndroidChannel() async {
    if (_channelReady) return;

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return;

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );
    await android.createNotificationChannel(channel);
    _channelReady = true;
  }

  Future<void> _ensureNotificationPermission() async {
    final enabled = await areNotificationsEnabled();
    if (enabled == true || enabled == null) return;

    final granted = await requestPermission();
    if (kDebugMode && granted == false) {
      debugPrint('[TripNotification] notifications are disabled by Android');
    }
  }

  Future<bool?> _nativeNotificationsEnabled() async {
    try {
      return await _settingsChannel.invokeMethod<bool>(
        'areNotificationsEnabled',
      );
    } on MissingPluginException {
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[TripNotification] native status check failed: $e');
      }
      return null;
    }
  }

  Future<bool?> _showNativeNotification({
    required String title,
    required String body,
  }) async {
    try {
      return await _settingsChannel.invokeMethod<bool>('showNotification', {
        'title': title,
        'body': body,
      });
    } on MissingPluginException {
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[TripNotification] native show failed: $e');
      }
      return null;
    }
  }
}
