// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import '../../../common/club_timezone.dart';
import '../../bookings/domain/booking_status.dart';
import '../domain/booking_history_entry.dart';
import '../domain/counters.dart';

Counters? parseCounters(Object? json) => switch (json) {
  {
    'all': final int all,
    'active': final int active,
    'completed': final int completed,
    'voided': final int voided,
  } =>
    Counters(all: all, active: active, completed: completed, voided: voided),
  _ => null,
};

DateTime? _inClubTime(String iso) {
  final moment = DateTime.tryParse(iso);
  return moment == null ? null : toClubTime(moment);
}

BookingHistoryEntry? parseBookingHistoryEntry(Object? json) {
  if (json case {
    'id': final String id,
    'space_id': final String spaceId,
    'venue_id': final String venueId,
    'space': final String space,
    'sport': final String sport,
    'kind': final String type,
    'venue': final String venue,
    'address': final String address,
    'starts_at': final String startsAt,
    'ends_at': final String endsAt,
    'total': final int total,
    'status': final String status,
    'reason': final Object? reason,
    'user_id': final String userId,
    'user': final String user,
    'created_at': final String createdAt,
    'canceled_at': final Object? cancelledAt,
    'canceled_by_name': final Object? cancelledByName,
    'space_deactivated': final bool spaceDeactivated,
  }) {
    final start = _inClubTime(startsAt);
    final end = _inClubTime(endsAt);
    final created = _inClubTime(createdAt);
    final matches = BookingStatus.values.where((e) => e.apiValue == status);
    if (start == null || end == null || created == null || matches.isEmpty) {
      return null;
    }
    return BookingHistoryEntry(
      id: id,
      spaceId: spaceId,
      venueId: venueId,
      space: space,
      sport: sport,
      type: type,
      venue: venue,
      address: address,
      startsAt: start,
      endsAt: end,
      total: total,
      status: matches.first,
      reason: reason is String ? reason : null,
      userId: userId,
      user: user,
      createdAt: created,
      cancelledAt: cancelledAt is String ? _inClubTime(cancelledAt) : null,
      cancelledByName: cancelledByName is String ? cancelledByName : null,
      spaceDeactivated: spaceDeactivated,
      voidable: json['voidable'] == true,
      noticeDelivery: json['notice_delivery'] is String
          ? json['notice_delivery'] as String
          : null,
      noticeAt: json['notice_at'] is String
          ? _inClubTime(json['notice_at'] as String)
          : null,
    );
  }
  return null;
}
