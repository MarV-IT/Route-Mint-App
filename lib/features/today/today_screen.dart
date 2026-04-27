import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import '../../core/preferences/user_preferences.dart';
import '../../core/tax/tax_service.dart';
import '../../shared/utils/currency_utils.dart';
import '../../shared/utils/distance_utils.dart';
import '../../shared/widgets/quick_actions_card.dart';
import '../../shared/widgets/summary_card.dart';
import '../../app/app.dart';
import '../trips/models/trip.dart';
import '../trips/services/trip_service.dart';

class TodayScreen extends StatefulWidget {
  final AppStrings strings;
  final AppUnit unit;
  final UserPreferences preferences;
  final VoidCallback onStartTrip;
  final VoidCallback onAddManually;
  final VoidCallback onAddExpense;

  const TodayScreen({
    super.key,
    required this.strings,
    required this.unit,
    required this.preferences,
    required this.onStartTrip,
    required this.onAddManually,
    required this.onAddExpense,
  });

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  final _taxService = TaxService();
  final _tripService = TripService();

  List<Trip> _todayTrips = [];
  double _totalDistance = 0;
  double _businessDistance = 0;
  double _taxToday = 0;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  @override
  void didUpdateWidget(TodayScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.preferences.country != widget.preferences.country) {
      setState(() {
        _taxToday = _taxService.calculateTaxFromKm(
          _businessDistance,
          widget.preferences.country,
        );
      });
    }
  }

  Future<void> _loadTrips() async {
    final allTrips = await _tripService.loadTrips();
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

    if (!mounted) return;

    setState(() {
      _todayTrips = todayTrips;
      _totalDistance = total;
      _businessDistance = business;
      _taxToday = _taxService.calculateTaxFromKm(
        business,
        widget.preferences.country,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final businessCount = _todayTrips
        .where((t) => t.category == 'business')
        .length;
    final countryLabel = widget.preferences.country == Country.usa
        ? widget.strings.unitedStates
        : widget.strings.canada;

    return Scaffold(
      appBar: AppBar(title: Text(widget.strings.today)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SummaryCard(
            title: widget.strings.todayDistance,
            value: formatDistance(_totalDistance, widget.unit),
            subtitle: '${widget.strings.tripsRecorded}: ${_todayTrips.length}',
          ),
          const SizedBox(height: 12),
          SummaryCard(
            title: widget.strings.businessTrips,
            value: formatDistance(_businessDistance, widget.unit),
            subtitle: '$businessCount ${widget.strings.tripsLabel}',
          ),
          const SizedBox(height: 12),
          SummaryCard(
            title: widget.strings.taxSavingsToday,
            value: formatCurrency(_taxToday, widget.preferences.currencyCode),
            subtitle: countryLabel,
          ),
          const SizedBox(height: 12),
          QuickActionsCard(
            strings: widget.strings,
            onStartTrip: widget.onStartTrip,
            onAddManually: widget.onAddManually,
            onAddExpense: widget.onAddExpense,
          ),
        ],
      ),
    );
  }
}
