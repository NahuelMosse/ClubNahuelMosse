// kit-shape: a screen or error family kept with its private parts.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_routes.dart';

/// A request to the API that failed through no fault of the person: [NoConnection] or
/// [ServerError]. Caught with `on NetworkFailure` where both are treated the same.
abstract interface class NetworkFailure implements Exception {}

/// The API was not reached: no network, or the API does not answer in time.
class NoConnection implements NetworkFailure {
  const NoConnection();
}

/// The API answered with an error of its own (5xx) or with something that is not the API.
class ServerError implements NetworkFailure {
  const ServerError(this.code, {this.message});
  final int code;

  /// What the server tells the person: it only comes with a 429 (too many attempts).
  final String? message;
}

/// The request went out but the API did not answer within the limit. It is a server
/// error, not one of the person's network: it is caught where [ServerError] is caught.
class ServerNotResponding extends ServerError {
  const ServerNotResponding() : super(0);
}

/// A response of the API with its status code and its JSON body already read.
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

  /// Whether asking for a route the app does not declare in [apiRoutes] fails. It does in
  /// debug, so every test watches it; in release the request goes out anyway.
  final bool verifyRoutes;

  void _declared(String method, String route) {
    if (verifyRoutes && !isRouteDeclared(method, route)) {
      throw AssertionError(
        'The app does not declare asking for $method $route (lib/api/api_routes.dart)',
      );
    }
  }

  /// How long it waits for a response before giving up.
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

  /// [token] is the Firebase ID token of whoever signed in.
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
      // No network, DNS, TLS or the connection was cut.
      throw const NoConnection();
    }
    if (r.statusCode >= 500) throw ServerError(r.statusCode);
    final Object? data;
    try {
      final text = utf8.decode(r.bodyBytes);
      data = text.isEmpty ? null : jsonDecode(text);
    } on FormatException {
      // It answered something that is not the API (a proxy, a captive portal).
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
