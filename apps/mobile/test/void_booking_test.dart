import 'package:clubnahuelmosse/features/spaces/data/spaces_repository.dart';
import 'package:clubnahuelmosse/features/venues/data/venues_repository.dart';
import 'dart:convert';

import 'package:clubnahuelmosse/features/admin/data/booking_history_api.dart';
import 'package:clubnahuelmosse/features/admin/domain/history_filters.dart';
import 'package:clubnahuelmosse/features/admin/data/booking_history_json.dart';
import 'package:clubnahuelmosse/features/admin/domain/pending_panel_filters.dart';
import 'package:clubnahuelmosse/features/admin/presentation/booking_detail_screen.dart';
import 'package:clubnahuelmosse/features/admin/presentation/admin_panel_screen.dart';
import 'package:clubnahuelmosse/common/price_format.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'support/admin.dart';
import 'support/mount.dart';
import 'package:clubnahuelmosse/features/spaces/presentation/spaces.dart';
import 'package:clubnahuelmosse/features/venues/presentation/venues.dart';

String bookingJson({bool voidable = true, String status = 'active'}) =>
    '{"id": "00000000-0000-7000-8000-000000000001", "space_id": "00000000-0000-7000-8000-000000000009", "venue_id": "00000000-0000-7000-8000-000000000001", "space":'
    ' "Moron_Rivadavia_19850_Futbol_F5_1", "sport": "Futbol", "kind": "F5", "venue":'
    ' "Sede Morón", "address": "Av. Rivadavia 19850", "starts_at":'
    ' "2026-11-12T21:00:00-03:00", "ends_at": "2026-11-12T22:00:00-03:00", "total": 38000,'
    ' "status": "$status", "reason": ${status == 'voided' ? '"lluvia"' : 'null'},'
    ' "user_id": "00000000-0000-7000-8000-000000000001", "user": "Nahuel Mosse",'
    ' "created_at": "2026-11-02T18:42:00-03:00", "canceled_at": null,'
    ' "canceled_by_name": null, "space_deactivated": false,'
    ' "voidable": $voidable}';

String listing(String booking) =>
    '{"bookings": [$booking], "total": 1, "page": 1, "per_page": 20,'
    ' "counters": {"all": 1, "active": 1, "completed": 0, "voided": 0}}';

void main() {
  setUpAll(loadFonts);

  Future<List<http.Request>> openPanel(
    WidgetTester tester, {
    bool voidable = true,
    (int, String)? onVoid,
    Size size = const Size(393, 852),
    double scale = 1,
  }) async {
    final requests = <http.Request>[];
    final api = apiRoutes({
      'GET /bookings/all': (200, listing(bookingJson(voidable: voidable))),
      'GET /spaces/catalog': (200, catalogJson),
      'POST /bookings/00000000-0000-7000-8000-000000000001/void':
          onVoid ?? (200, bookingJson(voidable: false, status: 'voided')),
    }, requests: requests);
    final session = FakeSession(adminProfile);
    await mountScreen(
      tester,
      AdminPanelScreen(
        history: BookingHistory(api: api, sesion: session),
        venues: Venues(
          repository: VenuesRepository(api: api, session: session),
        ),
        spaces: Spaces(
          repository: SpacesRepository(api: api, session: session),
        ),
        session: session,
        pending: PendingPanelFilters(),
      ),
      theme: darkTheme,
      size: size,
      textScale: scale,
    );
    return requests;
  }

  Future<void> askToVoid(WidgetTester tester) async {
    await tester.ensureVisible(find.text('ANULAR RESERVA'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ANULAR RESERVA'));
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.pumpAndSettle();
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  Iterable<http.Request> voids(List<http.Request> requests) =>
      requests.where((p) => p.method == 'POST');

  testWidgets('the confirmation shows the booking data', (tester) async {
    await openPanel(tester);

    await askToVoid(tester);

    expect(find.text('¿Anular esta reserva?'), findsOneWidget);
    final dialog = find.byType(Dialog);
    for (final item in ['Nahuel Mosse', 'Sede Morón', formatPesos(38000)]) {
      expect(
        find.descendant(of: dialog, matching: find.text(item)),
        findsOneWidget,
      );
    }
    expect(find.text('MOTIVO DE LA ANULACIÓN'), findsOneWidget);
  });

  testWidgets(
    'confirming with a reason sends the void and notifies @assumption:CU-15-SUP-04',
    (tester) async {
      final requests = await openPanel(tester);

      await askToVoid(tester);
      await tester.enterText(find.byType(TextField).last, '  Mantenimiento  ');
      await tapText(tester, 'CONFIRMAR ANULACIÓN');

      final request = voids(requests).single;
      expect(jsonDecode(request.body), {
        'reason': 'Mantenimiento',
        'space_id': '00000000-0000-7000-8000-000000000009',
        'starts_at': '2026-11-13T00:00:00.000Z',
      });
      expect(find.text('Reserva anulada correctamente'), findsOneWidget);
      await tapText(tester, 'ACEPTAR');
      expect(find.text('Reserva anulada correctamente'), findsNothing);
    },
  );

  testWidgets('without a reason it warns it is required and sends nothing', (
    tester,
  ) async {
    final requests = await openPanel(tester);

    await askToVoid(tester);
    await tester.enterText(find.byType(TextField).last, '   ');
    await tapText(tester, 'CONFIRMAR ANULACIÓN');

    expect(find.text('El motivo es obligatorio para anular'), findsOneWidget);
    expect(find.text('¿Anular esta reserva?'), findsOneWidget);
    expect(voids(requests), isEmpty);

    await tester.enterText(find.byType(TextField).last, 'Lluvia');
    await tester.pumpAndSettle();
    expect(find.text('El motivo es obligatorio para anular'), findsNothing);
  });

  testWidgets('«VOLVER» closes the confirmation without requesting anything', (
    tester,
  ) async {
    final requests = await openPanel(tester);

    await askToVoid(tester);
    await tapText(tester, 'VOLVER');

    expect(find.text('¿Anular esta reserva?'), findsNothing);
    expect(find.text('ANULAR RESERVA'), findsOneWidget);
    expect(voids(requests), isEmpty);
  });

  testWidgets('if the booking changed, it warns and reads the listing again', (
    tester,
  ) async {
    final requests = await openPanel(
      tester,
      onVoid: (409, '{"errors": {"reserva": "Esto cambió mientras tanto"}}'),
    );

    await askToVoid(tester);
    await tester.enterText(find.byType(TextField).last, 'Lluvia');
    await tapText(tester, 'CONFIRMAR ANULACIÓN');

    expect(find.text('Esto cambió mientras tanto'), findsOneWidget);
    final reads = requests.where((p) => p.method == 'GET').length;
    await tapText(tester, 'VER LO ACTUALIZADO');
    expect(requests.where((p) => p.method == 'GET').length, greaterThan(reads));
  });

  testWidgets(
    'if the server fails, it warns and the booking still offers to void @assumption:CU-15-SUP-08',
    (tester) async {
      await openPanel(tester, onVoid: (500, '{}'));

      await askToVoid(tester);
      await tester.enterText(find.byType(TextField).last, 'Lluvia');
      await tapText(tester, 'CONFIRMAR ANULACIÓN');

      expect(find.text('Error del servidor'), findsOneWidget);
      await tapText(tester, 'ACEPTAR');
      expect(find.text('ANULAR RESERVA'), findsOneWidget);
    },
  );

  testWidgets(
    'a booking the server does not report as voidable does not offer it @assumption:CU-15-SUP-06',
    (tester) async {
      await openPanel(tester, voidable: false);

      expect(find.text('Nahuel Mosse'), findsOneWidget);
      expect(find.text('ANULAR RESERVA'), findsNothing);
    },
  );

  testWidgets(
    'the detail also offers to void and notifies on return @assumption:CU-15-SUP-06',
    (tester) async {
      final requests = <http.Request>[];
      final api = apiRoutes({
        'POST /bookings/00000000-0000-7000-8000-000000000001/void': (
          200,
          bookingJson(voidable: false, status: 'voided'),
        ),
      }, requests: requests);
      final session = FakeSession(adminProfile);
      final booking = parseBookingHistoryEntry(jsonDecode(bookingJson()));
      if (booking == null) fail('the test booking cannot be read');
      bool? result;
      await mountScreen(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => BookingDetailScreen(
                        booking: booking,
                        history: BookingHistory(api: api, sesion: session),
                        session: session,
                        spaces: Spaces(
                          repository: SpacesRepository(
                            api: api,
                            session: session,
                          ),
                        ),
                        filters: const HistoryFilters(),
                        pending: PendingPanelFilters(),
                      ),
                    ),
                  );
                },
                child: const Text('ABRIR'),
              ),
            ),
          ),
        ),
        theme: darkTheme,
      );
      await tester.tap(find.text('ABRIR'));
      await tester.pumpAndSettle();

      await askToVoid(tester);
      await tester.enterText(find.byType(TextField).last, 'Lluvia');
      await tapText(tester, 'CONFIRMAR ANULACIÓN');
      await tapText(tester, 'ACEPTAR');

      expect(voids(requests), hasLength(1));
      expect(result, isTrue);
      expect(find.text('ABRIR'), findsOneWidget);
    },
  );

  testWidgets(
    'with text at 200% on a 360 wide screen the confirmation does not overflow',
    (tester) async {
      await openPanel(tester, size: const Size(360, 800), scale: 2);

      await askToVoid(tester);
      await tapText(tester, 'CONFIRMAR ANULACIÓN');

      expect(tester.takeException(), isNull);
      expect(find.text('El motivo es obligatorio para anular'), findsOneWidget);
    },
  );
}
