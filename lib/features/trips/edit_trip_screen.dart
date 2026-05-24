import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import '../../shared/utils/distance_utils.dart';
import '../../shared/widgets/address_autocomplete_field.dart';
import '../../shared/widgets/trip_map_preview.dart';
import '../../app/app.dart';
import '../trips/models/trip.dart';
import '../trips/services/trip_service.dart';
import '../work_mode/models/work_shift.dart';
import '../work_mode/models/work_mode_settings.dart';
import '../work_mode/services/work_mode_service.dart';
import 'trip_insights.dart';

const _kOtherPlatform = 'Other';
const List<String> _kDefaultPlatforms = [
  'Uber',
  'Lyft',
  'DoorDash',
  'Instacart',
  'Spark Driver',
  'Amazon Flex',
];
List<String> _purposeTemplates(AppStrings s) => [
  s.purposeDelivery,
  s.purposeClientVisit,
  s.purposeSupplies,
  s.purposeAirport,
  s.purposeMaintenance,
  s.purposeOther,
];

class EditTripScreen extends StatefulWidget {
  final Trip trip;
  final AppStrings strings;
  final AppUnit unit;
  final String currencyCode;
  final Future<void> Function() onPreferencesRefresh;

  const EditTripScreen({
    super.key,
    required this.trip,
    required this.strings,
    required this.unit,
    required this.currencyCode,
    required this.onPreferencesRefresh,
  });

  @override
  State<EditTripScreen> createState() => _EditTripScreenState();
}

class _EditTripScreenState extends State<EditTripScreen> {
  final _tripService = TripService();
  final _workModeService = WorkModeService();

  late final TextEditingController _fromController;
  late final TextEditingController _toController;
  late final TextEditingController _distanceController;
  late final TextEditingController _parkingController;
  late final TextEditingController _tollsController;
  late final TextEditingController _purposeController;
  late final TextEditingController _notesController;
  late final TextEditingController _customPlatformController;

  late String? _selectedCategory;
  String? _selectedPlatform;
  List<String> _platformOptions = _kDefaultPlatforms;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.trip;
    _fromController = TextEditingController(text: t.from);
    _toController = TextEditingController(text: t.to);
    final displayDist = fromKilometers(t.distance, widget.unit);
    _distanceController = TextEditingController(text: _fmtNum(displayDist));
    _parkingController = TextEditingController(
      text: t.parkingExpense > 0 ? _fmtNum(t.parkingExpense) : '',
    );
    _tollsController = TextEditingController(
      text: t.tollsExpense > 0 ? _fmtNum(t.tollsExpense) : '',
    );
    _purposeController = TextEditingController(text: t.businessPurpose ?? '');
    _notesController = TextEditingController(text: t.notes ?? '');
    _customPlatformController = TextEditingController();
    _selectedCategory = t.category;
    _loadPlatformOptions();
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
    _customPlatformController.dispose();
    super.dispose();
  }

  Future<void> _loadPlatformOptions() async {
    final settings = await _workModeService.loadSettings();
    if (!mounted) return;
    final merged = _buildPlatformOptions(settings);
    final matchedShift = _autoMatchedShift(settings);
    setState(() {
      _platformOptions = merged;
      if (matchedShift != null) {
        _selectedCategory = 'business';
        _selectedPlatform = matchedShift.platformName;
        _customPlatformController.clear();
      } else if (_selectedCategory != 'business' &&
          widget.trip.reviewStatus == TripReviewStatus.needsReview) {
        final suggestion = platformSuggestionFor(widget.trip);
        if (suggestion != null) {
          _selectedCategory = 'business';
          _selectedPlatform = suggestion;
          _customPlatformController.clear();
        }
      }
      _initPlatformSelection(merged);
    });
  }

  String _platformKey(String platform) => platform.trim().toLowerCase();

  WorkShift? _autoMatchedShift(WorkModeSettings settings) {
    if (widget.trip.reviewStatus != TripReviewStatus.needsReview) return null;
    if (widget.trip.detectionMode != TripDetectionMode.automatic) return null;

    final tripTime = widget.trip.startTime ?? widget.trip.date;
    return _workModeService.matchingShiftAt(settings, tripTime);
  }

  List<String> _buildPlatformOptions(WorkModeSettings settings) {
    final result = <String>[];
    for (final shift in settings.shifts) {
      if (!result.contains(shift.platformName)) {
        result.add(shift.platformName);
      }
    }
    for (final preset in _kDefaultPlatforms) {
      if (!result.contains(preset)) {
        result.add(preset);
      }
    }
    return result;
  }

  void _initPlatformSelection(List<String> options) {
    final existing = widget.trip.platformName;
    if (existing == null || existing.isEmpty) return;
    final existingOption = options.where(
      (option) => _platformKey(option) == _platformKey(existing),
    );
    if (existingOption.isNotEmpty) {
      _selectedPlatform = existingOption.first;
    } else {
      _selectedPlatform = _kOtherPlatform;
      _customPlatformController.text = existing;
    }
  }

  String _fmtNum(double value) =>
      value.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');

  double _parseExpense(String text) {
    final value = double.tryParse(text.trim()) ?? 0;
    return value < 0 ? 0 : value;
  }

  String _formatSeconds(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    }
    if (minutes > 0) {
      return '${minutes}m ${secs.toString().padLeft(2, '0')}s';
    }
    return '${secs}s';
  }

  String _trackingQualityLabel(TripTrackingDiagnostics diagnostics) {
    final s = widget.strings;
    if (diagnostics.maxGapSeconds > 90) {
      return s.trackingQualityGap;
    }
    if (diagnostics.averageAccuracyMeters <= 50 &&
        diagnostics.maxGapSeconds <= 30) {
      return s.trackingQualityGood;
    }
    if (diagnostics.averageAccuracyMeters <= 100) {
      return s.trackingQualityFair;
    }
    return s.trackingQualityPoor;
  }

  Widget _trackingQualityCard(TripTrackingDiagnostics diagnostics) {
    final s = widget.strings;
    final cs = Theme.of(context).colorScheme;
    final isPoor = diagnostics.averageAccuracyMeters > 100;
    final hasGpsGap = diagnostics.maxGapSeconds > 90;
    final needsAttention = isPoor || hasGpsGap;
    final color = needsAttention ? cs.error : cs.primary;

    Widget metric(String label, String value) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  needsAttention
                      ? Icons.warning_amber_outlined
                      : Icons.gps_fixed,
                  color: color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.trackingQuality,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _trackingQualityLabel(diagnostics),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: color),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                metric(s.rawGpsPoints, diagnostics.rawPointCount.toString()),
                metric(
                  s.acceptedGpsPoints,
                  diagnostics.validPointCount.toString(),
                ),
                metric(
                  s.droppedGpsPoints,
                  diagnostics.droppedPointCount.toString(),
                ),
                metric(
                  s.averageGpsAccuracy,
                  '${diagnostics.averageAccuracyMeters.toStringAsFixed(0)} m',
                ),
                metric(s.maxGpsGap, _formatSeconds(diagnostics.maxGapSeconds)),
                metric(
                  s.trackingDuration,
                  _formatSeconds(diagnostics.durationSeconds),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              s.distanceCalculationHint,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            if (hasGpsGap) ...[
              const SizedBox(height: 6),
              Text(
                s.routeMayBeShortHint,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: cs.error),
              ),
              const SizedBox(height: 6),
              Text(
                '${s.likelyCause}: ${s.likelyCauseGpsGap}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: cs.error),
              ),
            ] else if (isPoor) ...[
              const SizedBox(height: 6),
              Text(
                '${s.likelyCause}: ${s.likelyCausePoorAccuracy}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: cs.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? _resolvedPlatform() {
    if (_selectedCategory != 'business') return null;
    if (_selectedPlatform == null) return null;
    if (_selectedPlatform == _kOtherPlatform) {
      final custom = _customPlatformController.text.trim();
      return custom.isNotEmpty ? custom : null;
    }
    return _selectedPlatform;
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;

    final from = _fromController.text.trim();
    final to = _toController.text.trim();
    final category = _selectedCategory;

    if (from.isEmpty || to.isEmpty || category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.strings.fillRequiredFields)),
      );
      return;
    }

    final distance = double.tryParse(_distanceController.text.trim());
    if (distance == null || distance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.strings.distanceMustBePositive)),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final distanceKm = toKilometers(distance, widget.unit);
      final parking = _parseExpense(_parkingController.text);
      final tolls = _parseExpense(_tollsController.text);

      final purposeText = _purposeController.text.trim();
      final String? resolvedPurpose = purposeText.isNotEmpty
          ? purposeText
          : null;
      final resolvedNotes = _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim();

      final wasNeedsReview =
          widget.trip.reviewStatus == TripReviewStatus.needsReview;
      final updated = widget.trip.copyWith(
        from: from,
        to: to,
        distance: distanceKm,
        category: category,
        platformName: _resolvedPlatform(),
        parkingExpense: parking,
        tollsExpense: tolls,
        businessPurpose: resolvedPurpose,
        notes: resolvedNotes,
        reviewStatus: wasNeedsReview ? TripReviewStatus.reviewed : null,
      );

      await _tripService.updateTrip(updated);
      await widget.onPreferencesRefresh();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(widget.strings.tripUpdated)));
      Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleQuickReview({String? category}) async {
    if (_isSaving) return;
    if (category != null) {
      setState(() {
        _selectedCategory = category;
        if (category != 'business') {
          _selectedPlatform = null;
          _customPlatformController.clear();
        }
      });
    }
    await _handleSave();
  }

  Future<void> _handleDelete() async {
    final s = widget.strings;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.confirmDelete),
        content: Text(s.deleteConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.delete),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await _tripService.deleteTrip(widget.trip.id);
    await widget.onPreferencesRefresh();

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.editTrip),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline, color: cs.error),
            tooltip: s.deleteTrip,
            onPressed: _handleDelete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.trip.reviewStatus == TripReviewStatus.needsReview) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: cs.onSecondaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.detectedTripNeedsReview,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: cs.onSecondaryContainer,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.confirmDetailsAndMarkReviewed,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: cs.onSecondaryContainer),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${s.tripSavedAutomatically} ${s.stoppedAfterIdle}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: cs.onSecondaryContainer),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton.tonalIcon(
                              onPressed: _isSaving
                                  ? null
                                  : () => _handleQuickReview(
                                      category: 'business',
                                    ),
                              icon: const Icon(Icons.work_outline, size: 18),
                              label: Text(s.business),
                            ),
                            FilledButton.tonalIcon(
                              onPressed: _isSaving
                                  ? null
                                  : () => _handleQuickReview(
                                      category: 'personal',
                                    ),
                              icon: const Icon(Icons.person_outline, size: 18),
                              label: Text(s.personal),
                            ),
                            OutlinedButton.icon(
                              onPressed: _isSaving
                                  ? null
                                  : () => _handleQuickReview(),
                              icon: const Icon(Icons.check, size: 18),
                              label: Text(s.reviewed),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (widget.trip.startLatitude != null &&
              widget.trip.startLongitude != null &&
              widget.trip.endLatitude != null &&
              widget.trip.endLongitude != null) ...[
            Text(
              s.detectedRoute,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            TripMapPreview(
              startLatitude: widget.trip.startLatitude!,
              startLongitude: widget.trip.startLongitude!,
              endLatitude: widget.trip.endLatitude!,
              endLongitude: widget.trip.endLongitude!,
              routePoints: widget.trip.routePoints,
            ),
            const SizedBox(height: 16),
          ],
          if (widget.trip.trackingDiagnostics != null) ...[
            _trackingQualityCard(widget.trip.trackingDiagnostics!),
            const SizedBox(height: 16),
          ],
          AddressAutocompleteField(
            controller: _fromController,
            labelText: s.from,
            strings: s,
          ),
          const SizedBox(height: 12),
          AddressAutocompleteField(
            controller: _toController,
            labelText: s.to,
            strings: s,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _distanceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: s.distance,
              border: const OutlineInputBorder(),
              suffixText: unitLabel(widget.unit),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            items: [
              DropdownMenuItem(value: 'business', child: Text(s.business)),
              DropdownMenuItem(value: 'personal', child: Text(s.personal)),
            ],
            onChanged: (value) => setState(() {
              _selectedCategory = value;
              if (value != 'business') {
                _selectedPlatform = null;
                _customPlatformController.clear();
              }
            }),
            decoration: InputDecoration(
              labelText: s.category,
              border: const OutlineInputBorder(),
            ),
          ),
          if (_selectedCategory == 'business') ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedPlatform,
              hint: Text(s.selectPlatform),
              items: [
                ..._platformOptions.map(
                  (p) => DropdownMenuItem(value: p, child: Text(p)),
                ),
                DropdownMenuItem(
                  value: _kOtherPlatform,
                  child: Text(s.otherPlatform),
                ),
              ],
              onChanged: (value) => setState(() {
                _selectedPlatform = value;
                if (value != _kOtherPlatform) {
                  _customPlatformController.clear();
                }
              }),
              decoration: InputDecoration(
                labelText: s.platform,
                border: const OutlineInputBorder(),
              ),
            ),
            if (_selectedPlatform == _kOtherPlatform) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customPlatformController,
                decoration: InputDecoration(
                  labelText: s.customPlatformName,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ],
          const SizedBox(height: 20),
          Text(
            s.expensesOptional,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant),
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
                    labelText: s.parking,
                    border: const OutlineInputBorder(),
                    prefixText: '${widget.currencyCode} ',
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
                    labelText: s.tolls,
                    border: const OutlineInputBorder(),
                    prefixText: '${widget.currencyCode} ',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _purposeController,
            decoration: InputDecoration(
              labelText: s.businessPurpose,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _purposeTemplates(s)
                .map(
                  (purpose) => ActionChip(
                    label: Text(purpose),
                    onPressed: () => _purposeController.text = purpose,
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: s.notes,
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _handleSave,
              child: Text(
                widget.trip.reviewStatus == TripReviewStatus.needsReview
                    ? s.saveAndMarkReviewed
                    : s.updateTrip,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
