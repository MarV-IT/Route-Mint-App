import '../core/storage/settings_service.dart';
import '../core/tax/tax_service.dart';
import 'package:flutter/material.dart';
import '../core/localization/app_strings.dart';
import 'navigation.dart';

enum AppUnit { kilometers, miles }

enum AppLanguage {
  english,
  spanish,
  french,
  russian,
  ukrainian,
  dari,
}

class RouteMintApp extends StatefulWidget {
  const RouteMintApp({super.key});

  @override
  State<RouteMintApp> createState() => _RouteMintAppState();
}

class _RouteMintAppState extends State<RouteMintApp> {
  AppUnit _unit = AppUnit.kilometers;
  AppLanguage _selectedLanguage = AppLanguage.english;
  Country _country = Country.usa;

  final _settings = SettingsService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final unit = await _settings.loadUnit();
    final language = await _settings.loadLanguage();
    final country = await _settings.loadCountry();

    setState(() {
      _unit = unit;
      _selectedLanguage = language;
      _country = country;
    });
  }

  Future<void> _changeUnit(AppUnit? newUnit) async {
    if (newUnit == null) return;

    setState(() {
      _unit = newUnit;
    });

    await _settings.saveUnit(newUnit);
  }

  Future<void> _changeLanguage(AppLanguage? newLanguage) async {
    if (newLanguage == null) return;

    setState(() {
      _selectedLanguage = newLanguage;
    });

    await _settings.saveLanguage(newLanguage);
  }

  Future<void> _changeCountry(Country? newCountry) async {
    if (newCountry == null) return;

    setState(() {
      _country = newCountry;
    });

    await _settings.saveCountry(newCountry);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(_selectedLanguage);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Route Mint',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        scaffoldBackgroundColor: const Color(0xFFF6F8F7),
        useMaterial3: true,
      ),
      home: MainNavigationScreen(
        unit: _unit,
        selectedLanguage: _selectedLanguage,
        country: _country,
        onUnitChanged: _changeUnit,
        onLanguageChanged: _changeLanguage,
        onCountryChanged: _changeCountry,
        strings: strings,
      ),
    );
  }
}