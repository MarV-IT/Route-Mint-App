import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import '../../shared/utils/distance_utils.dart';
import '../../app/app.dart';
import '../../core/tax/tax_service.dart';
import '../work_mode/work_mode_screen.dart';

class ProfileScreen extends StatelessWidget {
  final AppStrings strings;
  final AppUnit selectedUnit;
  final AppLanguage selectedLanguage;
  final Country selectedCountry;

  final ValueChanged<AppUnit?> onUnitChanged;
  final ValueChanged<AppLanguage?> onLanguageChanged;
  final ValueChanged<Country?> onCountryChanged;

  const ProfileScreen({
    super.key,
    required this.strings,
    required this.selectedUnit,
    required this.selectedLanguage,
    required this.selectedCountry,
    required this.onUnitChanged,
    required this.onLanguageChanged,
    required this.onCountryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.profile),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text('March User'),
            subtitle: Text('march@example.com'),
          ),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.directions_car),
            title: Text(strings.vehicle),
            subtitle: const Text('Toyota Prius'),
          ),

          const SizedBox(height: 12),

          // ─── Units ─────────────────────────────
          DropdownButtonFormField<AppUnit>(
            value: selectedUnit,
            decoration: InputDecoration(
              labelText: strings.units,
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(
                value: AppUnit.kilometers,
                child: Text(strings.kilometers),
              ),
              DropdownMenuItem(
                value: AppUnit.miles,
                child: Text(strings.miles),
              ),
            ],
            onChanged: onUnitChanged,
          ),

          const SizedBox(height: 12),

          // ─── Language ─────────────────────────────
          DropdownButtonFormField<AppLanguage>(
            value: selectedLanguage,
            decoration: InputDecoration(
              labelText: strings.languageLabel,
              border: const OutlineInputBorder(),
            ),
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
              DropdownMenuItem(
                value: AppLanguage.dari,
                child: Text('Dari'),
              ),
            ],
            onChanged: onLanguageChanged,
          ),

          const SizedBox(height: 12),

          // ─── Country (🔥 нове) ─────────────────────────────
          DropdownButtonFormField<Country>(
            value: selectedCountry,
            decoration: const InputDecoration(
              labelText: 'Country',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: Country.usa,
                child: Text('USA'),
              ),
              DropdownMenuItem(
                value: Country.canada,
                child: Text('Canada'),
              ),
            ],
            onChanged: onCountryChanged,
          ),

          const SizedBox(height: 12),

          // ─── Rate preview ─────────────────────────────
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: Text(strings.reimbursementRate),
            subtitle: Text(
              selectedCountry == Country.usa
                  ? '\$0.725 / ${unitLabel(selectedUnit)}'
                  : '0.73 / km (first 5000) · 0.67 / km',
            ),
          ),

          const Divider(),

          // ─── Work mode ─────────────────────────────
          ListTile(
            leading: const Icon(Icons.work_outline),
            title: Text(strings.workMode),
            subtitle: Text(strings.workModeDescription),
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