import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:route_mint_app/core/notifications/trip_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  final calls = <MethodCall>[];
  var enabled = false;
  var grantPermission = false;
  var initializationFailures = 0;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    IOSFlutterLocalNotificationsPlugin.registerWith();
    SharedPreferences.setMockInitialValues({});
    calls.clear();
    enabled = false;
    grantPermission = false;
    initializationFailures = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          switch (call.method) {
            case 'initialize':
              if (initializationFailures-- > 0) {
                throw PlatformException(code: 'unavailable');
              }
              return true;
            case 'checkPermissions':
              return {'isEnabled': enabled};
            case 'requestPermissions':
              return grantPermission;
            default:
              return null;
          }
        });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('checking iOS notification status never requests permission', () async {
    final service = TripNotificationService.forTesting();
    expect(await service.areNotificationsEnabled(), isFalse);
    final settings =
        calls.singleWhere((call) => call.method == 'initialize').arguments
            as Map;
    expect(settings['requestAlertPermission'], isFalse);
    expect(settings['requestBadgePermission'], isFalse);
    expect(settings['requestSoundPermission'], isFalse);
    expect(calls.where((call) => call.method == 'requestPermissions'), isEmpty);
  });

  test('denied iOS test notification returns false without showing', () async {
    final service = TripNotificationService.forTesting();
    expect(await service.showTestNotification(), isFalse);
    expect(
      calls.where((call) => call.method == 'requestPermissions'),
      hasLength(1),
    );
    expect(calls.where((call) => call.method == 'show'), isEmpty);
  });

  test(
    'automatic alerts never prompt for permission in the background',
    () async {
      final service = TripNotificationService.forTesting();
      await service.showTripSavedForReview(distanceKm: 2);
      await service.showAutoDetectionState(active: true);
      expect(
        calls.where((call) => call.method == 'requestPermissions'),
        isEmpty,
      );
      expect(calls.where((call) => call.method == 'show'), isEmpty);
    },
  );

  test('enabled iOS test notifications use the plugin', () async {
    enabled = true;
    final service = TripNotificationService.forTesting();
    expect(await service.showTestNotification(), isTrue);
    expect(calls.where((call) => call.method == 'show'), hasLength(1));
    expect(calls.where((call) => call.method == 'requestPermissions'), isEmpty);
  });

  test('initialization can retry after a native failure', () async {
    initializationFailures = 1;
    final service = TripNotificationService.forTesting();
    expect(await service.areNotificationsEnabled(), isNull);
    expect(await service.areNotificationsEnabled(), isFalse);
    expect(calls.where((call) => call.method == 'initialize'), hasLength(2));
  });
}
