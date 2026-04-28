import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import '../../shared/utils/distance_utils.dart';
import '../../app/app.dart';
import 'models/trip.dart';
import 'services/trip_service.dart';

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

  late final TextEditingController _fromController;
  late final TextEditingController _toController;
  late final TextEditingController _distanceController;
  late final TextEditingController _parkingController;
  late final TextEditingController _tollsController;
  late final TextEditingController _purposeController;
  late final TextEditingController _notesController;
  late String? _selectedCategory;
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
    _selectedCategory = t.category;
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

  String _fmtNum(double value) =>
      value.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');

  double _parseExpense(String text) {
    final value = double.tryParse(text.trim()) ?? 0;
    return value < 0 ? 0 : value;
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

      final updated = widget.trip.copyWith(
        from: from,
        to: to,
        distance: distanceKm,
        category: category,
        parkingExpense: parking,
        tollsExpense: tolls,
        businessPurpose: resolvedPurpose,
        notes: resolvedNotes,
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
          TextField(
            controller: _fromController,
            decoration: InputDecoration(
              labelText: s.from,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _toController,
            decoration: InputDecoration(
              labelText: s.to,
              border: const OutlineInputBorder(),
            ),
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
            value: _selectedCategory,
            items: [
              DropdownMenuItem(value: 'business', child: Text(s.business)),
              DropdownMenuItem(value: 'personal', child: Text(s.personal)),
            ],
            onChanged: (value) => setState(() => _selectedCategory = value),
            decoration: InputDecoration(
              labelText: s.category,
              border: const OutlineInputBorder(),
            ),
          ),
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
              child: Text(s.updateTrip),
            ),
          ),
        ],
      ),
    );
  }
}
