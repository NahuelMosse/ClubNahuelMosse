import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// No se llegó a la API: sin red, o la API no responde a tiempo.
class SinConexion implements Exception {
  const SinConexion();
}

/// La API respondió con un error propio (5xx) o con algo que no es la API.
class ErrorDelServidor implements Exception {
  const ErrorDelServidor(this.codigo, {this.mensaje, this.referencia});
  final int codigo;

  /// Lo que el servidor dice a la persona: sólo viene con un 429 (demasiados intentos).
  final String? mensaje;

  /// El número con el que se encuentra este error en el registro de la API.
  final String? referencia;
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

class ClienteApi {
  ClienteApi(
    String base, {
    http.Client? cliente,
    this.limite = const Duration(seconds: 60),
    this.avisoDespuesDe = const Duration(seconds: 5),
  }) : _base = Uri.parse(base),
       _cliente = cliente ?? http.Client();

  final Uri _base;
  final http.Client _cliente;

  /// Cuánto espera una respuesta antes de rendirse: una API gratuita tarda hasta un minuto
  /// en despertar.
  final Duration limite;

  /// Cuánto tarda un pedido antes de que [despertando] se encienda.
  final Duration avisoDespuesDe;

  final _despertando = ValueNotifier<bool>(false);

  /// `true` mientras algún pedido lleva más de [avisoDespuesDe] sin respuesta.
  ValueListenable<bool> get despertando => _despertando;

  var _lentos = 0;

  Future<Respuesta> post(
    String ruta,
    Map<String, Object?> cuerpo, {
    String? token,
  }) => _enviar(
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
    () => _cliente.delete(
      _base.resolve(ruta),
      headers: {'authorization': 'Bearer $token'},
    ),
  );

  /// [token] es el ID token de Firebase de quien inició sesión.
  Future<Respuesta> get(String ruta, {String? token}) => _enviar(
    () => _cliente.get(
      _base.resolve(ruta),
      headers: {if (token != null) 'authorization': 'Bearer $token'},
    ),
  );

  Future<Respuesta> _enviar(Future<http.Response> Function() pedido) async {
    final http.Response r;
    var lento = false;
    final aviso = Timer(avisoDespuesDe, () {
      lento = true;
      _despertando.value = ++_lentos > 0;
    });
    try {
      r = await pedido().timeout(limite);
    } on TimeoutException {
      throw const ServidorSinRespuesta();
    } on Exception {
      // Sin red, DNS, TLS o la conexión cortada.
      throw const SinConexion();
    } finally {
      aviso.cancel();
      if (lento) _despertando.value = --_lentos > 0;
    }
    if (r.statusCode >= 500) {
      throw ErrorDelServidor(r.statusCode, referencia: _referencia(r));
    }
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

  static String? _referencia(http.Response r) {
    try {
      final datos = jsonDecode(utf8.decode(r.bodyBytes));
      final referencia = datos is Map ? datos['referencia'] : null;
      return referencia is String && referencia.isNotEmpty ? referencia : null;
    } on FormatException {
      return null;
    }
  }

  void cerrar() => _cliente.close();
}
