import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:route_mint_app/shared/widgets/trip_map_preview.dart';

void main() {
  testWidgets('renders safely with null coordinates', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TripMapPreview(
            startLatitude: null,
            startLongitude: null,
            endLatitude: null,
            endLongitude: null,
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(FlutterMap), findsNothing);
  });

  testWidgets('ignores invalid coordinates', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TripMapPreview(
            startLatitude: double.nan,
            startLongitude: -105,
            endLatitude: 40,
            endLongitude: -105,
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(FlutterMap), findsOneWidget);
  });

  testWidgets('does not crash with same start and end coordinates', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TripMapPreview(
            startLatitude: 40,
            startLongitude: -105,
            endLatitude: 40,
            endLongitude: -105,
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(FlutterMap), findsOneWidget);
  });
}
