import 'package:flutter/material.dart';
import '../../app/app.dart';
import '../../core/localization/app_strings.dart';
import '../../shared/utils/currency_utils.dart';
import '../../shared/utils/distance_utils.dart';
import 'edit_trip_screen.dart';
import 'models/trip.dart';
import 'services/trip_service.dart';

enum _PeriodFilter { all, thisMonth, lastMonth }

enum _StatusFilter { all, needsReview }

class TripsScreen extends StatefulWidget {
  final AppStrings strings;
  final AppUnit unit;
  final String currencyCode;

  const TripsScreen({
    super.key,
    required this.strings,
    required this.unit,
    required this.currencyCode,
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
  _StatusFilter _statusFilter = _StatusFilter.all;

  @override
  void initState() {
    super.initState();
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

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${months[d.month - 1]} ${d.day}, ${d.year} · $hh:$mm';
  }

  String _buildExpenseLine(Trip trip, AppStrings s) {
    final parts = <String>[];
    if (trip.parkingExpense > 0) {
      parts.add('${s.parking}: ${formatCurrency(trip.parkingExpense, widget.currencyCode)}');
    }
    if (trip.tollsExpense > 0) {
      parts.add('${s.tolls}: ${formatCurrency(trip.tollsExpense, widget.currencyCode)}');
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
      appBar: AppBar(title: Text(s.trips)),
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
                              () => _periodFilter = _PeriodFilter.thisMonth),
                        ),
                        ChoiceChip(
                          label: Text(s.lastMonth),
                          selected: _periodFilter == _PeriodFilter.lastMonth,
                          onSelected: (_) => setState(
                              () => _periodFilter = _PeriodFilter.lastMonth),
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
                              () => _statusFilter = _StatusFilter.needsReview),
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
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
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
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right,
                      size: 18, color: cs.onSurfaceVariant),
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
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  _dot(cs),
                  Text(
                    formatDistance(trip.distance, widget.unit),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontWeight: FontWeight.w500),
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
                ],
              ),

              if (trip.reviewStatus == TripReviewStatus.needsReview) ...[
                const SizedBox(height: 4),
                Text(
                  s.tapToReview,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],

              // ── Expenses ──────────────────────────────────────────────
              if (hasExpenses) ...[
                const SizedBox(height: 6),
                Text(
                  _buildExpenseLine(trip, s),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
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

  Widget _dot(ColorScheme cs) => Text(
        '·',
        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
      );

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
