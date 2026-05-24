import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/auth/auth_service.dart';
import '../../core/localization/app_strings.dart';
import '../../core/preferences/preferences_service.dart';
import '../../core/preferences/user_preferences.dart';
import '../../core/tax/tax_service.dart';
import '../../core/backup/backup_service.dart';
import '../../core/backup/cloud_backup_service.dart';
import '../../app/app.dart';
import '../../shared/utils/distance_utils.dart';
import '../auth/auth_screen.dart';
import '../work_mode/work_mode_screen.dart';
import 'tracking_diagnostics_screen.dart';

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
  late final TextEditingController _accountantNameController;
  late final TextEditingController _accountantPhoneController;
  late final TextEditingController _accountantAddressController;
  late final TextEditingController _insuranceCompanyController;
  late final TextEditingController _insurancePolicyController;
  late final TextEditingController _insuranceContactController;
  late final TextEditingController _odometerController;
  late final TextEditingController _lastOilController;
  late final TextEditingController _intervalController;
  late final TextEditingController _thresholdController;
  late final TextEditingController _lastBrakePadController;
  late final TextEditingController _brakePadIntervalController;
  late final TextEditingController _brakePadThresholdController;

  final _backupService = BackupService();
  final _cloudBackupService = CloudBackupService();
  final _prefsService = PreferencesService();
  bool _isExportingBackup = false;
  bool _isImportingBackup = false;
  bool _isUploadingCloud = false;
  bool _isRestoringCloud = false;
  int _cloudRefreshKey = 0;

  @override
  void initState() {
    super.initState();
    final p = widget.preferences;
    _driverController = TextEditingController(text: p.driverName ?? '');
    _businessController = TextEditingController(text: p.businessName ?? '');
    _vehicleController = TextEditingController(text: p.vehicleName ?? '');
    _accountantNameController = TextEditingController(
      text: p.accountantName ?? '',
    );
    _accountantPhoneController = TextEditingController(
      text: p.accountantPhone ?? '',
    );
    _accountantAddressController = TextEditingController(
      text: p.accountantAddress ?? '',
    );
    _insuranceCompanyController = TextEditingController(
      text: p.insuranceCompanyName ?? '',
    );
    _insurancePolicyController = TextEditingController(
      text: p.insurancePolicyNumber ?? '',
    );
    _insuranceContactController = TextEditingController(
      text: p.insuranceCompanyContact ?? '',
    );
    _odometerController = TextEditingController(
      text: _kmToDisplayText(p.vehicleOdometerKm),
    );
    _lastOilController = TextEditingController(
      text: _kmToDisplayText(p.lastOilChangeOdometerKm),
    );
    _intervalController = TextEditingController(
      text: _kmToDisplayText(p.oilChangeIntervalKm),
    );
    _thresholdController = TextEditingController(
      text: _kmToDisplayText(p.oilChangeReminderThresholdKm),
    );
    _lastBrakePadController = TextEditingController(
      text: _kmToDisplayText(p.lastBrakePadChangeOdometerKm),
    );
    _brakePadIntervalController = TextEditingController(
      text: _kmToDisplayText(p.brakePadChangeIntervalKm),
    );
    _brakePadThresholdController = TextEditingController(
      text: _kmToDisplayText(p.brakePadReminderThresholdKm),
    );
  }

  @override
  void dispose() {
    _driverController.dispose();
    _businessController.dispose();
    _vehicleController.dispose();
    _accountantNameController.dispose();
    _accountantPhoneController.dispose();
    _accountantAddressController.dispose();
    _insuranceCompanyController.dispose();
    _insurancePolicyController.dispose();
    _insuranceContactController.dispose();
    _odometerController.dispose();
    _lastOilController.dispose();
    _intervalController.dispose();
    _thresholdController.dispose();
    _lastBrakePadController.dispose();
    _brakePadIntervalController.dispose();
    _brakePadThresholdController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedUnit != widget.selectedUnit) {
      final p = widget.preferences;
      _odometerController.text = _kmToDisplayText(p.vehicleOdometerKm);
      _lastOilController.text = _kmToDisplayText(p.lastOilChangeOdometerKm);
      _intervalController.text = _kmToDisplayText(p.oilChangeIntervalKm);
      _thresholdController.text = _kmToDisplayText(
        p.oilChangeReminderThresholdKm,
      );
      _lastBrakePadController.text = _kmToDisplayText(
        p.lastBrakePadChangeOdometerKm,
      );
      _brakePadIntervalController.text = _kmToDisplayText(
        p.brakePadChangeIntervalKm,
      );
      _brakePadThresholdController.text = _kmToDisplayText(
        p.brakePadReminderThresholdKm,
      );
    }
  }

  String _kmToDisplayText(double? km) {
    if (km == null) return '';
    final display = fromKilometers(km, widget.selectedUnit);
    return display.toStringAsFixed(0);
  }

  double? _parseOptionalDouble(String text) {
    final t = text.trim();
    return t.isEmpty ? null : double.tryParse(t);
  }

  String get _unitSuffix => unitLabel(widget.selectedUnit);

  bool get _hasIdentityInfo =>
      _driverController.text.trim().isNotEmpty ||
      _businessController.text.trim().isNotEmpty ||
      _vehicleController.text.trim().isNotEmpty;

  bool get _hasAccountantInfo =>
      _accountantNameController.text.trim().isNotEmpty ||
      _accountantPhoneController.text.trim().isNotEmpty ||
      _accountantAddressController.text.trim().isNotEmpty;

  bool get _hasInsuranceInfo =>
      _insuranceCompanyController.text.trim().isNotEmpty ||
      _insurancePolicyController.text.trim().isNotEmpty ||
      _insuranceContactController.text.trim().isNotEmpty;

  bool get _hasMaintenanceInfo =>
      _odometerController.text.trim().isNotEmpty ||
      _lastOilController.text.trim().isNotEmpty ||
      _intervalController.text.trim().isNotEmpty ||
      _thresholdController.text.trim().isNotEmpty ||
      _lastBrakePadController.text.trim().isNotEmpty ||
      _brakePadIntervalController.text.trim().isNotEmpty ||
      _brakePadThresholdController.text.trim().isNotEmpty;

  String _saveOrEditLabel({required bool hasInfo, required String saveLabel}) {
    return hasInfo ? widget.strings.edit : saveLabel;
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        showCloseIcon: true,
      ),
    );
  }

  void _saveMaintenance() {
    final s = widget.strings;
    final unit = widget.selectedUnit;

    final odomInput = _parseOptionalDouble(_odometerController.text);
    final lastOilInput = _parseOptionalDouble(_lastOilController.text);
    final intervalInput = _parseOptionalDouble(_intervalController.text);
    final thresholdInput = _parseOptionalDouble(_thresholdController.text);
    final lastBrakePadInput = _parseOptionalDouble(
      _lastBrakePadController.text,
    );
    final brakePadIntervalInput = _parseOptionalDouble(
      _brakePadIntervalController.text,
    );
    final brakePadThresholdInput = _parseOptionalDouble(
      _brakePadThresholdController.text,
    );

    if (odomInput != null && odomInput < 0) {
      _showValidationError(s.odometerCannotBeNegative);
      return;
    }
    if (intervalInput != null && intervalInput <= 0) {
      _showValidationError(s.intervalMustBePositive);
      return;
    }
    if (thresholdInput != null && thresholdInput < 0) {
      _showValidationError(s.odometerCannotBeNegative);
      return;
    }
    if (brakePadIntervalInput != null && brakePadIntervalInput <= 0) {
      _showValidationError(s.intervalMustBePositive);
      return;
    }
    if (brakePadThresholdInput != null && brakePadThresholdInput < 0) {
      _showValidationError(s.odometerCannotBeNegative);
      return;
    }
    if (odomInput != null && lastOilInput != null && lastOilInput > odomInput) {
      _showValidationError(s.lastOilChangeCannotExceedCurrent);
      return;
    }
    if (odomInput != null &&
        lastBrakePadInput != null &&
        lastBrakePadInput > odomInput) {
      _showValidationError(s.lastOilChangeCannotExceedCurrent);
      return;
    }

    final updated = widget.preferences.copyWith(
      vehicleOdometerKm: odomInput == null
          ? null
          : toKilometers(odomInput, unit),
      lastOilChangeOdometerKm: lastOilInput == null
          ? null
          : toKilometers(lastOilInput, unit),
      oilChangeIntervalKm: intervalInput == null
          ? null
          : toKilometers(intervalInput, unit),
      oilChangeReminderThresholdKm: thresholdInput == null
          ? null
          : toKilometers(thresholdInput, unit),
      lastBrakePadChangeOdometerKm: lastBrakePadInput == null
          ? null
          : toKilometers(lastBrakePadInput, unit),
      brakePadChangeIntervalKm: brakePadIntervalInput == null
          ? null
          : toKilometers(brakePadIntervalInput, unit),
      brakePadReminderThresholdKm: brakePadThresholdInput == null
          ? null
          : toKilometers(brakePadThresholdInput, unit),
      lastOdometerUpdateAt: odomInput == null ? null : DateTime.now(),
    );
    widget.onPreferencesChanged(updated);
    setState(() {});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(s.profileSaved)));
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
    setState(() {});

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(widget.strings.profileSaved)));
  }

  void _saveAccountant() {
    final updated = widget.preferences.copyWith(
      accountantName: _accountantNameController.text.trim().isEmpty
          ? null
          : _accountantNameController.text.trim(),
      accountantPhone: _accountantPhoneController.text.trim().isEmpty
          ? null
          : _accountantPhoneController.text.trim(),
      accountantAddress: _accountantAddressController.text.trim().isEmpty
          ? null
          : _accountantAddressController.text.trim(),
    );
    widget.onPreferencesChanged(updated);
    setState(() {});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(widget.strings.profileSaved)));
  }

  void _saveInsurance() {
    final updated = widget.preferences.copyWith(
      insuranceCompanyName: _insuranceCompanyController.text.trim().isEmpty
          ? null
          : _insuranceCompanyController.text.trim(),
      insurancePolicyNumber: _insurancePolicyController.text.trim().isEmpty
          ? null
          : _insurancePolicyController.text.trim(),
      insuranceCompanyContact: _insuranceContactController.text.trim().isEmpty
          ? null
          : _insuranceContactController.text.trim(),
    );
    widget.onPreferencesChanged(updated);
    setState(() {});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(widget.strings.profileSaved)));
  }

  Future<void> _handleExportBackup() async {
    setState(() => _isExportingBackup = true);
    try {
      await _backupService.exportBackup();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(widget.strings.backupExported)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.strings.backupExportFailed)),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(widget.strings.backupImported)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.strings.backupImportFailed)),
      );
    } finally {
      if (mounted) setState(() => _isImportingBackup = false);
    }
  }

  Future<void> _handleCloudUpload() async {
    setState(() => _isUploadingCloud = true);
    try {
      await _cloudBackupService.uploadBackupForCurrentUser();
      if (!mounted) return;
      setState(() => _cloudRefreshKey++);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.strings.cloudBackupUploaded)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(widget.strings.cloudBackupFailed)));
    } finally {
      if (mounted) setState(() => _isUploadingCloud = false);
    }
  }

  Future<void> _handleCloudRestore() async {
    final hasBackup = await _cloudBackupService.hasCloudBackup();
    if (!mounted) return;

    if (!hasBackup) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.strings.noCloudBackupFound)),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widget.strings.cloudRestoreConfirmTitle),
        content: Text(widget.strings.cloudRestoreConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(widget.strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(widget.strings.restoreFromCloud),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isRestoringCloud = true);
    try {
      await _cloudBackupService.restoreBackupForCurrentUser();
      final restoredPrefs = await _prefsService.loadPreferences();
      if (!mounted) return;
      widget.onPreferencesChanged(restoredPrefs);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.strings.cloudBackupRestored)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.strings.cloudRestoreFailed)),
      );
    } finally {
      if (mounted) setState(() => _isRestoringCloud = false);
    }
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Widget _profileSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
    bool initiallyExpanded = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        leading: Icon(icon),
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [const SizedBox(height: 4), ...children],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;

    return Scaffold(
      appBar: AppBar(title: Text(s.profile)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _profileSection(
            icon: Icons.account_circle_outlined,
            title: s.account,
            initiallyExpanded: true,
            children: [
              // ── Account ───────────────────────────────────────────────────
              StreamBuilder<User?>(
                stream: AuthService().authStateChanges(),
                builder: (context, snapshot) {
                  final user = snapshot.data;
                  if (user != null) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.person_outline),
                          title: Text(user.email ?? user.uid),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.logout),
                          title: Text(s.signOut),
                          onTap: () async {
                            await AuthService().signOut();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(s.signedOut)),
                            );
                          },
                        ),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.person_outline),
                        title: Text(s.guestMode),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.login),
                        title: Text(s.signIn),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AuthScreen(
                              strings: s,
                              onContinueAsGuest: () => Navigator.pop(context),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),

          _profileSection(
            icon: Icons.badge_outlined,
            title: s.editProfileInfo,
            children: [
              // ── Report identity (editable) ─────────────────────────────────
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
                  child: Text(
                    _saveOrEditLabel(
                      hasInfo: _hasIdentityInfo,
                      saveLabel: s.save,
                    ),
                  ),
                ),
              ),
            ],
          ),

          _profileSection(
            icon: Icons.receipt_long_outlined,
            title: s.accountant,
            children: [
              // ── Accountant ─────────────────────────────────────────────────
              TextField(
                controller: _accountantNameController,
                decoration: InputDecoration(
                  labelText: s.accountantName,
                  hintText: s.optional,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _accountantPhoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: s.accountantPhone,
                  hintText: s.optional,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _accountantAddressController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: s.accountantAddress,
                  hintText: s.optional,
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 44,
                child: FilledButton(
                  onPressed: _saveAccountant,
                  child: Text(
                    _saveOrEditLabel(
                      hasInfo: _hasAccountantInfo,
                      saveLabel: s.saveAccountantInfo,
                    ),
                  ),
                ),
              ),
            ],
          ),

          _profileSection(
            icon: Icons.policy_outlined,
            title: s.insurance,
            children: [
              // ── Vehicle Maintenance ────────────────────────────────────────
              TextField(
                controller: _insuranceCompanyController,
                decoration: InputDecoration(
                  labelText: s.insuranceCompanyName,
                  hintText: s.optional,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _insurancePolicyController,
                decoration: InputDecoration(
                  labelText: s.insurancePolicyNumber,
                  hintText: s.optional,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _insuranceContactController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: s.insuranceCompanyContact,
                  hintText: s.optional,
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 44,
                child: FilledButton(
                  onPressed: _saveInsurance,
                  child: Text(
                    _saveOrEditLabel(
                      hasInfo: _hasInsuranceInfo,
                      saveLabel: s.saveInsuranceInfo,
                    ),
                  ),
                ),
              ),
            ],
          ),

          _profileSection(
            icon: Icons.car_repair_outlined,
            title: s.vehicleMaintenance,
            children: [
              TextField(
                controller: _odometerController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: s.currentOdometer,
                  hintText: s.optional,
                  suffixText: _unitSuffix,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _lastOilController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: s.lastOilChangeOdometer,
                  hintText: s.optional,
                  suffixText: _unitSuffix,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _intervalController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: s.oilChangeInterval,
                  hintText: widget.selectedUnit == AppUnit.miles
                      ? '5000'
                      : '8000',
                  suffixText: _unitSuffix,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _thresholdController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: s.oilChangeReminderThreshold,
                  hintText: widget.selectedUnit == AppUnit.miles
                      ? '500'
                      : '800',
                  suffixText: _unitSuffix,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _lastBrakePadController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: s.lastBrakePadChangeOdometer,
                  hintText: s.optional,
                  suffixText: _unitSuffix,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _brakePadIntervalController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: s.brakePadChangeInterval,
                  hintText: widget.selectedUnit == AppUnit.miles
                      ? '30000'
                      : '48000',
                  suffixText: _unitSuffix,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _brakePadThresholdController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: s.brakePadReminderThreshold,
                  hintText: widget.selectedUnit == AppUnit.miles
                      ? '1000'
                      : '1600',
                  suffixText: _unitSuffix,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 44,
                child: FilledButton(
                  onPressed: _saveMaintenance,
                  child: Text(
                    _saveOrEditLabel(
                      hasInfo: _hasMaintenanceInfo,
                      saveLabel: s.saveMaintenanceInfo,
                    ),
                  ),
                ),
              ),
            ],
          ),

          _profileSection(
            icon: Icons.tune_outlined,
            title: '${s.units} / ${s.languageLabel}',
            children: [
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
                onChanged: widget.onLanguageChanged,
              ),
              const SizedBox(height: 12),

              // ── Appearance ─────────────────────────────────────────────────
              DropdownButtonFormField<AppThemeMode>(
                initialValue: widget.preferences.themeMode,
                decoration: InputDecoration(
                  labelText: s.appearance,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: AppThemeMode.system,
                    child: Text(s.systemTheme),
                  ),
                  DropdownMenuItem(
                    value: AppThemeMode.light,
                    child: Text(s.lightTheme),
                  ),
                  DropdownMenuItem(
                    value: AppThemeMode.dark,
                    child: Text(s.darkTheme),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  widget.onPreferencesChanged(
                    widget.preferences.copyWith(themeMode: value),
                  );
                },
              ),
              const SizedBox(height: 12),

              const Divider(),
            ],
          ),

          _profileSection(
            icon: Icons.route_outlined,
            title: s.automation,
            children: [
              // ── Work Mode ──────────────────────────────────────────────────
              ListTile(
                leading: const Icon(Icons.work_outline),
                title: Text(s.workMode),
                subtitle: Text(s.autoClassifyTrips),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => WorkModeScreen(strings: s)),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.health_and_safety_outlined),
                title: Text(s.trackingDiagnostics),
                subtitle: Text(s.trackingDiagnosticsSubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TrackingDiagnosticsScreen(strings: s),
                  ),
                ),
              ),
              const Divider(),

              // ── Automation ────────────────────────────────────────────────
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
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                child: Text(
                  s.foregroundOnlyTracking,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
            ],
          ),

          _profileSection(
            icon: Icons.backup_outlined,
            title: '${s.dataBackup} / ${s.cloudBackup}',
            children: [
              // ── Data & Backup ──────────────────────────────────────────────
              Text(
                s.dataBackup,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
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
              const Divider(),

              // ── Cloud Backup ───────────────────────────────────────────────
              Text(
                s.cloudBackup,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              StreamBuilder<User?>(
                stream: AuthService().authStateChanges(),
                builder: (context, snapshot) {
                  final user = snapshot.data;
                  if (user == null) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.cloud_off_outlined),
                      title: Text(
                        s.signInToUseCloudBackup,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                    );
                  }
                  final busy = _isUploadingCloud || _isRestoringCloud;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${s.cloudBackupExplanation} ${s.cloudRestoreExplanation}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.cloud_upload_outlined),
                        title: Text(s.backupToCloud),
                        trailing: _isUploadingCloud
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.chevron_right),
                        onTap: busy ? null : _handleCloudUpload,
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.cloud_download_outlined),
                        title: Text(s.restoreFromCloud),
                        trailing: _isRestoringCloud
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.chevron_right),
                        onTap: busy ? null : _handleCloudRestore,
                      ),
                      FutureBuilder<DateTime?>(
                        key: ValueKey(_cloudRefreshKey),
                        future: _cloudBackupService.getLastCloudBackupTime(),
                        builder: (context, snap) {
                          final dt = snap.data;
                          if (dt == null) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 4, bottom: 8),
                            child: Text(
                              '${s.lastCloudBackup}: ${_formatDateTime(dt)}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline,
                                  ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
              const Divider(),
            ],
          ),

          _profileSection(
            icon: Icons.privacy_tip_outlined,
            title: s.privacyAndData,
            children: [
              // ── Privacy & Data ─────────────────────────────────────────────
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(Icons.smartphone_outlined),
                title: Text(s.tripsStoredLocally),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(Icons.cloud_outlined),
                title: Text(s.cloudBackupOptional),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(Icons.location_on_outlined),
                title: Text(s.locationUsageExplanation),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(Icons.radar_outlined),
                title: Text(s.foregroundTrackingExplanation),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
