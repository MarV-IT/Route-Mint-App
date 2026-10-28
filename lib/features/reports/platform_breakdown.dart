import 'package:flutter/material.dart' show DateTimeRange;

import '../trips/models/trip.dart';

/// The window the Reports charts summarise.
enum ChartPeriod { week, month, allTime }

/// What a slice of the platform charts stands for.
enum PlatformBucketKind { platform, otherWork, personal }

/// One slice of the platform charts: a named platform, the remaining work
/// trips, or personal trips.
class PlatformBucket {
  const PlatformBucket.platform(String this.name, int this.colorSlot)
    : kind = PlatformBucketKind.platform;
  const PlatformBucket.otherWork()
    : kind = PlatformBucketKind.otherWork,
      name = null,
      colorSlot = null;
  const PlatformBucket.personal()
    : kind = PlatformBucketKind.personal,
      name = null,
      colorSlot = null;

  final PlatformBucketKind kind;

  /// Display name; set only for [PlatformBucketKind.platform].
  final String? name;

  /// Colour slot 0..[PlatformColorAssignment.maxNamedPlatforms]-1; set only
  /// for named platforms.
  final int? colorSlot;

  @override
  bool operator ==(Object other) =>
      other is PlatformBucket && other.kind == kind && other.name == name;

  @override
  int get hashCode => Object.hash(kind, name);
}

/// Decides which platforms get a colour of their own.
///
/// Only [maxNamedPlatforms] colours stay distinguishable whatever two of
/// them end up side by side — validated for normal vision and red-green
/// colour blindness on both themes — so the most used platforms get those and
/// the rest of the work trips share the "other work" colour.
///
/// Ranking uses the whole trip history, never the selected period, so
/// switching Week / Month / All time does not repaint a platform.
class PlatformColorAssignment {
  PlatformColorAssignment._(this._slotByKey, this._displayName);

  static const maxNamedPlatforms = 3;

  final Map<String, int> _slotByKey;
  final Map<String, String> _displayName;

  factory PlatformColorAssignment.fromTrips(Iterable<Trip> allTrips) {
    final counts = <String, int>{};
    final displayName = <String, String>{};
    for (final trip in allTrips) {
      final key = _workPlatformKey(trip);
      if (key == null) continue;
      counts[key] = (counts[key] ?? 0) + 1;
      displayName.putIfAbsent(key, () => trip.platformName!.trim());
    }

    final ranked = counts.keys.toList()
      ..sort((a, b) {
        final byCount = counts[b]!.compareTo(counts[a]!);
        return byCount != 0 ? byCount : a.compareTo(b);
      });

    final slots = <String, int>{
      for (var i = 0; i < ranked.length && i < maxNamedPlatforms; i++)
        ranked[i]: i,
    };
    return PlatformColorAssignment._(slots, displayName);
  }

  PlatformBucket bucketFor(Trip trip) {
    if (trip.category != 'business') return const PlatformBucket.personal();
    final key = _workPlatformKey(trip);
    final slot = key == null ? null : _slotByKey[key];
    if (slot == null) return const PlatformBucket.otherWork();
    return PlatformBucket.platform(_displayName[key]!, slot);
  }

  /// Platforms are grouped case-insensitively so "Uber" typed by hand and
  /// "uber" from a list stay one slice.
  static String? _workPlatformKey(Trip trip) {
    if (trip.category != 'business') return null;
    final name = trip.platformName?.trim();
    if (name == null || name.isEmpty) return null;
    return name.toLowerCase();
  }
}

/// One row of the breakdown.
class PlatformShare {
  const PlatformShare({
    required this.bucket,
    required this.tripCount,
    required this.percent,
  });

  final PlatformBucket bucket;
  final int tripCount;

  /// Whole percent of all trips in the period; the shares sum to exactly 100.
  final int percent;

  /// A slice that has trips but rounds down to 0% — shown as "<1%" so the
  /// label never claims there is nothing there.
  bool get isBelowOnePercent => tripCount > 0 && percent == 0;
}

class PlatformBreakdown {
  const PlatformBreakdown({required this.shares, required this.totalTrips});

  /// Named platforms by trip count, then other work, then personal.
  final List<PlatformShare> shares;
  final int totalTrips;

  bool get isEmpty => totalTrips == 0;
}

/// The date range a [period] covers, used both for filtering and as the
/// report dates when the charts export a PDF.
DateTimeRange chartPeriodRange(
  ChartPeriod period,
  DateTime now, {
  DateTime? earliest,
}) {
  final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
  switch (period) {
    case ChartPeriod.week:
      final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
      return DateTimeRange(start: monday, end: endOfToday);
    case ChartPeriod.month:
      return DateTimeRange(
        start: DateTime(now.year, now.month),
        end: DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999),
      );
    case ChartPeriod.allTime:
      final start = earliest == null
          ? DateTime(now.year, now.month, now.day)
          : DateTime(earliest.year, earliest.month, earliest.day);
      return DateTimeRange(
        start: start.isAfter(endOfToday) ? endOfToday : start,
        end: endOfToday,
      );
  }
}

/// Records dated in [period]. All time keeps everything, including anything
/// dated after today.
List<T> inChartPeriod<T>(
  Iterable<T> records,
  DateTime Function(T record) dateOf,
  ChartPeriod period,
  DateTime now,
) {
  if (period == ChartPeriod.allTime) return records.toList();
  final range = chartPeriodRange(period, now);
  return records.where((r) {
    final date = dateOf(r);
    return !date.isBefore(range.start) && !date.isAfter(range.end);
  }).toList();
}

/// Trips that fall in [period].
List<Trip> tripsInPeriod(
  Iterable<Trip> trips,
  ChartPeriod period,
  DateTime now,
) => inChartPeriod(trips, (t) => t.date, period, now);

/// Groups [trips] into chart slices.
PlatformBreakdown buildPlatformBreakdown({
  required List<Trip> trips,
  required PlatformColorAssignment colors,
}) {
  final counts = <PlatformBucket, int>{};
  for (final trip in trips) {
    final bucket = colors.bucketFor(trip);
    counts[bucket] = (counts[bucket] ?? 0) + 1;
  }

  final ordered = counts.keys.toList()
    ..sort((a, b) {
      final byKind = a.kind.index.compareTo(b.kind.index);
      if (byKind != 0) return byKind;
      final byCount = counts[b]!.compareTo(counts[a]!);
      return byCount != 0 ? byCount : (a.colorSlot ?? 0) - (b.colorSlot ?? 0);
    });

  final percents = roundedPercents([for (final b in ordered) counts[b]!]);
  final shares = <PlatformShare>[
    for (var i = 0; i < ordered.length; i++)
      PlatformShare(
        bucket: ordered[i],
        tripCount: counts[ordered[i]]!,
        percent: percents[i],
      ),
  ];

  return PlatformBreakdown(shares: shares, totalTrips: trips.length);
}

/// Rounds each count's share to a whole percent so the results sum to
/// exactly 100. The largest share absorbs the rounding error, as the spec
/// asks, rather than nudging several small slices.
List<int> roundedPercents(List<int> counts) {
  final total = counts.fold(0, (s, c) => s + c);
  if (total == 0) return List.filled(counts.length, 0);

  final rounded = [for (final c in counts) (c * 100 / total).round()];
  var largest = 0;
  for (var i = 1; i < counts.length; i++) {
    if (counts[i] > counts[largest]) largest = i;
  }
  final error = 100 - rounded.fold(0, (s, p) => s + p);
  rounded[largest] = (rounded[largest] + error).clamp(0, 100).toInt();
  return rounded;
}
