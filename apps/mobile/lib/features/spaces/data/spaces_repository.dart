import '../../../api/api_client.dart';
import '../../../common/field_errors.dart';
import '../../session/domain/session_exceptions.dart';
import '../../session/domain/token_source.dart';
import '../domain/space.dart';
import '../domain/space_exceptions.dart';

/// Los espacios deportivos, leídos, dados de alta, editados y dados de baja en la API
/// con la sesión abierta.
class SpacesRepository {
  SpacesRepository({required ApiClient api, required TokenSource session})
    : _api = api,
      _session = session;

  final ApiClient _api;
  final TokenSource _session;
  Catalog? _catalog;

  Future<Respuesta> _get(String path) async {
    final r = await _api.get(path, token: await _session.token());
    if (r.codigo == 401) throw const SessionExpired();
    return r;
  }

  /// El catálogo de deportes y tipos; se pide una vez por sesión de la app.
  ///
  /// Lanza [SessionExpired], [SinConexion] o [ErrorDelServidor].
  Future<Catalog> catalog() async {
    final cached = _catalog;
    if (cached != null) return cached;
    final r = await _get('/espacios/catalogo');
    final parsed = r.codigo == 200 ? Catalog.fromJson(r.cuerpo) : null;
    if (parsed == null) throw ErrorDelServidor(r.codigo);
    return _catalog = parsed;
  }

  /// Los espacios activos por sede, deporte, tipo y número; sólo los de [venueId],
  /// [sport] y [kind] si se piden.
  ///
  /// Lanza [SessionExpired], [SinConexion] o [ErrorDelServidor].
  Future<List<Space>> active({
    String? venueId,
    String? sport,
    String? kind,
  }) async {
    final filters = {'sede_id': ?venueId, 'deporte': ?sport, 'tipo': ?kind};
    final query = Uri(
      path: '/espacios',
      queryParameters: filters.isEmpty ? null : filters,
    );
    final r = await _get(query.toString());
    final parsed = r.codigo == 200 ? Space.listFromBody(r.cuerpo) : null;
    if (parsed != null) return parsed;
    throw ErrorDelServidor(r.codigo);
  }

  /// El nombre y el número que tendría el próximo espacio de ese tipo en esa sede.
  ///
  /// Lanza [SpaceRejected], [SessionExpired], [SinConexion] o [ErrorDelServidor].
  Future<(String, int)> suggestedName({
    required String venueId,
    required String sport,
    required String kind,
  }) async {
    final query = Uri(
      path: '/espacios/nombre',
      queryParameters: {'sede_id': venueId, 'deporte': sport, 'tipo': kind},
    );
    final r = await _get(query.toString());
    if (r.codigo == 422) throw SpaceRejected(fieldErrors(r.cuerpo));
    if (r.cuerpo case {
      'nombre': final String n,
      'numero': final int number,
    } when r.codigo == 200) {
      return (n, number);
    }
    throw ErrorDelServidor(r.codigo);
  }

  /// Da de alta el espacio con el [number] que vio el administrador.
  ///
  /// Lanza [NameTaken], [SpaceRejected], [SessionExpired], [SinConexion] o
  /// [ErrorDelServidor].
  Future<Space> create({
    required String venueId,
    required String sport,
    required String kind,
    required bool covered,
    required bool lit,
    required int pricePerHour,
    required int number,
  }) async {
    final r = await _api.post('/espacios', {
      'sede_id': venueId,
      'deporte': sport,
      'tipo': kind,
      'techada': covered,
      'iluminada': lit,
      'precio_por_hora': pricePerHour,
      'numero': number,
    }, token: await _session.token());
    if (r.codigo == 401) throw const SessionExpired();
    if (r.codigo == 409) {
      if (r.cuerpo case {
        'nombre': final String name,
        'numero': final int next,
      }) {
        if (fieldErrors(r.cuerpo)['nombre'] case final message?) {
          throw NameTaken(message, name, next);
        }
      }
    }
    if (r.codigo == 422) {
      final errors = fieldErrors(r.cuerpo);
      if (errors.isNotEmpty) throw SpaceRejected(errors);
    }
    final space = r.codigo == 201 ? Space.fromJson(r.cuerpo) : null;
    if (space == null) throw ErrorDelServidor(r.codigo);
    return space;
  }

  /// Guarda lo que cambió de la condición, la iluminación y el precio del espacio [id].
  ///
  /// Lanza [SpaceUnavailable], [SpaceRejected], [SessionExpired], [SinConexion] o
  /// [ErrorDelServidor].
  Future<Space> update(
    String id, {
    bool? covered,
    bool? lit,
    int? pricePerHour,
  }) async {
    // Sólo lo que cambió: lo demás queda como lo haya guardado quien guardó último.
    final r = await _api.put('/espacios/$id', {
      'techada': ?covered,
      'iluminada': ?lit,
      'precio_por_hora': ?pricePerHour,
    }, token: await _session.token());
    if (r.codigo == 401) throw const SessionExpired();
    if (r.codigo == 404) throw const SpaceUnavailable();
    if (r.codigo == 422) {
      final errors = fieldErrors(r.cuerpo);
      if (errors.isNotEmpty) throw SpaceRejected(errors);
    }
    final space = r.codigo == 200 ? Space.fromJson(r.cuerpo) : null;
    if (space == null) throw ErrorDelServidor(r.codigo);
    return space;
  }

  /// Da de baja el espacio [id].
  ///
  /// Lanza [SpaceUnavailable], [SpaceHasBookings], [SessionExpired], [SinConexion] o
  /// [ErrorDelServidor].
  Future<void> deactivate(String id) async {
    final r = await _api.delete('/espacios/$id', token: await _session.token());
    if (r.codigo == 401) throw const SessionExpired();
    if (r.codigo == 404) throw const SpaceUnavailable();
    if (r.codigo == 409) throw const SpaceHasBookings();
    if (r.codigo != 204) throw ErrorDelServidor(r.codigo);
  }
}
