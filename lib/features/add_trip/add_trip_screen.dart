import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import '../../shared/utils/distance_utils.dart';
import '../../app/app.dart';
import '../trips/models/trip.dart';
import '../trips/services/trip_service.dart';
import '../work_mode/models/work_shift.dart';
import '../work_mode/models/work_mode_settings.dart';
import '../work_mode/services/work_mode_service.dart';

class AddTripScreen extends StatefulWidget {
  final AppStrings strings;
  final AppUnit unit;

  const AddTripScreen({
    super.key,
    required this.strings,
    required this.unit,
  });

  @override
  State<AddTripScreen> createState() => _AddTripScreenState();
}

class _AddTripScreenState extends State<AddTripScreen> {
  final _tripService = TripService();
  final _workModeService = WorkModeService();

  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _distanceController = TextEditingController();
  String? _selectedCategory;

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  /// Returns the matching WorkShift if Work Mode is enabled and the
  /// current time falls within any configured shift; otherwise null.
  WorkShift? _matchingShift(WorkModeSettings settings) {
    if (!settings.isEnabled) return null;

    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    for (final shift in settings.shifts) {
      final startMinutes = shift.startHour * 60 + shift.startMinute;
      final endMinutes = shift.endHour * 60 + shift.endMinute;

      // Support overnight shifts (e.g. 22:00 – 06:00)
      final isOvernight = endMinutes < startMinutes;
      final isMatch = isOvernight
          ? currentMinutes >= startMinutes || currentMinutes < endMinutes
          : currentMinutes >= startMinutes && currentMinutes < endMinutes;

      if (isMatch) return shift;
    }

    return null;
  }

  Future<void> _handleSave() async {
    final from = _fromController.text.trim();
    final to = _toController.text.trim();
    final distanceText = _distanceController.text.trim().replaceAll(',', '.');
    final enteredDistance = double.tryParse(distanceText);

    if (from.isEmpty || to.isEmpty || enteredDistance == null) {
      return;
    }

  // Always store distance internally in kilometers.
    final distanceInKm = widget.unit == AppUnit.miles
        ? enteredDistance / 0.621371
        : enteredDistance;

    final workSettings = await _workModeService.loadSettings();
    final matchedShift = _matchingShift(workSettings);

    final isManualCategory = _selectedCategory != null;

    final resolvedCategory =
        _selectedCategory ?? (matchedShift != null ? 'business' : 'personal');

    final resolvedPlatform = isManualCategory ? null : matchedShift?.platformName;

    final now = DateTime.now();

    final trip = Trip(
      id: now.millisecondsSinceEpoch.toString(),
      from: from,
      to: to,
      distance: distanceInKm,
      category: resolvedCategory,
      date: now,
      platformName: resolvedPlatform,
    );

    await _tripService.addTrip(trip);

    _fromController.clear();
    _toController.clear();
    _distanceController.clear();

    setState(() {
      _selectedCategory = null;
    });

    if (!mounted) return;

    final label = resolvedPlatform != null
        ? 'Trip saved · $resolvedPlatform'
        : 'Trip saved';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(label)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.strings.addTrip),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _fromController,
            decoration: InputDecoration(
              labelText: widget.strings.from,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _toController,
            decoration: InputDecoration(
              labelText: widget.strings.to,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _distanceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: widget.strings.distance,
              border: const OutlineInputBorder(),
              suffixText: unitLabel(widget.unit),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            items: [
              DropdownMenuItem(
                value: 'business',
                child: Text(widget.strings.business),
              ),
              DropdownMenuItem(
                value: 'personal',
                child: Text(widget.strings.personal),
              ),
            ],
            onChanged: (value) => setState(() => _selectedCategory = value),
            decoration: InputDecoration(
              labelText: widget.strings.category,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _handleSave,
              child: Text(widget.strings.saveTrip),
            ),
          ),
        ],
      ),
    );
  }
}
