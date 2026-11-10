import 'package:clubnahuelmosse/features/spaces/data/spaces_repository.dart';
import 'dart:convert';

import 'package:clubnahuelmosse/features/admin/data/booking_history_api.dart';
import 'package:clubnahuelmosse/features/admin/domain/history_filters.dart';
import 'package:clubnahuelmosse/features/admin/data/booking_history_json.dart';
import 'package:clubnahuelmosse/features/admin/domain/pending_panel_filters.dart';
import 'package:clubnahuelmosse/features/admin/presentation/booking_detail_screen.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/mount.dart';
import 'package:clubnahuelmosse/features/spaces/presentation/spaces.dart';

String bookingJson({
  String status = 'voided',
  String? delivery,
  String? deliveryAt,
}) =>
    '{"id": "00000000-0000-7000-8000-000000000001", "space_id": "00000000-0000-7000-8000-000000000009", "venue_id": "00000000-0000-7000-8000-000000000001", "space":'
    ' "Moron_Rivadavia_19850_Futbol_F5_1", "sport": "Futbol", "kind": "F5", "venue":'
    ' "Sede Morón", "address": "Av. Rivadavia 19850", "starts_at":'
    ' "2026-11-12T21:00:00-03:00", "ends_at": "2026-11-12T22:00:00-03:00", "total": 38000,'
    ' "status": "$status", "reason": "mantenimiento de la cancha",'
    ' "user_id": "00000000-0000-7000-8000-000000000001", "user": "Nahuel Mosse",'
    ' "created_at": "2026-11-02T18:42:00-03:00",'
    ' "canceled_at": "2026-11-03T10:00:00-03:00",'
    ' "canceled_by_name": "Ana Díaz", "space_deactivated": false,'
    ' "voidable": false, "notice_delivery": ${delivery == null ? 'null' : '"$delivery"'},'
    ' "notice_at": ${deliveryAt == null ? 'null' : '"$deliveryAt"'}}';

void main() {
  Future<void> open(
    WidgetTester tester,
    String json, {
    Size size = const Size(360, 800),
    double scale = 1,
  }) async {
    final booking = parseBookingHistoryEntry(jsonDecode(json));
    if (booking == null) fail('the test booking cannot be read');
    final session = FakeSession(adminProfile);
    final api = apiRoutes({});
    await mountScreen(
      tester,
      BookingDetailScreen(
        booking: booking,
        history: BookingHistory(api: api, sesion: session),
        session: session,
        spaces: Spaces(
          repository: SpacesRepository(api: api, session: session),
        ),
        filters: const HistoryFilters(),
        pending: PendingPanelFilters(),
      ),
      theme: darkTheme,
      size: size,
      textScale: scale,
    );
  }

  group('the detail traceability shows how the notice went out', () {
    testWidgets('sent: says it was sent and when', (tester) async {
      await open(
        tester,
        bookingJson(delivery: 'sent', deliveryAt: '2026-11-03T10:00:05-03:00'),
      );

      expect(find.text('Notificación enviada al usuario'), findsOneWidget);
      expect(find.text('03/11/2026 10:00'), findsWidgets);
    });

    for (final delivery in ['no_permission', 'no_channel', 'failed']) {
      testWidgets(
        '$delivery: stays in the center and the push did not go out',
        (tester) async {
          await open(
            tester,
            bookingJson(
              delivery: delivery,
              deliveryAt: '2026-11-03T10:00:05-03:00',
            ),
          );

          expect(find.text('Aviso en el centro del usuario'), findsOneWidget);
          expect(find.text('El push no salió'), findsOneWidget);
          expect(find.text('Notificación enviada al usuario'), findsNothing);
        },
      );
    }

    testWidgets('pending or no notice: not shown', (tester) async {
      await open(tester, bookingJson());

      expect(find.text('Anulada por el administrador'), findsOneWidget);
      expect(find.text('Notificación enviada al usuario'), findsNothing);
      expect(find.text('Aviso en el centro del usuario'), findsNothing);
    });

    for (final (width, height) in [(360.0, 800.0), (430.0, 932.0)]) {
      testWidgets('at 200 % and $width wide it is not cut off', (tester) async {
        await open(
          tester,
          bookingJson(
            delivery: 'no_channel',
            deliveryAt: '2026-11-03T10:00:05-03:00',
          ),
          size: Size(width, height),
          scale: 2,
        );
        await tester.ensureVisible(find.text('Aviso en el centro del usuario'));

        expect(find.text('El push no salió'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
