import '../../../api/api_client.dart';
import '../../../common/club_timezone.dart';
import '../../../common/dates.dart';
import '../../../common/field_errors.dart';
import '../../bookings/domain/booking_exceptions.dart';
import '../../session/domain/session_exceptions.dart';
import '../../session/domain/token_source.dart';
import '../domain/booking_history_entry.dart';
import '../domain/history_filters.dart';
import '../domain/history_page.dart';
import 'booking_history_json.dart';

String _query(HistoryFilters filters) {
  final status = filters.status;
  final sport = filters.sport;
  final since = filters.since;
  final until = filters.until;
  final search = filters.searchText;
  final parts = <String>[
    if (status != null) 'estado=${status.apiValue}',
    if (filters.venueId != null) 'sede_id=${filters.venueId}',
    if (sport != null) 'deporte=${Uri.encodeQueryComponent(sport)}',
    if (since != null) 'desde=${isoDate(since)}',
    if (until != null) 'hasta=${isoDate(until)}',
    if (search != null) 'q=${Uri.encodeQueryComponent(search)}',
  ];
  return parts.join('&');
}

/// The global booking history (CU-14), for an administrator only.
class BookingHistory {
  BookingHistory({required ApiClient api, required TokenSource sesion})
    : _api = api,
      _session = sesion;

  final ApiClient _api;
  final TokenSource _session;

  /// The page [page] (starts at 1) that satisfies [filters].
  ///
  /// Throws [SesionVencida], [SinConexion] or [ErrorDelServidor].
  Future<HistoryPage> page(HistoryFilters filters, {int page = 1}) async {
    final query = [
      _query(filters),
      'pagina=$page',
    ].where((s) => s.isNotEmpty).join('&');
    final r = await _api.get(
      '/reservas/todas?$query',
      token: await _session.token(),
    );
    if (r.codigo == 401) throw const SessionExpired();
    if (r.codigo == 200) {
      if (r.cuerpo case {
        'reservas': final List<Object?> list,
        'total': final int total,
        'pagina': final int pageNumber,
        'por_pagina': final int perPage,
        'contadores': final Object? countersJson,
      }) {
        final parsed = [for (final e in list) parseBookingHistoryEntry(e)];
        final counters = parseCounters(countersJson);
        if (!parsed.contains(null) && counters != null) {
          return HistoryPage(
            bookings: [...parsed.nonNulls],
            total: total,
            page: pageNumber,
            perPage: perPage,
            counters: counters,
          );
        }
      }
    }
    throw ErrorDelServidor(r.codigo);
  }

  /// The detail of any booking by [id]. `null` if it no longer exists.
  ///
  /// Throws [SesionVencida], [SinConexion] or [ErrorDelServidor].
  Future<BookingHistoryEntry?> detail(String id) async {
    final r = await _api.get(
      '/reservas/todas/$id',
      token: await _session.token(),
    );
    if (r.codigo == 401) throw const SessionExpired();
    if (r.codigo == 404) return null;
    if (r.codigo == 200) {
      final parsed = parseBookingHistoryEntry(r.cuerpo);
      if (parsed != null) return parsed;
    }
    throw ErrorDelServidor(r.codigo);
  }

  /// Voids [booking] with [reason], as the administrator saw it (court and time); the
  /// time slot becomes free again. Repeating a request that was already made answers
  /// the same.
  ///
  /// Throws [BookingChanged], [ReservaRechazada], [SesionVencida], [SinConexion] or
  /// [ErrorDelServidor].
  Future<BookingHistoryEntry> voidBooking(
    BookingHistoryEntry booking,
    String reason,
  ) async {
    final r = await _api.post('/reservas/${booking.id}/anular', {
      'motivo': reason,
      'espacio_id': booking.spaceId,
      'inicio': fromClubTime(booking.startsAt).toIso8601String(),
    }, token: await _session.token());
    if (r.codigo == 401) throw const SessionExpired();
    if (r.codigo == 404 || r.codigo == 409) throw const BookingChanged();
    final errors = fieldErrors(r.cuerpo);
    if (r.codigo == 422 && errors.isNotEmpty) throw BookingRejected(errors);
    final voided = r.codigo == 200 ? parseBookingHistoryEntry(r.cuerpo) : null;
    if (voided == null) throw ErrorDelServidor(r.codigo);
    return voided;
  }
}
