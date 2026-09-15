import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../core/auth/account_session_service.dart';
import '../core/backup/cloud_backup_service.dart';
import '../core/backup/daily_cloud_backup_service.dart';
import '../core/localization/app_strings.dart';
import '../core/location/geolocator_tracking_provider.dart';
import '../core/preferences/user_preferences.dart';
import '../core/subscription/entitlement_service.dart';
import '../core/preferences/preferences_service.dart';
import '../core/storage/account_data_store.dart';
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
  const RouteMintApp({super.key, this.accountSession});

  final AccountSessionService? accountSession;

  @override
  State<RouteMintApp> createState() => _RouteMintAppState();
}

class _RouteMintAppState extends State<RouteMintApp>
    with WidgetsBindingObserver {
  PreferencesService get _prefsService => PreferencesService();
  final _cloudBackupService = CloudBackupService();
  final _dailyCloudBackupService = DailyCloudBackupService();

  AppLanguage _selectedLanguage = AppLanguage.english;

  UserPreferences? _preferences; // null = still loading from storage
  int _selectedNavigationIndex = 0;
  Timer? _dailyCloudBackupTimer;
  AccountSessionService? _accountSession;
  int _accountRevision = 0;
  bool _loadingAccount = false;
  bool _dailyCloudBackupRunning = false;
  bool _cloudRestoreRunning = false;
  bool _cloudStartupVerified = false;
  bool _autoDetectionRestoreRunning = false;
  bool _autoDetectionRecoveryCompleted = false;
  int _dataRefreshKey = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.accountSession != null || Firebase.apps.isNotEmpty) {
      _accountSession = widget.accountSession ?? AccountSessionService.instance;
      _accountSession!.addListener(_onAccountSessionChanged);
      if (_accountSession!.isReady) _onAccountSessionChanged();
    } else {
      _loadPreferences();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dailyCloudBackupTimer?.cancel();
    _accountSession?.removeListener(_onAccountSessionChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_loadingAccount || !_accountReady) return;
      // Mobile operating systems suspend Dart timers in the background.
      _scheduleDailyCloudBackup();
      if (!_cloudStartupVerified && _accountSession?.user != null) {
        unawaited(
          _restoreCloudBackupOnFreshInstall().then(
            (_) => _checkDailyCloudBackup(),
          ),
        );
      } else {
        _checkDailyCloudBackup();
      }
      final prefs = _preferences;
      if (prefs != null) _restoreAutoDetection(prefs);
    }
  }

  bool get _accountReady => _accountSession?.isReady ?? true;

  bool _isCurrentAccount(AccountDataScope scope, int revision) =>
      mounted &&
      _accountReady &&
      revision == _accountRevision &&
      identical(scope, AccountDataStore.current);

  void _onAccountSessionChanged() {
    if (!mounted) return;
    _dailyCloudBackupTimer?.cancel();
    setState(() {
      _accountRevision++;
      _loadingAccount = true;
      _preferences = null;
      _selectedNavigationIndex = 0;
      _dataRefreshKey++;
      _autoDetectionRecoveryCompleted = false;
      _autoDetectionRestoreRunning = false;
      _dailyCloudBackupRunning = false;
      _cloudRestoreRunning = false;
      _cloudStartupVerified = false;
    });
    if (_accountReady) unawaited(_loadAccount());
  }

  Future<void> _loadAccount() async {
    final scope = AccountDataStore.current;
    final revision = _accountRevision;
    try {
      await _loadPreferences(performBackgroundTasks: false);
      if (!_isCurrentAccount(scope, revision)) return;
      if (_accountSession?.user != null) {
        await _restoreCloudBackupOnFreshInstall();
      }
      if (!_isCurrentAccount(scope, revision)) return;
      _scheduleDailyCloudBackup();
      _checkDailyCloudBackup();
      final prefs = _preferences;
      if (prefs != null) _restoreAutoDetection(prefs);
    } finally {
      if (_isCurrentAccount(scope, revision)) {
        setState(() => _loadingAccount = false);
      }
    }
  }

  Future<void> _loadPreferences({bool performBackgroundTasks = true}) async {
    if (!_accountReady) return;
    final scope = AccountDataStore.current;
    final revision = _accountRevision;
    final prefs = await _prefsService.loadPreferences();
    if (!_isCurrentAccount(scope, revision)) return;
    setState(() {
      _preferences = prefs;
      _selectedLanguage = prefs.language;
    });
    if (performBackgroundTasks) {
      _scheduleDailyCloudBackup(prefs);
      _checkDailyCloudBackup(prefs);
      _restoreAutoDetection(prefs);
    }
  }

  /// Picks up after an app kill: saves the trip that was still being recorded,
  /// and brings monitoring back if it was running.
  ///
  /// The OS reclaims the app during long trips — routine while a delivery app
  /// holds the foreground — and detection has no way back on its own.
  Future<void> _restoreAutoDetection(UserPreferences prefs) async {
    if (!_accountReady || _autoDetectionRestoreRunning) return;
    final scope = AccountDataStore.current;
    final revision = _accountRevision;
    _autoDetectionRestoreRunning = true;
    try {
      if (!_autoDetectionRecoveryCompleted) {
        // A preferences refresh or resume must never finish a live trip.
        final recovered =
            !appAutoDetectionService.isMonitoring &&
            await appAutoDetectionService.recoverInterruptedTrip();
        if (!_isCurrentAccount(scope, revision)) return;
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
      if (!_isCurrentAccount(scope, revision) ||
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
      if (_isCurrentAccount(scope, revision)) {
        _autoDetectionRestoreRunning = false;
      }
    }
  }

  Future<void> _checkDailyCloudBackup([UserPreferences? preferences]) async {
    if (!_accountReady || _dailyCloudBackupRunning || _cloudRestoreRunning) {
      return;
    }
    if (_accountSession?.user != null && !_cloudStartupVerified) return;
    final scope = AccountDataStore.current;
    final revision = _accountRevision;
    final prefs = preferences ?? _preferences;
    if (prefs == null) return;

    _dailyCloudBackupRunning = true;
    try {
      final updated = await _dailyCloudBackupService.runIfDue(prefs);
      if (updated == null || !_isCurrentAccount(scope, revision)) return;

      setState(() {
        _preferences = updated;
        _selectedLanguage = updated.language;
      });
      _scheduleDailyCloudBackup(updated);
    } finally {
      if (_isCurrentAccount(scope, revision)) _dailyCloudBackupRunning = false;
    }
  }

  Future<void> _restoreCloudBackupOnFreshInstall() async {
    if (!_accountReady || _cloudRestoreRunning) return;
    final scope = AccountDataStore.current;
    final revision = _accountRevision;
    _cloudRestoreRunning = true;
    try {
      final restored = await _cloudBackupService.restoreIfLocalDataIsEmpty();
      if (!_isCurrentAccount(scope, revision)) return;
      _cloudStartupVerified = true;
      if (!restored) return;

      final restoredPrefs = await _prefsService.loadPreferences();
      if (!_isCurrentAccount(scope, revision)) return;
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
      if (_isCurrentAccount(scope, revision)) _cloudRestoreRunning = false;
    }
  }

  void _scheduleDailyCloudBackup([UserPreferences? preferences]) {
    _dailyCloudBackupTimer?.cancel();
    if (!_accountReady) return;
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
      // Drop routes and widget caches belonging to the previous account.
      key: ValueKey(_accountSession?.revision ?? 0),
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
    final scope = AccountDataStore.current;
    final revision = _accountRevision;
    if (_accountSession?.error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(strings.authenticationFailedTryAgain),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () async {
                    try {
                      await _accountSession!.retry();
                    } catch (_) {}
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(strings.retry),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (_loadingAccount || _preferences == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_preferences!.onboardingCompleted) {
      return OnboardingScreen(
        strings: strings,
        onComplete: (prefs) {
          if (_isCurrentAccount(scope, revision)) _onOnboardingComplete(prefs);
        },
        onLanguageChanged: (language) {
          if (_isCurrentAccount(scope, revision)) _changeLanguage(language);
        },
      );
    }

    return AuthGate(
      strings: strings,
      child: MainNavigationScreen(
        key: ValueKey(_dataRefreshKey),
        unit: _preferences!.unit,
        preferences: _preferences!,
        selectedLanguage: _selectedLanguage,
        onUnitChanged: (unit) {
          if (_isCurrentAccount(scope, revision)) _changeUnit(unit);
        },
        onLanguageChanged: (language) {
          if (_isCurrentAccount(scope, revision)) _changeLanguage(language);
        },
        onPreferencesChanged: (prefs) {
          if (_isCurrentAccount(scope, revision)) _changePreferences(prefs);
        },
        onPreferencesRefresh: () async {
          if (_isCurrentAccount(scope, revision)) await _loadPreferences();
        },
        selectedIndex: _selectedNavigationIndex,
        onSelectedIndexChanged: (index) =>
            setState(() => _selectedNavigationIndex = index),
        strings: strings,
      ),
    );
  }
}
