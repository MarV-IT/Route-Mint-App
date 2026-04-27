import 'package:flutter/material.dart';
import '../core/localization/app_strings.dart';
import '../core/preferences/user_preferences.dart';
import '../features/today/today_screen.dart';
import '../features/trips/trips_screen.dart';
import '../features/add_trip/add_trip_screen.dart';
import '../features/reports/reports_screen.dart';
import '../features/profile/profile_screen.dart';
import 'app.dart';

class MainNavigationScreen extends StatefulWidget {
  final AppUnit unit;
  final UserPreferences preferences;
  final AppLanguage selectedLanguage;
  final ValueChanged<AppUnit?> onUnitChanged;
  final ValueChanged<AppLanguage?> onLanguageChanged;
  final AppStrings strings;

  const MainNavigationScreen({
    super.key,
    required this.unit,
    required this.preferences,
    required this.selectedLanguage,
    required this.onUnitChanged,
    required this.onLanguageChanged,
    required this.strings,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  void _selectTab(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;

    final pages = [
      TodayScreen(
        strings: strings,
        unit: widget.unit,
        preferences: widget.preferences,
        onStartTrip: () => _selectTab(2),
        onAddManually: () => _selectTab(2),
        onAddExpense: () => _selectTab(2),
      ),
      TripsScreen(strings: strings, unit: widget.unit),
      AddTripScreen(
        strings: strings,
        unit: widget.unit,
        preferences: widget.preferences,
      ),
      ReportsScreen(
        strings: strings,
        unit: widget.unit,
        preferences: widget.preferences,
      ),
      ProfileScreen(
        strings: strings,
        preferences: widget.preferences,
        selectedUnit: widget.unit,
        selectedLanguage: widget.selectedLanguage,
        onUnitChanged: widget.onUnitChanged,
        onLanguageChanged: widget.onLanguageChanged,
      ),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          _selectTab(index);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.today_outlined),
            selectedIcon: const Icon(Icons.today),
            label: strings.today,
          ),
          NavigationDestination(
            icon: const Icon(Icons.route_outlined),
            selectedIcon: const Icon(Icons.route),
            label: strings.trips,
          ),
          NavigationDestination(
            icon: const Icon(Icons.add_circle_outline),
            selectedIcon: const Icon(Icons.add_circle),
            label: strings.add,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart),
            label: strings.reports,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: strings.profile,
          ),
        ],
      ),
    );
  }
}
