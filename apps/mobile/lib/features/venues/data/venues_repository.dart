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
  /// Lanza [SessionExpired], [SinConexion] o [ErrorDelServidor].
  Future<List<Venue>> active() async {
    final r = await _api.get('/sedes', token: await _session.token());
    if (r.codigo == 401) throw const SessionExpired();
    if (r.codigo != 200) throw ErrorDelServidor(r.codigo);
    if (r.cuerpo case {'sedes': final List<Object?> venues}) {
      final parsed = [for (final s in venues) Venue.fromJson(s)];
      if (!parsed.contains(null)) return [...parsed.nonNulls];
    }
    throw ErrorDelServidor(r.codigo);
  }

  /// Da de alta la sede y devuelve la que quedó guardada.
  ///
  /// Lanza [VenueRejected], [SessionExpired], [SinConexion] o [ErrorDelServidor].
  Future<Venue> create({
    required String name,
    required String address,
    required String opening,
    required String closing,
    required List<int> days,
  }) async {
    final r = await _api.post('/sedes', {
      'nombre': name,
      'direccion': address,
      'apertura': opening,
      'cierre': closing,
      'dias': days,
    }, token: await _session.token());
    return _saved(r, 201);
  }

  /// Guarda los datos nuevos de la sede [id] y devuelve cómo quedó. Con [confirm], el
  /// horario se guarda aunque deje afuera reservas futuras.
  ///
  /// Lanza [BookingsOutsideHours], [VenueUnavailable], [VenueRejected], [SessionExpired],
  /// [SinConexion] o [ErrorDelServidor].
  Future<Venue> update(
    String id, {
    required String name,
    required String address,
    required String opening,
    required String closing,
    required List<int> days,
    bool confirm = false,
  }) async {
    final r = await _api.put('/sedes/$id', {
      'nombre': name,
      'direccion': address,
      'apertura': opening,
      'cierre': closing,
      'dias': days,
      'confirmar': confirm,
    }, token: await _session.token());
    if (r.codigo == 404) throw const VenueUnavailable();
    if (r.cuerpo case {
      'reservas_afuera': final int count,
    } when r.codigo == 409) {
      throw BookingsOutsideHours(count);
    }
    return _saved(r, 200);
  }

  /// Da de baja la sede [id] y sus espacios.
  ///
  /// Lanza [VenueUnavailable], [VenueHasBookings], [SessionExpired], [SinConexion] o
  /// [ErrorDelServidor].
  Future<void> deactivate(String id) async {
    final r = await _api.delete('/sedes/$id', token: await _session.token());
    if (r.codigo == 401) throw const SessionExpired();
    if (r.codigo == 404) throw const VenueUnavailable();
    if (r.codigo == 409) throw const VenueHasBookings();
    if (r.codigo != 204) throw ErrorDelServidor(r.codigo);
  }

  Venue _saved(Respuesta r, int success) {
    if (r.codigo == 401) throw const SessionExpired();
    if (r.codigo == 409 || r.codigo == 422) {
      final errors = fieldErrors(r.cuerpo);
      if (errors.isNotEmpty) {
        throw VenueRejected(errors, duplicate: r.codigo == 409);
      }
    }
    final venue = r.codigo == success ? Venue.fromJson(r.cuerpo) : null;
    if (venue == null) throw ErrorDelServidor(r.codigo);
    return venue;
  }
}
