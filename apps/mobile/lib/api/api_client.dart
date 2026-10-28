import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'rutas.dart';

/// Un pedido a la API que falló sin que la persona tenga la culpa: [SinConexion] o
/// [ErrorDelServidor]. Se atrapa con `on FalloDeRed` donde ambos se tratan igual.
abstract interface class FalloDeRed implements Exception {}

/// No se llegó a la API: sin red, o la API no responde a tiempo.
class SinConexion implements FalloDeRed {
  const SinConexion();
}

/// La API respondió con un error propio (5xx) o con algo que no es la API.
class ErrorDelServidor implements FalloDeRed {
  const ErrorDelServidor(this.codigo, {this.mensaje});
  final int codigo;

  /// Lo que el servidor dice a la persona: sólo viene con un 429 (demasiados intentos).
  final String? mensaje;
}

/// El pedido salió pero la API no contestó dentro del límite. Es un error del servidor, no
/// de la red de la persona: lo atrapan donde se atrapa [ErrorDelServidor].
class ServidorSinRespuesta extends ErrorDelServidor {
  const ServidorSinRespuesta() : super(0);
}

/// Una respuesta de la API con su código y su cuerpo JSON ya leído.
class Respuesta {
  const Respuesta(this.codigo, this.cuerpo);
  final int codigo;
  final Map<String, Object?> cuerpo;
}

class ApiClient {
  ApiClient(
    String base, {
    http.Client? cliente,
    this.limite = const Duration(seconds: 30),
    this.verificarRutas = kDebugMode,
  }) : _base = Uri.parse(base),
       _cliente = cliente ?? http.Client();

  final Uri _base;
  final http.Client _cliente;

  /// Si pedir una ruta que la app no declara en [rutasDeLaApi] falla. Es así en debug,
  /// así lo vigilan todos los tests; en release el pedido sale igual.
  final bool verificarRutas;

  void _declarada(String metodo, String ruta) {
    if (verificarRutas && !rutaDeclarada(metodo, ruta)) {
      throw AssertionError(
        'La app no declara pedir $metodo $ruta (lib/api/rutas.dart)',
      );
    }
  }

  /// Cuánto espera una respuesta antes de rendirse.
  final Duration limite;

  Future<Respuesta> post(
    String ruta,
    Map<String, Object?> cuerpo, {
    String? token,
  }) => _enviar(
    'POST',
    ruta,
    () => _cliente.post(
      _base.resolve(ruta),
      headers: {
        'content-type': 'application/json',
        if (token != null) 'authorization': 'Bearer $token',
      },
      body: jsonEncode(cuerpo),
    ),
  );

  Future<Respuesta> put(
    String ruta,
    Map<String, Object?> cuerpo, {
    String? token,
  }) => _enviar(
    'PUT',
    ruta,
    () => _cliente.put(
      _base.resolve(ruta),
      headers: {
        'content-type': 'application/json',
        if (token != null) 'authorization': 'Bearer $token',
      },
      body: jsonEncode(cuerpo),
    ),
  );

  Future<Respuesta> delete(String ruta, {required String token}) => _enviar(
    'DELETE',
    ruta,
    () => _cliente.delete(
      _base.resolve(ruta),
      headers: {'authorization': 'Bearer $token'},
    ),
  );

  /// [token] es el ID token de Firebase de quien inició sesión.
  Future<Respuesta> get(String ruta, {String? token}) => _enviar(
    'GET',
    ruta,
    () => _cliente.get(
      _base.resolve(ruta),
      headers: {if (token != null) 'authorization': 'Bearer $token'},
    ),
  );

  Future<Respuesta> _enviar(
    String metodo,
    String ruta,
    Future<http.Response> Function() pedido,
  ) async {
    _declarada(metodo, ruta);
    final http.Response r;
    try {
      r = await pedido().timeout(limite);
    } on TimeoutException {
      throw const ServidorSinRespuesta();
    } on Exception {
      // Sin red, DNS, TLS o la conexión cortada.
      throw const SinConexion();
    }
    if (r.statusCode >= 500) throw ErrorDelServidor(r.statusCode);
    final Object? datos;
    try {
      final texto = utf8.decode(r.bodyBytes);
      datos = texto.isEmpty ? null : jsonDecode(texto);
    } on FormatException {
      // Respondió algo que no es la API (un proxy, un portal cautivo).
      throw ErrorDelServidor(r.statusCode);
    }
    final Map<String, Object?> cuerpo = datos is Map<String, Object?>
        ? datos
        : const {};
    if (r.statusCode == 429) {
      final mensaje = cuerpo['mensaje'];
      throw ErrorDelServidor(429, mensaje: mensaje is String ? mensaje : null);
    }
    return Respuesta(r.statusCode, cuerpo);
  }

  void cerrar() => _cliente.close();
}
