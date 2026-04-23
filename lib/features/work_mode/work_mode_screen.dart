import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import 'models/work_shift.dart';
import 'models/work_mode_settings.dart';
import 'services/work_mode_service.dart';

class WorkModeScreen extends StatefulWidget {
  final AppStrings strings;

  const WorkModeScreen({
    super.key,
    required this.strings,
  });

  @override
  State<WorkModeScreen> createState() => _WorkModeScreenState();
}

class _WorkModeScreenState extends State<WorkModeScreen> {
  final _service = WorkModeService();

  WorkModeSettings _settings = WorkModeSettings.defaults();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _service.loadSettings();
    if (!mounted) return;

    setState(() {
      _settings = settings;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings(WorkModeSettings updated) async {
    setState(() {
      _settings = updated;
    });

    await _service.saveSettings(updated);
  }

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

  String _formatTime(int hour, int minute) {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.strings.workMode),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  elevation: 0,
                  child: SwitchListTile(
                    secondary: Icon(
                      Icons.work_outline,
                      color: _settings.isEnabled
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                    title: Text(widget.strings.enableWorkMode),
                    subtitle: Text(
                      _settings.isEnabled
                          ? widget.strings.workModeEnabledDescription
                          : widget.strings.workModeDisabledDescription,
                    ),
                    value: _settings.isEnabled,
                    onChanged: _toggleEnabled,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text(
                      widget.strings.workShifts,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      '${_settings.shifts.length} configured',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
                            widget.strings.noShiftsConfigured,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.strings.addShiftToEnableAutoClassification,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...List.generate(_settings.shifts.length, (index) {
                    final shift = _settings.shifts[index];
                    final start =
                        _formatTime(shift.startHour, shift.startMinute);
                    final end = _formatTime(shift.endHour, shift.endMinute);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        elevation: 0,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: colorScheme.primaryContainer,
                            child: Icon(
                              shift.isCustomPlatform
                                  ? Icons.directions_car
                                  : Icons.work,
                              color: colorScheme.onPrimaryContainer,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            shift.platformName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text('$start – $end'),
                          trailing: IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: colorScheme.error,
                            ),
                            tooltip: 'Remove shift',
                            onPressed: () => _removeShift(index),
                          ),
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _openAddShiftSheet,
                  icon: const Icon(Icons.add),
                  label: Text(widget.strings.addShift),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ],
            ),
    );
  }
}

class _AddShiftSheet extends StatefulWidget {
  final AppStrings strings;

  const _AddShiftSheet({
    required this.strings,
  });

  @override
  State<_AddShiftSheet> createState() => _AddShiftSheetState();
}

class _AddShiftSheetState extends State<_AddShiftSheet> {
  final _platformController = TextEditingController();

  static const _presets = [
    'Uber',
    'Amazon Flex',
    'Spark Driver',
    'DoorDash',
  ];

  String _platformName = 'Uber';
  bool _isCustomPlatform = false;
  int _startHour = 9;
  int _startMinute = 0;
  int _endHour = 17;
  int _endMinute = 0;

  @override
  void dispose() {
    _platformController.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = TimeOfDay(
      hour: isStart ? _startHour : _endHour,
      minute: isStart ? _startMinute : _endMinute,
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );

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

  void _handleSave() {
    final name =
        _isCustomPlatform ? _platformController.text.trim() : _platformName;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.strings.enterPlatformName)),
      );
      return;
    }

    if (_startHour == _endHour && _startMinute == _endMinute) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.strings.sameStartEndTimeError)),
      );
      return;
    }

    final shift = WorkShift(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      platformName: name,
      isCustomPlatform: _isCustomPlatform,
      startHour: _startHour,
      startMinute: _startMinute,
      endHour: _endHour,
      endMinute: _endMinute,
    );

    Navigator.of(context).pop(shift);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.strings.addShift,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.strings.platform,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          if (!_isCustomPlatform)
            DropdownButtonFormField<String>(
              value: _platformName,
              items: _presets
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text(p),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                setState(() {
                  _platformName = v ?? 'Uber';
                });
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
            )
          else
            TextField(
              controller: _platformController,
              decoration: InputDecoration(
                hintText: widget.strings.customPlatform,
                border: const OutlineInputBorder(),
              ),
            ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              setState(() {
                _isCustomPlatform = !_isCustomPlatform;
                _platformController.clear();
              });
            },
            child: Text(
              _isCustomPlatform
                  ? widget.strings.chooseFromPresets
                  : '+ ${widget.strings.customPlatform}',
              style: TextStyle(
                color: colorScheme.primary,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.strings.shiftHours,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _TimeButton(
                  label: widget.strings.start,
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
                  label: widget.strings.end,
                  time: _fmt(_endHour, _endMinute),
                  onTap: () => _pickTime(isStart: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _handleSave,
              child: Text(widget.strings.saveShift),
            ),
          ),
        ],
      ),
    );
  }
}

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
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}