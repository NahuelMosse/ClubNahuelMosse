import 'dart:io';

import 'package:clubnahuelmosse/features/notifications/domain/notification_kind.dart';
import 'package:clubnahuelmosse/features/session/domain/role.dart';
import 'package:flutter_test/flutter_test.dart';

Iterable<File> _dartFiles(String dir) => Directory(dir)
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'));

void main() {
  test(
    'los textos, rutas de la API, claves JSON y rutas de pantalla son los de antes @ENG-11-S3 @assumption:ENG-11-ASM-03',
    () {
      final features = _dartFiles(
        'lib/features',
      ).map((f) => f.readAsStringSync()).join('\n');
      for (final path in [
        "'/venues'",
        "'/spaces'",
        "'/me'",
        "'/me/password'",
        "'/notifications'",
        "'/devices'",
      ]) {
        expect(features, contains(path), reason: path);
      }
      for (final key in [
        "'birth_date'",
        "'unread'",
        "'created_at'",
        "'bookings_outside'",
      ]) {
        expect(features, contains(key), reason: key);
      }
      final router = File('lib/router.dart').readAsStringSync();
      for (final route in [
        "'/inicio'",
        "'/sedes",
        "'/notificaciones'",
        "'/perfil'",
      ]) {
        expect(router, contains(route), reason: route);
      }
    },
  );

  test(
    'Role y NotificationKind muestran su label en castellano y leen el valor de la API de siempre @assumption:ENG-11-ASM-01',
    () {
      expect(Role.user.label, 'usuario');
      expect(Role.admin.label, 'admin');
      expect(Role.fromApi('user'), Role.user);
      expect(Role.fromApi('admin'), Role.admin);
      expect(Role.fromApi('usuario'), isNull);
      expect(NotificationKind.reminder.label, 'recordatorio');
      expect(NotificationKind.forcedCancellation.label, 'cancelación del club');
      expect(NotificationKind.userCancellation.label, 'cancelación propia');
      expect(NotificationKind.fromApi('reminder'), NotificationKind.reminder);
      expect(
        NotificationKind.fromApi('forced_cancellation'),
        NotificationKind.forcedCancellation,
      );
      expect(
        NotificationKind.fromApi('user_cancellation'),
        NotificationKind.userCancellation,
      );
      expect(NotificationKind.fromApi('recordatorio'), isNull);
      expect(NotificationKind.userCancellation.apiValue, 'user_cancellation');
    },
  );
}
