// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
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
    if (status != null) 'status=${status.apiValue}',
    if (filters.venueId != null) 'venue_id=${filters.venueId}',
    if (sport != null) 'sport=${Uri.encodeQueryComponent(sport)}',
    if (since != null) 'since=${isoDate(since)}',
    if (until != null) 'until=${isoDate(until)}',
    if (search != null) 'q=${Uri.encodeQueryComponent(search)}',
  ];
  return parts.join('&');
}

/// The global booking history (CU-14), for an administrator only.
class BookingHistory {
  BookingHistory({required ApiClient api, required TokenSource session})
    : _api = api,
      _session = session;

  final ApiClient _api;
  final TokenSource _session;

  /// The page [page] (starts at 1) that satisfies [filters].
  ///
  /// Throws [SesionVencida], [NoConnection] or [ServerError].
  Future<HistoryPage> page(HistoryFilters filters, {int page = 1}) async {
    final query = [
      _query(filters),
      'page=$page',
    ].where((s) => s.isNotEmpty).join('&');
    final r = await _api.get(
      '/bookings/all?$query',
      token: await _session.token(),
    );
    if (r.code == 401) throw const SessionExpired();
    if (r.code == 200) {
      if (r.body case {
        'bookings': final List<Object?> list,
        'total': final int total,
        'page': final int pageNumber,
        'per_page': final int perPage,
        'counters': final Object? countersJson,
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
    throw ServerError(r.code);
  }

  /// The detail of any booking by [id]. `null` if it no longer exists.
  ///
  /// Throws [SesionVencida], [NoConnection] or [ServerError].
  Future<BookingHistoryEntry?> detail(String id) async {
    final r = await _api.get(
      '/bookings/all/$id',
      token: await _session.token(),
    );
    if (r.code == 401) throw const SessionExpired();
    if (r.code == 404) return null;
    if (r.code == 200) {
      final parsed = parseBookingHistoryEntry(r.body);
      if (parsed != null) return parsed;
    }
    throw ServerError(r.code);
  }

  /// Voids [booking] with [reason], as the administrator saw it (court and time); the
  /// time slot becomes free again. Repeating a request that was already made answers
  /// the same.
  ///
  /// Throws [BookingChanged], [ReservaRechazada], [SesionVencida], [NoConnection] or
  /// [ServerError].
  Future<BookingHistoryEntry> voidBooking(
    BookingHistoryEntry booking,
    String reason,
  ) async {
    final r = await _api.post('/bookings/${booking.id}/void', {
      'reason': reason,
      'space_id': booking.spaceId,
      'starts_at': fromClubTime(booking.startsAt).toIso8601String(),
    }, token: await _session.token());
    if (r.code == 401) throw const SessionExpired();
    if (r.code == 404 || r.code == 409) throw const BookingChanged();
    final errors = fieldErrors(r.body);
    if (r.code == 422 && errors.isNotEmpty) throw BookingRejected(errors);
    final voided = r.code == 200 ? parseBookingHistoryEntry(r.body) : null;
    if (voided == null) throw ServerError(r.code);
    return voided;
  }
}
