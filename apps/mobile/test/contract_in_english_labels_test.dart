import 'dart:convert';
import 'dart:io';

import 'package:clubnahuelmosse/features/bookings/domain/booking_status.dart';
import 'package:clubnahuelmosse/features/notifications/domain/notification_kind.dart';
import 'package:clubnahuelmosse/features/session/domain/role.dart';
import 'package:flutter_test/flutter_test.dart';

// The interface words of each value live in the .arb files (ENG-19): the Spanish catalog
// keeps the words people read while the API values are English.
Map<String, Object?> _spanish() =>
    jsonDecode(File('lib/l10n/app_es.arb').readAsStringSync())
        as Map<String, Object?>;

void main() {
  test(
    'each booking status, role and notification kind shows the same Spanish word as before @ENG-18-S10 @assumption:ENG-18-ASM-07',
    () {
      final spanish = _spanish();
      expect(
        {
          for (final s in BookingStatus.values)
            s.apiValue:
                spanish['bookingStatus${s.name[0].toUpperCase()}${s.name.substring(1)}'],
        },
        {
          'active': 'Activa',
          'completed': 'Completada',
          'canceled': 'Cancelada',
          'voided': 'Anulada',
        },
      );
      expect(Role.values.map((r) => r.apiValue), ['user', 'admin']);
      expect(
        NotificationKind.values.map((k) => k.apiValue),
        containsAll([
          'forced_cancellation',
          'reminder',
          'five_minute_reminder',
          'user_cancellation',
        ]),
      );
    },
  );
}
