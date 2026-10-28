// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import '../../bookings/domain/booking_status.dart';

/// A booking as an administrator sees it (CU-14): who made it and its traceability.
class BookingHistoryEntry {
  const BookingHistoryEntry({
    required this.id,
    required this.spaceId,
    required this.venueId,
    required this.space,
    required this.sport,
    required this.type,
    required this.venue,
    required this.address,
    required this.startsAt,
    required this.endsAt,
    required this.total,
    required this.status,
    required this.reason,
    required this.userId,
    required this.user,
    required this.createdAt,
    required this.cancelledAt,
    required this.cancelledByName,
    required this.spaceDeactivated,
    this.voidable = false,
    this.noticeDelivery,
    this.noticeAt,
  });

  final String id;
  final String spaceId;
  final String venueId;
  final String space;
  final String sport;
  final String type;
  final String venue;
  final String address;
  final DateTime startsAt;
  final DateTime endsAt;
  final int total;
  final BookingStatus status;
  final String? reason;
  final String userId;
  final String user;
  final DateTime createdAt;
  final DateTime? cancelledAt;
  final String? cancelledByName;

  /// The space or its venue is no longer active: the booking stays in the history (FA8).
  final bool spaceDeactivated;

  /// Active and not started yet, by the server clock: only then voiding is offered.
  final bool voidable;

  /// How the notice of the voiding reached whoever booked (`enviada`, `sin_permiso`,
  /// `sin_canal` or `fallida`) and when; `null` if there was no notice or it has not
  /// gone out yet.
  final String? noticeDelivery;
  final DateTime? noticeAt;
}
