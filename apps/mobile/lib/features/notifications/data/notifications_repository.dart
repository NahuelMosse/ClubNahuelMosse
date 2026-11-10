// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import '../../../api/api_client.dart';
import '../../session/domain/session_exceptions.dart';
import '../../session/domain/token_source.dart';
import '../domain/app_notification.dart';
import '../domain/center_reading.dart';

/// The notifications and the devices of whoever signed in, in the API.
class NotificationsRepository {
  NotificationsRepository({
    required ApiClient api,
    required TokenSource session,
  }) : _api = api,
       _session = session;

  final ApiClient _api;
  final TokenSource _session;

  /// Lanza [SessionExpired], [NoConnection] o [ServerError].
  Future<CenterReading> center() async {
    final r = await _api.get('/notifications', token: await _session.token());
    if (r.code == 401) throw const SessionExpired();
    if (r.code == 200) {
      if (r.body case {
        'notifications': final List<Object?> list,
        'unread': final int unread,
      }) {
        final parsed = [for (final e in list) AppNotification.fromJson(e)];
        if (!parsed.contains(null)) {
          return CenterReading([...parsed.nonNulls], unread);
        }
      }
    }
    throw ServerError(r.code);
  }

  /// Lanza [SessionExpired], [NoConnection] o [ServerError].
  Future<void> read(String id) async {
    final r = await _api.post(
      '/notifications/$id/read',
      const {},
      token: await _session.token(),
    );
    _expect204(r);
  }

  /// Lanza [SessionExpired], [NoConnection] o [ServerError].
  Future<void> readAll() async {
    final r = await _api.post(
      '/notifications/read-all',
      const {},
      token: await _session.token(),
    );
    _expect204(r);
  }

  /// Tells the API that this phone receives the account's notices, with the permission it
  /// gave the operating system.
  ///
  /// Throws [SessionExpired], [NoConnection] or [ServerError].
  Future<void> registerDevice({
    required String token,
    required String platform,
    required bool permission,
  }) async {
    final r = await _api.put('/devices', {
      'token': token,
      'platform': platform,
      'permission_granted': permission,
    }, token: await _session.token());
    _expect204(r);
  }

  /// This phone stops receiving the account's notices.
  ///
  /// Throws [SessionExpired], [NoConnection] or [ServerError].
  ///
  /// [session] is the token of the session being closed, taken before it closes.
  Future<void> unregisterDevice(String token, {required String session}) async {
    final r = await _api.post('/devices/unregister', {
      'token': token,
    }, token: session);
    _expect204(r);
  }

  void _expect204(ApiResponse r) {
    if (r.code == 401) throw const SessionExpired();
    if (r.code != 204) throw ServerError(r.code);
  }
}
