import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import '../../shared/widgets/summary_card.dart';
import '../../shared/widgets/quick_actions_card.dart';
import '../../shared/utils/distance_utils.dart';
import '../../app/app.dart';
import '../trips/services/trip_service.dart';
import '../trips/models/trip.dart';
import '../../core/tax/tax_service.dart';
import '../../core/storage/settings_service.dart';

class TodayScreen extends StatefulWidget {
  final AppStrings strings;
  final AppUnit unit;

  const TodayScreen({
    super.key,
    required this.strings,
    required this.unit,
  });

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  final _taxService = TaxService();
  final _settingsService = SettingsService();

  double _taxToday = 0;
  Country _country = Country.usa;

  final _tripService = TripService();

  List<Trip> _todayTrips = [];
  double _totalDistance = 0;
  double _businessDistance = 0;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    final allTrips = await _tripService.loadTrips();
    final country = await _settingsService.loadCountry();

    final now = DateTime.now();

    final todayTrips = allTrips.where((trip) {
      return trip.date.year == now.year &&
           trip.date.month == now.month &&
           trip.date.day == now.day;
    }).toList();

    double total = 0;
    double business = 0;

    for (final trip in todayTrips) {
      total += trip.distance;

      if (trip.category == 'business') {
      business += trip.distance;
      }
    }

    final tax = _taxService.calculateTaxFromKm(business, country);

    if (!mounted) return;

    setState(() {
      _todayTrips = todayTrips;
      _totalDistance = total;
      _businessDistance = business;
      _taxToday = tax;
      _country = country;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.strings.today),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SummaryCard(
            title: widget.strings.todayDistance,
            value: formatDistance(_totalDistance, widget.unit),
            subtitle:
                '${widget.strings.tripsRecorded}: ${_todayTrips.length}',
          ),
          const SizedBox(height: 12),
          SummaryCard(
            title: widget.strings.businessTrips,
            value: formatDistance(_businessDistance, widget.unit),
            subtitle: '${_todayTrips.length} ${widget.strings.tripsNeedReview}',
          ),
          const SizedBox(height: 12),
          SummaryCard(
            title: 'Tax savings today',
            value: '\$${_taxToday.toStringAsFixed(2)}',
            subtitle: _country == Country.usa ? 'USA rate' : 'Canada rate',
          ),
          const SizedBox(height: 12),
          QuickActionsCard(strings: widget.strings),
        ],
      ),
    );
  }
}