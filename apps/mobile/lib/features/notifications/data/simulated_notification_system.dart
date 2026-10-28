import 'package:shared_preferences/shared_preferences.dart';

import '../domain/notification_system.dart';

/// El sistema de un dispositivo de prueba, sin Firebase Cloud Messaging.
///
/// La respuesta al permiso la guarda la app en el dispositivo (los escenarios la fijan); sin
/// respuesta guardada, todavía no preguntó. Pedirlo guarda y devuelve la respuesta fijada,
/// concedido si no hay otra. Nada llega por acá: con la app abierta la lista se entera
/// consultando la API.
class SimulatedNotificationSystem implements NotificationSystem {
  static const _permissionKey = 'permiso_notificaciones_simulado';
  static const _tokenKey = 'token_notificaciones_simulado';

  @override
  String get platform => 'android';

  @override
  Future<bool> isAllowed() async =>
      (await SharedPreferences.getInstance()).getString(_permissionKey) ==
      'concedido';

  @override
  Future<bool> wasAsked() async =>
      (await SharedPreferences.getInstance()).getString(_permissionKey) != null;

  @override
  Future<bool> requestPermission() async {
    final prefs = await SharedPreferences.getInstance();
    final answer = prefs.getString(_permissionKey) ?? 'concedido';
    await prefs.setString(_permissionKey, answer);
    return answer == 'concedido';
  }

  @override
  Future<String?> token() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_tokenKey);
    if (saved != null) return saved;
    final fresh = 'simulado-${DateTime.now().microsecondsSinceEpoch}';
    await prefs.setString(_tokenKey, fresh);
    return fresh;
  }

  @override
  Future<void> forgetToken() async {
    await (await SharedPreferences.getInstance()).remove(_tokenKey);
  }

  @override
  Stream<void> get onArrive => const Stream.empty();

  @override
  Stream<NoticeTapped> get onTap => const Stream.empty();

  @override
  Future<NoticeTapped?> openedBy() async => null;
}
