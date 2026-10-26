import 'package:flutter/foundation.dart';

import '../api/cliente_api.dart';
import '../comun/errores_de_campo.dart';
import '../sesion/sesion.dart';
import 'espacio.dart';

/// El espacio o su sede ya no están activos: los dio de baja otra sesión.
class EspacioNoDisponible implements Exception {
  const EspacioNoDisponible();
}

/// El espacio tiene reservas activas que todavía no terminaron: no se da de baja.
class EspacioConReservas implements Exception {
  const EspacioConReservas();
}

/// La API rechazó el espacio: cada campo con su mensaje.
class EspacioRechazado implements Exception {
  const EspacioRechazado(this.errores);
  final Map<String, String> errores;
}

/// El número que se mostraba ya lo tomó otro alta; [nombre] y [numero] son los siguientes.
class NombreOcupado implements Exception {
  const NombreOcupado(this.mensaje, this.nombre, this.numero);
  final String mensaje;
  final String nombre;
  final int numero;
}

/// Los espacios deportivos, leídos, dados de alta, editados y dados de baja en la API
/// con la sesión abierta. Avisa a quien escucha cada vez que uno cambia.
class Espacios extends ChangeNotifier {
  Espacios({required ClienteApi api, required Sesion sesion})
    : _api = api,
      _sesion = sesion;

  final ClienteApi _api;
  final Sesion _sesion;
  Catalogo? _catalogo;

  Future<Respuesta> _get(String ruta) async {
    final r = await _api.get(ruta, token: await _sesion.token());
    if (r.codigo == 401) throw const SesionVencida();
    return r;
  }

  /// El catálogo de deportes y tipos; se pide una vez por sesión de la app.
  ///
  /// Lanza [SesionVencida], [SinConexion] o [ErrorDelServidor].
  Future<Catalogo> catalogo() async {
    final guardado = _catalogo;
    if (guardado != null) return guardado;
    final r = await _get('/espacios/catalogo');
    final leido = r.codigo == 200 ? Catalogo.desdeJson(r.cuerpo) : null;
    if (leido == null) throw ErrorDelServidor(r.codigo);
    return _catalogo = leido;
  }

  /// Los espacios activos por sede, deporte, tipo y número; sólo los de [sedeId],
  /// [deporte] y [tipo] si se piden.
  ///
  /// Lanza [SesionVencida], [SinConexion] o [ErrorDelServidor].
  Future<List<Espacio>> activos({
    String? sedeId,
    String? deporte,
    String? tipo,
  }) async {
    final filtros = {
      'sede_id': ?sedeId,
      'deporte': ?deporte,
      'tipo': ?tipo,
    };
    final consulta = Uri(
      path: '/espacios',
      queryParameters: filtros.isEmpty ? null : filtros,
    );
    final r = await _get(consulta.toString());
    final leidos = r.codigo == 200 ? Espacio.listaDesdeCuerpo(r.cuerpo) : null;
    if (leidos != null) return leidos;
    throw ErrorDelServidor(r.codigo);
  }

  /// El nombre y el número que tendría el próximo espacio de ese tipo en esa sede.
  ///
  /// Lanza [EspacioRechazado], [SesionVencida], [SinConexion] o [ErrorDelServidor].
  Future<(String, int)> nombreSugerido({
    required String sedeId,
    required String deporte,
    required String tipo,
  }) async {
    final consulta = Uri(
      path: '/espacios/nombre',
      queryParameters: {'sede_id': sedeId, 'deporte': deporte, 'tipo': tipo},
    );
    final r = await _get(consulta.toString());
    if (r.codigo == 422) throw EspacioRechazado(erroresDeCampo(r.cuerpo));
    if (r.cuerpo case {
      'nombre': final String n,
      'numero': final int numero,
    } when r.codigo == 200) {
      return (n, numero);
    }
    throw ErrorDelServidor(r.codigo);
  }

  /// Da de alta el espacio con el [numero] que vio el administrador.
  ///
  /// Lanza [NombreOcupado], [EspacioRechazado], [SesionVencida], [SinConexion] o
  /// [ErrorDelServidor].
  Future<Espacio> darDeAlta({
    required String sedeId,
    required String deporte,
    required String tipo,
    required bool techada,
    required bool iluminada,
    required int precioPorHora,
    required int numero,
  }) async {
    final r = await _api.post('/espacios', {
      'sede_id': sedeId,
      'deporte': deporte,
      'tipo': tipo,
      'techada': techada,
      'iluminada': iluminada,
      'precio_por_hora': precioPorHora,
      'numero': numero,
    }, token: await _sesion.token());
    if (r.codigo == 401) throw const SesionVencida();
    if (r.codigo == 409) {
      if (r.cuerpo case {
        'nombre': final String nombre,
        'numero': final int siguiente,
      }) {
        if (erroresDeCampo(r.cuerpo)['nombre'] case final mensaje?) {
          throw NombreOcupado(mensaje, nombre, siguiente);
        }
      }
    }
    if (r.codigo == 422) {
      final errores = erroresDeCampo(r.cuerpo);
      if (errores.isNotEmpty) throw EspacioRechazado(errores);
    }
    final espacio = r.codigo == 201 ? Espacio.desdeJson(r.cuerpo) : null;
    if (espacio == null) throw ErrorDelServidor(r.codigo);
    notifyListeners();
    return espacio;
  }

  /// Guarda lo que cambió de la condición, la iluminación y el precio del espacio [id].
  ///
  /// Lanza [EspacioNoDisponible], [EspacioRechazado], [SesionVencida], [SinConexion] o
  /// [ErrorDelServidor].
  Future<Espacio> editar(
    String id, {
    bool? techada,
    bool? iluminada,
    int? precioPorHora,
  }) async {
    // Sólo lo que cambió: lo demás queda como lo haya guardado quien guardó último.
    final r = await _api.put('/espacios/$id', {
      'techada': ?techada,
      'iluminada': ?iluminada,
      'precio_por_hora': ?precioPorHora,
    }, token: await _sesion.token());
    if (r.codigo == 401) throw const SesionVencida();
    if (r.codigo == 404) throw const EspacioNoDisponible();
    if (r.codigo == 422) {
      final errores = erroresDeCampo(r.cuerpo);
      if (errores.isNotEmpty) throw EspacioRechazado(errores);
    }
    final espacio = r.codigo == 200 ? Espacio.desdeJson(r.cuerpo) : null;
    if (espacio == null) throw ErrorDelServidor(r.codigo);
    notifyListeners();
    return espacio;
  }

  /// Da de baja el espacio [id].
  ///
  /// Lanza [EspacioNoDisponible], [EspacioConReservas], [SesionVencida], [SinConexion] o
  /// [ErrorDelServidor].
  Future<void> darDeBaja(String id) async {
    final r = await _api.delete('/espacios/$id', token: await _sesion.token());
    if (r.codigo == 401) throw const SesionVencida();
    if (r.codigo == 404) throw const EspacioNoDisponible();
    if (r.codigo == 409) throw const EspacioConReservas();
    if (r.codigo != 204) throw ErrorDelServidor(r.codigo);
    notifyListeners();
  }

  /// Avisa que lo que se vio de los espacios ya no vale (por ejemplo, uno que se dio de
  /// baja): quien los muestra los vuelve a pedir.
  void avisarCambio() => notifyListeners();
}
