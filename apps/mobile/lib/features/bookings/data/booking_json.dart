import '../../../common/club_timezone.dart';
import '../domain/booking.dart';
import '../domain/booking_status.dart';

/// The booking in [json]; `null` if it is not one.
Booking? bookingFromJson(Object? json) {
  if (json case {
    'id': final String id,
    'espacio_id': final String spaceId,
    'sede_id': final String venueId,
    'espacio': final String space,
    'deporte': final String sport,
    'tipo': final String kind,
    'sede': final String venue,
    'direccion': final String address,
    'inicio': final String startsAt,
    'fin': final String endsAt,
    'total': final int total,
    'estado': final String status,
    'motivo': final Object? reason,
  }) {
    final start = _inClubTime(startsAt);
    final end = _inClubTime(endsAt);
    final parsedStatus = BookingStatus.fromApi(status);
    if (start == null || end == null || parsedStatus == null) return null;
    return Booking(
      id: id,
      spaceId: spaceId,
      venueId: venueId,
      space: space,
      sport: sport,
      kind: kind,
      venue: venue,
      address: address,
      startsAt: start,
      endsAt: end,
      total: total,
      status: parsedStatus,
      reason: reason is String ? reason : null,
      cancelable: json['cancelable'] == true,
    );
  }
  return null;
}

DateTime? _inClubTime(String iso) {
  final moment = DateTime.tryParse(iso);
  return moment == null ? null : toClubTime(moment);
}
