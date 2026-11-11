import 'package:clubnahuelmosse/features/spaces/data/spaces_repository.dart';
import 'dart:async';
import 'dart:convert';

import 'package:clubnahuelmosse/features/admin/data/booking_history_api.dart';
import 'package:clubnahuelmosse/features/admin/domain/history_filters.dart';
import 'package:clubnahuelmosse/features/admin/data/booking_history_json.dart';
import 'package:clubnahuelmosse/features/admin/domain/booking_history_entry.dart';
import 'package:clubnahuelmosse/features/admin/domain/pending_panel_filters.dart';
import 'package:clubnahuelmosse/features/admin/presentation/booking_detail_screen.dart';
import 'package:clubnahuelmosse/features/admin/presentation/booking_filters_screen.dart';
import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:clubnahuelmosse/common/button.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../support/admin.dart';
import '../support/mount.dart';
import 'package:clubnahuelmosse/features/spaces/domain/space.dart';
import 'package:clubnahuelmosse/features/spaces/presentation/spaces.dart';

String _booking({
  bool voidable = true,
  String status = 'active',
  String notice = '',
}) =>
    '{"id": "00000000-0000-7000-8000-000000000001", "space_id": "00000000-0000-7000-8000-000000000009", "venue_id": "00000000-0000-7000-8000-000000000001", "space":'
    ' "Moron_Rivadavia_19850_Futbol_F5_1", "sport": "Futbol", "kind": "F5", "venue":'
    ' "Sede Morón", "address": "Av. Rivadavia 19850", "starts_at":'
    ' "2026-11-12T21:00:00-03:00", "ends_at": "2026-11-12T22:00:00-03:00", "total": 38000,'
    ' "status": "$status", "reason": ${status == 'voided' ? '"lluvia"' : 'null'},'
    ' "user_id": "00000000-0000-7000-8000-000000000001", "user": "Nahuel Mosse",'
    ' "created_at": "2026-11-02T18:42:00-03:00",'
    ' "canceled_at": ${status == 'voided' ? '"2026-11-03T10:00:00-03:00"' : 'null'},'
    ' "canceled_by_name": ${status == 'voided' ? '"Ana Díaz"' : 'null'},'
    ' "space_deactivated": false, "voidable": $voidable$notice}';

void main() {
  setUpAll(loadFonts);

  final session = FakeSession(adminProfile);

  Widget detail(BookingHistoryEntry booking, ApiClient api) =>
      BookingDetailScreen(
        booking: booking,
        history: BookingHistory(api: api, session: session),
        session: session,
        spaces: Spaces(
          repository: SpacesRepository(api: api, session: session),
        ),
        filters: const HistoryFilters(),
        pending: PendingPanelFilters(),
      );

  BookingHistoryEntry parsed(String json) {
    final r = parseBookingHistoryEntry(jsonDecode(json));
    if (r == null) fail('the test booking cannot be read');
    return r;
  }

  group('detail', () {
    testWidgets('shows what is current on the server, with the notice line', (
      tester,
    ) async {
      final api = apiRoutes({
        'GET /bookings/all/00000000-0000-7000-8000-000000000001': (
          200,
          _booking(
            voidable: false,
            status: 'voided',
            notice:
                ', "notice_delivery": "sent", "notice_at": "2026-11-03T10:00:05-03:00"',
          ),
        ),
        'GET /spaces/catalog': (200, catalogJson),
      });
      await mountScreen(
        tester,
        detail(parsed(_booking()), api),
        theme: darkTheme,
      );
      await tester.pumpAndSettle();

      expect(find.text('Notificación enviada al usuario'), findsOneWidget);
      expect(find.text('Anulada por el administrador'), findsOneWidget);
      expect(find.text('ANULAR RESERVA'), findsNothing);
    });

    testWidgets('names the sport as the catalog does, with the accent', (
      tester,
    ) async {
      final api = apiRoutes({'GET /spaces/catalog': (200, catalogJson)});
      await mountScreen(
        tester,
        detail(parsed(_booking()), api),
        theme: darkTheme,
      );
      await tester.pumpAndSettle();

      expect(find.text('Fútbol'), findsOneWidget);
      expect(find.text('Futbol'), findsNothing);
    });

    testWidgets('the arrow has an accessible name', (tester) async {
      final semantics = tester.ensureSemantics();
      final api = apiRoutes({'GET /spaces/catalog': (200, catalogJson)});
      await mountScreen(
        tester,
        detail(parsed(_booking()), api),
        theme: darkTheme,
      );
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      expect(find.byTooltip('Volver'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('with the void in flight you cannot leave', (tester) async {
      final response = Completer<http.Response>();
      final api = ApiClient(
        'http://api.falsa',
        client: MockClient((request) async {
          if (request.method == 'POST') return response.future;
          return http.Response.bytes(
            utf8.encode(
              request.url.path == '/spaces/catalog' ? catalogJson : '{}',
            ),
            request.url.path == '/spaces/catalog' ? 200 : 404,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      bool? result;
      await mountScreen(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => detail(parsed(_booking()), api),
                  ),
                );
              },
              child: const Text('ABRIR'),
            ),
          ),
        ),
        theme: darkTheme,
      );
      await tester.tap(find.text('ABRIR'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ANULAR RESERVA'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Lluvia');
      await tester.ensureVisible(find.text('CONFIRMAR ANULACIÓN'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('CONFIRMAR ANULACIÓN'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byTooltip('Volver'), warnIfMissed: false);
      await tester.pump();
      await tester.tap(find.text('VOLVER AL LISTADO'), warnIfMissed: false);
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.text('Detalle de reserva'), findsOneWidget);
      expect(result, isNull);

      response.complete(
        http.Response.bytes(
          utf8.encode(_booking(voidable: false, status: 'voided')),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('ACEPTAR'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
      expect(find.text('Detalle de reserva'), findsNothing);
    });
  });

  group('filters', () {
    Future<void> open(WidgetTester tester) async {
      await mountScreen(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => openBookingFilters(
                context,
                filters: const HistoryFilters(),
                venues: const [],
                catalog: const Catalog([]),
              ),
              child: const Text('ABRIR'),
            ),
          ),
        ),
        theme: darkTheme,
      );
      await tester.tap(find.text('ABRIR'));
      await tester.pumpAndSettle();
    }

    bool applyEnabled(WidgetTester tester) =>
        tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onTap != null;

    testWidgets(
      'a date that does not exist flags the error and blocks APLICAR',
      (tester) async {
        await open(tester);
        expect(applyEnabled(tester), isTrue);

        await tester.enterText(find.byType(TextField).first, '31022026');
        await tester.pumpAndSettle();

        expect(find.text('Fecha inválida'), findsOneWidget);
        expect(applyEnabled(tester), isFalse);

        await tester.enterText(find.byType(TextField).first, '28022026');
        await tester.pumpAndSettle();

        expect(find.text('Fecha inválida'), findsNothing);
        expect(applyEnabled(tester), isTrue);
      },
    );

    testWidgets('the X has an accessible name', (tester) async {
      final semantics = tester.ensureSemantics();
      await open(tester);

      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      expect(find.byTooltip('Cerrar'), findsOneWidget);
      semantics.dispose();
    });
  });
}
