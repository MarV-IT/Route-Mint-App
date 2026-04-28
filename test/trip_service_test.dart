import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:route_mint_app/features/trips/models/trip.dart';
import 'package:route_mint_app/features/trips/services/trip_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Trip metadata backward compatibility', () {
    test('loads old trips without detection metadata safely', () {
      final trip = Trip.fromJson({
        'id': 'old-trip',
        'from': 'Home',
        'to': 'Client',
        'distance': 12.5,
        'category': 'business',
        'date': '2026-04-27T09:00:00.000',
      });

      expect(trip.detectionMode, TripDetectionMode.manual);
      expect(trip.reviewStatus, TripReviewStatus.reviewed);
      expect(trip.startTime, DateTime.parse('2026-04-27T09:00:00.000'));
      expect(trip.endTime, isNull);
    });

    test('falls back safely for unknown enum string values', () {
      final trip = Trip.fromJson({
        'id': 'unknown-enums',
        'from': 'Home',
        'to': 'Client',
        'distance': 12.5,
        'category': 'business',
        'date': '2026-04-27T09:00:00.000',
        'detectionMode': 'futureMode',
        'reviewStatus': 'futureStatus',
      });

      expect(trip.detectionMode, TripDetectionMode.manual);
      expect(trip.reviewStatus, TripReviewStatus.reviewed);
    });

    test('TripService skips malformed saved entries', () async {
      SharedPreferences.setMockInitialValues({
        'trips': jsonEncode([
          {
            'id': 'valid-trip',
            'from': 'Home',
            'to': 'Client',
            'distance': 12.5,
            'category': 'business',
            'date': '2026-04-27T09:00:00.000',
          },
          {
            'id': 'broken-trip',
            'from': 'Home',
            'to': 'Client',
            'distance': 'not-a-number',
            'category': 'business',
            'date': '2026-04-27T09:00:00.000',
          },
          'not an object',
        ]),
      });

      final trips = await TripService().loadTrips();

      expect(trips, hasLength(1));
      expect(trips.single.id, 'valid-trip');
      expect(trips.single.detectionMode, TripDetectionMode.manual);
      expect(trips.single.reviewStatus, TripReviewStatus.reviewed);
    });
  });
}
