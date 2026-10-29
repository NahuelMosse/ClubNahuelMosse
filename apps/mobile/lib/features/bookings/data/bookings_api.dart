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
  BookingsApi({required ApiClient api, required TokenSource sesion})
    : _api = api,
      _sesion = sesion;

  final ApiClient _api;
  final TokenSource _sesion;

  /// All the upcoming ones (nearest first) or the whole history (most recent first).
  ///
  /// Throws [SesionVencida], [SinConexion] or [ErrorDelServidor].
  Future<List<Booking>> mine({required bool history}) async {
    final when = history ? 'history' : 'upcoming';
    final r = await _api.get(
      '/bookings?when=$when',
      token: await _sesion.token(),
    );
    if (r.codigo == 401) throw const SessionExpired();
    if (r.codigo == 200) {
      if (r.cuerpo case {'bookings': final List<Object?> list}) {
        final read = [for (final e in list) bookingFromJson(e)];
        if (!read.contains(null)) return [...read.nonNulls];
      }
    }
    throw ErrorDelServidor(r.codigo);
  }

  /// Books what was chosen on the availability screen.
  ///
  /// Throws [SlotTaken], [SpaceUnavailable], [BookingRejected], [SesionVencida],
  /// [SinConexion] or [ErrorDelServidor].
  Future<Booking> book(BookingChoice choice) async {
    final r = await _api.post('/bookings', {
      'space_id': choice.space.id,
      'date': isoDate(choice.date),
      'start_hour': choice.start,
      'hours': choice.hours,
    }, token: await _sesion.token());
    if (r.codigo == 401) throw const SessionExpired();
    if (r.codigo == 409) throw const SlotTaken();
    final errors = fieldErrors(r.cuerpo);
    if (r.codigo == 422 && errors.isNotEmpty) {
      if (errors.containsKey('space_id')) throw const SpaceUnavailable();
      throw BookingRejected(errors);
    }
    final booking = r.codigo == 201 ? bookingFromJson(r.cuerpo) : null;
    if (booking == null) throw ErrorDelServidor(r.codigo);
    return booking;
  }

  /// Cancels [booking]; the slot becomes free again.
  ///
  /// Throws [BookingChanged], [SesionVencida], [SinConexion] or [ErrorDelServidor].
  Future<Booking> cancel(Booking booking) async {
    final r = await _api.post(
      '/bookings/${booking.id}/cancel',
      const {},
      token: await _sesion.token(),
    );
    if (r.codigo == 401) throw const SessionExpired();
    if (r.codigo == 404 || r.codigo == 409) throw const BookingChanged();
    final canceled = r.codigo == 200 ? bookingFromJson(r.cuerpo) : null;
    if (canceled == null) throw ErrorDelServidor(r.codigo);
    return canceled;
  }

  /// Moves [booking] to the space, day and hour of [next], with the same duration.
  ///
  /// Throws [SlotTaken], [BookingChanged], [SpaceUnavailable], [BookingRejected],
  /// [SesionVencida], [SinConexion] or [ErrorDelServidor].
  Future<Booking> modify(Booking booking, BookingChoice next) async {
    final r = await _api.post('/bookings/${booking.id}/modify', {
      'space_id': next.space.id,
      'date': isoDate(next.date),
      'start_hour': next.start,
    }, token: await _sesion.token());
    if (r.codigo == 401) throw const SessionExpired();
    if (r.codigo == 404) throw const BookingChanged();
    final errors = fieldErrors(r.cuerpo);
    if (errors.isNotEmpty) {
      if (r.codigo == 409) {
        throw errors.containsKey('slot')
            ? const SlotTaken()
            : const BookingChanged();
      }
      if (r.codigo == 422) {
        if (errors.containsKey('space_id')) throw const SpaceUnavailable();
        throw BookingRejected(errors);
      }
    }
    final modified = r.codigo == 200 ? bookingFromJson(r.cuerpo) : null;
    if (modified == null) throw ErrorDelServidor(r.codigo);
    return modified;
  }
}
