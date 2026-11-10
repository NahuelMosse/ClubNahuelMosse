import 'dart:convert';

import 'package:clubnahuelmosse/features/notifications/data/simulated_notification_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notifications_test.dart'
    show FakeApi, FakeSystem, centerOf, bodyOf;
import 'support/mount.dart';

/// A system that starts without having asked and answers whatever is set when asked.
class UnaskedSystem extends FakeSystem {
  UnaskedSystem({this.answer = true}) : super(granted: false);

  final bool answer;
  bool alreadyAsked = false;

  @override
  Future<bool> wasAsked() async => alreadyAsked;

  @override
  Future<bool> requestPermission() async {
    requests++;
    alreadyAsked = true;
    granted = answer;
    return answer;
  }
}

void main() {
  testWidgets(
    'on entry, if the system has not asked yet, the app requests the permission and registers the phone with the answer @NOT-01-S1 @assumption:NOT-01-ASM-02',
    (tester) async {
      final api = FakeApi();
      final system = UnaskedSystem();
      centerOf(api, FakeSession(userProfile), system: system);
      await tester.pumpAndSettle();

      expect(system.requests, 1);
      final request = bodyOf(api.of('PUT', '/devices').last);
      expect(request['permission_granted'], isTrue);
    },
  );

  testWidgets('if it already answered, it does not ask again on entry @NOT-01-S2', (
    tester,
  ) async {
    final system = UnaskedSystem()..alreadyAsked = true;
    centerOf(FakeApi(), FakeSession(userProfile), system: system);
    await tester.pumpAndSettle();

    expect(system.requests, 0);
  });

  testWidgets(
    'an admin does not get the question on entry @assumption:NOT-01-ASM-01',
    (tester) async {
      final system = UnaskedSystem();
      centerOf(FakeApi(), FakeSession(adminProfile), system: system);
      await tester.pumpAndSettle();

      expect(system.requests, 0);
    },
  );

  testWidgets('«Activar» still asks for the permission @NOT-01-S2', (tester) async {
    final system = UnaskedSystem()..alreadyAsked = true;
    final center = centerOf(
      FakeApi(),
      FakeSession(userProfile),
      system: system,
    );
    await tester.pumpAndSettle();

    await center.enable();

    expect(system.requests, 1);
  });

  testWidgets(
    'if it denies the permission on entry, the phone is registered without permission and not asked again @NOT-01-S1 @NOT-01-S2',
    (tester) async {
      final api = FakeApi();
      final system = UnaskedSystem(answer: false);
      final session = FakeSession(userProfile);
      centerOf(api, session, system: system);
      await tester.pumpAndSettle();

      expect(system.requests, 1);
      final request = bodyOf(api.of('PUT', '/devices').last);
      expect(request['permission_granted'], isFalse);

      centerOf(api, session, system: system);
      await tester.pumpAndSettle();
      expect(system.requests, 1);
      expect(jsonEncode(request), contains('token-del-telefono'));
    },
  );

  test(
    'the simulated system with no saved answer says it has not asked yet, and requesting the permission granted or denied saves it @assumption:NOT-01-ASM-03',
    () async {
      SharedPreferences.setMockInitialValues({});
      var system = SimulatedNotificationSystem();
      expect(await system.wasAsked(), isFalse);
      expect(await system.requestPermission(), isTrue);
      expect(await system.wasAsked(), isTrue);
      expect(await system.isAllowed(), isTrue);

      SharedPreferences.setMockInitialValues({
        'permiso_notificaciones_simulado': 'denegado',
      });
      system = SimulatedNotificationSystem();
      expect(await system.wasAsked(), isTrue);
      expect(await system.isAllowed(), isFalse);
      expect(await system.requestPermission(), isFalse);
      expect(await system.wasAsked(), isTrue);
    },
  );
}
