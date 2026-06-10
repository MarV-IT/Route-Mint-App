import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/backup/cloud_backup_service.dart';
import '../core/backup/daily_cloud_backup_service.dart';
import '../core/localization/app_strings.dart';
import '../core/preferences/user_preferences.dart';
import '../core/preferences/preferences_service.dart';
import '../features/auth/auth_gate.dart';
import '../features/onboarding/onboarding_screen.dart';
import 'navigation.dart';

enum AppUnit { kilometers, miles }

enum AppLanguage { english, spanish, french, russian, ukrainian, dari }

enum AppThemeMode { system, light, dark }

class RouteMintApp extends StatefulWidget {
  const RouteMintApp({super.key});

  @override
  State<RouteMintApp> createState() => _RouteMintAppState();
}

class _RouteMintAppState extends State<RouteMintApp> {
  final _prefsService = PreferencesService();
  final _cloudBackupService = CloudBackupService();
  final _dailyCloudBackupService = DailyCloudBackupService();

  AppLanguage _selectedLanguage = AppLanguage.english;

  UserPreferences? _preferences; // null = still loading from storage
  int _selectedNavigationIndex = 0;
  Timer? _dailyCloudBackupTimer;
  StreamSubscription<User?>? _authSubscription;
  bool _dailyCloudBackupRunning = false;
  bool _cloudRestoreRunning = false;
  int _dataRefreshKey = 0;

  @override
  void initState() {
    super.initState();
    if (Firebase.apps.isNotEmpty) {
      _authSubscription = FirebaseAuth.instance.authStateChanges().listen((
        user,
      ) async {
        if (user != null) {
          await _restoreCloudBackupOnFreshInstall();
        }
        _scheduleDailyCloudBackup();
        _checkDailyCloudBackup();
      });
    }
    _loadPreferences();
  }

  @override
  void dispose() {
    _dailyCloudBackupTimer?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final prefs = await _prefsService.loadPreferences();
    if (!mounted) return;
    setState(() {
      _preferences = prefs;
      _selectedLanguage = prefs.language;
    });
    _scheduleDailyCloudBackup(prefs);
    _checkDailyCloudBackup(prefs);
  }

  Future<void> _checkDailyCloudBackup([UserPreferences? preferences]) async {
    if (_dailyCloudBackupRunning) return;
    final prefs = preferences ?? _preferences;
    if (prefs == null) return;

    _dailyCloudBackupRunning = true;
    final updated = await _dailyCloudBackupService.runIfDue(prefs);
    _dailyCloudBackupRunning = false;
    if (updated == null || !mounted) return;

    setState(() {
      _preferences = updated;
      _selectedLanguage = updated.language;
    });
    _scheduleDailyCloudBackup(updated);
  }

  Future<void> _restoreCloudBackupOnFreshInstall() async {
    if (_cloudRestoreRunning) return;
    _cloudRestoreRunning = true;
    try {
      final restored = await _cloudBackupService.restoreIfLocalDataIsEmpty();
      if (!restored || !mounted) return;

      final restoredPrefs = await _prefsService.loadPreferences();
      if (!mounted) return;
      setState(() {
        _preferences = restoredPrefs;
        _selectedLanguage = restoredPrefs.language;
        _dataRefreshKey++;
      });
      if (kDebugMode) {
        debugPrint('[CloudBackup] restored backup on fresh install');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CloudBackup] fresh install restore skipped: $e');
      }
    } finally {
      _cloudRestoreRunning = false;
    }
  }

  void _scheduleDailyCloudBackup([UserPreferences? preferences]) {
    _dailyCloudBackupTimer?.cancel();
    final prefs = preferences ?? _preferences;
    if (prefs == null) return;

    final nextBackup = _dailyCloudBackupService.nextBackupTime();
    final delay = nextBackup.difference(DateTime.now());
    _dailyCloudBackupTimer = Timer(delay, () {
      _checkDailyCloudBackup();
      _scheduleDailyCloudBackup();
    });
  }

  // ─── Handlers ─────────────────────────────────────────────────────────────

  void _changeUnit(AppUnit? newUnit) {
    if (newUnit == null || _preferences == null) return;
    final updated = _preferences!.copyWith(unit: newUnit);
    setState(() => _preferences = updated);
    _prefsService.savePreferences(updated);
    _scheduleDailyCloudBackup(updated);
  }

  void _changeLanguage(AppLanguage? newLanguage) {
    if (newLanguage == null || _preferences == null) return;
    final updated = _preferences!.copyWith(language: newLanguage);
    setState(() {
      _preferences = updated;
      _selectedLanguage = newLanguage;
    });
    _prefsService.savePreferences(updated);
    _scheduleDailyCloudBackup(updated);
  }

  void _changePreferences(UserPreferences updated) {
    setState(() {
      _preferences = updated;
      _selectedLanguage = updated.language;
      _dataRefreshKey++;
    });
    _prefsService.savePreferences(updated);
    _scheduleDailyCloudBackup(updated);
    _checkDailyCloudBackup(updated);
  }

  void _onOnboardingComplete(UserPreferences prefs) {
    final updated = prefs.copyWith(language: _selectedLanguage);
    setState(() => _preferences = updated);
    _prefsService.savePreferences(updated);
    _scheduleDailyCloudBackup(updated);
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(_selectedLanguage);

    const seed = Color(0xFF52D6FD);

    final themeMode = switch (_preferences?.themeMode ?? AppThemeMode.system) {
      AppThemeMode.system => ThemeMode.system,
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
    };

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MarV Route',
      themeMode: themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF0FBFD),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: _buildHome(strings),
    );
  }

  Widget _buildHome(AppStrings strings) {
    if (_preferences == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_preferences!.onboardingCompleted) {
      return OnboardingScreen(
        strings: strings,
        onComplete: _onOnboardingComplete,
      );
    }

    return AuthGate(
      strings: strings,
      child: MainNavigationScreen(
        key: ValueKey(_dataRefreshKey),
        unit: _preferences!.unit,
        preferences: _preferences!,
        selectedLanguage: _selectedLanguage,
        onUnitChanged: _changeUnit,
        onLanguageChanged: _changeLanguage,
        onPreferencesChanged: _changePreferences,
        onPreferencesRefresh: _loadPreferences,
        selectedIndex: _selectedNavigationIndex,
        onSelectedIndexChanged: (index) =>
            setState(() => _selectedNavigationIndex = index),
        strings: strings,
      ),
    );
  }
}
