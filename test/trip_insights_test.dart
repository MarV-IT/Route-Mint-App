import 'package:flutter_test/flutter_test.dart';
import 'package:route_mint_app/features/trips/models/trip.dart';
import 'package:route_mint_app/features/trips/trip_insights.dart';

void main() {
  group('platformSuggestionFor', () {
    test('suggests Spark Driver for Walmart trips', () {
      final trip = _trip(from: '8300 W Overland Rd Walmart', to: 'Customer');

      expect(platformSuggestionFor(trip), 'Spark Driver');
    });

    test('suggests Amazon Flex for Amazon trips', () {
      final trip = _trip(from: 'Amazon Fulfillment Center', to: 'Customer');

      expect(platformSuggestionFor(trip), 'Amazon Flex');
    });
  });

  group('mergeTrips', () {
    test('combines nearby automatic segments', () {
      final first = _trip(
        id: 'a',
        distance: 2,
        start: DateTime(2026, 5, 22, 10),
        end: DateTime(2026, 5, 22, 10, 10),
      );
      final second = _trip(
        id: 'b',
        from: 'Middle',
        to: 'End',
        distance: 3,
        start: DateTime(2026, 5, 22, 10, 20),
        end: DateTime(2026, 5, 22, 10, 30),
      );

      expect(isMergeCandidate(first, second), isTrue);

      final merged = mergeTrips(first, second);

      expect(merged.id, 'a');
      expect(merged.to, 'End');
      expect(merged.distance, 5);
    });
  });
}

Trip _trip({
  String id = 'trip',
  String from = 'Start',
  String to = 'End',
  double distance = 1,
  DateTime? start,
  DateTime? end,
}) {
  final startedAt = start ?? DateTime(2026, 5, 22, 10);
  return Trip(
    id: id,
    from: from,
    to: to,
    distance: distance,
    category: 'personal',
    date: startedAt,
    detectionMode: TripDetectionMode.automatic,
    reviewStatus: TripReviewStatus.needsReview,
    startTime: startedAt,
    endTime: end ?? startedAt.add(const Duration(minutes: 10)),
  );
}
