import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:route_mint_app/shared/widgets/trip_map_preview.dart';

/// Serves a 1x1 transparent PNG for every tile so widget tests never reach
/// the real OpenStreetMap servers.
class _OfflineTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return MemoryImage(_transparentPixel);
  }
}

final Uint8List _transparentPixel = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAAXNSR0IArs4c6QAA'
  'AARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAALSURBVBhXY2AA'
  'AgAABQABqtXIUQAAAABJRU5ErkJggg==',
);

void main() {
  testWidgets('renders safely with null coordinates', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TripMapPreview(
            startLatitude: null,
            startLongitude: null,
            endLatitude: null,
            endLongitude: null,
            tileProvider: _OfflineTileProvider(),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(FlutterMap), findsNothing);
  });

  testWidgets('ignores invalid coordinates', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TripMapPreview(
            startLatitude: double.nan,
            startLongitude: -105,
            endLatitude: 40,
            endLongitude: -105,
            tileProvider: _OfflineTileProvider(),
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
      MaterialApp(
        home: Scaffold(
          body: TripMapPreview(
            startLatitude: 40,
            startLongitude: -105,
            endLatitude: 40,
            endLongitude: -105,
            tileProvider: _OfflineTileProvider(),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(FlutterMap), findsOneWidget);
  });
}
