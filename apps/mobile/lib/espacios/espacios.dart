import 'package:flutter/foundation.dart';

import '../api/cliente_api.dart';
import '../sesion/sesion.dart';
import 'espacio.dart';

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

/// Los espacios deportivos, leídos y dados de alta en la API con la sesión abierta. Avisa
/// a quien escucha cada vez que se da de alta uno.
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

  /// Los espacios activos, por sede y por nombre.
  ///
  /// Lanza [SesionVencida], [SinConexion] o [ErrorDelServidor].
  Future<List<Espacio>> activos() async {
    final r = await _get('/espacios');
    if (r.codigo == 200) {
      if (r.cuerpo case {'espacios': final List<Object?> lista}) {
        final leidos = [for (final e in lista) Espacio.desdeJson(e)];
        if (!leidos.contains(null)) return [...leidos.nonNulls];
      }
    }
    throw ErrorDelServidor(r.codigo);
  }

  /// El nombre y el número que tendría el próximo espacio de ese tipo en esa sede.
  ///
  /// Lanza [EspacioRechazado], [SesionVencida], [SinConexion] o [ErrorDelServidor].
  Future<(String, int)> nombreSugerido({
    required int sedeId,
    required String deporte,
    required String tipo,
  }) async {
    final consulta = Uri(
      path: '/espacios/nombre',
      queryParameters: {'sede_id': '$sedeId', 'deporte': deporte, 'tipo': tipo},
    );
    final r = await _get(consulta.toString());
    if (r.codigo == 422) throw EspacioRechazado(_errores(r));
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
    required int sedeId,
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
        'errores': {'nombre': final String mensaje},
        'nombre': final String nombre,
        'numero': final int siguiente,
      }) {
        throw NombreOcupado(mensaje, nombre, siguiente);
      }
    }
    if (r.codigo == 422) {
      final errores = _errores(r);
      if (errores.isNotEmpty) throw EspacioRechazado(errores);
    }
    final espacio = r.codigo == 201 ? Espacio.desdeJson(r.cuerpo) : null;
    if (espacio == null) throw ErrorDelServidor(r.codigo);
    notifyListeners();
    return espacio;
  }

  static Map<String, String> _errores(Respuesta r) =>
      switch (r.cuerpo['errores']) {
        final Map<String, Object?> mapa => {
          for (final MapEntry(:key, :value) in mapa.entries)
            if (value is String) key: value,
        },
        _ => const <String, String>{},
      };
}
