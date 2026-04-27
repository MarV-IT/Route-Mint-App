import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import '../../core/preferences/user_preferences.dart';
import '../../core/tax/tax_service.dart';
import '../../app/app.dart';
import '../work_mode/work_mode_screen.dart';

class ProfileScreen extends StatelessWidget {
  final AppStrings strings;
  final UserPreferences preferences;
  final AppUnit selectedUnit;
  final AppLanguage selectedLanguage;
  final ValueChanged<AppUnit?> onUnitChanged;
  final ValueChanged<AppLanguage?> onLanguageChanged;

  const ProfileScreen({
    super.key,
    required this.strings,
    required this.preferences,
    required this.selectedUnit,
    required this.selectedLanguage,
    required this.onUnitChanged,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final s = strings;

    return Scaffold(
      appBar: AppBar(title: Text(s.profile)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── User info ────────────────────────────────────────────────
          const ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text('March User'),
            subtitle: Text('march@example.com'),
          ),
          const Divider(),

          // ── Country & currency (read-only from preferences) ───────────
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: Text(s.countryLabel),
            subtitle: Text(
              preferences.country == Country.usa ? s.unitedStates : s.canada,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: Text(s.currencyLabel),
            subtitle: Text(preferences.currencyCode),
          ),
          const Divider(),

          // ── Vehicle ───────────────────────────────────────────────────
          ListTile(
            leading: const Icon(Icons.directions_car),
            title: Text(s.vehicle),
            subtitle: const Text('Toyota Prius'),
          ),
          const SizedBox(height: 12),

          // ── Distance unit ─────────────────────────────────────────────
          DropdownButtonFormField<AppUnit>(
            initialValue: selectedUnit,
            decoration: InputDecoration(
              labelText: s.units,
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(
                value: AppUnit.kilometers,
                child: Text(s.kilometers),
              ),
              DropdownMenuItem(value: AppUnit.miles, child: Text(s.miles)),
            ],
            onChanged: onUnitChanged,
          ),
          const SizedBox(height: 12),

          // ── Language ──────────────────────────────────────────────────
          DropdownButtonFormField<AppLanguage>(
            initialValue: selectedLanguage,
            decoration: InputDecoration(
              labelText: s.languageLabel,
              border: const OutlineInputBorder(),
            ),
            // Language names are in their own native script —
            // a user who picked the wrong language needs their own
            // language visible to switch back.
            items: const [
              DropdownMenuItem(
                value: AppLanguage.english,
                child: Text('English'),
              ),
              DropdownMenuItem(
                value: AppLanguage.spanish,
                child: Text('Español'),
              ),
              DropdownMenuItem(
                value: AppLanguage.french,
                child: Text('Français'),
              ),
              DropdownMenuItem(
                value: AppLanguage.russian,
                child: Text('Русский'),
              ),
              DropdownMenuItem(
                value: AppLanguage.ukrainian,
                child: Text('Українська'),
              ),
              DropdownMenuItem(value: AppLanguage.dari, child: Text('Dari')),
            ],
            onChanged: onLanguageChanged,
          ),
          const SizedBox(height: 12),

          const Divider(),

          // ── Work Mode ─────────────────────────────────────────────────
          ListTile(
            leading: const Icon(Icons.work_outline),
            title: Text(s.workMode),
            subtitle: Text(s.autoClassifyTrips),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WorkModeScreen(strings: strings),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
