import 'booking_status.dart';

/// A booking of the person asking, with the total saved when it was made.
class Booking {
  const Booking({
    required this.id,
    required this.spaceId,
    required this.venueId,
    required this.space,
    required this.sport,
    required this.kind,
    required this.venue,
    required this.address,
    required this.startsAt,
    required this.endsAt,
    required this.total,
    required this.status,
    required this.reason,
    this.cancelable = false,
  });

  final String id;
  final String spaceId;
  final String venueId;

  /// The composed name of the space.
  final String space;
  final String sport;
  final String kind;
  final String venue;
  final String address;

  /// In club time.
  final DateTime startsAt;
  final DateTime endsAt;
  final int total;
  final BookingStatus status;
  final String? reason;

  /// Active and not started yet, according to the server.
  final bool cancelable;
}
