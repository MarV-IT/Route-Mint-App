import 'package:flutter/material.dart';
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

  AppLanguage _selectedLanguage = AppLanguage.english;

  UserPreferences? _preferences; // null = still loading from storage
  int _selectedNavigationIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await _prefsService.loadPreferences();
    setState(() {
      _preferences = prefs;
      _selectedLanguage = prefs.language;
    });
  }

  // ─── Handlers ─────────────────────────────────────────────────────────────

  void _changeUnit(AppUnit? newUnit) {
    if (newUnit == null || _preferences == null) return;
    final updated = _preferences!.copyWith(unit: newUnit);
    setState(() => _preferences = updated);
    _prefsService.savePreferences(updated);
  }

  void _changeLanguage(AppLanguage? newLanguage) {
    if (newLanguage == null || _preferences == null) return;
    final updated = _preferences!.copyWith(language: newLanguage);
    setState(() {
      _preferences = updated;
      _selectedLanguage = newLanguage;
    });
    _prefsService.savePreferences(updated);
  }

  void _changePreferences(UserPreferences updated) {
    setState(() {
      _preferences = updated;
      _selectedLanguage = updated.language;
    });
    _prefsService.savePreferences(updated);
  }

  void _onOnboardingComplete(UserPreferences prefs) {
    final updated = prefs.copyWith(language: _selectedLanguage);
    setState(() => _preferences = updated);
    _prefsService.savePreferences(updated);
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
