import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../domain/notification_system.dart';

/// The real notification system: Firebase Cloud Messaging with the project of the
/// configuration. The notices arrive through Google's service and the system tray shows
/// them; with the app open, [onArrive] reports so the center is read.
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
