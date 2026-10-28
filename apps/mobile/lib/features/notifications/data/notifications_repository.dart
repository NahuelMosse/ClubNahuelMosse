import '../../../api/api_client.dart';
import '../../session/domain/session_exceptions.dart';
import '../../session/domain/token_source.dart';
import '../domain/app_notification.dart';
import '../domain/center_reading.dart';

/// Las notificaciones y los dispositivos de quien inició sesión, en la API.
class NotificationsRepository {
  NotificationsRepository({
    required ApiClient api,
    required TokenSource session,
  }) : _api = api,
       _session = session;

  final ApiClient _api;
  final TokenSource _session;

  /// Lanza [SessionExpired], [SinConexion] o [ErrorDelServidor].
  Future<CenterReading> center() async {
    final r = await _api.get('/notificaciones', token: await _session.token());
    if (r.codigo == 401) throw const SessionExpired();
    if (r.codigo == 200) {
      if (r.cuerpo case {
        'notificaciones': final List<Object?> list,
        'no_leidas': final int unread,
      }) {
        final parsed = [for (final e in list) AppNotification.fromJson(e)];
        if (!parsed.contains(null)) {
          return CenterReading([...parsed.nonNulls], unread);
        }
      }
    }
    throw ErrorDelServidor(r.codigo);
  }

  /// Lanza [SessionExpired], [SinConexion] o [ErrorDelServidor].
  Future<void> read(String id) async {
    final r = await _api.post(
      '/notificaciones/$id/leer',
      const {},
      token: await _session.token(),
    );
    _expect204(r);
  }

  /// Lanza [SessionExpired], [SinConexion] o [ErrorDelServidor].
  Future<void> readAll() async {
    final r = await _api.post(
      '/notificaciones/leer-todas',
      const {},
      token: await _session.token(),
    );
    _expect204(r);
  }

  /// Le dice a la API que este teléfono recibe los avisos de la cuenta, con el permiso que
  /// le dio al sistema operativo.
  ///
  /// Lanza [SessionExpired], [SinConexion] o [ErrorDelServidor].
  Future<void> registerDevice({
    required String token,
    required String platform,
    required bool permission,
  }) async {
    final r = await _api.put('/dispositivos', {
      'token': token,
      'plataforma': platform,
      'permiso': permission,
    }, token: await _session.token());
    _expect204(r);
  }

  /// Este teléfono deja de recibir los avisos de la cuenta.
  ///
  /// Lanza [SessionExpired], [SinConexion] o [ErrorDelServidor].
  ///
  /// [session] es el token de la sesión que se está cerrando, tomado antes de que se cierre.
  Future<void> unregisterDevice(String token, {required String session}) async {
    final r = await _api.post('/dispositivos/baja', {
      'token': token,
    }, token: session);
    _expect204(r);
  }

  void _expect204(Respuesta r) {
    if (r.codigo == 401) throw const SessionExpired();
    if (r.codigo != 204) throw ErrorDelServidor(r.codigo);
  }
}
