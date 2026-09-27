import 'dart:convert';
import 'dart:io';

import 'package:clubnahuelmosse/configuracion.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

enum EstadoApi { normal, sinRed, falla }

/// Una API intermedia en el mismo dispositivo que la app: reenvía a la API de la corrida
/// hasta que el escenario la corta o la hace fallar. Sirve para simular que la red o el
/// servidor se caen después de iniciar sesión.
class ApiIntermedia {
  ApiIntermedia._(this._servidor, this._destino) {
    _servidor.listen(_atender);
  }

  static Future<ApiIntermedia> abrir() async {
    final servidor = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final api = ApiIntermedia._(
      servidor,
      Uri.parse(Configuracion.desdeEntorno().apiUrl),
    );
    addTearDown(() => servidor.close(force: true));
    return api;
  }

  final HttpServer _servidor;
  final Uri _destino;
  final _cliente = HttpClient();
  EstadoApi estado = EstadoApi.normal;

  String get url => 'http://127.0.0.1:${_servidor.port}';

  Future<void> _atender(HttpRequest pedido) async {
    switch (estado) {
      case EstadoApi.sinRed:
        // La conexión se corta sin respuesta, como cuando se va la señal.
        final socket = await pedido.response.detachSocket(writeHeaders: false);
        socket.destroy();
      case EstadoApi.falla:
        pedido.response.statusCode = HttpStatus.internalServerError;
        await pedido.response.close();
      case EstadoApi.normal:
        final reenvio = await _cliente.openUrl(
          pedido.method,
          _destino.replace(
            path: pedido.uri.path,
            query: pedido.uri.hasQuery ? pedido.uri.query : null,
          ),
        );
        pedido.headers.forEach((nombre, valores) {
          if (nombre != HttpHeaders.hostHeader) {
            for (final valor in valores) {
              reenvio.headers.add(nombre, valor);
            }
          }
        });
        await reenvio.addStream(pedido);
        final respuesta = await reenvio.close();
        pedido.response.statusCode = respuesta.statusCode;
        respuesta.headers.forEach((nombre, valores) {
          if (nombre != HttpHeaders.transferEncodingHeader) {
            for (final valor in valores) {
              pedido.response.headers.add(nombre, valor);
            }
          }
        });
        await pedido.response.addStream(respuesta);
        await pedido.response.close();
    }
  }
}

Uri _identidad(String metodo) {
  const emulador = String.fromEnvironment('AUTH_EMULADOR');
  return Uri.parse(
    'http://$emulador/identitytoolkit.googleapis.com/v1/accounts:$metodo'
    '?key=clave-del-emulador',
  );
}

Future<String?> _token(String correo, String contrasena) async {
  final r = await http.post(
    _identidad('signInWithPassword'),
    headers: {'content-type': 'application/json'},
    body: jsonEncode({
      'email': correo,
      'password': contrasena,
      'returnSecureToken': true,
    }),
  );
  if (r.statusCode != 200) return null;
  if (jsonDecode(r.body) case {'idToken': final String token}) return token;
  return null;
}

/// Si esa contraseña sirve hoy para entrar, preguntado a Firebase y no a la app.
Future<bool> puedeEntrar(String correo, String contrasena) async =>
    await _token(correo, contrasena) != null;

/// Cambia la contraseña desde otro dispositivo: Firebase invalida las sesiones abiertas.
Future<void> cambiarDesdeOtroDispositivo(
  String correo,
  String actual,
  String nueva,
) async {
  // Firebase cuenta la revocación por segundos: el token de la app tiene que ser de un
  // segundo anterior al cambio para que quede vencido.
  await Future<void>.delayed(const Duration(milliseconds: 1100));
  final token = await _token(correo, actual);
  if (token == null) throw StateError('la contraseña actual no sirve');
  final r = await http.post(
    _identidad('update'),
    headers: {'content-type': 'application/json'},
    body: jsonEncode({
      'idToken': token,
      'password': nueva,
      'returnSecureToken': true,
    }),
  );
  if (r.statusCode != 200) {
    throw StateError('no se pudo cambiar la contraseña: ${r.statusCode}');
  }
}
