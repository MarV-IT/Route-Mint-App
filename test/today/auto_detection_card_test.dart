import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:route_mint_app/app/app.dart';
import 'package:route_mint_app/core/localization/app_strings.dart';
import 'package:route_mint_app/core/location/geolocator_tracking_provider.dart';
import 'package:route_mint_app/core/location/trip_recovery_store.dart';
import 'package:route_mint_app/core/storage/account_data_store.dart';
import 'package:route_mint_app/features/today/auto_detection_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeGeolocator extends GeolocatorPlatform {
  final positions = StreamController<Position>.broadcast();
  LocationPermission permission = LocationPermission.whileInUse;
  bool serviceEnabled = true;

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async => permission;

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) =>
      positions.stream;

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async => throw const LocationServiceDisabledException();
}

void main() {
  final uk = AppStrings(AppLanguage.ukrainian);
  late GeolocatorPlatform originalPlatform;
  late _FakeGeolocator geolocator;

  setUp(() {
    originalPlatform = GeolocatorPlatform.instance;
    geolocator = _FakeGeolocator();
    GeolocatorPlatform.instance = geolocator;
    SharedPreferences.setMockInitialValues({});
    AccountDataStore.resetForTesting();
    TripRecoveryStore.resetForTesting();
  });
  tearDown(() {
    GeolocatorPlatform.instance = originalPlatform;
    AccountDataStore.resetForTesting();
  });

  Future<void> pumpCard(
    WidgetTester tester, {
    required bool compact,
    VoidCallback? onDetectionStarted,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: AutoDetectionCard(
            strings: uk,
            onTripSaved: () {},
            onDetectionStarted: onDetectionStarted,
            compact: compact,
          ),
        ),
      ),
    ),
  );

  /// Lets a start or stop sequence finish. Its steps alternate between the
  /// store, notifications and the widget, so several rounds are needed; the
  /// last pumps let the short "nothing recorded" message go away.
  Future<void> settle(WidgetTester tester) async {
    for (var round = 0; round < 6; round++) {
      await tester.runAsync(pumpEventQueue);
      await tester.pump();
    }
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  /// Detection is one service for the whole process. It has to be stopped
  /// inside the test that started it, while its timers can still run.
  Future<void> withDetectionStopped(
    WidgetTester tester,
    Future<void> Function() body,
  ) async {
    try {
      await body();
    } finally {
      if (appAutoDetectionService.isMonitoring) {
        unawaited(appAutoDetectionService.stopMonitoring());
        await settle(tester);
      }
    }
  }

  for (final compact in [true, false]) {
    final layout = compact ? 'compact' : 'full';

    testWidgets('$layout card starts and stops detection on its own', (
      tester,
    ) async {
      await withDetectionStopped(tester, () async {
        var started = 0;
        await pumpCard(
          tester,
          compact: compact,
          onDetectionStarted: () => started++,
        );

        // Nothing has to be switched on anywhere else first.
        expect(find.text(uk.autoDetectionOff), findsOneWidget);
        expect(find.textContaining('Профіл'), findsNothing);

        if (compact) {
          final button = tester.widget<IconButton>(find.byType(IconButton));
          expect(button.onPressed, isNotNull);
          await tester.tap(find.byType(IconButton));
        } else {
          await tester.tap(find.text(uk.startAutoDetection));
        }
        await settle(tester);

        expect(appAutoDetectionService.isMonitoring, isTrue);
        expect(started, 1);
        expect(find.text(uk.watchingForMovement), findsOneWidget);

        if (compact) {
          await tester.tap(find.byType(IconButton));
        } else {
          await tester.tap(find.text(uk.stopAutoDetection));
        }
        await settle(tester);

        expect(appAutoDetectionService.isMonitoring, isFalse);
        expect(find.text(uk.autoDetectionOff), findsOneWidget);
        // Stopping is not a new decision to switch the feature on.
        expect(started, 1);
      });
    });
  }

  testWidgets('tapping the compact card itself also starts detection', (
    tester,
  ) async {
    await withDetectionStopped(tester, () async {
      await pumpCard(tester, compact: true);
      await tester.tap(find.text(uk.autoTripDetection));
      await settle(tester);
      expect(appAutoDetectionService.isMonitoring, isTrue);
    });
  });

  testWidgets('a refused location permission starts nothing', (tester) async {
    await withDetectionStopped(tester, () async {
      geolocator.permission = LocationPermission.deniedForever;
      var started = 0;
      await pumpCard(
        tester,
        compact: true,
        onDetectionStarted: () => started++,
      );
      await tester.tap(find.byType(IconButton));
      await settle(tester);

      expect(appAutoDetectionService.isMonitoring, isFalse);
      expect(started, 0);
      expect(find.text(uk.locationPermissionRequired), findsOneWidget);
      // The control stays usable for another try.
      expect(
        tester.widget<IconButton>(find.byType(IconButton)).onPressed,
        isNotNull,
      );
    });
  });

  testWidgets('the compact card fits a narrow phone with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: AutoDetectionCard(
                strings: uk,
                onTripSaved: () {},
                compact: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
