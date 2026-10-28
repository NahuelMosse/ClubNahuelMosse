import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../domain/notification_system.dart';

/// El sistema de notificaciones real: Firebase Cloud Messaging con el proyecto de la
/// configuración. Los avisos llegan por el servicio de Google y los muestra la bandeja del
/// sistema; con la app abierta, [onArrive] avisa para que se lea el centro.
class FcmNotificationSystem implements NotificationSystem {
  FcmNotificationSystem(this._messaging);

  final FirebaseMessaging _messaging;

  @override
  String get platform =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

  static bool _granted(AuthorizationStatus status) =>
      status == AuthorizationStatus.authorized ||
      status == AuthorizationStatus.provisional;

  @override
  Future<bool> isAllowed() async => _granted(
    (await _messaging.getNotificationSettings()).authorizationStatus,
  );

  @override
  Future<bool> wasAsked() async =>
      (await _messaging.getNotificationSettings()).authorizationStatus !=
      AuthorizationStatus.notDetermined;

  @override
  Future<bool> requestPermission() async =>
      _granted((await _messaging.requestPermission()).authorizationStatus);

  @override
  Future<String?> token() => _messaging.getToken();

  @override
  Future<void> forgetToken() => _messaging.deleteToken();

  static NoticeTapped _notice(RemoteMessage message) =>
      NoticeTapped.fromData(message.data);

  @override
  Stream<void> get onArrive => FirebaseMessaging.onMessage;

  @override
  Stream<NoticeTapped> get onTap =>
      FirebaseMessaging.onMessageOpenedApp.map(_notice);

  @override
  Future<NoticeTapped?> openedBy() async {
    final message = await _messaging.getInitialMessage();
    return message == null ? null : _notice(message);
  }
}
