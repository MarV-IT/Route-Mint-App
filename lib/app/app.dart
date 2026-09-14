import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../core/backup/cloud_backup_service.dart';
import '../core/backup/daily_cloud_backup_service.dart';
import '../core/localization/app_strings.dart';
import '../core/location/geolocator_tracking_provider.dart';
import '../core/preferences/user_preferences.dart';
import '../core/subscription/entitlement_service.dart';
import '../core/preferences/preferences_service.dart';
import '../features/auth/auth_gate.dart';
import '../features/onboarding/onboarding_screen.dart';
import 'navigation.dart';

enum AppUnit { kilometers, miles }

enum AppLanguage { english, spanish, french, russian, ukrainian, dari }

extension AppLanguageDisplay on AppLanguage {
  /// Name written in the language's own script. Someone who ended up in a
  /// language they cannot read needs to spot their own to switch back.
  String get nativeName => switch (this) {
    AppLanguage.english => 'English',
    AppLanguage.spanish => 'Español',
    AppLanguage.french => 'Français',
    AppLanguage.russian => 'Русский',
    AppLanguage.ukrainian => 'Українська',
    AppLanguage.dari => 'Dari',
  };
}

enum AppThemeMode { system, light, dark }

class RouteMintApp extends StatefulWidget {
  const RouteMintApp({super.key});

  @override
  State<RouteMintApp> createState() => _RouteMintAppState();
}

class _RouteMintAppState extends State<RouteMintApp>
    with WidgetsBindingObserver {
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
  bool _autoDetectionRestoreRunning = false;
  bool _autoDetectionRecoveryCompleted = false;
  int _dataRefreshKey = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    WidgetsBinding.instance.removeObserver(this);
    _dailyCloudBackupTimer?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Mobile operating systems suspend Dart timers in the background.
      _scheduleDailyCloudBackup();
      _checkDailyCloudBackup();
      final prefs = _preferences;
      if (prefs != null) _restoreAutoDetection(prefs);
    }
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
    _restoreAutoDetection(prefs);
  }

  /// Picks up after an app kill: saves the trip that was still being recorded,
  /// and brings monitoring back if it was running.
  ///
  /// The OS reclaims the app during long trips — routine while a delivery app
  /// holds the foreground — and detection has no way back on its own.
  Future<void> _restoreAutoDetection(UserPreferences prefs) async {
    if (_autoDetectionRestoreRunning) return;
    _autoDetectionRestoreRunning = true;
    try {
      if (!_autoDetectionRecoveryCompleted) {
        // A preferences refresh or resume must never finish a live trip.
        final recovered =
            !appAutoDetectionService.isMonitoring &&
            await appAutoDetectionService.recoverInterruptedTrip();
        _autoDetectionRecoveryCompleted = true;
        if (recovered && mounted) {
          setState(() => _dataRefreshKey++);
        }
      }

      if (!prefs.autoTripDetectionEnabled) return;
      if (!EntitlementService(prefs).canUseAutoDetection) return;
      if (appAutoDetectionService.isMonitoring) return;
      if (!await appAutoDetectionService.wasMonitoringBeforeRestart()) return;
      if (!await Geolocator.isLocationServiceEnabled()) return;
      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return;
      }
      // Starting Android's location service requires a visible activity.
      // Resume retries this check without opening permission dialogs.
      final current = _preferences;
      if (!mounted ||
          WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed ||
          appTrackingService.isTracking ||
          current == null ||
          !current.autoTripDetectionEnabled ||
          !EntitlementService(current).canUseAutoDetection) {
        return;
      }

      await appAutoDetectionService.startMonitoring();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AutoDetection] restore after restart skipped: $e');
      }
    } finally {
      _autoDetectionRestoreRunning = false;
    }
  }

  Future<void> _checkDailyCloudBackup([UserPreferences? preferences]) async {
    if (_dailyCloudBackupRunning) return;
    final prefs = preferences ?? _preferences;
    if (prefs == null) return;

    _dailyCloudBackupRunning = true;
    try {
      final updated = await _dailyCloudBackupService.runIfDue(prefs);
      if (updated == null || !mounted) return;

      setState(() {
        _preferences = updated;
        _selectedLanguage = updated.language;
      });
      _scheduleDailyCloudBackup(updated);
    } finally {
      _dailyCloudBackupRunning = false;
    }
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
        onLanguageChanged: _changeLanguage,
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
