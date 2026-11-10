import 'dart:async';

import 'package:clubnahuelmosse/features/notifications/data/simulated_notification_system.dart';
import 'package:clubnahuelmosse/features/notifications/presentation/fcm_notification_system.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notifications_spanish_test.dart' show FakeApi, FakeSystem, centerOf;
import 'support/mount.dart';

/// A system that has not answered the permission question until the test decides.
class StallingSystem extends FakeSystem {
  StallingSystem() : super(concedido: false);

  final answer = Completer<bool>();

  @override
  Future<bool> wasAsked() async => false;

  @override
  Future<bool> requestPermission() {
    solicitudes++;
    return answer.future;
  }
}

/// Firebase Messaging with the permission status the test sets.
class FakeMessaging implements FirebaseMessaging {
  FakeMessaging(this.status);

  final AuthorizationStatus status;

  @override
  Future<NotificationSettings> getNotificationSettings() async =>
      NotificationSettings(
        alert: AppleNotificationSetting.notSupported,
        announcement: AppleNotificationSetting.notSupported,
        authorizationStatus: status,
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
    'with Firebase, the permission counts as asked only after the system has an answer @NOT-01-S2',
    () async {
      expect(
        await FcmNotificationSystem(
          FakeMessaging(AuthorizationStatus.notDetermined),
        ).wasAsked(),
        isFalse,
      );
      expect(
        await FcmNotificationSystem(
          FakeMessaging(AuthorizationStatus.denied),
        ).wasAsked(),
        isTrue,
      );
      expect(
        await FcmNotificationSystem(
          FakeMessaging(AuthorizationStatus.authorized),
        ).wasAsked(),
        isTrue,
      );
    },
  );

  test(
    'the simulated system keeps the phone token between requests @NOT-01-S1',
    () async {
      SharedPreferences.setMockInitialValues({});
      final system = SimulatedNotificationSystem();
      final first = await system.token();
      expect(first, isNotNull);
      expect(await system.token(), first);
    },
  );

  testWidgets(
    'if the app closes while the system asks for the permission, it does not register the phone @NOT-01-S1',
    (tester) async {
      final api = FakeApi();
      final system = StallingSystem();
      final center = centerOf(api, FakeSession(userProfile), sistema: system);
      await tester.pump();
      expect(system.solicitudes, 1);

      center.dispose();
      system.answer.complete(true);
      await tester.pumpAndSettle();

      expect(api.de('PUT', '/dispositivos'), isEmpty);
    },
  );
}
