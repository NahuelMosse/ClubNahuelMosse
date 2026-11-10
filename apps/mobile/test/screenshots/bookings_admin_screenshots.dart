import 'package:clubnahuelmosse/features/session/presentation/access_denied_screen.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide testWidgets;

import '../support/admin.dart';
import '../support/mount.dart';
import '../support/fixed_clock.dart';

/// Asserts nothing: produces the step-9 strip to compare against the prototype (CU-14).
void main() {
  setUpAll(loadFonts);

  const phones = {'360': Size(360, 800), '430': Size(430, 932)};
  const modes = {'dark': true, 'light': false};

  Future<void> capture(WidgetTester tester, String file) async {
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile(file));
  }

  const counters =
      '"counters": {"all": 49, "active": 12, "completed": 31, "voided": 5}';

  const activeBookingJson =
      '{"id": "00000000-0000-7000-8000-000000000001", "space_id": "00000000-0000-7000-8000-000000000009", "venue_id": "00000000-0000-7000-8000-000000000001", "space":'
      ' "Moron_Rivadavia_19850_Futbol_F5_1", "sport": "Futbol", "kind": "F5", "venue":'
      ' "Sede Morón", "address": "Av. Rivadavia 19850", "starts_at":'
      ' "2026-11-12T21:00:00-03:00", "ends_at": "2026-11-12T22:00:00-03:00", "total": 38000,'
      ' "status": "active", "reason": null, "user_id": "00000000-0000-7000-8000-000000000001", "user": "Nahuel Mosse",'
      ' "created_at": "2026-11-02T18:42:00-03:00", "canceled_at": null,'
      ' "canceled_by_name": null, "space_deactivated": false, "voidable": true}';

  const completedBookingJson =
      '{"id": "00000000-0000-7000-8000-000000000002", "space_id": "00000000-0000-7000-8000-000000000010", "venue_id": "00000000-0000-7000-8000-000000000002", "space":'
      ' "RamosMejia_Belgrano_1240_Voley_IND_1", "sport": "Voley", "kind": "IND", "venue":'
      ' "Sede Ramos Mejía", "address": "Calle Belgrano 1240", "starts_at":'
      ' "2026-11-04T20:00:00-03:00", "ends_at": "2026-11-04T21:00:00-03:00", "total": 33000,'
      ' "status": "completed", "reason": null, "user_id": "00000000-0000-7000-8000-000000000001", "user": "Nahuel Mosse",'
      ' "created_at": "2026-10-20T09:10:00-03:00", "canceled_at": null,'
      ' "canceled_by_name": null, "space_deactivated": false}';

  const voidedBookingJson =
      '{"id": "00000000-0000-7000-8000-000000000003", "space_id": "00000000-0000-7000-8000-000000000011", "venue_id": "00000000-0000-7000-8000-000000000002", "space":'
      ' "RamosMejia_Belgrano_1240_Hockey_H7_1", "sport": "Hockey", "kind": "H7", "venue":'
      ' "Sede Ramos Mejía", "address": "Calle Belgrano 1240", "starts_at":'
      ' "2026-10-30T19:00:00-03:00", "ends_at": "2026-10-30T20:00:00-03:00", "total": 48000,'
      ' "status": "voided", "reason": "mantenimiento de la cancha", "user_id": "00000000-0000-7000-8000-000000000001",'
      ' "user": "Nahuel Mosse", "created_at": "2026-10-21T11:07:00-03:00",'
      ' "canceled_at": "2026-10-28T09:15:00-03:00", "canceled_by_name":'
      ' "Admin Sistema", "space_deactivated": false, "notice_delivery": "sent",'
      ' "notice_at": "2026-10-28T09:15:00-03:00"}';

  for (final MapEntry(key: width, value: size) in phones.entries) {
    for (final MapEntry(key: mode, value: dark) in modes.entries) {
      testWidgets('listing with bookings $width $mode', (tester) async {
        await mountAdmin(
          tester,
          start: '/admin',
          dark: dark,
          size: size,
          api: apiRoutes({
            'GET /bookings/all': (
              200,
              '{"bookings": [$activeBookingJson, $completedBookingJson,'
                  ' $voidedBookingJson], "total": 49, "page": 1, "per_page": 20,'
                  ' $counters}',
            ),
            'GET /spaces/catalog': (200, catalogJson),
          }),
        );
        await capture(tester, 'admin/bookings_${width}_$mode.png');
      });

      testWidgets('listing loading $width $mode', (tester) async {
        await mountAdmin(
          tester,
          start: '/admin',
          dark: dark,
          size: size,
          api: apiRoutes({
            'GET /bookings/all': (
              200,
              '{"bookings": [], "total": 0, "page": 1, "per_page": 20, $counters}',
            ),
            'GET /spaces/catalog': (200, catalogJson),
          }),
        );
        // A single frame, before the request returns.
        await tester.pump();
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('admin/bookings_loading_${width}_$mode.png'),
        );
      });

      testWidgets('no results $width $mode', (tester) async {
        await mountAdmin(
          tester,
          start: '/admin',
          dark: dark,
          size: size,
          api: apiRoutes({
            'GET /bookings/all': (
              200,
              '{"bookings": [], "total": 0, "page": 1, "per_page": 20,'
                  ' "counters": {"all": 0, "active": 0, "completed": 0,'
                  ' "voided": 0}}',
            ),
            'GET /spaces/catalog': (200, catalogJson),
          }),
        );
        await tester.enterText(
          find.bySemanticsLabel('Buscar reserva'),
          'sin coincidencia',
        );
        await capture(tester, 'admin/bookings_no_results_${width}_$mode.png');
      });

      testWidgets('empty history $width $mode', (tester) async {
        await mountAdmin(
          tester,
          start: '/admin',
          dark: dark,
          size: size,
          api: apiRoutes({
            'GET /bookings/all': (
              200,
              '{"bookings": [], "total": 0, "page": 1, "per_page": 20,'
                  ' "counters": {"all": 0, "active": 0, "completed": 0,'
                  ' "voided": 0}}',
            ),
            'GET /spaces/catalog': (200, catalogJson),
          }),
        );
        await capture(tester, 'admin/bookings_empty_${width}_$mode.png');
      });

      testWidgets('filters panel $width $mode', (tester) async {
        await mountAdmin(
          tester,
          start: '/admin',
          dark: dark,
          size: size,
          api: apiRoutes({
            'GET /bookings/all': (
              200,
              '{"bookings": [$activeBookingJson], "total": 49, "page": 1,'
                  ' "per_page": 20, $counters}',
            ),
            'GET /spaces/catalog': (200, catalogJson),
            'GET /venues': (
              200,
              '{"venues": [$venueMoronJson, $venueCastelarJson]}',
            ),
          }),
        );
        await tester.tap(find.text('Filtros'));
        await capture(tester, 'admin/bookings_filters_${width}_$mode.png');
      });

      testWidgets('invalid date range $width $mode', (tester) async {
        await mountAdmin(
          tester,
          start: '/admin',
          dark: dark,
          size: size,
          api: apiRoutes({
            'GET /bookings/all': (
              200,
              '{"bookings": [], "total": 0, "page": 1, "per_page": 20,'
                  ' "counters": {"all": 0, "active": 0, "completed": 0,'
                  ' "voided": 0}}',
            ),
            'GET /spaces/catalog': (200, catalogJson),
            'GET /venues': (200, '{"venues": [$venueMoronJson]}'),
          }),
        );
        await tester.tap(find.text('Filtros'));
        await tester.pumpAndSettle();
        await tester.enterText(find.bySemanticsLabel('Desde'), '30112026');
        await tester.enterText(find.bySemanticsLabel('Hasta'), '01112026');
        await capture(
          tester,
          'admin/bookings_range_invalid_${width}_$mode.png',
        );
      });

      testWidgets('booking detail $width $mode', (tester) async {
        await mountAdmin(
          tester,
          start: '/admin',
          dark: dark,
          size: size,
          api: apiRoutes({
            'GET /bookings/all': (
              200,
              '{"bookings": [$activeBookingJson], "total": 1, "page": 1,'
                  ' "per_page": 20, $counters}',
            ),
            'GET /spaces/catalog': (200, catalogJson),
          }),
        );
        await tester.tap(find.text('Moron_Rivadavia_19850_Futbol_F5_1'));
        await capture(tester, 'admin/bookings_detail_${width}_$mode.png');
      });

      testWidgets('voided booking detail $width $mode', (tester) async {
        await mountAdmin(
          tester,
          start: '/admin',
          dark: dark,
          size: size,
          api: apiRoutes({
            'GET /bookings/all': (
              200,
              '{"bookings": [$voidedBookingJson], "total": 1, "page": 1,'
                  ' "per_page": 20, $counters}',
            ),
            'GET /spaces/catalog': (200, catalogJson),
          }),
        );
        await tester.tap(find.text('RamosMejia_Belgrano_1240_Hockey_H7_1'));
        await capture(
          tester,
          'admin/bookings_detail_voided_${width}_$mode.png',
        );
      });

      testWidgets('access denied $width $mode', (tester) async {
        await mountScreen(
          tester,
          AccessDeniedScreen(session: FakeSession(userProfile)),
          theme: dark ? darkTheme : lightTheme,
          size: size,
        );
        await capture(tester, 'admin/access_denied_${width}_$mode.png');
      });
    }
  }
}
