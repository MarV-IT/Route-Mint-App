import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:route_mint_app/app/app.dart';
import 'package:route_mint_app/core/localization/app_strings.dart';
import 'package:route_mint_app/core/location/geolocator_tracking_provider.dart';
import 'package:route_mint_app/core/preferences/user_preferences.dart';
import 'package:route_mint_app/features/add_trip/add_trip_screen.dart';
import 'package:route_mint_app/features/fuel/add_fuel_entry_screen.dart';
import 'package:route_mint_app/features/today/foreground_tracking_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final strings = AppStrings(AppLanguage.ukrainian);
  final preferences = UserPreferences.defaults();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    for (final fuel in [false, true]) {
      testWidgets(
        '$platform ${fuel ? 'fuel' : 'trip'} form fits a small phone with large text and keyboard',
        (tester) async {
          tester.view.physicalSize = const Size(320, 568);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            MaterialApp(
              theme: ThemeData(platform: platform),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(2),
                  viewInsets: const EdgeInsets.only(bottom: 220),
                  padding: const EdgeInsets.only(top: 24, bottom: 34),
                ),
                child: child!,
              ),
              home: fuel
                  ? AddFuelEntryScreen(
                      strings: strings,
                      unit: AppUnit.kilometers,
                      preferences: preferences,
                    )
                  : AddTripScreen(
                      strings: strings,
                      unit: AppUnit.kilometers,
                      preferences: preferences,
                      onPreferencesRefresh: () async {},
                    ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          for (var i = 0; i < 12; i++) {
            await tester.drag(
              find.byType(Scrollable).first,
              const Offset(0, -250),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
        },
      );
    }
  }

  testWidgets('an interrupted manual trip offers saving on a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    appTrackingService.hasPendingTripNotifier.value = true;
    addTearDown(() => appTrackingService.hasPendingTripNotifier.value = false);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: ForegroundTrackingCard(
                strings: strings,
                preferences: preferences,
                onTripSaved: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text(strings.saveTripButton), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });
}
