import 'package:flutter/material.dart';
import '../../app/app.dart';
import '../../core/localization/app_strings.dart';
import '../../shared/utils/distance_utils.dart';
import '../../shared/widgets/trip_tile.dart';
import 'models/trip.dart';
import 'services/trip_service.dart';

class TripsScreen extends StatefulWidget {
  final AppStrings strings;
  final AppUnit unit;

  const TripsScreen({
    super.key,
    required this.strings,
    required this.unit,
  });

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  final _tripService = TripService();
  late Future<List<Trip>> _tripsFuture;

  @override
  void initState() {
    super.initState();
    _tripsFuture = _tripService.loadTrips();
  }

  Future<void> _refreshTrips() async {
    setState(() {
      _tripsFuture = _tripService.loadTrips();
    });
  }

  String _formatCategory(String category) {
    switch (category) {
      case 'business':
        return widget.strings.business;
      case 'personal':
        return widget.strings.personal;
      default:
        return category;
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.strings.trips),
      ),
      body: FutureBuilder<List<Trip>>(
        future: _tripsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading trips'),
            );
          }

          final trips = snapshot.data ?? [];

          if (trips.isEmpty) {
            return Center(
              child: Text('No trips yet'),
            );
          }

          final sortedTrips = [...trips]
            ..sort((a, b) => b.date.compareTo(a.date));

          return RefreshIndicator(
            onRefresh: _refreshTrips,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sortedTrips.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final trip = sortedTrips[index];

                return TripTile(
                  title: '${trip.from} → ${trip.to}',
                  subtitle:
                      '${formatDistance(trip.distance, widget.unit)} • ${_formatCategory(trip.category)} • ${_formatTime(trip.date)}',
                );
              },
            ),
          );
        },
      ),
    );
  }
}