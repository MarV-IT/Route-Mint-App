import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import '../../core/preferences/user_preferences.dart';
import '../../core/preferences/preferences_service.dart';
import '../../core/tax/tax_service.dart';
import '../../app/app.dart';
import '../work_mode/models/work_shift.dart';
import '../work_mode/models/work_mode_settings.dart';
import '../work_mode/services/work_mode_service.dart';

/// Three-step first-launch onboarding flow.
///
/// Step 1: Choose country (sets country + currency + unit defaults).
/// Step 2: Confirm / change distance unit.
/// Step 3: Add first work shift (skippable).
///
/// On completion, saves [UserPreferences] with onboardingCompleted = true
/// and calls [onComplete] so the root widget can rebuild into the main app.
class OnboardingScreen extends StatefulWidget {
  final AppStrings strings;
  final ValueChanged<UserPreferences> onComplete;

  const OnboardingScreen({
    super.key,
    required this.strings,
    required this.onComplete,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _prefsService = PreferencesService();
  final _workModeService = WorkModeService();
  final _pageController = PageController();

  // Draft preferences built up across steps
  Country _country = Country.usa;
  AppUnit _unit = AppUnit.miles;
  String _currencyCode = 'USD';

  int _currentPage = 0;
  static const int _totalPages = 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ─── Navigation ───────────────────────────────────────────────────────────

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _onCountrySelected(Country country) {
    final derived = UserPreferences.fromCountry(country);
    setState(() {
      _country = country;
      _unit = derived.unit;
      _currencyCode = derived.currencyCode;
    });
    _nextPage();
  }

  void _onUnitSelected(AppUnit unit) {
    setState(() => _unit = unit);
    _nextPage();
  }

  Future<void> _finish({WorkShift? shift}) async {
    if (shift != null) {
      final existing = await _workModeService.loadSettings();
      final updated = WorkModeSettings(
        isEnabled: true,
        shifts: [...existing.shifts, shift],
      );
      await _workModeService.saveSettings(updated);
    }

    final prefs = UserPreferences(
      country: _country,
      currencyCode: _currencyCode,
      unit: _unit,
      language: widget.strings.currentLanguage,
      onboardingCompleted: true,
    );

    await _prefsService.savePreferences(prefs);
    widget.onComplete(prefs);
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Progress dots
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: List.generate(_totalPages, (i) {
                  final active = i == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(right: 6),
                    height: 6,
                    width: active ? 24 : 8,
                    decoration: BoxDecoration(
                      color: active
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _CountryStep(strings: s, onSelected: _onCountrySelected),
                  _UnitStep(
                    strings: s,
                    selectedUnit: _unit,
                    onSelected: _onUnitSelected,
                  ),
                  _ShiftStep(strings: s, onFinish: _finish),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Step 1: Country ──────────────────────────────────────────────────────────

class _CountryStep extends StatelessWidget {
  final AppStrings strings;
  final ValueChanged<Country> onSelected;

  const _CountryStep({required this.strings, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final s = strings;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Icon(Icons.flag_outlined, size: 40, color: cs.primary),
          const SizedBox(height: 20),
          Text(
            s.welcomeToRouteMint,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            s.chooseYourCountry,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 40),
          _CountryTile(
            label: s.unitedStates,
            subtitle: s.usdCurrency,
            flag: '🇺🇸',
            onTap: () => onSelected(Country.usa),
          ),
          const SizedBox(height: 16),
          _CountryTile(
            label: s.canada,
            subtitle: s.cadCurrency,
            flag: '🇨🇦',
            onTap: () => onSelected(Country.canada),
          ),
        ],
      ),
    );
  }
}

class _CountryTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final String flag;
  final VoidCallback onTap;

  const _CountryTile({
    required this.label,
    required this.subtitle,
    required this.flag,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outline, width: 1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

// ─── Step 2: Distance unit ────────────────────────────────────────────────────

class _UnitStep extends StatelessWidget {
  final AppStrings strings;
  final AppUnit selectedUnit;
  final ValueChanged<AppUnit> onSelected;

  const _UnitStep({
    required this.strings,
    required this.selectedUnit,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final s = strings;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Icon(Icons.speed_outlined, size: 40, color: cs.primary),
          const SizedBox(height: 20),
          Text(
            s.chooseDistanceUnit,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            s.recommendedByCountry,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 40),
          _UnitTile(
            label: s.miles,
            icon: Icons.directions_car_outlined,
            selected: selectedUnit == AppUnit.miles,
            onTap: () => onSelected(AppUnit.miles),
          ),
          const SizedBox(height: 16),
          _UnitTile(
            label: s.kilometers,
            icon: Icons.directions_car_outlined,
            selected: selectedUnit == AppUnit.kilometers,
            onTap: () => onSelected(AppUnit.kilometers),
          ),
        ],
      ),
    );
  }
}

class _UnitTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _UnitTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: selected ? cs.primaryContainer : Colors.transparent,
          border: Border.all(
            color: selected ? cs.primary : cs.outline,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? cs.primary : cs.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: selected ? cs.primary : cs.onSurface,
                ),
              ),
            ),
            if (selected) Icon(Icons.check_circle, color: cs.primary, size: 22),
          ],
        ),
      ),
    );
  }
}

// ─── Step 3: First shift ──────────────────────────────────────────────────────

class _ShiftStep extends StatefulWidget {
  final AppStrings strings;
  final Future<void> Function({WorkShift? shift}) onFinish;

  const _ShiftStep({required this.strings, required this.onFinish});

  @override
  State<_ShiftStep> createState() => _ShiftStepState();
}

class _ShiftStepState extends State<_ShiftStep> {
  bool _isSaving = false;

  Future<void> _openShiftSheet() async {
    // Reuse the existing _AddShiftSheet from WorkModeScreen via
    // WorkModeScreen's public sheet. We trigger the bottom sheet
    // directly using the same pattern as WorkModeScreen.
    final shift = await showModalBottomSheet<WorkShift>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OnboardingShiftSheet(strings: widget.strings),
    );

    if (shift == null) return;
    setState(() => _isSaving = true);
    await widget.onFinish(shift: shift);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Icon(Icons.schedule_outlined, size: 40, color: cs.primary),
          const SizedBox(height: 20),
          Text(
            s.addYourFirstShift,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            s.addShiftDescription,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _openShiftSheet,
              icon: const Icon(Icons.add),
              label: Text(s.addShift),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: TextButton(
              onPressed: _isSaving ? null : () => widget.onFinish(shift: null),
              child: Text(s.skipForNow),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Onboarding shift sheet ───────────────────────────────────────────────────
// A minimal inline sheet that mirrors WorkModeScreen's _AddShiftSheet
// without importing the private class. This keeps onboarding self-contained.

class _OnboardingShiftSheet extends StatefulWidget {
  final AppStrings strings;
  const _OnboardingShiftSheet({required this.strings});

  @override
  State<_OnboardingShiftSheet> createState() => _OnboardingShiftSheetState();
}

class _OnboardingShiftSheetState extends State<_OnboardingShiftSheet> {
  final _platformController = TextEditingController();

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

  void _save() {
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final cs = Theme.of(context).colorScheme;
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
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.3),
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

            // Platform
            Text(
              s.platform,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
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
                style: TextStyle(color: cs.primary, fontSize: 13),
              ),
            ),
            const SizedBox(height: 20),

            // Hours
            Text(
              s.shiftHours,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _TimePickerButton(
                    label: s.start,
                    time: _fmt(_startHour, _startMinute),
                    onTap: () => _pickTime(isStart: true),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    Icons.arrow_forward,
                    color: cs.onSurfaceVariant,
                    size: 18,
                  ),
                ),
                Expanded(
                  child: _TimePickerButton(
                    label: s.end,
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
              child: FilledButton(onPressed: _save, child: Text(s.saveShift)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimePickerButton extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onTap;
  const _TimePickerButton({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
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
