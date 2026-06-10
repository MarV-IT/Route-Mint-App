import 'package:flutter/material.dart';

import '../../app/app.dart';
import '../../core/localization/app_strings.dart';
import '../../core/preferences/user_preferences.dart';
import '../../shared/utils/currency_utils.dart';
import '../../shared/utils/distance_utils.dart';
import 'add_fuel_entry_screen.dart';
import 'models/fuel_entry.dart';
import 'services/fuel_service.dart';

const double _litersPerGallon = 3.785411784;

class FuelLogScreen extends StatefulWidget {
  const FuelLogScreen({
    super.key,
    required this.strings,
    required this.unit,
    required this.preferences,
  });

  final AppStrings strings;
  final AppUnit unit;
  final UserPreferences preferences;

  @override
  State<FuelLogScreen> createState() => _FuelLogScreenState();
}

class _FuelLogScreenState extends State<FuelLogScreen> {
  final _fuelService = FuelService();
  List<FuelEntry> _entries = [];
  bool _isLoading = true;

  bool get _usesMiles => widget.unit == AppUnit.miles;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final entries = await _fuelService.loadFuelEntries();
    entries.sort((a, b) => b.date.compareTo(a.date));
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _isLoading = false;
    });
  }

  Future<void> _openEntry({FuelEntry? entry}) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddFuelEntryScreen(
          strings: widget.strings,
          unit: widget.unit,
          preferences: widget.preferences,
          entry: entry,
        ),
      ),
    );
    if (changed == true) _loadEntries();
  }

  Future<void> _deleteEntry(FuelEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widget.strings.deleteFuelEntry),
        content: Text(widget.strings.deleteFuelEntryConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(widget.strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(widget.strings.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _fuelService.deleteFuelEntry(entry.id);
    await _loadEntries();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(widget.strings.fuelEntryDeleted)));
  }

  String _formatDate(DateTime date) {
    final d = date.toLocal();
    return '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';
  }

  String _formatVolume(FuelEntry entry) {
    if (_usesMiles) {
      final gallons = entry.volumeLiters / _litersPerGallon;
      return '${gallons.toStringAsFixed(2)} ${widget.strings.gallons}';
    }
    return '${entry.volumeLiters.toStringAsFixed(2)} ${widget.strings.liters}';
  }

  String? _formatOdometer(FuelEntry entry) {
    final odometer = entry.odometerKm;
    if (odometer == null) return null;
    return '${fromKilometers(odometer, widget.unit).toStringAsFixed(0)} ${unitLabel(widget.unit)}';
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    return Scaffold(
      appBar: AppBar(title: Text(s.fuelLog)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEntry(),
        icon: const Icon(Icons.add),
        label: Text(s.addFuel),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadEntries,
              child: _entries.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.sizeOf(context).height * 0.25,
                        ),
                        Center(child: Text(s.noFuelEntries)),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _entries.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final entry = _entries[index];
                        final odometer = _formatOdometer(entry);
                        return Card(
                          elevation: 0,
                          child: ListTile(
                            leading: const Icon(
                              Icons.local_gas_station_outlined,
                            ),
                            title: Text(entry.stationName ?? s.fuel),
                            subtitle: Text(
                              [
                                _formatDate(entry.date),
                                _formatVolume(entry),
                                ?odometer,
                              ].join(' · '),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  formatCurrency(
                                    entry.totalCost,
                                    widget.preferences.currencyCode,
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _openEntry(entry: entry);
                                    } else if (value == 'delete') {
                                      _deleteEntry(entry);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text(s.edit),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text(s.delete),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            onTap: () => _openEntry(entry: entry),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
