import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// No se llegó a la API: sin red, o la API no responde a tiempo.
class SinConexion implements Exception {
  const SinConexion();
}

/// La API respondió con un error propio (5xx) o con algo que no es la API.
class ErrorDelServidor implements Exception {
  const ErrorDelServidor(this.codigo);
  final int codigo;
}

/// Una respuesta de la API con su código y su cuerpo JSON ya leído.
class Respuesta {
  const Respuesta(this.codigo, this.cuerpo);
  final int codigo;
  final Map<String, Object?> cuerpo;
}

class ClienteApi {
  ClienteApi(String base, {http.Client? cliente})
    : _base = Uri.parse(base),
      _cliente = cliente ?? http.Client();

  final Uri _base;
  final http.Client _cliente;
  static const _limite = Duration(seconds: 15);

  Future<Respuesta> post(String ruta, Map<String, Object?> cuerpo) => _enviar(
    () => _cliente.post(
      _base.resolve(ruta),
      headers: {'content-type': 'application/json'},
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
    try {
      r = await pedido().timeout(_limite);
    } on Exception {
      // Sin red, DNS, TLS, la conexión cortada o la API que no contesta a tiempo.
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
    return Respuesta(
      r.statusCode,
      datos is Map<String, Object?> ? datos : const {},
    );
  }

  void cerrar() => _cliente.close();
}
