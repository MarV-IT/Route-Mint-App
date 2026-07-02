import 'package:flutter/material.dart';

import '../../app/app.dart';
import '../../core/localization/app_strings.dart';
import '../../core/preferences/user_preferences.dart';
import '../../shared/utils/distance_utils.dart';
import 'models/fuel_entry.dart';
import 'services/fuel_service.dart';

const double _litersPerGallon = 3.785411784;

class AddFuelEntryScreen extends StatefulWidget {
  const AddFuelEntryScreen({
    super.key,
    required this.strings,
    required this.unit,
    required this.preferences,
    this.entry,
  });

  final AppStrings strings;
  final AppUnit unit;
  final UserPreferences preferences;
  final FuelEntry? entry;

  @override
  State<AddFuelEntryScreen> createState() => _AddFuelEntryScreenState();
}

class _AddFuelEntryScreenState extends State<AddFuelEntryScreen> {
  final _fuelService = FuelService();
  final _odometerController = TextEditingController();
  final _volumeController = TextEditingController();
  final _costController = TextEditingController();
  final _stationController = TextEditingController();
  final _notesController = TextEditingController();

  late DateTime _date;
  bool _isSaving = false;

  bool get _isEditing => widget.entry != null;
  bool get _usesMiles => widget.unit == AppUnit.miles;
  String get _volumeUnitLabel =>
      _usesMiles ? widget.strings.gallons : widget.strings.liters;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _date = entry?.date ?? DateTime.now();
    if (entry != null) {
      if (entry.odometerKm != null) {
        _odometerController.text = _fmt(
          fromKilometers(entry.odometerKm!, widget.unit),
        );
      }
      if (entry.volumeLiters > 0) {
        _volumeController.text = _fmt(_fromLiters(entry.volumeLiters));
      }
      _costController.text = _fmt(entry.totalCost);
      _stationController.text = entry.stationName ?? '';
      _notesController.text = entry.notes ?? '';
    }
  }

  @override
  void dispose() {
    _odometerController.dispose();
    _volumeController.dispose();
    _costController.dispose();
    _stationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _fmt(double value) =>
      value.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');

  double _toLiters(double value) =>
      _usesMiles ? value * _litersPerGallon : value;

  double _fromLiters(double liters) =>
      _usesMiles ? liters / _litersPerGallon : liters;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDate: _date,
    );
    if (picked == null) return;
    setState(() {
      _date = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _date.hour,
        _date.minute,
      );
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        showCloseIcon: true,
      ),
    );
  }

  Future<void> _save() async {
    if (_isSaving) return;

    final volumeText = _volumeController.text.trim();
    final volume = volumeText.isEmpty ? null : double.tryParse(volumeText);
    final totalCost = double.tryParse(_costController.text.trim()) ?? 0;
    final odometer = _odometerController.text.trim().isEmpty
        ? null
        : double.tryParse(_odometerController.text.trim());

    if (volumeText.isNotEmpty && (volume == null || volume <= 0)) {
      _showError(widget.strings.fuelAmountMustBePositive);
      return;
    }
    if (totalCost < 0) {
      _showError(widget.strings.totalCostCannotBeNegative);
      return;
    }
    if (odometer != null && odometer < 0) {
      _showError(widget.strings.odometerCannotBeNegative);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final entry = FuelEntry(
        id:
            widget.entry?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        date: _date,
        odometerKm: odometer == null
            ? null
            : toKilometers(odometer, widget.unit),
        volumeLiters: volume == null ? 0 : _toLiters(volume),
        totalCost: totalCost,
        stationName: _stationController.text.trim().isEmpty
            ? null
            : _stationController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (_isEditing) {
        await _fuelService.updateFuelEntry(entry);
      } else {
        await _fuelService.addFuelEntry(entry);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(widget.strings.fuelEntrySaved)));
      Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final dateText =
        '${_date.month.toString().padLeft(2, '0')}/${_date.day.toString().padLeft(2, '0')}/${_date.year}';

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? s.editFuel : s.addFuel)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text('${s.date}: $dateText'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _odometerController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: s.odometer,
              suffixText: unitLabel(widget.unit),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _volumeController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: '${s.fuelAmount} (${s.optional})',
              suffixText: _volumeUnitLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _costController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: s.totalCost,
              prefixText: '${widget.preferences.currencyCode} ',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _stationController,
            decoration: InputDecoration(
              labelText: s.stationName,
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
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.local_gas_station_outlined),
              label: Text(_isSaving ? s.saving : s.save),
            ),
          ),
        ],
      ),
    );
  }
}
