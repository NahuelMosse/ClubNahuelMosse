import 'package:clubnahuelmosse/features/notifications/domain/notification_kind.dart';
import 'package:clubnahuelmosse/features/session/domain/role.dart';
import 'package:flutter_test/flutter_test.dart';

// Replaces the Role and NotificationKind test of account_in_english_test.dart (card
// ENG-19, Log L4): the interface labels left the domain and live in the .arb files.
void main() {
  test(
    'Role and NotificationKind show their Spanish label and read the same API value as always @assumption:ENG-11-ASM-01',
    () {
      expect(Role.fromApi('user'), Role.user);
      expect(Role.fromApi('admin'), Role.admin);
      expect(Role.fromApi('otro'), isNull);
      expect(Role.user.apiValue, 'user');
      expect(Role.admin.apiValue, 'admin');
      expect(NotificationKind.fromApi('reminder'), NotificationKind.reminder);
      expect(
        NotificationKind.fromApi('forced_cancellation'),
        NotificationKind.forcedCancellation,
      );
      expect(
        NotificationKind.fromApi('user_cancellation'),
        NotificationKind.userCancellation,
      );
      expect(NotificationKind.fromApi('x'), isNull);
      expect(NotificationKind.userCancellation.apiValue, 'user_cancellation');
    },
  );
}
