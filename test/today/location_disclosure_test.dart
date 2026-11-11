import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:route_mint_app/app/app.dart';
import 'package:route_mint_app/core/localization/app_strings.dart';
import 'package:route_mint_app/core/location/location_permission_service.dart';
import 'package:route_mint_app/core/storage/account_data_store.dart';
import 'package:route_mint_app/features/today/location_disclosure.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeGeolocator extends GeolocatorPlatform {
  _FakeGeolocator({required bool willPrompt})
    : permission = willPrompt
          ? LocationPermission.denied
          : LocationPermission.whileInUse;

  LocationPermission permission;
  bool serviceEnabled = true;
  Completer<LocationPermission>? pendingCheck;
  final permissionResults = <LocationPermission>[];
  int requests = 0;

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async {
    final pending = pendingCheck;
    if (pending != null) return pending.future;
    if (permissionResults.isNotEmpty) return permissionResults.removeAt(0);
    return permission;
  }

  @override
  Future<LocationPermission> requestPermission() async {
    requests++;
    return LocationPermission.whileInUse;
  }
}

void main() {
  final strings = AppStrings(AppLanguage.english);
  LocationPermissionStatus? result;
  late GeolocatorPlatform originalPlatform;

  setUp(() {
    originalPlatform = GeolocatorPlatform.instance;
    SharedPreferences.setMockInitialValues({});
    AccountDataStore.resetForTesting();
  });
  tearDown(() {
    GeolocatorPlatform.instance = originalPlatform;
    AccountDataStore.resetForTesting();
  });

  /// Pumps a button that starts a tracking feature and taps it.
  Future<void> start(WidgetTester tester, _FakeGeolocator service) async {
    result = null;
    GeolocatorPlatform.instance = service;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await requestLocationWithDisclosure(
                  context,
                  strings: strings,
                  permissionService: LocationPermissionService(),
                );
              },
              child: const Text('start'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('start'));
    await tester.pumpAndSettle();
  }

  testWidgets('explains the use of location before the system prompt', (
    tester,
  ) async {
    final service = _FakeGeolocator(willPrompt: true);
    await start(tester, service);

    expect(find.text(strings.locationDisclosureTitle), findsOneWidget);
    expect(find.text(strings.locationDisclosureBody), findsOneWidget);
    expect(service.requests, 0, reason: 'nothing is asked before consent');

    await tester.tap(find.text(strings.continueAction));
    await tester.pumpAndSettle();

    expect(service.requests, 1);
    expect(result, LocationPermissionStatus.granted);
  });

  testWidgets('declining the explanation never reaches the system prompt', (
    tester,
  ) async {
    final service = _FakeGeolocator(willPrompt: true);
    await start(tester, service);

    await tester.tap(find.text(strings.notNow));
    await tester.pumpAndSettle();

    expect(service.requests, 0);
    expect(result, LocationPermissionStatus.denied);
  });

  testWidgets('no explanation when the system is not going to ask', (
    tester,
  ) async {
    final service = _FakeGeolocator(willPrompt: false);
    await start(tester, service);

    expect(find.text(strings.locationDisclosureTitle), findsNothing);
    expect(service.requests, 0);
    expect(result, LocationPermissionStatus.granted);
  });

  testWidgets('disabled services and permanent denial do not prompt', (
    tester,
  ) async {
    final service = _FakeGeolocator(willPrompt: true)..serviceEnabled = false;
    await start(tester, service);
    expect(result, LocationPermissionStatus.serviceDisabled);
    expect(find.byType(AlertDialog), findsNothing);
    expect(service.requests, 0);

    service.serviceEnabled = true;
    service.permission = LocationPermission.deniedForever;
    await start(tester, service);
    expect(result, LocationPermissionStatus.permanentlyDenied);
    expect(find.byType(AlertDialog), findsNothing);
    expect(service.requests, 0);
  });

  testWidgets('a changing permission result cannot bypass disclosure', (
    tester,
  ) async {
    final service = _FakeGeolocator(willPrompt: false)
      ..permissionResults.addAll([
        LocationPermission.whileInUse,
        LocationPermission.denied,
      ]);
    await start(tester, service);

    expect(
      service.requests,
      0,
      reason: 'no consent was given for a native prompt',
    );
  });

  testWidgets('leaving while checking permission cannot open a system prompt', (
    tester,
  ) async {
    final check = Completer<LocationPermission>();
    final service = _FakeGeolocator(willPrompt: true)..pendingCheck = check;
    await start(tester, service);
    await tester.pumpWidget(const SizedBox.shrink());
    check.complete(LocationPermission.denied);
    await tester.pumpAndSettle();

    expect(result, LocationPermissionStatus.denied);
    expect(service.requests, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('consent from a disposed screen cannot open a system prompt', (
    tester,
  ) async {
    final service = _FakeGeolocator(willPrompt: true);
    GeolocatorPlatform.instance = service;
    final showStart = ValueNotifier(true);
    addTearDown(showStart.dispose);
    result = null;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder<bool>(
            valueListenable: showStart,
            builder: (context, visible, _) => visible
                ? Builder(
                    builder: (context) => TextButton(
                      onPressed: () async {
                        result = await requestLocationWithDisclosure(
                          context,
                          strings: strings,
                          permissionService: LocationPermissionService(),
                        );
                      },
                      child: const Text('start'),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.tap(find.text('start'));
    await tester.pumpAndSettle();
    showStart.value = false;
    await tester.pump();
    await tester.tap(find.text(strings.continueAction));
    await tester.pumpAndSettle();

    expect(result, LocationPermissionStatus.denied);
    expect(service.requests, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'switching accounts while reading the disclosure cancels the request',
    (tester) async {
      await tester.runAsync(() => AccountDataStore.activate('A'));
      final service = _FakeGeolocator(willPrompt: true);
      await start(tester, service);
      await tester.runAsync(() => AccountDataStore.activate('B'));
      await tester.tap(find.text(strings.continueAction));
      await tester.pumpAndSettle();

      expect(result, LocationPermissionStatus.denied);
      expect(service.requests, 0);
    },
  );

  testWidgets('the explanation fits a narrow phone in every language', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final language in AppLanguage.values) {
      final localized = AppStrings(language);
      final service = _FakeGeolocator(willPrompt: true);
      GeolocatorPlatform.instance = service;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => requestLocationWithDisclosure(
                  context,
                  strings: localized,
                  permissionService: LocationPermissionService(),
                ),
                child: const Text('start'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('start'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: '$language');
      expect(find.text(localized.notNow), findsOneWidget, reason: '$language');

      // Close the dialog before the next language is pumped.
      await tester.tap(find.text(localized.notNow));
      await tester.pumpAndSettle();
    }
  });
}
