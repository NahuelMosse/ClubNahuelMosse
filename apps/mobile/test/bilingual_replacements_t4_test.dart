import 'package:clubnahuelmosse/features/notifications/domain/notification_kind.dart';
import 'package:clubnahuelmosse/features/session/domain/role.dart';
import 'package:flutter_test/flutter_test.dart';

// Replaces the Role and NotificationKind test of account_in_english_test.dart (card
// ENG-19, Log L4): the interface labels left the domain and live in the .arb files.
void main() {
  test(
    'Role y NotificationKind muestran su label en castellano y leen el valor de la API de siempre @assumption:ENG-11-ASM-01',
    () {
      expect(Role.fromApi('usuario'), Role.user);
      expect(Role.fromApi('admin'), Role.admin);
      expect(Role.fromApi('otro'), isNull);
      expect(Role.user.apiValue, 'usuario');
      expect(Role.admin.apiValue, 'admin');
      expect(
        NotificationKind.fromApi('recordatorio'),
        NotificationKind.reminder,
      );
      expect(
        NotificationKind.fromApi('cancelacion_forzosa'),
        NotificationKind.forcedCancellation,
      );
      expect(
        NotificationKind.fromApi('cancelacion_usuario'),
        NotificationKind.userCancellation,
      );
      expect(NotificationKind.fromApi('x'), isNull);
      expect(NotificationKind.userCancellation.apiValue, 'cancelacion_usuario');
    },
  );
}
