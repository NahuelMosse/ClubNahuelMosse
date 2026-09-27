import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// No se llegó a la API: sin red, o la API no responde a tiempo.
class SinConexion implements Exception {
  const SinConexion();
}

/// La API respondió con un error propio (5xx).
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

  Future<Respuesta> post(String ruta, Map<String, Object?> cuerpo) async {
    final http.Response r;
    try {
      r = await _cliente
          .post(
            _base.resolve(ruta),
            headers: {'content-type': 'application/json'},
            body: jsonEncode(cuerpo),
          )
          .timeout(_limite);
    } on SocketException {
      throw const SinConexion();
    } on http.ClientException {
      throw const SinConexion();
    } on TimeoutException {
      throw const SinConexion();
    }
    if (r.statusCode >= 500) throw ErrorDelServidor(r.statusCode);
    final texto = utf8.decode(r.bodyBytes);
    final datos = texto.isEmpty ? null : jsonDecode(texto);
    return Respuesta(
      r.statusCode,
      datos is Map<String, Object?> ? datos : const {},
    );
  }

  void cerrar() => _cliente.close();
}
