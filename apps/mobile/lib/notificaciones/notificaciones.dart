import '../api/cliente_api.dart';
import '../sesion/sesion.dart';
import 'notificacion.dart';

/// Lo que devuelve el centro: las últimas notificaciones y cuántas hay sin leer en total.
class LecturaDelCentro {
  const LecturaDelCentro(this.notificaciones, this.noLeidas);
  final List<Notificacion> notificaciones;
  final int noLeidas;
}

/// Las notificaciones y los dispositivos de quien inició sesión, en la API.
class Notificaciones {
  Notificaciones({required ClienteApi api, required Sesion sesion})
    : _api = api,
      _sesion = sesion;

  final ClienteApi _api;
  final Sesion _sesion;

  /// Lanza [SesionVencida], [SinConexion] o [ErrorDelServidor].
  Future<LecturaDelCentro> centro() async {
    final r = await _api.get('/notificaciones', token: await _sesion.token());
    if (r.codigo == 401) throw const SesionVencida();
    if (r.codigo == 200) {
      if (r.cuerpo case {
        'notificaciones': final List<Object?> lista,
        'no_leidas': final int noLeidas,
      }) {
        final leidas = [for (final e in lista) Notificacion.desdeJson(e)];
        if (!leidas.contains(null)) {
          return LecturaDelCentro([...leidas.nonNulls], noLeidas);
        }
      }
    }
    throw ErrorDelServidor(r.codigo);
  }

  /// Lanza [SesionVencida], [SinConexion] o [ErrorDelServidor].
  Future<void> leer(int id) async {
    final r = await _api.post(
      '/notificaciones/$id/leer',
      const {},
      token: await _sesion.token(),
    );
    _esperar204(r);
  }

  /// Lanza [SesionVencida], [SinConexion] o [ErrorDelServidor].
  Future<void> leerTodas() async {
    final r = await _api.post(
      '/notificaciones/leer-todas',
      const {},
      token: await _sesion.token(),
    );
    _esperar204(r);
  }

  /// Le dice a la API que este teléfono recibe los avisos de la cuenta, con el permiso que
  /// le dio al sistema operativo.
  ///
  /// Lanza [SesionVencida], [SinConexion] o [ErrorDelServidor].
  Future<void> registrarDispositivo({
    required String token,
    required String plataforma,
    required bool permiso,
  }) async {
    final r = await _api.put('/dispositivos', {
      'token': token,
      'plataforma': plataforma,
      'permiso': permiso,
    }, token: await _sesion.token());
    _esperar204(r);
  }

  /// Este teléfono deja de recibir los avisos de la cuenta.
  ///
  /// Lanza [SesionVencida], [SinConexion] o [ErrorDelServidor].
  Future<void> darDeBajaDispositivo(String token) async {
    final r = await _api.post('/dispositivos/baja', {
      'token': token,
    }, token: await _sesion.token());
    _esperar204(r);
  }

  void _esperar204(Respuesta r) {
    if (r.codigo == 401) throw const SesionVencida();
    if (r.codigo != 204) throw ErrorDelServidor(r.codigo);
  }
}
