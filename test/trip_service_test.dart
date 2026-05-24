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

    test('loads tracking diagnostics when present', () {
      final trip = Trip.fromJson({
        'id': 'diagnostic-trip',
        'from': 'Home',
        'to': 'Client',
        'distance': 12.5,
        'category': 'business',
        'date': '2026-04-27T09:00:00.000',
        'trackingDiagnostics': {
          'rawPointCount': 10,
          'validPointCount': 8,
          'droppedPointCount': 2,
          'averageAccuracyMeters': 24.5,
          'maxGapSeconds': 35,
          'durationSeconds': 600,
        },
      });

      expect(trip.trackingDiagnostics, isNotNull);
      expect(trip.trackingDiagnostics!.rawPointCount, 10);
      expect(trip.trackingDiagnostics!.validPointCount, 8);
      expect(trip.trackingDiagnostics!.droppedPointCount, 2);
      expect(trip.trackingDiagnostics!.averageAccuracyMeters, 24.5);
      expect(trip.trackingDiagnostics!.maxGapSeconds, 35);
      expect(trip.trackingDiagnostics!.durationSeconds, 600);
    });

    test('normalizes UTC trip timestamps to device local time', () {
      final trip = Trip.fromJson({
        'id': 'utc-trip',
        'from': 'Home',
        'to': 'Client',
        'distance': 12.5,
        'category': 'business',
        'date': '2026-05-07T20:26:00.000Z',
        'startTime': '2026-05-07T20:26:00.000Z',
        'endTime': '2026-05-07T20:40:00.000Z',
        'routePoints': [
          {
            'latitude': 43.615,
            'longitude': -116.202,
            'timestamp': '2026-05-07T20:26:00.000Z',
          },
        ],
      });

      expect(trip.date.isUtc, false);
      expect(trip.date, DateTime.parse('2026-05-07T20:26:00.000Z').toLocal());
      expect(
        trip.startTime,
        DateTime.parse('2026-05-07T20:26:00.000Z').toLocal(),
      );
      expect(
        trip.endTime,
        DateTime.parse('2026-05-07T20:40:00.000Z').toLocal(),
      );
      expect(
        trip.routePoints.single.timestamp,
        DateTime.parse('2026-05-07T20:26:00.000Z').toLocal(),
      );
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

    test('TripService adds trip distance to stored odometer', () async {
      SharedPreferences.setMockInitialValues({
        'user_preferences': jsonEncode({
          'country': 'usa',
          'currencyCode': 'USD',
          'unit': 'miles',
          'language': 'english',
          'onboardingCompleted': true,
          'vehicleOdometerKm': 1000.0,
        }),
      });

      await TripService().addTrip(
        Trip(
          id: 'trip-1',
          from: 'A',
          to: 'B',
          distance: 25.0,
          category: 'personal',
          date: DateTime(2026, 5, 13),
        ),
      );

      final prefs = await SharedPreferences.getInstance();
      final stored =
          jsonDecode(prefs.getString('user_preferences')!)
              as Map<String, dynamic>;

      expect(stored['vehicleOdometerKm'], 1025.0);
    });

    test(
      'TripService adjusts odometer by edit delta and delete delta',
      () async {
        SharedPreferences.setMockInitialValues({
          'user_preferences': jsonEncode({
            'country': 'usa',
            'currencyCode': 'USD',
            'unit': 'miles',
            'language': 'english',
            'onboardingCompleted': true,
            'vehicleOdometerKm': 1000.0,
          }),
        });

        final service = TripService();
        final trip = Trip(
          id: 'trip-1',
          from: 'A',
          to: 'B',
          distance: 25.0,
          category: 'personal',
          date: DateTime(2026, 5, 13),
        );

        await service.addTrip(trip);
        await service.updateTrip(trip.copyWith(distance: 30.0));
        await service.deleteTrip(trip.id);

        final prefs = await SharedPreferences.getInstance();
        final stored =
            jsonDecode(prefs.getString('user_preferences')!)
                as Map<String, dynamic>;

        expect(stored['vehicleOdometerKm'], 1000.0);
      },
    );
  });
}
