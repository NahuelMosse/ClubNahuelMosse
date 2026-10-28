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
      '{"id": "00000000-0000-7000-8000-000000000001", "espacio_id": "00000000-0000-7000-8000-000000000009", "sede_id": "00000000-0000-7000-8000-000000000001", "espacio":'
      ' "Moron_Rivadavia_19850_Futbol_F5_1", "deporte": "Futbol", "tipo": "F5", "sede":'
      ' "Sede Morón", "direccion": "Av. Rivadavia 19850", "inicio":'
      ' "2026-11-12T21:00:00-03:00", "fin": "2026-11-12T22:00:00-03:00", "total": 38000,'
      ' "estado": "activa", "motivo": null, "usuario_id": "00000000-0000-7000-8000-000000000001", "usuario": "Nahuel Mosse",'
      ' "creado_en": "2026-11-02T18:42:00-03:00", "cancelada_en": null,'
      ' "cancelada_por_nombre": null, "espacio_de_baja": false}';

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
          'GET /reservas/todas': (
            200,
            '{"reservas": [$reservaJson], "total": 1, "pagina": 1,'
                ' "por_pagina": 20, "contadores": {"todas": 1, "activas": 1,'
                ' "completadas": 0, "anuladas": 0}}',
          ),
          'GET /espacios/catalogo': (200, catalogoJson),
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
          'GET /reservas/todas': (
            200,
            '{"reservas": [], "total": 0, "pagina": 1, "por_pagina": 20,'
                ' "contadores": {"todas": 0, "activas": 0, "completadas": 0,'
                ' "anuladas": 0}}',
          ),
          'GET /espacios/catalogo': (200, catalogoJson),
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
            'GET /reservas/todas': (
              200,
              '{"reservas": [$reservaJson], "total": 1, "pagina": 1,'
                  ' "por_pagina": 20, "contadores": {"todas": 1, "activas": 1,'
                  ' "completadas": 0, "anuladas": 0}}',
            ),
            'GET /espacios/catalogo': (200, catalogoJson),
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
      '{"reservas": [${ids.map(reservaN).join(',')}], "total": 40,'
      ' "pagina": $numero, "por_pagina": 20, "contadores": {"todas": 40,'
      ' "activas": 40, "completadas": 0, "anuladas": 0}}';

  testWidgets(
    'un cambio de filtro con la página siguiente en camino no traba el scroll '
    'y la página siguiente no repite reservas',
    (tester) async {
      final segundas = <Completer<http.Response>>[];
      final api = ApiClient(
        'http://api.falsa',
        cliente: MockClient((pedido) async {
          final cabeceras = {'content-type': 'application/json; charset=utf-8'};
          if (pedido.url.path == '/reservas/todas') {
            if (pedido.url.queryParameters['pagina'] == '2') {
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
            pedido.url.path == '/espacios/catalogo' ? 200 : 404,
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
