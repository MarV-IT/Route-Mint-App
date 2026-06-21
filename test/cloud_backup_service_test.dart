import 'package:flutter_test/flutter_test.dart';
import 'package:route_mint_app/core/backup/cloud_backup_service.dart';
import 'package:route_mint_app/features/trips/models/trip.dart';

void main() {
  group('CloudBackupService.tripToBackupJson', () {
    final trip = Trip(
      id: 'trip-1',
      from: 'Home',
      to: 'Airport',
      distance: 42.5,
      category: 'Business',
      date: DateTime(2026, 6, 13, 9, 0),
      startLatitude: 40.0,
      startLongitude: -105.0,
      endLatitude: 40.1,
      endLongitude: -105.2,
      routePoints: List.generate(
        500,
        (i) => TripRoutePoint(
          latitude: 40.0 + i * 0.0001,
          longitude: -105.0 - i * 0.0001,
          timestamp: DateTime(2026, 6, 13, 9, 0).add(Duration(seconds: i)),
        ),
      ),
    );

    test('drops route points to bound Firestore document size', () {
      final json = CloudBackupService.tripToBackupJson(trip);

      expect(json['routePoints'], isEmpty);
    });

    test('preserves all other trip data', () {
      final json = CloudBackupService.tripToBackupJson(trip);
      final restored = Trip.fromJson(json);

      expect(restored.id, trip.id);
      expect(restored.from, trip.from);
      expect(restored.to, trip.to);
      expect(restored.distance, trip.distance);
      expect(restored.category, trip.category);
      expect(restored.startLatitude, trip.startLatitude);
      expect(restored.endLongitude, trip.endLongitude);
      expect(restored.routePoints, isEmpty);
    });

    test('does not mutate the source trip', () {
      CloudBackupService.tripToBackupJson(trip);

      expect(trip.routePoints, hasLength(500));
    });
  });
}
