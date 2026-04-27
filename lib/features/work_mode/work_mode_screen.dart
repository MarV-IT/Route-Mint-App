import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/localization/app_strings.dart';
import '../../shared/utils/currency_utils.dart';
import 'models/work_shift.dart';
import 'models/work_mode_settings.dart';
import 'services/work_mode_service.dart';

class WorkModeScreen extends StatefulWidget {
  final AppStrings strings;

  const WorkModeScreen({super.key, required this.strings});

  @override
  State<WorkModeScreen> createState() => _WorkModeScreenState();
}

class _WorkModeScreenState extends State<WorkModeScreen> {
  final _service = WorkModeService();

  WorkModeSettings _settings = WorkModeSettings.defaults();
  bool _isLoading = true;

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _service.loadSettings();
    setState(() {
      _settings = settings;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings(WorkModeSettings updated) async {
    setState(() => _settings = updated);
    await _service.saveSettings(updated);
  }

  // ─── Handlers ─────────────────────────────────────────────────────────────

  Future<void> _toggleEnabled(bool value) async {
    await _saveSettings(_settings.copyWith(isEnabled: value));
  }

  Future<void> _removeShift(int index) async {
    final updated = List<WorkShift>.from(_settings.shifts)..removeAt(index);
    await _saveSettings(_settings.copyWith(shifts: updated));
  }

  Future<void> _openAddShiftSheet() async {
    final newShift = await showModalBottomSheet<WorkShift>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddShiftSheet(strings: widget.strings),
    );
    if (newShift == null) return;
    final updated = List<WorkShift>.from(_settings.shifts)..add(newShift);
    await _saveSettings(_settings.copyWith(shifts: updated));
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _formatTime(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(s.workMode)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Enable toggle ──────────────────────────────────────────
                Card(
                  elevation: 0,
                  child: SwitchListTile(
                    secondary: Icon(
                      Icons.work_outline,
                      color: _settings.isEnabled
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                    title: Text(s.enableWorkMode),
                    subtitle: Text(
                      _settings.isEnabled
                          ? s.tripsDuringShiftsAutoClassified
                          : s.allTripsClassifiedManually,
                    ),
                    value: _settings.isEnabled,
                    onChanged: _toggleEnabled,
                  ),
                ),

                const SizedBox(height: 24),

                // ── Shifts header ──────────────────────────────────────────
                Row(
                  children: [
                    Text(
                      s.workShifts,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_settings.shifts.length} ${s.configured}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Empty state ────────────────────────────────────────────
                if (_settings.shifts.isEmpty)
                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 32,
                        horizontal: 16,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 40,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            s.noShiftsConfigured,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            s.addShiftToEnableAutoClassification,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                // ── Shift list ─────────────────────────────────────────────
                else
                  ...List.generate(_settings.shifts.length, (index) {
                    final shift = _settings.shifts[index];
                    final hasExpenses = shift.totalExpenses > 0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: colorScheme.primaryContainer,
                                child: Icon(
                                  shift.isCustomPlatform
                                      ? Icons.directions_car
                                      : Icons.work,
                                  color: colorScheme.onPrimaryContainer,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      shift.platformName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${_formatTime(shift.startHour, shift.startMinute)}'
                                      ' – '
                                      '${_formatTime(shift.endHour, shift.endMinute)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                    if (hasExpenses) ...[
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 6,
                                        children: [
                                          if (shift.fuelExpense > 0)
                                            _ExpenseChip(
                                              icon: Icons.local_gas_station,
                                              label:
                                                  '${s.fuel} ${formatCurrencyCompact(shift.fuelExpense)}',
                                            ),
                                          if (shift.parkingExpense > 0)
                                            _ExpenseChip(
                                              icon: Icons.local_parking,
                                              label:
                                                  '${s.parking} ${formatCurrencyCompact(shift.parkingExpense)}',
                                            ),
                                          if (shift.tollsExpense > 0)
                                            _ExpenseChip(
                                              icon: Icons.toll,
                                              label:
                                                  '${s.tolls} ${formatCurrencyCompact(shift.tollsExpense)}',
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${s.totalExpenses}: ${formatCurrencyCompact(shift.totalExpenses)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: colorScheme.error,
                                ),
                                tooltip: s.removeShift,
                                onPressed: () => _removeShift(index),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                const SizedBox(height: 16),

                // ── Add shift button ───────────────────────────────────────
                OutlinedButton.icon(
                  onPressed: _openAddShiftSheet,
                  icon: const Icon(Icons.add),
                  label: Text(s.addShift),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ],
            ),
    );
  }
}

// ─── Expense chip ─────────────────────────────────────────────────────────────

class _ExpenseChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ExpenseChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: cs.onSecondaryContainer),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: cs.onSecondaryContainer),
          ),
        ],
      ),
    );
  }
}

// ─── Add Shift Bottom Sheet ────────────────────────────────────────────────────

class _AddShiftSheet extends StatefulWidget {
  final AppStrings strings;
  const _AddShiftSheet({required this.strings});

  @override
  State<_AddShiftSheet> createState() => _AddShiftSheetState();
}

class _AddShiftSheetState extends State<_AddShiftSheet> {
  final _platformController = TextEditingController();
  final _fuelController = TextEditingController();
  final _parkingController = TextEditingController();
  final _tollsController = TextEditingController();

  static const _presets = ['Uber', 'Lyft', 'DoorDash', 'Instacart'];

  String _platformName = 'Uber';
  bool _isCustomPlatform = false;
  int _startHour = 9;
  int _startMinute = 0;
  int _endHour = 17;
  int _endMinute = 0;

  @override
  void dispose() {
    _platformController.dispose();
    _fuelController.dispose();
    _parkingController.dispose();
    _tollsController.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = TimeOfDay(
      hour: isStart ? _startHour : _endHour,
      minute: isStart ? _startMinute : _endMinute,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startHour = picked.hour;
        _startMinute = picked.minute;
      } else {
        _endHour = picked.hour;
        _endMinute = picked.minute;
      }
    });
  }

  String _fmt(int h, int m) =>
      '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

  double _parseExpense(String text) {
    final v = double.tryParse(text.trim()) ?? 0;
    return v < 0 ? 0 : v;
  }

  double get _totalPreview =>
      _parseExpense(_fuelController.text) +
      _parseExpense(_parkingController.text) +
      _parseExpense(_tollsController.text);

  void _handleSave() {
    final name = _isCustomPlatform
        ? _platformController.text.trim()
        : _platformName;
    if (name.isEmpty) return;

    Navigator.of(context).pop(
      WorkShift(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        platformName: name,
        isCustomPlatform: _isCustomPlatform,
        startHour: _startHour,
        startMinute: _startMinute,
        endHour: _endHour,
        endMinute: _endMinute,
        fuelExpense: _parseExpense(_fuelController.text),
        parkingExpense: _parseExpense(_parkingController.text),
        tollsExpense: _parseExpense(_tollsController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              s.addWorkShift,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),

            // ── Platform ──────────────────────────────────────────────────
            _sheetLabel(context, s.platform),
            const SizedBox(height: 8),
            if (!_isCustomPlatform)
              DropdownButtonFormField<String>(
                initialValue: _platformName,
                items: _presets
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) => setState(() => _platformName = v ?? 'Uber'),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
              )
            else
              TextField(
                controller: _platformController,
                // Hint kept in English — it's a placeholder example value,
                // not a UI label, so translation adds little value here.
                decoration: const InputDecoration(
                  hintText: 'e.g. My Company',
                  border: OutlineInputBorder(),
                ),
              ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() {
                _isCustomPlatform = !_isCustomPlatform;
                _platformController.clear();
              }),
              child: Text(
                _isCustomPlatform ? s.chooseFromPresets : s.customPlatform,
                style: TextStyle(color: colorScheme.primary, fontSize: 13),
              ),
            ),

            const SizedBox(height: 20),

            // ── Shift hours ───────────────────────────────────────────────
            _sheetLabel(context, s.shiftHours),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _TimeButton(
                    label: s.start,
                    time: _fmt(_startHour, _startMinute),
                    onTap: () => _pickTime(isStart: true),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    Icons.arrow_forward,
                    color: colorScheme.onSurfaceVariant,
                    size: 18,
                  ),
                ),
                Expanded(
                  child: _TimeButton(
                    label: s.end,
                    time: _fmt(_endHour, _endMinute),
                    onTap: () => _pickTime(isStart: false),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Expenses ──────────────────────────────────────────────────
            _sheetLabel(context, s.expensesOptional),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _ExpenseField(
                    controller: _fuelController,
                    label: s.fuel,
                    icon: Icons.local_gas_station,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ExpenseField(
                    controller: _parkingController,
                    label: s.parking,
                    icon: Icons.local_parking,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ExpenseField(
                    controller: _tollsController,
                    label: s.tolls,
                    icon: Icons.toll,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),

            // Total expenses live preview
            if (_totalPreview > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      s.totalExpenses,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      formatCurrencyCompact(_totalPreview),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 28),

            // ── Save ──────────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _handleSave,
                child: Text(s.saveShift),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetLabel(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

// ─── Expense field ────────────────────────────────────────────────────────────

class _ExpenseField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final ValueChanged<String> onChanged;

  const _ExpenseField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        prefixText: '\$',
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      ),
    );
  }
}

// ─── Time Button ──────────────────────────────────────────────────────────────

class _TimeButton extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onTap;

  const _TimeButton({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              time,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
