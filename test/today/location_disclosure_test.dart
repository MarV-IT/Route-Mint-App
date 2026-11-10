import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:route_mint_app/app/app.dart';
import 'package:route_mint_app/core/localization/app_strings.dart';
import 'package:route_mint_app/core/location/location_permission_service.dart';
import 'package:route_mint_app/features/today/location_disclosure.dart';

class _FakePermissionService extends LocationPermissionService {
  _FakePermissionService({required this.willPrompt});

  final bool willPrompt;
  int requests = 0;

  @override
  Future<bool> willPromptForPermission() async => willPrompt;

  @override
  Future<LocationPermissionStatus> checkAndRequest() async {
    requests++;
    return LocationPermissionStatus.granted;
  }
}

void main() {
  final strings = AppStrings(AppLanguage.english);
  LocationPermissionStatus? result;

  /// Pumps a button that starts a tracking feature and taps it.
  Future<void> start(
    WidgetTester tester,
    _FakePermissionService service,
  ) async {
    result = null;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await requestLocationWithDisclosure(
                  context,
                  strings: strings,
                  permissionService: service,
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
    final service = _FakePermissionService(willPrompt: true);
    await start(tester, service);

    expect(find.text(strings.locationDisclosureTitle), findsOneWidget);
    expect(
      find.textContaining('even when the app is closed or not in use'),
      findsOneWidget,
    );
    expect(service.requests, 0, reason: 'nothing is asked before consent');

    await tester.tap(find.text(strings.continueAction));
    await tester.pumpAndSettle();

    expect(service.requests, 1);
    expect(result, LocationPermissionStatus.granted);
  });

  testWidgets('declining the explanation never reaches the system prompt', (
    tester,
  ) async {
    final service = _FakePermissionService(willPrompt: true);
    await start(tester, service);

    await tester.tap(find.text(strings.notNow));
    await tester.pumpAndSettle();

    expect(service.requests, 0);
    expect(result, LocationPermissionStatus.denied);
  });

  testWidgets('no explanation when the system is not going to ask', (
    tester,
  ) async {
    final service = _FakePermissionService(willPrompt: false);
    await start(tester, service);

    expect(find.text(strings.locationDisclosureTitle), findsNothing);
    expect(service.requests, 1);
    expect(result, LocationPermissionStatus.granted);
  });

  testWidgets('the explanation fits a narrow phone in every language', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final language in AppLanguage.values) {
      final localized = AppStrings(language);
      final service = _FakePermissionService(willPrompt: true);
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
                  permissionService: service,
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
