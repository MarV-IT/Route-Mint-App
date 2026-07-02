import 'package:flutter/material.dart';
import '../../app/app.dart';
import '../../core/localization/app_strings.dart';
import '../../shared/utils/currency_utils.dart';
import '../../shared/utils/distance_utils.dart';
import 'edit_trip_screen.dart';
import 'models/trip.dart';
import 'services/trip_service.dart';
import 'trip_insights.dart';

enum _PeriodFilter { all, thisMonth, lastMonth }

enum _StatusFilter { all, needsReview }

class TripsScreen extends StatefulWidget {
  final AppStrings strings;
  final AppUnit unit;
  final String currencyCode;
  final bool showNeedsReviewOnly;
  final Future<void> Function() onPreferencesRefresh;

  const TripsScreen({
    super.key,
    required this.strings,
    required this.unit,
    required this.currencyCode,
    required this.onPreferencesRefresh,
    this.showNeedsReviewOnly = false,
  });

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  final _tripService = TripService();

  List<Trip> _allTrips = [];
  bool _isLoading = true;
  String? _categoryFilter; // null = all, 'business', 'personal'
  _PeriodFilter _periodFilter = _PeriodFilter.all;
  late _StatusFilter _statusFilter;

  @override
  void initState() {
    super.initState();
    _statusFilter = widget.showNeedsReviewOnly
        ? _StatusFilter.needsReview
        : _StatusFilter.all;
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    final trips = await _tripService.loadTrips();
    if (!mounted) return;
    setState(() {
      _allTrips = trips;
      _isLoading = false;
    });
  }

  List<Trip> get _filteredTrips {
    var result = [..._allTrips];

    if (_categoryFilter != null) {
      result = result.where((t) => t.category == _categoryFilter).toList();
    }

    if (_periodFilter != _PeriodFilter.all) {
      final now = DateTime.now();
      final DateTime start, end;
      if (_periodFilter == _PeriodFilter.thisMonth) {
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      } else {
        final first = DateTime(now.year, now.month - 1, 1);
        start = first;
        end = DateTime(first.year, first.month + 1, 0, 23, 59, 59);
      }
      result = result
          .where((t) => !t.date.isBefore(start) && !t.date.isAfter(end))
          .toList();
    }

    if (_statusFilter == _StatusFilter.needsReview) {
      result = result
          .where((t) => t.reviewStatus == TripReviewStatus.needsReview)
          .toList();
    }

    result.sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  List<Trip> get _pendingTrips {
    final trips = _allTrips
        .where((trip) => trip.reviewStatus == TripReviewStatus.needsReview)
        .toList();
    trips.sort((a, b) => a.date.compareTo(b.date));
    return trips;
  }

  String _formatDate(DateTime d) {
    final local = d.toLocal();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '${months[local.month - 1]} ${local.day}, ${local.year} · $hh:$mm';
  }

  String _buildExpenseLine(Trip trip, AppStrings s) {
    final parts = <String>[];
    if (trip.parkingExpense > 0) {
      parts.add(
        '${s.parking}: ${formatCurrency(trip.parkingExpense, widget.currencyCode)}',
      );
    }
    if (trip.tollsExpense > 0) {
      parts.add(
        '${s.tolls}: ${formatCurrency(trip.tollsExpense, widget.currencyCode)}',
      );
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(s.trips)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final filtered = _filteredTrips;
    final hasAnyTrips = _allTrips.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.trips),
        actions: [
          if (_pendingTrips.isNotEmpty)
            TextButton.icon(
              onPressed: _openQuickReview,
              icon: const Icon(Icons.rate_review_outlined, size: 18),
              label: Text('${_pendingTrips.length}'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTrips,
        child: CustomScrollView(
          slivers: [
            // ── Filters ───────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: Text(s.all),
                          selected: _categoryFilter == null,
                          onSelected: (_) =>
                              setState(() => _categoryFilter = null),
                        ),
                        ChoiceChip(
                          label: Text(s.business),
                          selected: _categoryFilter == 'business',
                          onSelected: (_) =>
                              setState(() => _categoryFilter = 'business'),
                        ),
                        ChoiceChip(
                          label: Text(s.personal),
                          selected: _categoryFilter == 'personal',
                          onSelected: (_) =>
                              setState(() => _categoryFilter = 'personal'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: Text(s.all),
                          selected: _periodFilter == _PeriodFilter.all,
                          onSelected: (_) =>
                              setState(() => _periodFilter = _PeriodFilter.all),
                        ),
                        ChoiceChip(
                          label: Text(s.thisMonth),
                          selected: _periodFilter == _PeriodFilter.thisMonth,
                          onSelected: (_) => setState(
                            () => _periodFilter = _PeriodFilter.thisMonth,
                          ),
                        ),
                        ChoiceChip(
                          label: Text(s.lastMonth),
                          selected: _periodFilter == _PeriodFilter.lastMonth,
                          onSelected: (_) => setState(
                            () => _periodFilter = _PeriodFilter.lastMonth,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: Text(s.all),
                          selected: _statusFilter == _StatusFilter.all,
                          onSelected: (_) =>
                              setState(() => _statusFilter = _StatusFilter.all),
                        ),
                        ChoiceChip(
                          label: Text(s.needsReview),
                          selected: _statusFilter == _StatusFilter.needsReview,
                          onSelected: (_) => setState(
                            () => _statusFilter = _StatusFilter.needsReview,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                  ],
                ),
              ),
            ),

            // ── Empty states ──────────────────────────────────────────────
            if (!hasAnyTrips)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text(s.noTripsYet)),
              )
            else if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        s.noTripsFound,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        s.tryChangingFilters,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              // ── Trip list ─────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                sliver: SliverList.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, index) => _buildTripCard(filtered[index]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripCard(Trip trip) {
    final s = widget.strings;
    final cs = Theme.of(context).colorScheme;
    final isBusiness = trip.category == 'business';
    final hasExpenses = trip.parkingExpense > 0 || trip.tollsExpense > 0;
    final quality = qualityInsightFor(trip);
    final suggestion = platformSuggestionFor(trip);
    final mergeCandidate = _mergeCandidateFor(trip);

    return Card(
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final refreshed = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => EditTripScreen(
                trip: trip,
                strings: widget.strings,
                unit: widget.unit,
                currencyCode: widget.currencyCode,
                onPreferencesRefresh: widget.onPreferencesRefresh,
              ),
            ),
          );
          if (refreshed == true) _loadTrips();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── From → To ─────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      '${trip.from} → ${trip.to}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // ── Date · Distance · Category · Platform ──────────────────
              Wrap(
                spacing: 4,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    _formatDate(trip.date),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  _dot(cs),
                  Text(
                    formatDistance(trip.distance, widget.unit),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  _dot(cs),
                  _categoryBadge(isBusiness, s, cs),
                  if (trip.reviewStatus == TripReviewStatus.needsReview) ...[
                    _dot(cs),
                    _needsReviewBadge(s, cs),
                  ],
                  if (trip.platformName != null) ...[
                    _dot(cs),
                    Text(
                      trip.platformName!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (trip.detectionMode == TripDetectionMode.automatic) ...[
                    _dot(cs),
                    _qualityBadge(quality, cs),
                  ],
                ],
              ),

              if (trip.reviewStatus == TripReviewStatus.needsReview) ...[
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      suggestion == null
                          ? s.tapToReview
                          : s.suggestedPlatform(suggestion),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _quickReviewTrip(
                        trip,
                        category: 'business',
                        platformName: suggestion ?? trip.platformName,
                      ),
                      child: Text(s.business),
                    ),
                    TextButton(
                      onPressed: () =>
                          _quickReviewTrip(trip, category: 'personal'),
                      child: Text(s.personal),
                    ),
                  ],
                ),
              ],

              if (mergeCandidate != null) ...[
                const SizedBox(height: 4),
                OutlinedButton.icon(
                  onPressed: () => _mergeTripWith(trip, mergeCandidate.trip),
                  icon: Icon(
                    mergeCandidate.isPrevious
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                    size: 18,
                  ),
                  label: Text(
                    mergeCandidate.isPrevious
                        ? s.mergeWithPreviousTrip
                        : s.mergeWithNextTrip,
                  ),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],

              // ── Expenses ──────────────────────────────────────────────
              if (hasExpenses) ...[
                const SizedBox(height: 6),
                Text(
                  _buildExpenseLine(trip, s),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],

              // ── Business purpose ──────────────────────────────────────
              if (trip.businessPurpose != null) ...[
                const SizedBox(height: 4),
                Text(
                  trip.businessPurpose!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot(ColorScheme cs) =>
      Text('·', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12));

  Widget _qualityBadge(TripQualityInsight quality, ColorScheme cs) {
    final color = quality.needsAttention ? cs.error : cs.primary;
    return Tooltip(
      message: _qualityDetail(quality),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            quality.needsAttention
                ? Icons.warning_amber_outlined
                : Icons.gps_fixed,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            _qualityLabel(quality),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  ({Trip trip, bool isPrevious})? _mergeCandidateFor(Trip trip) {
    if (trip.detectionMode != TripDetectionMode.automatic) return null;

    final candidates = _allTrips
        .where((other) => isMergeCandidate(trip, other))
        .toList();
    if (candidates.isEmpty) return null;

    candidates.sort((a, b) {
      final gapCompare = _mergeGap(trip, a).compareTo(_mergeGap(trip, b));
      if (gapCompare != 0) return gapCompare;
      final tripStart = trip.startTime ?? trip.date;
      final aDistance = (a.startTime ?? a.date)
          .difference(tripStart)
          .inMilliseconds
          .abs();
      final bDistance = (b.startTime ?? b.date)
          .difference(tripStart)
          .inMilliseconds
          .abs();
      return aDistance.compareTo(bDistance);
    });

    final candidate = candidates.first;
    final tripStart = trip.startTime ?? trip.date;
    final candidateStart = candidate.startTime ?? candidate.date;
    return (trip: candidate, isPrevious: candidateStart.isBefore(tripStart));
  }

  Duration _mergeGap(Trip trip, Trip other) {
    final tripStart = trip.startTime ?? trip.date;
    final tripEnd = trip.endTime ?? trip.date;
    final otherStart = other.startTime ?? other.date;
    final otherEnd = other.endTime ?? other.date;

    if (otherEnd.isBefore(tripStart)) {
      return tripStart.difference(otherEnd);
    }
    if (tripEnd.isBefore(otherStart)) {
      return otherStart.difference(tripEnd);
    }
    return Duration.zero;
  }

  Future<void> _quickReviewTrip(
    Trip trip, {
    required String category,
    String? platformName,
  }) async {
    final suggestion = platformName ?? platformSuggestionFor(trip);
    final resolved = trip.copyWith(
      category: category,
      platformName: category == 'business' ? suggestion : null,
      businessPurpose:
          category == 'business' &&
              trip.businessPurpose == null &&
              suggestion != null
          ? widget.strings.platformBusinessTrip(suggestion)
          : trip.businessPurpose,
      reviewStatus: TripReviewStatus.reviewed,
    );
    await _tripService.updateTrip(resolved);
    await widget.onPreferencesRefresh();
    await _loadTrips();
  }

  Future<void> _mergeTripWith(Trip trip, Trip other) async {
    final merged = mergeTrips(trip, other);
    final removed = merged.id == trip.id ? other : trip;
    await _tripService.updateTrip(merged);
    await _tripService.deleteTrip(removed.id);
    await widget.onPreferencesRefresh();
    await _loadTrips();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(widget.strings.tripSegmentsMerged)));
  }

  Future<void> _openQuickReview() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _QuickReviewScreen(
          trips: _pendingTrips,
          strings: widget.strings,
          unit: widget.unit,
          tripService: _tripService,
          onPreferencesRefresh: widget.onPreferencesRefresh,
        ),
      ),
    );
    if (changed == true) _loadTrips();
  }

  String _qualityLabel(TripQualityInsight quality) =>
      _qualityLabelFor(widget.strings, quality);

  String _qualityDetail(TripQualityInsight quality) =>
      _qualityDetailFor(widget.strings, quality);

  Widget _needsReviewBadge(AppStrings s, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        s.needsReview,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: cs.onErrorContainer,
        ),
      ),
    );
  }

  Widget _categoryBadge(bool isBusiness, AppStrings s, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isBusiness ? cs.primaryContainer : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isBusiness ? s.business : s.personal,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isBusiness ? cs.onPrimaryContainer : cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _QuickReviewScreen extends StatefulWidget {
  const _QuickReviewScreen({
    required this.trips,
    required this.strings,
    required this.unit,
    required this.tripService,
    required this.onPreferencesRefresh,
  });

  final List<Trip> trips;
  final AppStrings strings;
  final AppUnit unit;
  final TripService tripService;
  final Future<void> Function() onPreferencesRefresh;

  @override
  State<_QuickReviewScreen> createState() => _QuickReviewScreenState();
}

class _QuickReviewScreenState extends State<_QuickReviewScreen> {
  int _index = 0;
  bool _changed = false;
  bool _isSaving = false;

  Trip? get _trip =>
      _index >= widget.trips.length ? null : widget.trips[_index];

  Future<void> _save({required String category, String? platformName}) async {
    final trip = _trip;
    if (trip == null || _isSaving) return;
    setState(() => _isSaving = true);
    final suggestion = platformName ?? platformSuggestionFor(trip);
    final updated = trip.copyWith(
      category: category,
      platformName: category == 'business' ? suggestion : null,
      businessPurpose:
          category == 'business' &&
              trip.businessPurpose == null &&
              suggestion != null
          ? widget.strings.platformBusinessTrip(suggestion)
          : trip.businessPurpose,
      reviewStatus: TripReviewStatus.reviewed,
    );
    await widget.tripService.updateTrip(updated);
    await widget.onPreferencesRefresh();
    if (!mounted) return;
    setState(() {
      _changed = true;
      _isSaving = false;
      _index += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final trip = _trip;
    final cs = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(s.quickReview)),
        body: trip == null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 48),
                    const SizedBox(height: 12),
                    Text(s.allPendingTripsReviewed),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(s.reviewed),
                    ),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LinearProgressIndicator(
                      value: (_index + 1) / widget.trips.length,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${_index + 1} / ${widget.trips.length}',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${trip.from} -> ${trip.to}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formatDistance(trip.distance, widget.unit),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _InsightRow(trip: trip, strings: s),
                    const Spacer(),
                    if (platformSuggestionFor(trip) != null) ...[
                      OutlinedButton.icon(
                        onPressed: _isSaving
                            ? null
                            : () => _save(
                                category: 'business',
                                platformName: platformSuggestionFor(trip),
                              ),
                        icon: const Icon(Icons.auto_awesome_outlined),
                        label: Text(
                          s.usePlatform(platformSuggestionFor(trip)!),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    ...defaultTripPlatforms.map(
                      (platform) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: FilledButton.tonal(
                          onPressed: _isSaving
                              ? null
                              : () => _save(
                                  category: 'business',
                                  platformName: platform,
                                ),
                          child: Text(platform),
                        ),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: _isSaving
                          ? null
                          : () => _save(category: 'personal'),
                      child: Text(s.personal),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({required this.trip, required this.strings});

  final Trip trip;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final quality = qualityInsightFor(trip);
    final suggestion = platformSuggestionFor(trip);
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Chip(
          avatar: Icon(
            quality.needsAttention
                ? Icons.warning_amber_outlined
                : Icons.gps_fixed,
            size: 18,
          ),
          label: Text(_qualityLabelFor(strings, quality)),
          side: BorderSide(
            color: quality.needsAttention ? cs.error : cs.outlineVariant,
          ),
        ),
        if (suggestion != null)
          Chip(
            avatar: const Icon(Icons.auto_awesome_outlined, size: 18),
            label: Text(strings.suggestedPlatform(suggestion)),
          ),
      ],
    );
  }
}

String _qualityLabelFor(AppStrings strings, TripQualityInsight quality) {
  return switch (quality.kind) {
    TripQualityKind.manual => strings.tripQualityManual,
    TripQualityKind.gpsGaps => strings.tripQualityGpsGaps,
    TripQualityKind.lowGps => strings.tripQualityLowGps,
    TripQualityKind.good => strings.tripQualityGpsGood,
  };
}

String _qualityDetailFor(AppStrings strings, TripQualityInsight quality) {
  return switch (quality.kind) {
    TripQualityKind.manual => strings.tripQualityManualDetail,
    TripQualityKind.gpsGaps => strings.tripQualityGpsGapsDetail,
    TripQualityKind.lowGps => strings.tripQualityLowGpsDetail,
    TripQualityKind.good => strings.tripQualityGpsGoodDetail,
  };
}
