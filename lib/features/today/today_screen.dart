import 'package:flutter/material.dart';
import '../../core/backup/cloud_backup_service.dart';
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
import '../work_mode/services/work_mode_service.dart';
import 'auto_detection_card.dart';
import 'brake_pad_card.dart';
import 'foreground_tracking_card.dart';
import 'live_trip_map_card.dart';
import 'oil_change_card.dart';

enum _DashboardPeriod { today, thisWeek, thisMonth, thisYear }

class _SetupChecklistCard extends StatelessWidget {
  const _SetupChecklistCard({
    required this.strings,
    required this.countryDone,
    required this.vehicleDone,
    required this.autoDetectionDone,
    required this.workShiftDone,
    required this.cloudBackupDone,
  });

  final AppStrings strings;
  final bool countryDone;
  final bool vehicleDone;
  final bool autoDetectionDone;
  final bool workShiftDone;
  final bool cloudBackupDone;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = [
      (strings.checklistChooseCountry, countryDone),
      (strings.checklistAddVehicle, vehicleDone),
      (strings.checklistEnableAutoDetection, autoDetectionDone),
      (strings.checklistAddWorkShift, workShiftDone),
      (strings.checklistCloudBackup, cloudBackupDone),
    ];

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.checklist_outlined, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    strings.setupChecklist,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final item in items) ...[
              _ChecklistRow(label: item.$1, isDone: item.$2),
              if (item != items.last) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.label, required this.isDone});

  final String label;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(
          isDone ? Icons.check_box : Icons.check_box_outline_blank,
          size: 22,
          color: isDone ? cs.primary : cs.onSurfaceVariant,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

class _WeeklyOdometerReminderCard extends StatelessWidget {
  const _WeeklyOdometerReminderCard({
    required this.strings,
    required this.unit,
    required this.controller,
    required this.onSave,
  });

  final AppStrings strings;
  final AppUnit unit;
  final TextEditingController controller;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: cs.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.speed_outlined, color: cs.onTertiaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    strings.weeklyOdometerReminder,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: cs.onTertiaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              strings.weeklyOdometerReminderMessage,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: cs.onTertiaryContainer),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: strings.currentOdometer,
                suffixText: unitLabel(unit),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: onSave,
                icon: const Icon(Icons.check),
                label: Text(strings.updateOdometer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewInboxCard extends StatelessWidget {
  const _ReviewInboxCard({
    required this.strings,
    required this.count,
    required this.onReviewTrips,
  });

  final AppStrings strings;
  final int count;
  final VoidCallback onReviewTrips;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: cs.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.rate_review_outlined,
                  color: cs.onSecondaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.tripsNeedReviewCount(count),
                        softWrap: true,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: cs.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        strings.reviewDetectedTripsBeforeExport,
                        softWrap: true,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonal(
                onPressed: onReviewTrips,
                child: Text(
                  strings.reviewTrips,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TodayScreen extends StatefulWidget {
  final AppStrings strings;
  final AppUnit unit;
  final UserPreferences preferences;
  final ValueChanged<UserPreferences> onPreferencesChanged;
  final Future<void> Function() onPreferencesRefresh;
  final VoidCallback onStartTrip;
  final VoidCallback onAddManually;
  final VoidCallback onAddExpense;
  final VoidCallback onReviewTrips;

  const TodayScreen({
    super.key,
    required this.strings,
    required this.unit,
    required this.preferences,
    required this.onPreferencesChanged,
    required this.onPreferencesRefresh,
    required this.onStartTrip,
    required this.onAddManually,
    required this.onAddExpense,
    required this.onReviewTrips,
  });

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  final _taxService = TaxService();
  final _tripService = TripService();
  final _workModeService = WorkModeService();
  final _cloudBackupService = CloudBackupService();
  late final TextEditingController _odometerReminderController;

  _DashboardPeriod _period = _DashboardPeriod.today;
  List<Trip> _periodTrips = [];
  double _totalDistance = 0;
  double _businessDistance = 0;
  double _taxPeriod = 0;
  int _needsReviewCount = 0;
  bool _hasWorkShift = false;
  bool _hasCloudBackup = false;

  @override
  void initState() {
    super.initState();
    _odometerReminderController = TextEditingController(
      text: _odometerDisplayText(widget.preferences.vehicleOdometerKm),
    );
    _loadTrips();
    _loadSetupChecklistState();
  }

  @override
  void dispose() {
    _odometerReminderController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TodayScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.preferences.country != widget.preferences.country) {
      setState(() {
        _taxPeriod = _taxService.calculateTaxFromKm(
          _businessDistance,
          widget.preferences.country,
        );
      });
    }
    if (oldWidget.preferences != widget.preferences) {
      if (oldWidget.preferences.vehicleOdometerKm !=
          widget.preferences.vehicleOdometerKm) {
        _odometerReminderController.text = _odometerDisplayText(
          widget.preferences.vehicleOdometerKm,
        );
      }
      _loadSetupChecklistState();
    }
  }

  String _odometerDisplayText(double? km) {
    if (km == null) return '';
    return fromKilometers(km, widget.unit).toStringAsFixed(0);
  }

  Future<void> _loadSetupChecklistState() async {
    final workSettings = await _workModeService.loadSettings();
    final hasCloudBackup = await _cloudBackupService.hasCloudBackup();
    if (!mounted) return;

    setState(() {
      _hasWorkShift = workSettings.shifts.isNotEmpty;
      _hasCloudBackup = hasCloudBackup;
    });
  }

  bool get _countryChecklistDone => widget.preferences.onboardingCompleted;

  bool get _vehicleChecklistDone =>
      widget.preferences.vehicleName?.trim().isNotEmpty == true;

  bool get _setupChecklistComplete =>
      _countryChecklistDone &&
      _vehicleChecklistDone &&
      widget.preferences.autoTripDetectionEnabled &&
      _hasWorkShift &&
      _hasCloudBackup;

  bool get _isWeeklyOdometerReminderDue {
    final now = DateTime.now();
    if (now.weekday != DateTime.monday) return false;
    final last = widget.preferences.lastOdometerUpdateAt;
    if (last == null) return true;
    final mondayStart = DateTime(now.year, now.month, now.day);
    return last.isBefore(mondayStart);
  }

  Future<void> _saveWeeklyOdometer() async {
    final value = double.tryParse(_odometerReminderController.text.trim());
    if (value == null || value < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.strings.odometerCannotBeNegative)),
      );
      return;
    }

    final updated = widget.preferences.copyWith(
      vehicleOdometerKm: toKilometers(value, widget.unit),
      lastOdometerUpdateAt: DateTime.now(),
    );
    widget.onPreferencesChanged(updated);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(widget.strings.odometerUpdated)));
  }

  bool _isInPeriod(DateTime tripDate) {
    final now = DateTime.now();
    switch (_period) {
      case _DashboardPeriod.today:
        return tripDate.year == now.year &&
            tripDate.month == now.month &&
            tripDate.day == now.day;
      case _DashboardPeriod.thisWeek:
        final weekStart = DateTime(
          now.year,
          now.month,
          now.day - (now.weekday - 1),
        );
        final dayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        return !tripDate.isBefore(weekStart) && !tripDate.isAfter(dayEnd);
      case _DashboardPeriod.thisMonth:
        return tripDate.year == now.year && tripDate.month == now.month;
      case _DashboardPeriod.thisYear:
        return tripDate.year == now.year;
    }
  }

  Future<void> _loadTrips() async {
    final allTrips = await _tripService.loadTrips();
    final periodTrips = allTrips
        .where((trip) => _isInPeriod(trip.date))
        .toList();

    double total = 0;
    double business = 0;

    for (final trip in periodTrips) {
      total += trip.distance;
      if (trip.category == 'business') {
        business += trip.distance;
      }
    }

    final needsReview = allTrips
        .where((t) => t.reviewStatus == TripReviewStatus.needsReview)
        .length;

    if (!mounted) return;

    setState(() {
      _periodTrips = periodTrips;
      _totalDistance = total;
      _businessDistance = business;
      _taxPeriod = _taxService.calculateTaxFromKm(
        business,
        widget.preferences.country,
      );
      _needsReviewCount = needsReview;
    });
  }

  void _handleTripSaved() {
    _loadTrips();
    widget.onPreferencesRefresh();
  }

  String get _mileageLabel {
    final s = widget.strings;
    return switch (_period) {
      _DashboardPeriod.today => s.mileageToday,
      _DashboardPeriod.thisWeek => s.mileageThisWeek,
      _DashboardPeriod.thisMonth => s.mileageThisMonth,
      _DashboardPeriod.thisYear => s.mileageThisYear,
    };
  }

  String get _taxLabel {
    final s = widget.strings;
    return switch (_period) {
      _DashboardPeriod.today => s.taxSavingsToday,
      _DashboardPeriod.thisWeek => s.taxSavingsThisWeek,
      _DashboardPeriod.thisMonth => s.taxSavingsThisMonth,
      _DashboardPeriod.thisYear => s.taxSavingsThisYear,
    };
  }

  String _chipLabel(_DashboardPeriod p) {
    final s = widget.strings;
    return switch (p) {
      _DashboardPeriod.today => s.todayPeriod,
      _DashboardPeriod.thisWeek => s.thisWeek,
      _DashboardPeriod.thisMonth => s.thisMonth,
      _DashboardPeriod.thisYear => s.thisYear,
    };
  }

  @override
  Widget build(BuildContext context) {
    final businessCount = _periodTrips
        .where((t) => t.category == 'business')
        .length;
    final countryLabel = widget.preferences.country == Country.usa
        ? widget.strings.unitedStates
        : widget.strings.canada;

    return Scaffold(
      appBar: AppBar(title: Text(widget.strings.home)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < _DashboardPeriod.values.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  FilterChip(
                    label: Text(_chipLabel(_DashboardPeriod.values[i])),
                    selected: _period == _DashboardPeriod.values[i],
                    onSelected: (_) {
                      setState(() => _period = _DashboardPeriod.values[i]);
                      _loadTrips();
                    },
                  ),
                ],
              ],
            ),
          ),
          if (!_setupChecklistComplete) ...[
            const SizedBox(height: 12),
            _SetupChecklistCard(
              strings: widget.strings,
              countryDone: _countryChecklistDone,
              vehicleDone: _vehicleChecklistDone,
              autoDetectionDone: widget.preferences.autoTripDetectionEnabled,
              workShiftDone: _hasWorkShift,
              cloudBackupDone: _hasCloudBackup,
            ),
          ],
          if (_isWeeklyOdometerReminderDue) ...[
            const SizedBox(height: 12),
            _WeeklyOdometerReminderCard(
              strings: widget.strings,
              unit: widget.unit,
              controller: _odometerReminderController,
              onSave: _saveWeeklyOdometer,
            ),
          ],
          if (_needsReviewCount > 0) ...[
            const SizedBox(height: 12),
            _ReviewInboxCard(
              strings: widget.strings,
              count: _needsReviewCount,
              onReviewTrips: widget.onReviewTrips,
            ),
          ],
          const SizedBox(height: 12),
          SummaryCard(
            title: _mileageLabel,
            value: formatDistance(_totalDistance, widget.unit),
            subtitle: '${widget.strings.tripsRecorded}: ${_periodTrips.length}',
          ),
          const SizedBox(height: 12),
          SummaryCard(
            title: widget.strings.businessTrips,
            value: formatDistance(_businessDistance, widget.unit),
            subtitle: '$businessCount ${widget.strings.tripsLabel}',
          ),
          const SizedBox(height: 12),
          SummaryCard(
            title: _taxLabel,
            value: formatCurrency(_taxPeriod, widget.preferences.currencyCode),
            subtitle: countryLabel,
          ),
          const SizedBox(height: 12),
          OilChangeCard(
            strings: widget.strings,
            preferences: widget.preferences,
            unit: widget.unit,
          ),
          const SizedBox(height: 12),
          BrakePadCard(
            strings: widget.strings,
            preferences: widget.preferences,
            unit: widget.unit,
          ),
          const SizedBox(height: 12),
          QuickActionsCard(
            strings: widget.strings,
            onStartTrip: widget.onStartTrip,
            onAddManually: widget.onAddManually,
            onAddExpense: widget.onAddExpense,
          ),
          const SizedBox(height: 12),
          ForegroundTrackingCard(
            strings: widget.strings,
            preferences: widget.preferences,
            onTripSaved: _handleTripSaved,
          ),
          const SizedBox(height: 12),
          AutoDetectionCard(
            strings: widget.strings,
            preferences: widget.preferences,
            onTripSaved: _handleTripSaved,
          ),
          const SizedBox(height: 12),
          LiveTripMapCard(strings: widget.strings),
        ],
      ),
    );
  }
}
