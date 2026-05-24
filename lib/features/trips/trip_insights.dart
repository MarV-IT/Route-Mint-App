import 'models/trip.dart';

enum TripQualityKind { manual, gpsGaps, lowGps, good }

const List<String> defaultTripPlatforms = [
  'Uber',
  'Lyft',
  'DoorDash',
  'Instacart',
  'Spark Driver',
  'Amazon Flex',
];

class TripQualityInsight {
  const TripQualityInsight({required this.kind, required this.needsAttention});

  final TripQualityKind kind;
  final bool needsAttention;
}

TripQualityInsight qualityInsightFor(Trip trip) {
  final diagnostics = trip.trackingDiagnostics;
  if (diagnostics == null) {
    return const TripQualityInsight(
      kind: TripQualityKind.manual,
      needsAttention: false,
    );
  }

  if (diagnostics.maxGapSeconds > 90) {
    return const TripQualityInsight(
      kind: TripQualityKind.gpsGaps,
      needsAttention: true,
    );
  }

  if (diagnostics.averageAccuracyMeters > 100) {
    return const TripQualityInsight(
      kind: TripQualityKind.lowGps,
      needsAttention: true,
    );
  }

  return const TripQualityInsight(
    kind: TripQualityKind.good,
    needsAttention: false,
  );
}

String? platformSuggestionFor(Trip trip) {
  final haystack = '${trip.from} ${trip.to}'.toLowerCase();

  if (_containsAny(haystack, const ['walmart', 'sam club', "sam's club"])) {
    return 'Spark Driver';
  }
  if (_containsAny(haystack, const ['amazon', 'fulfillment', 'warehouse'])) {
    return 'Amazon Flex';
  }
  if (_containsAny(haystack, const [
    'costco',
    'safeway',
    'albertsons',
    'kroger',
    'grocery',
    'market',
  ])) {
    return 'Instacart';
  }
  if (_containsAny(haystack, const [
    'restaurant',
    'pizza',
    'taco',
    'burger',
    'mcdonald',
    'wendy',
    'chipotle',
    'subway',
    'cafe',
  ])) {
    return 'DoorDash';
  }
  if (_containsAny(haystack, const ['airport', 'terminal', 'hotel'])) {
    return 'Uber';
  }

  return null;
}

bool isMergeCandidate(
  Trip a,
  Trip b, {
  Duration maxGap = const Duration(minutes: 20),
}) {
  if (a.id == b.id) return false;
  if (a.detectionMode != TripDetectionMode.automatic ||
      b.detectionMode != TripDetectionMode.automatic) {
    return false;
  }

  final aStart = a.startTime ?? a.date;
  final aEnd = a.endTime ?? a.date;
  final bStart = b.startTime ?? b.date;
  final bEnd = b.endTime ?? b.date;

  final gap = aEnd.isBefore(bStart)
      ? bStart.difference(aEnd)
      : bEnd.isBefore(aStart)
      ? aStart.difference(bEnd)
      : Duration.zero;

  return !gap.isNegative && gap <= maxGap;
}

Trip mergeTrips(Trip a, Trip b) {
  final first = (a.startTime ?? a.date).isBefore(b.startTime ?? b.date) ? a : b;
  final second = first.id == a.id ? b : a;
  final category = first.category == second.category
      ? first.category
      : (first.category == 'business' || second.category == 'business')
      ? 'business'
      : 'personal';
  final platformName = first.platformName == second.platformName
      ? first.platformName
      : first.platformName ?? second.platformName;

  return first.copyWith(
    to: second.to,
    distance: first.distance + second.distance,
    category: category,
    platformName: category == 'business' ? platformName : null,
    parkingExpense: first.parkingExpense + second.parkingExpense,
    tollsExpense: first.tollsExpense + second.tollsExpense,
    businessPurpose: first.businessPurpose ?? second.businessPurpose,
    notes: _mergedNotes(first.notes, second.notes),
    reviewStatus:
        first.reviewStatus == TripReviewStatus.needsReview ||
            second.reviewStatus == TripReviewStatus.needsReview
        ? TripReviewStatus.needsReview
        : TripReviewStatus.reviewed,
    endTime: second.endTime ?? second.date,
    endLatitude: second.endLatitude,
    endLongitude: second.endLongitude,
    routePoints: [...first.routePoints, ...second.routePoints],
    trackingDiagnostics: _mergeDiagnostics(
      first.trackingDiagnostics,
      second.trackingDiagnostics,
    ),
  );
}

bool _containsAny(String haystack, List<String> needles) =>
    needles.any(haystack.contains);

String? _mergedNotes(String? first, String? second) {
  if (first == null || first.isEmpty) return second;
  if (second == null || second.isEmpty || second == first) return first;
  return '$first\n$second';
}

TripTrackingDiagnostics? _mergeDiagnostics(
  TripTrackingDiagnostics? first,
  TripTrackingDiagnostics? second,
) {
  if (first == null) return second;
  if (second == null) return first;

  final validPoints = first.validPointCount + second.validPointCount;
  final weightedAccuracy = validPoints == 0
      ? 0.0
      : ((first.averageAccuracyMeters * first.validPointCount) +
                (second.averageAccuracyMeters * second.validPointCount)) /
            validPoints;

  return TripTrackingDiagnostics(
    rawPointCount: first.rawPointCount + second.rawPointCount,
    validPointCount: validPoints,
    droppedPointCount: first.droppedPointCount + second.droppedPointCount,
    averageAccuracyMeters: weightedAccuracy,
    maxGapSeconds: first.maxGapSeconds > second.maxGapSeconds
        ? first.maxGapSeconds
        : second.maxGapSeconds,
    durationSeconds: first.durationSeconds + second.durationSeconds,
  );
}
