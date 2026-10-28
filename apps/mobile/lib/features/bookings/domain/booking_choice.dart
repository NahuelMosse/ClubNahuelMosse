// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import '../../../common/dates.dart';
import '../../spaces/domain/space.dart';
import '../../venues/domain/venue.dart';

/// What was picked on the availability screen and moves on to the booking confirmation.
/// Choosing does not book anything.
class BookingChoice {
  const BookingChoice({
    required this.venue,
    required this.space,
    required this.kind,
    required this.date,
    required this.start,
    required this.end,
    required this.hours,
  });

  final Venue venue;
  final Space space;

  /// The kind as displayed: «Fútbol 5».
  final String kind;
  final DateTime date;

  /// `HH:MM` in club time.
  final String start;
  final String end;
  final int hours;

  int get total => space.pricePerHour * hours;

  /// «18:00 – 19:00 · 1 hora».
  String get timeRange => '$start – $end · ${duration(hours)}';
}
