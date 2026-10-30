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

import '../soporte/admin.dart';
import '../soporte/montar.dart';
import 'package:clubnahuelmosse/features/spaces/presentation/spaces.dart';
import 'package:clubnahuelmosse/features/venues/presentation/venues.dart';

String _uuid(int n) =>
    '00000000-0000-7000-8000-${n.toString().padLeft(12, '0')}';

void main() {
  setUpAll(cargarFuentes);

  const reservaJson =
      '{"id": "00000000-0000-7000-8000-000000000001", "space_id": "00000000-0000-7000-8000-000000000009", "venue_id": "00000000-0000-7000-8000-000000000001", "space":'
      ' "Moron_Rivadavia_19850_Futbol_F5_1", "sport": "Futbol", "kind": "F5", "venue":'
      ' "Sede Morón", "address": "Av. Rivadavia 19850", "starts_at":'
      ' "2026-11-12T21:00:00-03:00", "ends_at": "2026-11-12T22:00:00-03:00", "total": 38000,'
      ' "status": "active", "reason": null, "user_id": "00000000-0000-7000-8000-000000000001", "user": "Nahuel Mosse",'
      ' "created_at": "2026-11-02T18:42:00-03:00", "canceled_at": null,'
      ' "canceled_by_name": null, "space_deactivated": false}';

  Widget pantalla({required ApiClient api}) {
    final sesion = SesionFalsa(perfilAdmin);
    return AdminPanelScreen(
      history: BookingHistory(api: api, sesion: sesion),
      venues: Venues(
        repository: VenuesRepository(api: api, session: sesion),
      ),
      spaces: Spaces(
        repository: SpacesRepository(api: api, session: sesion),
      ),
      session: sesion,
      pending: PendingPanelFilters(),
    );
  }

  testWidgets('muestra el listado con el total y el contador de cada pestaña', (
    tester,
  ) async {
    await montar(
      tester,
      pantalla(
        api: apiRutas({
          'GET /bookings/all': (
            200,
            '{"bookings": [$reservaJson], "total": 1, "page": 1,'
                ' "per_page": 20, "counters": {"all": 1, "active": 1,'
                ' "completed": 0, "voided": 0}}',
          ),
          'GET /spaces/catalog': (200, catalogoJson),
        }),
      ),
      tema: darkTheme,
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('1 RESERVA EN TOTAL'), findsOneWidget);
    expect(find.text('Activas (1)'), findsOneWidget);
    expect(find.text('Nahuel Mosse'), findsOneWidget);
    expect(find.text('ACTIVA'), findsOneWidget);
  });

  testWidgets('sin reservas en el sistema muestra «No hay reservas»', (
    tester,
  ) async {
    await montar(
      tester,
      pantalla(
        api: apiRutas({
          'GET /bookings/all': (
            200,
            '{"bookings": [], "total": 0, "page": 1, "per_page": 20,'
                ' "counters": {"all": 0, "active": 0, "completed": 0,'
                ' "voided": 0}}',
          ),
          'GET /spaces/catalog': (200, catalogoJson),
        }),
      ),
      tema: darkTheme,
    );
    await tester.pumpAndSettle();

    expect(find.text('No hay reservas'), findsOneWidget);
    expect(find.text('LIMPIAR FILTROS'), findsNothing);
  });

  testWidgets(
    'con el texto al 200% en 360 de ancho no hay overflow ni excepciones',
    (tester) async {
      await montar(
        tester,
        pantalla(
          api: apiRutas({
            'GET /bookings/all': (
              200,
              '{"bookings": [$reservaJson], "total": 1, "page": 1,'
                  ' "per_page": 20, "counters": {"all": 1, "active": 1,'
                  ' "completed": 0, "voided": 0}}',
            ),
            'GET /spaces/catalog': (200, catalogoJson),
          }),
        ),
        tema: darkTheme,
        tamano: const Size(360, 800),
        escalaTexto: 2,
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Reservas'), findsOneWidget);
    },
  );

  String reservaN(int id) => reservaJson
      .replaceFirst(
        '"id": "00000000-0000-7000-8000-000000000001",',
        '"id": "${_uuid(id)}",',
      )
      .replaceFirst('Nahuel Mosse', 'Socio $id');

  String pagina(Iterable<int> ids, int numero) =>
      '{"bookings": [${ids.map(reservaN).join(',')}], "total": 40,'
      ' "page": $numero, "per_page": 20, "counters": {"all": 40,'
      ' "active": 40, "completed": 0, "voided": 0}}';

  testWidgets(
    'un cambio de filtro con la página siguiente en camino no traba el scroll '
    'y la página siguiente no repite reservas',
    (tester) async {
      final segundas = <Completer<http.Response>>[];
      final api = ApiClient(
        'http://api.falsa',
        cliente: MockClient((pedido) async {
          final cabeceras = {'content-type': 'application/json; charset=utf-8'};
          if (pedido.url.path == '/bookings/all') {
            if (pedido.url.queryParameters['page'] == '2') {
              final c = Completer<http.Response>();
              segundas.add(c);
              return c.future;
            }
            return http.Response.bytes(
              utf8.encode(pagina(List.generate(20, (i) => i + 1), 1)),
              200,
              headers: cabeceras,
            );
          }
          return http.Response.bytes(
            utf8.encode(catalogoJson),
            pedido.url.path == '/spaces/catalog' ? 200 : 404,
            headers: cabeceras,
          );
        }),
      );
      await montar(
        tester,
        pantalla(api: api),
        tema: darkTheme,
        tamano: const Size(393, 852),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -20000));
      await tester.pump();
      await tester.pump();
      expect(segundas, hasLength(1));
      expect(find.byType(Skeleton, skipOffstage: false), findsOneWidget);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, 20000));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Activas (40)'));
      await tester.pumpAndSettle();
      expect(find.byType(Skeleton, skipOffstage: false), findsNothing);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -20000));
      await tester.pump();
      expect(segundas, hasLength(2));

      // La página siguiente repite la última reserva de la primera.
      segundas.last.complete(
        http.Response.bytes(
          utf8.encode(pagina([20, 21], 2)),
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
