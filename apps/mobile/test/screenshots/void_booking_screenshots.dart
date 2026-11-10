import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide testWidgets;

import '../support/admin.dart';
import '../support/mount.dart';
import '../support/fixed_clock.dart';

/// Asserts nothing: produces the step-9 strip to compare against the prototype (CU-15).
void main() {
  setUpAll(loadFonts);

  const phones = {'360': Size(360, 800), '430': Size(430, 932)};
  const modes = {'dark': true, 'light': false};

  const bookingJson =
      '{"id": "00000000-0000-7000-8000-000000000001", "space_id": "00000000-0000-7000-8000-000000000009", "venue_id": "00000000-0000-7000-8000-000000000001", "space":'
      ' "Moron_Rivadavia_19850_Futbol_F5_1", "sport": "Futbol", "kind": "F5", "venue":'
      ' "Sede Morón", "address": "Av. Rivadavia 19850", "starts_at":'
      ' "2026-11-12T21:00:00-03:00", "ends_at": "2026-11-12T22:00:00-03:00", "total": 38000,'
      ' "status": "active", "reason": null, "user_id": "00000000-0000-7000-8000-000000000001", "user": "Nahuel Mosse",'
      ' "created_at": "2026-11-02T18:42:00-03:00", "canceled_at": null,'
      ' "canceled_by_name": null, "space_deactivated": false, "voidable": true}';

  Future<void> openConfirmation(
    WidgetTester tester, {
    required bool dark,
    required Size size,
  }) async {
    await mountAdmin(
      tester,
      start: '/admin',
      dark: dark,
      size: size,
      api: apiRoutes({
        'GET /bookings/all': (
          200,
          '{"bookings": [$bookingJson], "total": 1, "page": 1, "per_page": 20,'
              ' "counters": {"all": 1, "active": 1, "completed": 0, "voided": 0}}',
        ),
        'GET /spaces/catalog': (200, catalogJson),
      }),
    );
  }

  Future<void> capture(WidgetTester tester, String file) async {
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile(file));
  }

  for (final MapEntry(key: width, value: size) in phones.entries) {
    for (final MapEntry(key: mode, value: dark) in modes.entries) {
      testWidgets('listing with VOID BOOKING $width $mode', (tester) async {
        await openConfirmation(tester, dark: dark, size: size);
        await capture(tester, 'bookings/void_list_${width}_$mode.png');
      });

      testWidgets('confirm voiding $width $mode', (tester) async {
        await openConfirmation(tester, dark: dark, size: size);
        await tester.tap(find.text('ANULAR RESERVA'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextField).last,
          'Mantenimiento urgente del césped sintético.',
        );
        await capture(tester, 'bookings/void_confirm_${width}_$mode.png');
      });

      testWidgets('void without a reason $width $mode', (tester) async {
        await openConfirmation(tester, dark: dark, size: size);
        await tester.tap(find.text('ANULAR RESERVA'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('CONFIRMAR ANULACIÓN'));
        await capture(tester, 'bookings/void_no_reason_${width}_$mode.png');
      });
    }
  }
}
