// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import '../../../api/api_client.dart';
import '../../../common/field_errors.dart';
import '../../session/domain/session_exceptions.dart';
import '../../session/domain/token_source.dart';
import '../domain/venue.dart';
import '../domain/venue_exceptions.dart';

/// Las sedes del club, leídas, dadas de alta y editadas en la API con la sesión abierta.
class VenuesRepository {
  VenuesRepository({required ApiClient api, required TokenSource session})
    : _api = api,
      _session = session;

  final ApiClient _api;
  final TokenSource _session;

  /// Las sedes activas, por nombre.
  ///
  /// Lanza [SessionExpired], [NoConnection] o [ServerError].
  Future<List<Venue>> active() async {
    final r = await _api.get('/venues', token: await _session.token());
    if (r.code == 401) throw const SessionExpired();
    if (r.code != 200) throw ServerError(r.code);
    if (r.body case {'venues': final List<Object?> venues}) {
      final parsed = [for (final s in venues) Venue.fromJson(s)];
      if (!parsed.contains(null)) return [...parsed.nonNulls];
    }
    throw ServerError(r.code);
  }

  /// Da de alta la sede y devuelve la que quedó guardada.
  ///
  /// Lanza [VenueRejected], [SessionExpired], [NoConnection] o [ServerError].
  Future<Venue> create({
    required String name,
    required String address,
    required String opening,
    required String closing,
    required List<int> days,
  }) async {
    final r = await _api.post('/venues', {
      'name': name,
      'address': address,
      'opens_at': opening,
      'closes_at': closing,
      'open_days': days,
    }, token: await _session.token());
    return _saved(r, 201);
  }

  /// Guarda los datos nuevos de la sede [id] y devuelve cómo quedó. Con [confirm], el
  /// horario se guarda aunque deje afuera reservas futuras.
  ///
  /// Lanza [BookingsOutsideHours], [VenueUnavailable], [VenueRejected], [SessionExpired],
  /// [NoConnection] o [ServerError].
  Future<Venue> update(
    String id, {
    required String name,
    required String address,
    required String opening,
    required String closing,
    required List<int> days,
    bool confirm = false,
  }) async {
    final r = await _api.put('/venues/$id', {
      'name': name,
      'address': address,
      'opens_at': opening,
      'closes_at': closing,
      'open_days': days,
      'confirm': confirm,
    }, token: await _session.token());
    if (r.code == 404) throw const VenueUnavailable();
    if (r.body case {'bookings_outside': final int count} when r.code == 409) {
      throw BookingsOutsideHours(count);
    }
    return _saved(r, 200);
  }

  /// Da de baja la sede [id] y sus espacios.
  ///
  /// Lanza [VenueUnavailable], [VenueHasBookings], [SessionExpired], [NoConnection] o
  /// [ServerError].
  Future<void> deactivate(String id) async {
    final r = await _api.delete('/venues/$id', token: await _session.token());
    if (r.code == 401) throw const SessionExpired();
    if (r.code == 404) throw const VenueUnavailable();
    if (r.code == 409) throw const VenueHasBookings();
    if (r.code != 204) throw ServerError(r.code);
  }

  Venue _saved(ApiResponse r, int success) {
    if (r.code == 401) throw const SessionExpired();
    if (r.code == 409 || r.code == 422) {
      final errors = fieldErrors(r.body);
      if (errors.isNotEmpty) {
        throw VenueRejected(errors, duplicate: r.code == 409);
      }
    }
    final venue = r.code == success ? Venue.fromJson(r.body) : null;
    if (venue == null) throw ServerError(r.code);
    return venue;
  }
}
