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
import 'package:http/http.dart' as http;

import 'support/mount.dart';
import 'package:clubnahuelmosse/features/spaces/presentation/spaces.dart';

String _booking({
  String status = 'active',
  bool voidable = true,
  String? reason,
  String? voidedAt,
  String? voidedBy,
}) =>
    '{"id": "00000000-0000-7000-8000-000000000001", "space_id": "00000000-0000-7000-8000-000000000009", "venue_id": "00000000-0000-7000-8000-000000000001", "space":'
    ' "Moron_Rivadavia_19850_Futbol_F5_1", "sport": "Futbol", "kind": "F5", "venue":'
    ' "Sede Morón", "address": "Av. Rivadavia 19850", "starts_at":'
    ' "2026-11-12T21:00:00-03:00", "ends_at": "2026-11-12T22:00:00-03:00", "total": 38000,'
    ' "status": "$status", "reason": ${reason == null ? 'null' : '"$reason"'},'
    ' "user_id": "00000000-0000-7000-8000-000000000001", "user": "Nahuel Mosse",'
    ' "created_at": "2026-11-02T18:42:00-03:00",'
    ' "canceled_at": ${voidedAt == null ? 'null' : '"$voidedAt"'},'
    ' "canceled_by_name": ${voidedBy == null ? 'null' : '"$voidedBy"'},'
    ' "space_deactivated": false, "voidable": $voidable}';

void main() {
  setUpAll(loadFonts);

  Future<void> openDetail(
    WidgetTester tester,
    String booking,
    List<http.Request> requests,
  ) async {
    final voided = _booking(
      status: 'voided',
      voidable: false,
      reason: 'Lluvia',
      voidedAt: '2026-11-12T18:30:00-03:00',
      voidedBy: 'Ana Díaz',
    );
    final api = apiRoutes({
      'POST /bookings/00000000-0000-7000-8000-000000000001/void': (200, voided),
    }, requests: requests);
    final session = FakeSession(adminProfile);
    final parsed = parseBookingHistoryEntry(jsonDecode(booking));
    expect(parsed, isNotNull);
    await mountScreen(
      tester,
      BookingDetailScreen(
        booking: parsed!,
        history: BookingHistory(api: api, sesion: session),
        session: session,
        spaces: Spaces(
          repository: SpacesRepository(api: api, session: session),
        ),
        filters: const HistoryFilters(),
        pending: PendingPanelFilters(),
      ),
      theme: darkTheme,
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.pumpAndSettle();
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  Iterable<http.Request> voids(List<http.Request> requests) => requests.where(
    (p) =>
        p.method == 'POST' &&
        p.url.path == '/bookings/00000000-0000-7000-8000-000000000001/void',
  );

  testWidgets('the admin voids a booking from the history detail '
      '@REV-08-S8 @assumption:REV-08-ASM-01', (tester) async {
    final requests = <http.Request>[];
    await openDetail(tester, _booking(), requests);

    await tap(tester, 'ANULAR RESERVA');
    expect(find.text('¿Anular esta reserva?'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'Lluvia');
    await tap(tester, 'CONFIRMAR ANULACIÓN');

    expect(voids(requests), hasLength(1));
    expect(
      jsonDecode(voids(requests).single.body),
      containsPair('reason', 'Lluvia'),
    );
    expect(find.text('Reserva anulada correctamente'), findsOneWidget);
  });

  testWidgets('the detail of a voided booking says who voided it, when and why '
      '@REV-08-S8', (tester) async {
    await openDetail(
      tester,
      _booking(
        status: 'voided',
        voidable: false,
        reason: 'Lluvia',
        voidedAt: '2026-11-12T18:30:00-03:00',
        voidedBy: 'Ana Díaz',
      ),
      [],
    );

    expect(find.text('Anulada por el administrador'), findsOneWidget);
    expect(find.textContaining('Por Ana Díaz'), findsOneWidget);
    expect(find.textContaining('12/11/2026 18:30'), findsOneWidget);
    expect(find.textContaining('Lluvia'), findsWidgets);
    expect(find.text('ANULAR RESERVA'), findsNothing);
  });

  testWidgets(
    'going back without confirming the void leaves the booking as it was @REV-08-S9',
    (tester) async {
      final requests = <http.Request>[];
      await openDetail(tester, _booking(), requests);

      await tap(tester, 'ANULAR RESERVA');
      await tester.enterText(find.byType(TextField).last, 'Lluvia');
      await tap(tester, 'VOLVER');

      expect(voids(requests), isEmpty);
      expect(find.text('¿Anular esta reserva?'), findsNothing);
      expect(find.text('ANULAR RESERVA'), findsOneWidget);
      expect(find.text('Anulada por el administrador'), findsNothing);
    },
  );

  testWidgets(
    'canceling the void dialog leaves the booking as it was and the slot taken '
    '@REV-08-S9',
    (tester) async {
      final requests = <http.Request>[];
      await openDetail(tester, _booking(), requests);

      await tap(tester, 'ANULAR RESERVA');
      await tester.enterText(find.byType(TextField).last, 'Lluvia');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(voids(requests), isEmpty);
      expect(find.text('¿Anular esta reserva?'), findsNothing);
      expect(find.text('ANULAR RESERVA'), findsOneWidget);
      expect(find.text('Anulada por el administrador'), findsNothing);
    },
  );

  testWidgets(
    'tapping outside the void dialog leaves the booking as it was and returns to the detail '
    '@REV-08-S9',
    (tester) async {
      final requests = <http.Request>[];
      await openDetail(tester, _booking(), requests);

      await tap(tester, 'ANULAR RESERVA');
      await tester.tapAt(const Offset(2, 2));
      await tester.pumpAndSettle();

      expect(voids(requests), isEmpty);
      expect(find.text('¿Anular esta reserva?'), findsNothing);
      expect(find.text('ANULAR RESERVA'), findsOneWidget);
      expect(find.text('Anulada por el administrador'), findsNothing);
    },
  );
}
