import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/localization/app_strings.dart';
import '../../core/preferences/preferences_service.dart';
import '../../core/preferences/user_preferences.dart';
import '../../core/tax/tax_service.dart';
import '../../core/backup/backup_service.dart';
import '../../app/app.dart';
import '../work_mode/work_mode_screen.dart';

class ProfileScreen extends StatefulWidget {
  final AppStrings strings;
  final UserPreferences preferences;
  final AppUnit selectedUnit;
  final AppLanguage selectedLanguage;
  final ValueChanged<AppUnit?> onUnitChanged;
  final ValueChanged<AppLanguage?> onLanguageChanged;
  final ValueChanged<UserPreferences> onPreferencesChanged;

  const ProfileScreen({
    super.key,
    required this.strings,
    required this.preferences,
    required this.selectedUnit,
    required this.selectedLanguage,
    required this.onUnitChanged,
    required this.onLanguageChanged,
    required this.onPreferencesChanged,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _driverController;
  late final TextEditingController _businessController;
  late final TextEditingController _vehicleController;

  final _backupService = BackupService();
  final _prefsService = PreferencesService();
  bool _isExportingBackup = false;
  bool _isImportingBackup = false;

  @override
  void initState() {
    super.initState();
    final p = widget.preferences;
    _driverController = TextEditingController(text: p.driverName ?? '');
    _businessController = TextEditingController(text: p.businessName ?? '');
    _vehicleController = TextEditingController(text: p.vehicleName ?? '');
  }

  @override
  void dispose() {
    _driverController.dispose();
    _businessController.dispose();
    _vehicleController.dispose();
    super.dispose();
  }

  void _saveIdentity() {
    final updated = widget.preferences.copyWith(
      driverName: _driverController.text.trim().isEmpty
          ? null
          : _driverController.text.trim(),
      businessName: _businessController.text.trim().isEmpty
          ? null
          : _businessController.text.trim(),
      vehicleName: _vehicleController.text.trim().isEmpty
          ? null
          : _vehicleController.text.trim(),
    );
    widget.onPreferencesChanged(updated);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.strings.profileSaved)),
    );
  }

  Future<void> _handleExportBackup() async {
    setState(() => _isExportingBackup = true);
    try {
      await _backupService.exportBackup();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.strings.backupExported)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.strings.backupExportFailed}: $e')),
      );
    } finally {
      if (mounted) setState(() => _isExportingBackup = false);
    }
  }

  Future<void> _handleImportBackup() async {
    // Pick the file first — before showing any dialog.
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final fileBytes = result.files.first.bytes;
    if (fileBytes == null) return;
    final jsonString = utf8.decode(fileBytes);

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widget.strings.backupImportConfirmTitle),
        content: Text(widget.strings.backupImportConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(widget.strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(widget.strings.importBackup),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isImportingBackup = true);
    try {
      await _backupService.importBackup(jsonString);
      final restoredPrefs = await _prefsService.loadPreferences();
      if (!mounted) return;
      widget.onPreferencesChanged(restoredPrefs);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.strings.backupImported)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.strings.backupImportFailed}: $e')),
      );
    } finally {
      if (mounted) setState(() => _isImportingBackup = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;

    return Scaffold(
      appBar: AppBar(title: Text(s.profile)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Report identity (editable) ─────────────────────────────────
          Text(
            s.editProfileInfo,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _driverController,
            decoration: InputDecoration(
              labelText: s.driverName,
              hintText: s.optional,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _businessController,
            decoration: InputDecoration(
              labelText: s.businessName,
              hintText: s.optional,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _vehicleController,
            decoration: InputDecoration(
              labelText: s.vehicle,
              hintText: s.optional,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: FilledButton(
              onPressed: _saveIdentity,
              child: Text(s.save),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(),

          // ── Country & currency (read-only from preferences) ────────────
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: Text(s.countryLabel),
            subtitle: Text(
              widget.preferences.country == Country.usa
                  ? s.unitedStates
                  : s.canada,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: Text(s.currencyLabel),
            subtitle: Text(widget.preferences.currencyCode),
          ),
          const Divider(),

          // ── Distance unit ──────────────────────────────────────────────
          DropdownButtonFormField<AppUnit>(
            initialValue: widget.selectedUnit,
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
            onChanged: widget.onUnitChanged,
          ),
          const SizedBox(height: 12),

          // ── Language ───────────────────────────────────────────────────
          DropdownButtonFormField<AppLanguage>(
            initialValue: widget.selectedLanguage,
            decoration: InputDecoration(
              labelText: s.languageLabel,
              border: const OutlineInputBorder(),
            ),
            // Language names are in their own native script —
            // a user who picked the wrong language needs their own
            // language visible to switch back.
            items: const [
              DropdownMenuItem(value: AppLanguage.english, child: Text('English')),
              DropdownMenuItem(value: AppLanguage.spanish, child: Text('Español')),
              DropdownMenuItem(value: AppLanguage.french, child: Text('Français')),
              DropdownMenuItem(value: AppLanguage.russian, child: Text('Русский')),
              DropdownMenuItem(value: AppLanguage.ukrainian, child: Text('Українська')),
              DropdownMenuItem(value: AppLanguage.dari, child: Text('Dari')),
            ],
            onChanged: widget.onLanguageChanged,
          ),
          const SizedBox(height: 12),

          const Divider(),

          // ── Work Mode ──────────────────────────────────────────────────
          ListTile(
            leading: const Icon(Icons.work_outline),
            title: Text(s.workMode),
            subtitle: Text(s.autoClassifyTrips),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WorkModeScreen(strings: s),
              ),
            ),
          ),
          const Divider(),

          // ── Automation ────────────────────────────────────────────────
          Text(
            s.automation,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          SwitchListTile(
            secondary: const Icon(Icons.radar_outlined),
            title: Text(s.autoTripDetection),
            subtitle: Text(s.autoTripDetectionDescription),
            value: widget.preferences.autoTripDetectionEnabled,
            onChanged: (value) {
              final updated = widget.preferences.copyWith(
                autoTripDetectionEnabled: value,
              );
              widget.onPreferencesChanged(updated);
            },
          ),
          const Divider(),

          // ── Data & Backup ──────────────────────────────────────────────
          Text(
            s.dataBackup,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          ListTile(
            leading: const Icon(Icons.upload_outlined),
            title: Text(s.exportBackup),
            trailing: _isExportingBackup
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right),
            onTap: (_isExportingBackup || _isImportingBackup)
                ? null
                : _handleExportBackup,
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: Text(s.importBackup),
            trailing: _isImportingBackup
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right),
            onTap: (_isExportingBackup || _isImportingBackup)
                ? null
                : _handleImportBackup,
          ),
        ],
      ),
    );
  }
}
