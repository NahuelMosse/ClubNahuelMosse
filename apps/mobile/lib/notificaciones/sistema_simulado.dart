import 'package:shared_preferences/shared_preferences.dart';

import 'sistema.dart';

/// El sistema de un dispositivo de prueba, sin Firebase Cloud Messaging.
///
/// La respuesta al permiso la guarda la app en el dispositivo (los escenarios la fijan); sin
/// respuesta guardada, todavía no preguntó. Pedirlo guarda y devuelve la respuesta fijada,
/// concedido si no hay otra. Nada llega por acá: con la app abierta la lista se entera
/// consultando la API.
class SistemaSimulado implements SistemaDeNotificaciones {
  static const _clavePermiso = 'permiso_notificaciones_simulado';
  static const _claveToken = 'token_notificaciones_simulado';

  @override
  String get plataforma => 'android';

  @override
  Future<bool> permitido() async =>
      (await SharedPreferences.getInstance()).getString(_clavePermiso) ==
      'concedido';

  @override
  Future<bool> preguntado() async =>
      (await SharedPreferences.getInstance()).getString(_clavePermiso) != null;

  @override
  Future<bool> solicitarPermiso() async {
    final prefs = await SharedPreferences.getInstance();
    final respuesta = prefs.getString(_clavePermiso) ?? 'concedido';
    await prefs.setString(_clavePermiso, respuesta);
    return respuesta == 'concedido';
  }

  @override
  Future<String?> token() async {
    final prefs = await SharedPreferences.getInstance();
    final guardado = prefs.getString(_claveToken);
    if (guardado != null) return guardado;
    final nuevo = 'simulado-${DateTime.now().microsecondsSinceEpoch}';
    await prefs.setString(_claveToken, nuevo);
    return nuevo;
  }

  @override
  Future<void> olvidarToken() async {
    await (await SharedPreferences.getInstance()).remove(_claveToken);
  }

  @override
  Stream<void> get alLlegar => const Stream.empty();

  @override
  Stream<AvisoTocado> get alTocar => const Stream.empty();

  @override
  Future<AvisoTocado?> abiertaPor() async => null;
}
