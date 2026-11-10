// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import '../../../api/api_client.dart';
import '../../../common/dates.dart';
import '../../../common/field_errors.dart';
import '../../session/domain/session_exceptions.dart';
import '../../session/domain/token_source.dart';
import '../domain/availability_exceptions.dart';
import '../domain/booking.dart';
import '../domain/booking_choice.dart';
import '../domain/booking_exceptions.dart';
import 'booking_json.dart';

/// The bookings of the signed-in person, read and written through the API.
class BookingsApi {
  BookingsApi({required ApiClient api, required TokenSource session})
    : _api = api,
      _session = session;

  final ApiClient _api;
  final TokenSource _session;

  /// All the upcoming ones (nearest first) or the whole history (most recent first).
  ///
  /// Throws [SesionVencida], [NoConnection] or [ServerError].
  Future<List<Booking>> mine({required bool history}) async {
    final when = history ? 'history' : 'upcoming';
    final r = await _api.get(
      '/bookings?when=$when',
      token: await _session.token(),
    );
    if (r.code == 401) throw const SessionExpired();
    if (r.code == 200) {
      if (r.body case {'bookings': final List<Object?> list}) {
        final read = [for (final e in list) bookingFromJson(e)];
        if (!read.contains(null)) return [...read.nonNulls];
      }
    }
    throw ServerError(r.code);
  }

  /// Books what was chosen on the availability screen.
  ///
  /// Throws [SlotTaken], [SpaceUnavailable], [BookingRejected], [SesionVencida],
  /// [NoConnection] or [ServerError].
  Future<Booking> book(BookingChoice choice) async {
    final r = await _api.post('/bookings', {
      'space_id': choice.space.id,
      'date': isoDate(choice.date),
      'start_hour': choice.start,
      'hours': choice.hours,
    }, token: await _session.token());
    if (r.code == 401) throw const SessionExpired();
    if (r.code == 409) throw const SlotTaken();
    final errors = fieldErrors(r.body);
    if (r.code == 422 && errors.isNotEmpty) {
      if (errors.containsKey('space_id')) throw const SpaceUnavailable();
      throw BookingRejected(errors);
    }
    final booking = r.code == 201 ? bookingFromJson(r.body) : null;
    if (booking == null) throw ServerError(r.code);
    return booking;
  }

  /// Cancels [booking]; the slot becomes free again.
  ///
  /// Throws [BookingChanged], [SesionVencida], [NoConnection] or [ServerError].
  Future<Booking> cancel(Booking booking) async {
    final r = await _api.post(
      '/bookings/${booking.id}/cancel',
      const {},
      token: await _session.token(),
    );
    if (r.code == 401) throw const SessionExpired();
    if (r.code == 404 || r.code == 409) throw const BookingChanged();
    final canceled = r.code == 200 ? bookingFromJson(r.body) : null;
    if (canceled == null) throw ServerError(r.code);
    return canceled;
  }

  /// Moves [booking] to the space, day and hour of [next], with the same duration.
  ///
  /// Throws [SlotTaken], [BookingChanged], [SpaceUnavailable], [BookingRejected],
  /// [SesionVencida], [NoConnection] or [ServerError].
  Future<Booking> modify(Booking booking, BookingChoice next) async {
    final r = await _api.post('/bookings/${booking.id}/modify', {
      'space_id': next.space.id,
      'date': isoDate(next.date),
      'start_hour': next.start,
    }, token: await _session.token());
    if (r.code == 401) throw const SessionExpired();
    if (r.code == 404) throw const BookingChanged();
    final errors = fieldErrors(r.body);
    if (errors.isNotEmpty) {
      if (r.code == 409) {
        throw errors.containsKey('slot')
            ? const SlotTaken()
            : const BookingChanged();
      }
      if (r.code == 422) {
        if (errors.containsKey('space_id')) throw const SpaceUnavailable();
        throw BookingRejected(errors);
      }
    }
    final modified = r.code == 200 ? bookingFromJson(r.body) : null;
    if (modified == null) throw ServerError(r.code);
    return modified;
  }
}
