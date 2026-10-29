import 'dart:async';

import 'package:clubnahuelmosse/features/notifications/data/simulated_notification_system.dart';
import 'package:clubnahuelmosse/features/notifications/presentation/fcm_notification_system.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notifications_spanish_test.dart' show ApiFalsa, SistemaFalso, centroDe;
import 'soporte/montar.dart';

/// Un sistema que no contestó la pregunta del permiso hasta que el test lo decide.
class SistemaQueDemora extends SistemaFalso {
  SistemaQueDemora() : super(concedido: false);

  final respuesta = Completer<bool>();

  @override
  Future<bool> wasAsked() async => false;

  @override
  Future<bool> requestPermission() {
    solicitudes++;
    return respuesta.future;
  }
}

/// Firebase Messaging con el estado de permiso que fija el test.
class MensajeriaFalsa implements FirebaseMessaging {
  MensajeriaFalsa(this.estado);

  final AuthorizationStatus estado;

  @override
  Future<NotificationSettings> getNotificationSettings() async =>
      NotificationSettings(
        alert: AppleNotificationSetting.notSupported,
        announcement: AppleNotificationSetting.notSupported,
        authorizationStatus: estado,
        badge: AppleNotificationSetting.notSupported,
        carPlay: AppleNotificationSetting.notSupported,
        lockScreen: AppleNotificationSetting.notSupported,
        notificationCenter: AppleNotificationSetting.notSupported,
        showPreviews: AppleShowPreviewSetting.notSupported,
        timeSensitive: AppleNotificationSetting.notSupported,
        criticalAlert: AppleNotificationSetting.notSupported,
        sound: AppleNotificationSetting.notSupported,
        providesAppNotificationSettings: AppleNotificationSetting.notSupported,
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'con Firebase, el permiso cuenta como preguntado sólo después de que el sistema tiene una respuesta @NOT-01-S2',
    () async {
      expect(
        await FcmNotificationSystem(
          MensajeriaFalsa(AuthorizationStatus.notDetermined),
        ).wasAsked(),
        isFalse,
      );
      expect(
        await FcmNotificationSystem(
          MensajeriaFalsa(AuthorizationStatus.denied),
        ).wasAsked(),
        isTrue,
      );
      expect(
        await FcmNotificationSystem(
          MensajeriaFalsa(AuthorizationStatus.authorized),
        ).wasAsked(),
        isTrue,
      );
    },
  );

  test(
    'el sistema simulado conserva el token del teléfono entre pedidos @NOT-01-S1',
    () async {
      SharedPreferences.setMockInitialValues({});
      final sistema = SimulatedNotificationSystem();
      final primero = await sistema.token();
      expect(primero, isNotNull);
      expect(await sistema.token(), primero);
    },
  );

  testWidgets(
    'si la app se cierra mientras el sistema pregunta el permiso, no registra el teléfono @NOT-01-S1',
    (tester) async {
      final api = ApiFalsa();
      final sistema = SistemaQueDemora();
      final centro = centroDe(
        api,
        SesionFalsa(perfilUsuario),
        sistema: sistema,
      );
      await tester.pump();
      expect(sistema.solicitudes, 1);

      centro.dispose();
      sistema.respuesta.complete(true);
      await tester.pumpAndSettle();

      expect(api.de('PUT', '/dispositivos'), isEmpty);
    },
  );
}
