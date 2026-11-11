// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import '../../../api/api_client.dart';
import '../../../common/field_errors.dart';
import '../../session/domain/session_exceptions.dart';
import '../../session/domain/token_source.dart';
import '../domain/space.dart';
import '../domain/space_exceptions.dart';

/// The sports spaces, read, created, edited and deactivated in the API with the open
/// session.
class SpacesRepository {
  SpacesRepository({required ApiClient api, required TokenSource session})
    : _api = api,
      _session = session;

  final ApiClient _api;
  final TokenSource _session;
  Catalog? _catalog;

  Future<ApiResponse> _get(String path) async {
    final r = await _api.get(path, token: await _session.token());
    if (r.code == 401) throw const SessionExpired();
    return r;
  }

  /// The catalog of sports and types; it is requested once per app session.
  ///
  /// Throws [SessionExpired], [NoConnection] or [ServerError].
  Future<Catalog> catalog() async {
    final cached = _catalog;
    if (cached != null) return cached;
    final r = await _get('/spaces/catalog');
    final parsed = r.code == 200 ? Catalog.fromJson(r.body) : null;
    if (parsed == null) throw ServerError(r.code);
    return _catalog = parsed;
  }

  /// The active spaces by venue, sport, type and number; only those of [venueId], [sport]
  /// and [kind] if requested.
  ///
  /// Throws [SessionExpired], [NoConnection] or [ServerError].
  Future<List<Space>> active({
    String? venueId,
    String? sport,
    String? kind,
  }) async {
    final filters = {'venue_id': ?venueId, 'sport': ?sport, 'kind': ?kind};
    final query = Uri(
      path: '/spaces',
      queryParameters: filters.isEmpty ? null : filters,
    );
    final r = await _get(query.toString());
    final parsed = r.code == 200 ? Space.listFromBody(r.body) : null;
    if (parsed != null) return parsed;
    throw ServerError(r.code);
  }

  /// The name and the number the next space of that type at that venue would have.
  ///
  /// Throws [SpaceRejected], [SessionExpired], [NoConnection] or [ServerError].
  Future<(String, int)> suggestedName({
    required String venueId,
    required String sport,
    required String kind,
  }) async {
    final query = Uri(
      path: '/spaces/name',
      queryParameters: {'venue_id': venueId, 'sport': sport, 'kind': kind},
    );
    final r = await _get(query.toString());
    if (r.code == 422) throw SpaceRejected(fieldErrors(r.body));
    if (r.body case {
      'name': final String n,
      'number': final int number,
    } when r.code == 200) {
      return (n, number);
    }
    throw ServerError(r.code);
  }

  /// Creates the space with the [number] the administrator saw.
  ///
  /// Throws [NameTaken], [SpaceRejected], [SessionExpired], [NoConnection] or
  /// [ServerError].
  Future<Space> create({
    required String venueId,
    required String sport,
    required String kind,
    required bool covered,
    required bool lit,
    required int pricePerHour,
    required int number,
  }) async {
    final r = await _api.post('/spaces', {
      'venue_id': venueId,
      'sport': sport,
      'kind': kind,
      'covered': covered,
      'lit': lit,
      'price_per_hour': pricePerHour,
      'number': number,
    }, token: await _session.token());
    if (r.code == 401) throw const SessionExpired();
    if (r.code == 409) {
      if (r.body case {'name': final String name, 'number': final int next}) {
        if (fieldErrors(r.body)['name'] case final message?) {
          throw NameTaken(message, name, next);
        }
      }
    }
    if (r.code == 422) {
      final errors = fieldErrors(r.body);
      if (errors.isNotEmpty) throw SpaceRejected(errors);
    }
    final space = r.code == 201 ? Space.fromJson(r.body) : null;
    if (space == null) throw ServerError(r.code);
    return space;
  }

  /// Saves what changed of the condition, the lighting and the price of the space [id].
  ///
  /// Throws [SpaceUnavailable], [SpaceRejected], [SessionExpired], [NoConnection] or
  /// [ServerError].
  Future<Space> update(
    String id, {
    bool? covered,
    bool? lit,
    int? pricePerHour,
  }) async {
    // Only what changed: the rest stays as whoever saved last left it.
    final r = await _api.put('/spaces/$id', {
      'covered': ?covered,
      'lit': ?lit,
      'price_per_hour': ?pricePerHour,
    }, token: await _session.token());
    if (r.code == 401) throw const SessionExpired();
    if (r.code == 404) throw const SpaceUnavailable();
    if (r.code == 422) {
      final errors = fieldErrors(r.body);
      if (errors.isNotEmpty) throw SpaceRejected(errors);
    }
    final space = r.code == 200 ? Space.fromJson(r.body) : null;
    if (space == null) throw ServerError(r.code);
    return space;
  }

  /// Deactivates the space [id].
  ///
  /// Throws [SpaceUnavailable], [SpaceHasBookings], [SessionExpired], [NoConnection] or
  /// [ServerError].
  Future<void> deactivate(String id) async {
    final r = await _api.delete('/spaces/$id', token: await _session.token());
    if (r.code == 401) throw const SessionExpired();
    if (r.code == 404) throw const SpaceUnavailable();
    if (r.code == 409) throw const SpaceHasBookings();
    if (r.code != 204) throw ServerError(r.code);
  }
}
