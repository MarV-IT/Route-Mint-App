import '../../core/tax/tax_service.dart';
import 'models/trip.dart';

/// The business kilometres in [trips], each with its trip date, ready for
/// [TaxService.calculateTaxForTrips].
Iterable<DatedDistance> businessDistances(Iterable<Trip> trips) => trips
    .where((t) => t.category == 'business')
    .map((t) => (date: t.date, km: t.distance));
