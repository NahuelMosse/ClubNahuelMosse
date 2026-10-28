import '../../../common/club_timezone.dart';
import '../../bookings/domain/booking_status.dart';
import '../domain/booking_history_entry.dart';
import '../domain/counters.dart';

Counters? parseCounters(Object? json) => switch (json) {
  {
    'todas': final int all,
    'activas': final int active,
    'completadas': final int completed,
    'anuladas': final int voided,
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
    'espacio_id': final String spaceId,
    'sede_id': final String venueId,
    'espacio': final String space,
    'deporte': final String sport,
    'tipo': final String type,
    'sede': final String venue,
    'direccion': final String address,
    'inicio': final String startsAt,
    'fin': final String endsAt,
    'total': final int total,
    'estado': final String status,
    'motivo': final Object? reason,
    'usuario_id': final String userId,
    'usuario': final String user,
    'creado_en': final String createdAt,
    'cancelada_en': final Object? cancelledAt,
    'cancelada_por_nombre': final Object? cancelledByName,
    'espacio_de_baja': final bool spaceDeactivated,
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
      voidable: json['anulable'] == true,
      noticeDelivery: json['aviso_envio'] is String
          ? json['aviso_envio'] as String
          : null,
      noticeAt: json['aviso_en'] is String
          ? _inClubTime(json['aviso_en'] as String)
          : null,
    );
  }
  return null;
}
