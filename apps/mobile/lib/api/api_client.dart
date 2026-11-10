// kit-shape: a screen or error family kept with its private parts.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_routes.dart';

/// Un pedido a la API que falló sin que la persona tenga la culpa: [NoConnection] o
/// [ServerError]. Se atrapa con `on FalloDeRed` donde ambos se tratan igual.
abstract interface class NetworkFailure implements Exception {}

/// No se llegó a la API: sin red, o la API no responde a tiempo.
class NoConnection implements NetworkFailure {
  const NoConnection();
}

/// La API respondió con un error propio (5xx) o con algo que no es la API.
class ServerError implements NetworkFailure {
  const ServerError(this.code, {this.message});
  final int code;

  /// Lo que el servidor dice a la persona: sólo viene con un 429 (demasiados intentos).
  final String? message;
}

/// El pedido salió pero la API no contestó dentro del límite. Es un error del servidor, no
/// de la red de la persona: lo atrapan donde se atrapa [ServerError].
class ServerNotResponding extends ServerError {
  const ServerNotResponding() : super(0);
}

/// Una respuesta de la API con su código y su cuerpo JSON ya leído.
class ApiResponse {
  const ApiResponse(this.code, this.body);
  final int code;
  final Map<String, Object?> body;
}

class ApiClient {
  ApiClient(
    String base, {
    http.Client? client,
    this.limit = const Duration(seconds: 30),
    this.verifyRoutes = kDebugMode,
  }) : _base = Uri.parse(base),
       _client = client ?? http.Client();

  final Uri _base;
  final http.Client _client;

  /// Si pedir una ruta que la app no declara en [apiRoutes] falla. Es así en debug,
  /// así lo vigilan todos los tests; en release el pedido sale igual.
  final bool verifyRoutes;

  void _declared(String method, String route) {
    if (verifyRoutes && !isRouteDeclared(method, route)) {
      throw AssertionError(
        'La app no declara pedir $method $route (lib/api/api_routes.dart)',
      );
    }
  }

  /// Cuánto espera una respuesta antes de rendirse.
  final Duration limit;

  Future<ApiResponse> post(
    String route,
    Map<String, Object?> body, {
    String? token,
  }) => _send(
    'POST',
    route,
    () => _client.post(
      _base.resolve(route),
      headers: {
        'content-type': 'application/json',
        if (token != null) 'authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    ),
  );

  Future<ApiResponse> put(
    String route,
    Map<String, Object?> body, {
    String? token,
  }) => _send(
    'PUT',
    route,
    () => _client.put(
      _base.resolve(route),
      headers: {
        'content-type': 'application/json',
        if (token != null) 'authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    ),
  );

  Future<ApiResponse> delete(String route, {required String token}) => _send(
    'DELETE',
    route,
    () => _client.delete(
      _base.resolve(route),
      headers: {'authorization': 'Bearer $token'},
    ),
  );

  /// [token] es el ID token de Firebase de quien inició sesión.
  Future<ApiResponse> get(String route, {String? token}) => _send(
    'GET',
    route,
    () => _client.get(
      _base.resolve(route),
      headers: {if (token != null) 'authorization': 'Bearer $token'},
    ),
  );

  Future<ApiResponse> _send(
    String method,
    String route,
    Future<http.Response> Function() request,
  ) async {
    _declared(method, route);
    final http.Response r;
    try {
      r = await request().timeout(limit);
    } on TimeoutException {
      throw const ServerNotResponding();
    } on Exception {
      // Sin red, DNS, TLS o la conexión cortada.
      throw const NoConnection();
    }
    if (r.statusCode >= 500) throw ServerError(r.statusCode);
    final Object? data;
    try {
      final text = utf8.decode(r.bodyBytes);
      data = text.isEmpty ? null : jsonDecode(text);
    } on FormatException {
      // Respondió algo que no es la API (un proxy, un portal cautivo).
      throw ServerError(r.statusCode);
    }
    final Map<String, Object?> body = data is Map<String, Object?>
        ? data
        : const {};
    if (r.statusCode == 429) {
      final message = body['message'];
      throw ServerError(429, message: message is String ? message : null);
    }
    return ApiResponse(r.statusCode, body);
  }

  void close() => _client.close();
}
