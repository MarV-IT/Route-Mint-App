import 'package:flutter/material.dart';
import '../core/localization/app_strings.dart';
import '../core/location/auto_trip_detection_service.dart';
import '../core/location/geolocator_tracking_provider.dart';
import '../core/preferences/user_preferences.dart';
import '../features/today/today_screen.dart';
import '../features/trips/trips_screen.dart';
import '../features/add_trip/add_trip_screen.dart';
import '../features/expenses/add_expense_screen.dart';
import '../features/reports/reports_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/profile/tracking_diagnostics_screen.dart';
import 'app.dart';

class MainNavigationScreen extends StatefulWidget {
  final AppUnit unit;
  final UserPreferences preferences;
  final AppLanguage selectedLanguage;
  final ValueChanged<AppUnit?> onUnitChanged;
  final ValueChanged<AppLanguage?> onLanguageChanged;
  final ValueChanged<UserPreferences> onPreferencesChanged;
  final Future<void> Function() onPreferencesRefresh;
  final int selectedIndex;
  final ValueChanged<int> onSelectedIndexChanged;
  final AppStrings strings;

  const MainNavigationScreen({
    super.key,
    required this.unit,
    required this.preferences,
    required this.selectedLanguage,
    required this.onUnitChanged,
    required this.onLanguageChanged,
    required this.onPreferencesChanged,
    required this.onPreferencesRefresh,
    required this.selectedIndex,
    required this.onSelectedIndexChanged,
    required this.strings,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  bool _tripsShowNeedsReview = false;

  void _selectTab(int index) {
    setState(() {
      // Reset the inbox filter when the user navigates away from Trips
      // so a subsequent normal tap on the Trips tab shows all trips.
      if (index != 1) _tripsShowNeedsReview = false;
    });
    widget.onSelectedIndexChanged(index);
  }

  void _navigateToTripsForReview() {
    setState(() {
      _tripsShowNeedsReview = true;
    });
    widget.onSelectedIndexChanged(1);
  }

  Future<void> _openAddExpense() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(
          strings: widget.strings,
          unit: widget.unit,
          preferences: widget.preferences,
        ),
      ),
    );
  }

  Future<void> _openPermissionCheck() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrackingDiagnosticsScreen(strings: widget.strings),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;

    final pages = [
      TodayScreen(
        strings: strings,
        unit: widget.unit,
        preferences: widget.preferences,
        onPreferencesChanged: widget.onPreferencesChanged,
        onPreferencesRefresh: widget.onPreferencesRefresh,
        onStartTrip: () => _selectTab(2),
        onAddManually: () => _selectTab(2),
        onAddExpense: _openAddExpense,
        onReviewTrips: _navigateToTripsForReview,
        onCheckPermissions: _openPermissionCheck,
      ),
      TripsScreen(
        strings: strings,
        unit: widget.unit,
        currencyCode: widget.preferences.currencyCode,
        showNeedsReviewOnly: _tripsShowNeedsReview,
        onPreferencesRefresh: widget.onPreferencesRefresh,
      ),
      AddTripScreen(
        strings: strings,
        unit: widget.unit,
        preferences: widget.preferences,
        onPreferencesRefresh: widget.onPreferencesRefresh,
      ),
      ReportsScreen(
        strings: strings,
        unit: widget.unit,
        preferences: widget.preferences,
        onReviewDetectedTrips: _navigateToTripsForReview,
      ),
      ProfileScreen(
        strings: strings,
        preferences: widget.preferences,
        selectedUnit: widget.unit,
        selectedLanguage: widget.selectedLanguage,
        onUnitChanged: widget.onUnitChanged,
        onLanguageChanged: widget.onLanguageChanged,
        onPreferencesChanged: widget.onPreferencesChanged,
      ),
    ];

    return Scaffold(
      body: Column(
        children: [
          Expanded(child: pages[widget.selectedIndex]),
          // Show a persistent banner on every tab except Today (index 0),
          // where the tracking card already shows status.
          ValueListenableBuilder<bool>(
            valueListenable: appTrackingService.isTrackingNotifier,
            builder: (context, isTracking, _) {
              return ValueListenableBuilder<AutoDetectionState>(
                valueListenable: appAutoDetectionService.stateNotifier,
                builder: (context, autoState, _) {
                  final autoIsActive = autoState != AutoDetectionState.idle;
                  if ((!isTracking && !autoIsActive) ||
                      widget.selectedIndex == 0) {
                    return const SizedBox.shrink();
                  }
                  return _ActiveTrackingBanner(
                    strings: strings,
                    autoDetectionActive: autoIsActive && !isTracking,
                  );
                },
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.selectedIndex,
        onDestinationSelected: (index) {
          _selectTab(index);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: strings.home,
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

class _ActiveTrackingBanner extends StatelessWidget {
  const _ActiveTrackingBanner({
    required this.strings,
    required this.autoDetectionActive,
  });

  final AppStrings strings;
  final bool autoDetectionActive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(
              autoDetectionActive ? Icons.radar_outlined : Icons.gps_fixed,
              size: 16,
              color: colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    autoDetectionActive
                        ? strings.autoTripDetection
                        : strings.trackingActiveTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    autoDetectionActive
                        ? strings.tripDetectedTracking
                        : strings.trackingActiveMessage,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
