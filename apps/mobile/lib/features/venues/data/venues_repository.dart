// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import '../../../api/api_client.dart';
import '../../../common/field_errors.dart';
import '../../session/domain/session_exceptions.dart';
import '../../session/domain/token_source.dart';
import '../domain/venue.dart';
import '../domain/venue_exceptions.dart';

/// The venues of the club, read, created and edited in the API with the open session.
class VenuesRepository {
  VenuesRepository({required ApiClient api, required TokenSource session})
    : _api = api,
      _session = session;

  final ApiClient _api;
  final TokenSource _session;

  /// The active venues, by name.
  ///
  /// Throws [SessionExpired], [NoConnection] or [ServerError].
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

  /// Creates the venue and returns the one that was saved.
  ///
  /// Throws [VenueRejected], [SessionExpired], [NoConnection] or [ServerError].
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

  /// Saves the new data of the venue [id] and returns how it ended up. With [confirm],
  /// the schedule is saved even if it leaves future bookings outside.
  ///
  /// Throws [BookingsOutsideHours], [VenueUnavailable], [VenueRejected],
  /// [SessionExpired], [NoConnection] or [ServerError].
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

  /// Deactivates the venue [id] and its spaces.
  ///
  /// Throws [VenueUnavailable], [VenueHasBookings], [SessionExpired], [NoConnection] or
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
