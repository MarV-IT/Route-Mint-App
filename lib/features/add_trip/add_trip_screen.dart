import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import '../../core/preferences/user_preferences.dart';
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
  final UserPreferences preferences;

  const AddTripScreen({
    super.key,
    required this.strings,
    required this.unit,
    required this.preferences,
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
  final _parkingController = TextEditingController();
  final _tollsController = TextEditingController();
  final _purposeController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedCategory;

  WorkShift? _activeShift;

  @override
  void initState() {
    super.initState();
    _loadWorkSettings();
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _distanceController.dispose();
    _parkingController.dispose();
    _tollsController.dispose();
    _purposeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkSettings() async {
    final settings = await _workModeService.loadSettings();
    if (!mounted) return;
    setState(() => _activeShift = _matchingShift(settings));
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

      final isOvernight = endMinutes < startMinutes;
      final isMatch = isOvernight
          ? currentMinutes >= startMinutes || currentMinutes < endMinutes
          : currentMinutes >= startMinutes && currentMinutes < endMinutes;

      if (isMatch) return shift;
    }

    return null;
  }

  double _parseExpense(String text) {
    final value = double.tryParse(text.trim()) ?? 0;
    return value < 0 ? 0 : value;
  }

  String _purposeHint() {
    final platform = _activeShift?.platformName;
    if (platform != null) return '$platform business trip';
    if (_selectedCategory == 'business') return 'Business trip';
    return '';
  }

  Future<void> _handleSave() async {
    final from = _fromController.text.trim();
    final to = _toController.text.trim();
    final distance = double.tryParse(_distanceController.text.trim());
    final category = _selectedCategory;

    if (from.isEmpty || to.isEmpty || distance == null || category == null) {
      return;
    }

    // Reload work settings at save time for accuracy.
    final workSettings = await _workModeService.loadSettings();
    final matchedShift = _matchingShift(workSettings);

    final resolvedCategory = matchedShift != null ? 'business' : category;
    final resolvedPlatform = matchedShift?.platformName;

    final distanceKm = toKilometers(distance, widget.unit);
    final parking = _parseExpense(_parkingController.text);
    final tolls = _parseExpense(_tollsController.text);

    final purposeText = _purposeController.text.trim();
    String? resolvedPurpose;
    if (purposeText.isNotEmpty) {
      resolvedPurpose = purposeText;
    } else if (resolvedCategory == 'business') {
      resolvedPurpose = resolvedPlatform != null
          ? '$resolvedPlatform business trip'
          : 'Business trip';
    }

    final resolvedNotes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();

    final now = DateTime.now();
    final trip = Trip(
      id: now.millisecondsSinceEpoch.toString(),
      from: from,
      to: to,
      distance: distanceKm,
      category: resolvedCategory,
      date: now,
      platformName: resolvedPlatform,
      parkingExpense: parking,
      tollsExpense: tolls,
      businessPurpose: resolvedPurpose,
      notes: resolvedNotes,
    );

    await _tripService.addTrip(trip);

    _fromController.clear();
    _toController.clear();
    _distanceController.clear();
    _parkingController.clear();
    _tollsController.clear();
    _purposeController.clear();
    _notesController.clear();
    setState(() {
      _selectedCategory = null;
      _activeShift = matchedShift; // keep in sync
    });

    if (!mounted) return;

    final label = resolvedPlatform != null
        ? '${widget.strings.tripSaved} · $resolvedPlatform'
        : widget.strings.tripSaved;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(label)));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(widget.strings.addTrip)),
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
          if (_activeShift != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.work_outline, color: cs.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.strings.workModeActiveTripBusiness}'
                          ' · ${_activeShift!.platformName}',
                          style: TextStyle(
                            color: cs.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.strings.workModeOverridesCategory,
                          style: TextStyle(
                            color: cs.onPrimaryContainer.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
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

          // ── Optional trip expenses ─────────────────────────────────────
          Text(
            widget.strings.expensesOptional,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _parkingController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: widget.strings.parking,
                    border: const OutlineInputBorder(),
                    prefixText: '${widget.preferences.currencyCode} ',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _tollsController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: widget.strings.tolls,
                    border: const OutlineInputBorder(),
                    prefixText: '${widget.preferences.currencyCode} ',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _purposeController,
            decoration: InputDecoration(
              labelText: widget.strings.businessPurpose,
              hintText: _purposeHint(),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: widget.strings.notes,
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _handleSave,
              child: Text(widget.strings.saveTripButton),
            ),
          ),
        ],
      ),
    );
  }
}
