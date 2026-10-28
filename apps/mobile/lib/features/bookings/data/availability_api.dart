import '../../../api/api_client.dart';
import '../../../common/dates.dart';
import '../../../common/field_errors.dart';
import '../../session/domain/session_exceptions.dart';
import '../../session/domain/token_source.dart';
import '../../spaces/domain/space.dart';
import '../domain/availability_exceptions.dart';
import '../domain/availability_grid.dart';
import 'availability_json.dart';

/// The availability of the spaces, read from the API with the session open.
class AvailabilityApi {
  AvailabilityApi({required ApiClient api, required TokenSource sesion})
    : _api = api,
      _sesion = sesion;

  final ApiClient _api;
  final TokenSource _sesion;

  /// Reads [query] with the session token; a 401 is an expired session.
  Future<Respuesta> _fetch(Uri query) async {
    final r = await _api.get(query.toString(), token: await _sesion.token());
    if (r.codigo == 401) throw const SessionExpired();
    return r;
  }

  /// The grid of space [spaceId] for [date] (today if absent) with slots of [hours].
  ///
  /// Throws [SpaceUnavailable], [DateExpired], [SesionVencida], [SinConexion] or
  /// [ErrorDelServidor].
  ///
  /// [bookingId] is the booking being modified: it does not count as taken.
  Future<AvailabilityGrid> grid(
    String spaceId, {
    DateTime? date,
    int hours = 1,
    String? bookingId,
  }) async {
    final day = date;
    final query = Uri(
      path: '/espacios/$spaceId/horarios',
      queryParameters: {
        'horas': '$hours',
        'reserva_id': ?bookingId,
        if (day != null) 'fecha': isoDate(day),
      },
    );
    final r = await _fetch(query);
    final errors = fieldErrors(r.cuerpo);
    if (r.codigo == 404 && errors.containsKey('espacio_id')) {
      throw const SpaceUnavailable();
    }
    if (r.codigo == 422 && errors.containsKey('fecha')) {
      throw const DateExpired();
    }
    final grid = r.codigo == 200 ? availabilityGridFromJson(r.cuerpo) : null;
    if (grid == null) throw ErrorDelServidor(r.codigo);
    return grid;
  }

  /// The spaces of [venueId] and [sport] (and [kind] if present) free for the whole range
  /// [from] to [to] (`HH:MM`) on [date].
  ///
  /// Throws [RangeRejected], [SesionVencida], [SinConexion] or [ErrorDelServidor].
  Future<List<Space>> freeSpaces({
    required String venueId,
    required String sport,
    String? kind,
    required DateTime date,
    required String from,
    required String to,
  }) async {
    final query = Uri(
      path: '/espacios/disponibles',
      queryParameters: {
        'sede_id': venueId,
        'deporte': sport,
        'tipo': ?kind,
        'fecha': isoDate(date),
        'desde': from,
        'hasta': to,
      },
    );
    final r = await _fetch(query);
    final errors = fieldErrors(r.cuerpo);
    if (r.codigo == 422 && errors.isNotEmpty) throw RangeRejected(errors);
    final found = r.codigo == 200 ? Space.listFromBody(r.cuerpo) : null;
    if (found != null) return found;
    throw ErrorDelServidor(r.codigo);
  }
}
