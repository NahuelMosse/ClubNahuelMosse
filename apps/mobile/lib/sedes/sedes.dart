import 'package:flutter/foundation.dart';

import '../api/cliente_api.dart';
import '../comun/errores_de_campo.dart';
import '../sesion/sesion.dart';
import 'sede.dart';

/// La API rechazó la sede: cada campo con su mensaje.
class SedeRechazada implements Exception {
  const SedeRechazada(this.errores, {this.repetido = false});
  final Map<String, String> errores;

  /// Otra sede activa ya tiene ese nombre (409), no es un problema de formato.
  final bool repetido;
}

/// La sede ya no está activa: la dio de baja otra sesión.
class SedeNoDisponible implements Exception {
  const SedeNoDisponible();
}

/// La sede tiene reservas activas que todavía no terminaron: no se da de baja.
class SedeConReservas implements Exception {
  const SedeConReservas();
}

/// El horario nuevo deja afuera [cantidad] reservas futuras: hay que confirmarlo.
class ReservasAfuera implements Exception {
  const ReservasAfuera(this.cantidad);
  final int cantidad;
}

/// Las sedes del club, leídas, dadas de alta y editadas en la API con la sesión abierta.
/// Avisa a quien escucha cada vez que una cambia.
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
    return _guardada(r, 201);
  }

  /// Guarda los datos nuevos de la sede [id] y devuelve cómo quedó. Con [confirmar], el
  /// horario se guarda aunque deje afuera reservas futuras.
  ///
  /// Lanza [ReservasAfuera], [SedeNoDisponible], [SedeRechazada], [SesionVencida],
  /// [SinConexion] o [ErrorDelServidor].
  Future<Sede> editar(
    String id, {
    required String nombre,
    required String direccion,
    required String apertura,
    required String cierre,
    required List<int> dias,
    bool confirmar = false,
  }) async {
    final r = await _api.put('/sedes/$id', {
      'nombre': nombre,
      'direccion': direccion,
      'apertura': apertura,
      'cierre': cierre,
      'dias': dias,
      'confirmar': confirmar,
    }, token: await _sesion.token());
    if (r.codigo == 404) throw const SedeNoDisponible();
    if (r.cuerpo case {
      'reservas_afuera': final int cantidad,
    } when r.codigo == 409) {
      throw ReservasAfuera(cantidad);
    }
    return _guardada(r, 200);
  }

  /// Da de baja la sede [id] y sus espacios.
  ///
  /// Lanza [SedeNoDisponible], [SedeConReservas], [SesionVencida], [SinConexion] o
  /// [ErrorDelServidor].
  Future<void> darDeBaja(String id) async {
    final r = await _api.delete('/sedes/$id', token: await _sesion.token());
    if (r.codigo == 401) throw const SesionVencida();
    if (r.codigo == 404) throw const SedeNoDisponible();
    if (r.codigo == 409) throw const SedeConReservas();
    if (r.codigo != 204) throw ErrorDelServidor(r.codigo);
    notifyListeners();
  }

  Sede _guardada(Respuesta r, int exito) {
    if (r.codigo == 401) throw const SesionVencida();
    if (r.codigo == 409 || r.codigo == 422) {
      final errores = erroresDeCampo(r.cuerpo);
      if (errores.isNotEmpty) {
        throw SedeRechazada(errores, repetido: r.codigo == 409);
      }
    }
    final sede = r.codigo == exito ? Sede.desdeJson(r.cuerpo) : null;
    if (sede == null) throw ErrorDelServidor(r.codigo);
    notifyListeners();
    return sede;
  }

  /// Avisa que lo que se vio de las sedes ya no vale (por ejemplo, una que se dio de baja):
  /// quien las muestra las vuelve a pedir.
  void avisarCambio() => notifyListeners();
}
