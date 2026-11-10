import 'package:clubnahuelmosse/features/spaces/data/spaces_repository.dart';
import 'package:clubnahuelmosse/features/venues/data/venues_repository.dart';
import 'dart:async';
import 'dart:convert';

import 'package:clubnahuelmosse/features/admin/data/booking_history_api.dart';
import 'package:clubnahuelmosse/features/admin/domain/pending_panel_filters.dart';
import 'package:clubnahuelmosse/features/admin/presentation/admin_panel_screen.dart';
import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:clubnahuelmosse/common/skeleton.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../support/admin.dart';
import '../support/mount.dart';
import 'package:clubnahuelmosse/features/spaces/presentation/spaces.dart';
import 'package:clubnahuelmosse/features/venues/presentation/venues.dart';

String _uuid(int n) =>
    '00000000-0000-7000-8000-${n.toString().padLeft(12, '0')}';

void main() {
  setUpAll(loadFonts);

  const bookingJson =
      '{"id": "00000000-0000-7000-8000-000000000001", "space_id": "00000000-0000-7000-8000-000000000009", "venue_id": "00000000-0000-7000-8000-000000000001", "space":'
      ' "Moron_Rivadavia_19850_Futbol_F5_1", "sport": "Futbol", "kind": "F5", "venue":'
      ' "Sede Morón", "address": "Av. Rivadavia 19850", "starts_at":'
      ' "2026-11-12T21:00:00-03:00", "ends_at": "2026-11-12T22:00:00-03:00", "total": 38000,'
      ' "status": "active", "reason": null, "user_id": "00000000-0000-7000-8000-000000000001", "user": "Nahuel Mosse",'
      ' "created_at": "2026-11-02T18:42:00-03:00", "canceled_at": null,'
      ' "canceled_by_name": null, "space_deactivated": false}';

  Widget screen({required ApiClient api}) {
    final session = FakeSession(adminProfile);
    return AdminPanelScreen(
      history: BookingHistory(api: api, session: session),
      venues: Venues(
        repository: VenuesRepository(api: api, session: session),
      ),
      spaces: Spaces(
        repository: SpacesRepository(api: api, session: session),
      ),
      session: session,
      pending: PendingPanelFilters(),
    );
  }

  testWidgets('shows the listing with the total and the count of each tab', (
    tester,
  ) async {
    await mountScreen(
      tester,
      screen(
        api: apiRoutes({
          'GET /bookings/all': (
            200,
            '{"bookings": [$bookingJson], "total": 1, "page": 1,'
                ' "per_page": 20, "counters": {"all": 1, "active": 1,'
                ' "completed": 0, "voided": 0}}',
          ),
          'GET /spaces/catalog': (200, catalogJson),
        }),
      ),
      theme: darkTheme,
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('1 RESERVA EN TOTAL'), findsOneWidget);
    expect(find.text('Activas (1)'), findsOneWidget);
    expect(find.text('Nahuel Mosse'), findsOneWidget);
    expect(find.text('ACTIVA'), findsOneWidget);
  });

  testWidgets('with no bookings in the system it shows «No hay reservas»', (
    tester,
  ) async {
    await mountScreen(
      tester,
      screen(
        api: apiRoutes({
          'GET /bookings/all': (
            200,
            '{"bookings": [], "total": 0, "page": 1, "per_page": 20,'
                ' "counters": {"all": 0, "active": 0, "completed": 0,'
                ' "voided": 0}}',
          ),
          'GET /spaces/catalog': (200, catalogJson),
        }),
      ),
      theme: darkTheme,
    );
    await tester.pumpAndSettle();

    expect(find.text('No hay reservas'), findsOneWidget);
    expect(find.text('LIMPIAR FILTROS'), findsNothing);
  });

  testWidgets(
    'with text at 200% at 360 width there is no overflow or exceptions',
    (tester) async {
      await mountScreen(
        tester,
        screen(
          api: apiRoutes({
            'GET /bookings/all': (
              200,
              '{"bookings": [$bookingJson], "total": 1, "page": 1,'
                  ' "per_page": 20, "counters": {"all": 1, "active": 1,'
                  ' "completed": 0, "voided": 0}}',
            ),
            'GET /spaces/catalog': (200, catalogJson),
          }),
        ),
        theme: darkTheme,
        size: const Size(360, 800),
        textScale: 2,
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Reservas'), findsOneWidget);
    },
  );

  String bookingN(int id) => bookingJson
      .replaceFirst(
        '"id": "00000000-0000-7000-8000-000000000001",',
        '"id": "${_uuid(id)}",',
      )
      .replaceFirst('Nahuel Mosse', 'Socio $id');

  String page(Iterable<int> ids, int number) =>
      '{"bookings": [${ids.map(bookingN).join(',')}], "total": 40,'
      ' "page": $number, "per_page": 20, "counters": {"all": 40,'
      ' "active": 40, "completed": 0, "voided": 0}}';

  testWidgets(
    'a filter change with the next page in flight does not lock the scroll '
    'and the next page does not repeat bookings',
    (tester) async {
      final secondPages = <Completer<http.Response>>[];
      final api = ApiClient(
        'http://api.falsa',
        client: MockClient((request) async {
          final headers = {'content-type': 'application/json; charset=utf-8'};
          if (request.url.path == '/bookings/all') {
            if (request.url.queryParameters['page'] == '2') {
              final c = Completer<http.Response>();
              secondPages.add(c);
              return c.future;
            }
            return http.Response.bytes(
              utf8.encode(page(List.generate(20, (i) => i + 1), 1)),
              200,
              headers: headers,
            );
          }
          return http.Response.bytes(
            utf8.encode(catalogJson),
            request.url.path == '/spaces/catalog' ? 200 : 404,
            headers: headers,
          );
        }),
      );
      await mountScreen(
        tester,
        screen(api: api),
        theme: darkTheme,
        size: const Size(393, 852),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -20000));
      await tester.pump();
      await tester.pump();
      expect(secondPages, hasLength(1));
      expect(find.byType(Skeleton, skipOffstage: false), findsOneWidget);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, 20000));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Activas (40)'));
      await tester.pumpAndSettle();
      expect(find.byType(Skeleton, skipOffstage: false), findsNothing);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -20000));
      await tester.pump();
      expect(secondPages, hasLength(2));

      // The next page repeats the last booking of the first.
      secondPages.last.complete(
        http.Response.bytes(
          utf8.encode(page([20, 21], 2)),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -20000));
      await tester.pumpAndSettle();

      expect(find.text('Socio 20'), findsOneWidget);
      expect(find.text('Socio 21'), findsOneWidget);
    },
  );
}
