import 'package:flutter/foundation.dart';

import '../api/cliente_api.dart';
import '../sesion/sesion.dart';
import 'sede.dart';

/// La API rechazó la sede: cada campo con su mensaje.
class SedeRechazada implements Exception {
  const SedeRechazada(this.errores, {this.repetido = false});
  final Map<String, String> errores;

  /// Otra sede activa ya tiene ese nombre (409), no es un problema de formato.
  final bool repetido;
}

/// Las sedes del club, leídas y dadas de alta en la API con la sesión abierta. Avisa a
/// quien escucha cada vez que se da de alta una.
class Sedes extends ChangeNotifier {
  Sedes({required ClienteApi api, required Sesion sesion})
    : _api = api,
      _sesion = sesion;

  final ClienteApi _api;
  final Sesion _sesion;

  /// Las sedes activas, por nombre.
  ///
  /// Lanza [SesionVencida], [SinConexion] o [ErrorDelServidor].
  Future<List<Sede>> activas() async {
    final r = await _api.get('/sedes', token: await _sesion.token());
    if (r.codigo == 401) throw const SesionVencida();
    if (r.codigo != 200) throw ErrorDelServidor(r.codigo);
    if (r.cuerpo case {'sedes': final List<Object?> sedes}) {
      final leidas = [for (final s in sedes) Sede.desdeJson(s)];
      if (!leidas.contains(null)) return [...leidas.nonNulls];
    }
    throw ErrorDelServidor(r.codigo);
  }

  /// Da de alta la sede y devuelve la que quedó guardada.
  ///
  /// Lanza [SedeRechazada], [SesionVencida], [SinConexion] o [ErrorDelServidor].
  Future<Sede> darDeAlta({
    required String nombre,
    required String direccion,
    required String apertura,
    required String cierre,
    required List<int> dias,
  }) async {
    final r = await _api.post('/sedes', {
      'nombre': nombre,
      'direccion': direccion,
      'apertura': apertura,
      'cierre': cierre,
      'dias': dias,
    }, token: await _sesion.token());
    if (r.codigo == 401) throw const SesionVencida();
    if (r.codigo == 409 || r.codigo == 422) {
      final errores = switch (r.cuerpo['errores']) {
        final Map<String, Object?> mapa => {
          for (final MapEntry(:key, :value) in mapa.entries)
            if (value is String) key: value,
        },
        _ => const <String, String>{},
      };
      if (errores.isNotEmpty) {
        throw SedeRechazada(errores, repetido: r.codigo == 409);
      }
    }
    final sede = r.codigo == 201 ? Sede.desdeJson(r.cuerpo) : null;
    if (sede == null) throw ErrorDelServidor(r.codigo);
    notifyListeners();
    return sede;
  }

  /// Avisa que lo que se vio de las sedes ya no vale (por ejemplo, una que se dio de baja):
  /// quien las muestra las vuelve a pedir.
  void avisarCambio() => notifyListeners();
}
