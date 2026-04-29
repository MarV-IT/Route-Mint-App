import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import '../../shared/utils/distance_utils.dart';
import '../../shared/widgets/address_autocomplete_field.dart';
import '../../shared/widgets/trip_map_preview.dart';
import '../../app/app.dart';
import '../trips/models/trip.dart';
import '../trips/services/trip_service.dart';
import '../work_mode/models/work_mode_settings.dart';
import '../work_mode/services/work_mode_service.dart';

const _kOtherPlatform = 'Other';
const List<String> _kDefaultPlatforms = [
  'Uber', 'Lyft', 'DoorDash', 'Instacart', 'Spark Driver', 'Amazon Flex',
];

class EditTripScreen extends StatefulWidget {
  final Trip trip;
  final AppStrings strings;
  final AppUnit unit;
  final String currencyCode;

  const EditTripScreen({
    super.key,
    required this.trip,
    required this.strings,
    required this.unit,
    required this.currencyCode,
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
        text: t.parkingExpense > 0 ? _fmtNum(t.parkingExpense) : '');
    _tollsController = TextEditingController(
        text: t.tollsExpense > 0 ? _fmtNum(t.tollsExpense) : '');
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
    setState(() {
      _platformOptions = merged;
      _initPlatformSelection(merged);
    });
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
    if (options.contains(existing)) {
      _selectedPlatform = existing;
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
      final String? resolvedPurpose =
          purposeText.isNotEmpty ? purposeText : null;
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
        reviewStatus:
            wasNeedsReview ? TripReviewStatus.reviewed : null,
      );

      await _tripService.updateTrip(updated);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.strings.tripUpdated)),
      );
      Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
                  Icon(Icons.info_outline,
                      size: 20, color: cs.onSecondaryContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.detectedTripNeedsReview,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSecondaryContainer,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.confirmDetailsAndMarkReviewed,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: cs.onSecondaryContainer,
                                  ),
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
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
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
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _parkingController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
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
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
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
