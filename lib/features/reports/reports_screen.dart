import 'package:flutter/material.dart';
import '../../app/app.dart';
import '../../core/localization/app_strings.dart';
import '../../shared/utils/distance_utils.dart';
import '../../shared/widgets/summary_card.dart';
import '../trips/models/trip.dart';
import '../trips/services/trip_service.dart';

class ReportsScreen extends StatefulWidget {
  final AppStrings strings;
  final AppUnit unit;

  const ReportsScreen({
    super.key,
    required this.strings,
    required this.unit,
  });

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _tripService = TripService();

  List<Trip> _monthTrips = [];
  List<Trip> _yearTrips = [];

  double _monthTotalDistance = 0;
  double _monthBusinessDistance = 0;

  double _yearTotalDistance = 0;
  double _yearBusinessDistance = 0;

  Map<String, double> _monthPlatformBreakdown = {};

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    final allTrips = await _tripService.loadTrips();
    final now = DateTime.now();

    final monthTrips = allTrips.where((trip) {
      return trip.date.year == now.year && trip.date.month == now.month;
    }).toList();

    final yearTrips = allTrips.where((trip) {
      return trip.date.year == now.year;
    }).toList();

    double monthTotal = 0;
    double monthBusiness = 0;
    final Map<String, double> monthBreakdown = {};

    for (final trip in monthTrips) {
      monthTotal += trip.distance;

      if (trip.category == 'business') {
        monthBusiness += trip.distance;

        final platform = (trip.platformName == null || trip.platformName!.isEmpty)
            ? 'Other'
            : trip.platformName!;

        monthBreakdown[platform] =
            (monthBreakdown[platform] ?? 0) + trip.distance;
      }
    }

    double yearTotal = 0;
    double yearBusiness = 0;

    for (final trip in yearTrips) {
      yearTotal += trip.distance;

      if (trip.category == 'business') {
        yearBusiness += trip.distance;
      }
    }

    if (!mounted) return;

    setState(() {
      _monthTrips = monthTrips;
      _yearTrips = yearTrips;
      _monthTotalDistance = monthTotal;
      _monthBusinessDistance = monthBusiness;
      _yearTotalDistance = yearTotal;
      _yearBusinessDistance = yearBusiness;
      _monthPlatformBreakdown = monthBreakdown;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sortedEntries = _monthPlatformBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.strings.reports),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SummaryCard(
            title: 'This month',
            value: formatDistance(_monthTotalDistance, widget.unit),
            subtitle:
                'Business: ${formatDistance(_monthBusinessDistance, widget.unit)} • Trips: ${_monthTrips.length}',
          ),
          const SizedBox(height: 12),
          SummaryCard(
            title: 'This year',
            value: formatDistance(_yearTotalDistance, widget.unit),
            subtitle:
                'Business: ${formatDistance(_yearBusinessDistance, widget.unit)} • Trips: ${_yearTrips.length}',
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: sortedEntries.isEmpty
                  ? const Text('No business trips by platform yet')
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'This month by platform',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...sortedEntries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(entry.key),
                                ),
                                Text(
                                  formatDistance(entry.value, widget.unit),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}