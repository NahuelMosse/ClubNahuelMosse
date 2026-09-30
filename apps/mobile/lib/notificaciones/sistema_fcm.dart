import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'sistema.dart';

/// El sistema de notificaciones real: Firebase Cloud Messaging con el proyecto de la
/// configuración. Los avisos llegan por el servicio de Google y los muestra la bandeja del
/// sistema; con la app abierta, [alLlegar] avisa para que se lea el centro.
class SistemaFcm implements SistemaDeNotificaciones {
  SistemaFcm(this._mensajeria);

  final FirebaseMessaging _mensajeria;

  @override
  String get plataforma =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

  static bool _concedido(AuthorizationStatus estado) =>
      estado == AuthorizationStatus.authorized ||
      estado == AuthorizationStatus.provisional;

  @override
  Future<bool> permitido() async => _concedido(
    (await _mensajeria.getNotificationSettings()).authorizationStatus,
  );

  @override
  Future<bool> solicitarPermiso() async =>
      _concedido((await _mensajeria.requestPermission()).authorizationStatus);

  @override
  Future<String?> token() => _mensajeria.getToken();

  static int? _reservaDe(RemoteMessage mensaje) =>
      int.tryParse(mensaje.data['reserva_id']?.toString() ?? '');

  @override
  Stream<int?> get alLlegar => FirebaseMessaging.onMessage.map(_reservaDe);

  @override
  Stream<int?> get alTocar =>
      FirebaseMessaging.onMessageOpenedApp.map(_reservaDe);

  @override
  Future<int?> abiertaPor() async {
    final mensaje = await _mensajeria.getInitialMessage();
    return mensaje == null ? null : _reservaDe(mensaje);
  }
}
