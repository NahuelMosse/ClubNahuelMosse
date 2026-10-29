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

import 'soporte/admin.dart';
import 'soporte/montar.dart';
import 'package:clubnahuelmosse/features/spaces/presentation/spaces.dart';
import 'package:clubnahuelmosse/features/venues/presentation/venues.dart';

String reservaJson({bool anulable = true, String estado = 'active'}) =>
    '{"id": "00000000-0000-7000-8000-000000000001", "space_id": "00000000-0000-7000-8000-000000000009", "venue_id": "00000000-0000-7000-8000-000000000001", "space":'
    ' "Moron_Rivadavia_19850_Futbol_F5_1", "sport": "Futbol", "kind": "F5", "venue":'
    ' "Sede Morón", "address": "Av. Rivadavia 19850", "starts_at":'
    ' "2026-11-12T21:00:00-03:00", "ends_at": "2026-11-12T22:00:00-03:00", "total": 38000,'
    ' "status": "$estado", "reason": ${estado == 'voided' ? '"lluvia"' : 'null'},'
    ' "user_id": "00000000-0000-7000-8000-000000000001", "user": "Nahuel Mosse",'
    ' "created_at": "2026-11-02T18:42:00-03:00", "canceled_at": null,'
    ' "canceled_by_name": null, "space_deactivated": false,'
    ' "voidable": $anulable}';

String listado(String reserva) =>
    '{"bookings": [$reserva], "total": 1, "page": 1, "per_page": 20,'
    ' "counters": {"all": 1, "active": 1, "completed": 0, "voided": 0}}';

void main() {
  setUpAll(cargarFuentes);

  Future<List<http.Request>> abrirPanel(
    WidgetTester tester, {
    bool anulable = true,
    (int, String)? alAnular,
    Size tamano = const Size(393, 852),
    double escala = 1,
  }) async {
    final pedidos = <http.Request>[];
    final api = apiRutas({
      'GET /bookings/all': (200, listado(reservaJson(anulable: anulable))),
      'GET /spaces/catalog': (200, catalogoJson),
      'POST /bookings/00000000-0000-7000-8000-000000000001/void':
          alAnular ?? (200, reservaJson(anulable: false, estado: 'voided')),
    }, pedidos: pedidos);
    final sesion = SesionFalsa(perfilAdmin);
    await montar(
      tester,
      AdminPanelScreen(
        history: BookingHistory(api: api, sesion: sesion),
        venues: Venues(
          repository: VenuesRepository(api: api, session: sesion),
        ),
        spaces: Spaces(
          repository: SpacesRepository(api: api, session: sesion),
        ),
        session: sesion,
        pending: PendingPanelFilters(),
      ),
      tema: darkTheme,
      tamano: tamano,
      escalaTexto: escala,
    );
    return pedidos;
  }

  Future<void> pedirAnular(WidgetTester tester) async {
    await tester.ensureVisible(find.text('ANULAR RESERVA'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ANULAR RESERVA'));
    await tester.pumpAndSettle();
  }

  Future<void> tocarTexto(WidgetTester tester, String texto) async {
    await tester.ensureVisible(find.text(texto));
    await tester.pumpAndSettle();
    await tester.tap(find.text(texto));
    await tester.pumpAndSettle();
  }

  Iterable<http.Request> anulaciones(List<http.Request> pedidos) =>
      pedidos.where((p) => p.method == 'POST');

  testWidgets('la confirmación muestra los datos de la reserva', (
    tester,
  ) async {
    await abrirPanel(tester);

    await pedirAnular(tester);

    expect(find.text('¿Anular esta reserva?'), findsOneWidget);
    final dialogo = find.byType(Dialog);
    for (final dato in ['Nahuel Mosse', 'Sede Morón', formatPesos(38000)]) {
      expect(
        find.descendant(of: dialogo, matching: find.text(dato)),
        findsOneWidget,
      );
    }
    expect(find.text('MOTIVO DE LA ANULACIÓN'), findsOneWidget);
  });

  testWidgets(
    'confirmar con motivo manda la anulación y avisa @supuesto:CU-15-SUP-04',
    (tester) async {
      final pedidos = await abrirPanel(tester);

      await pedirAnular(tester);
      await tester.enterText(find.byType(TextField).last, '  Mantenimiento  ');
      await tocarTexto(tester, 'CONFIRMAR ANULACIÓN');

      final pedido = anulaciones(pedidos).single;
      expect(jsonDecode(pedido.body), {
        'reason': 'Mantenimiento',
        'space_id': '00000000-0000-7000-8000-000000000009',
        'starts_at': '2026-11-13T00:00:00.000Z',
      });
      expect(find.text('Reserva anulada correctamente'), findsOneWidget);
      await tocarTexto(tester, 'ACEPTAR');
      expect(find.text('Reserva anulada correctamente'), findsNothing);
    },
  );

  testWidgets('sin motivo avisa que es obligatorio y no manda nada', (
    tester,
  ) async {
    final pedidos = await abrirPanel(tester);

    await pedirAnular(tester);
    await tester.enterText(find.byType(TextField).last, '   ');
    await tocarTexto(tester, 'CONFIRMAR ANULACIÓN');

    expect(find.text('El motivo es obligatorio para anular'), findsOneWidget);
    expect(find.text('¿Anular esta reserva?'), findsOneWidget);
    expect(anulaciones(pedidos), isEmpty);

    await tester.enterText(find.byType(TextField).last, 'Lluvia');
    await tester.pumpAndSettle();
    expect(find.text('El motivo es obligatorio para anular'), findsNothing);
  });

  testWidgets('VOLVER cierra la confirmación sin pedir nada', (tester) async {
    final pedidos = await abrirPanel(tester);

    await pedirAnular(tester);
    await tocarTexto(tester, 'VOLVER');

    expect(find.text('¿Anular esta reserva?'), findsNothing);
    expect(find.text('ANULAR RESERVA'), findsOneWidget);
    expect(anulaciones(pedidos), isEmpty);
  });

  testWidgets('si la reserva cambió, avisa y vuelve a leer el listado', (
    tester,
  ) async {
    final pedidos = await abrirPanel(
      tester,
      alAnular: (409, '{"errors": {"reserva": "Esto cambió mientras tanto"}}'),
    );

    await pedirAnular(tester);
    await tester.enterText(find.byType(TextField).last, 'Lluvia');
    await tocarTexto(tester, 'CONFIRMAR ANULACIÓN');

    expect(find.text('Esto cambió mientras tanto'), findsOneWidget);
    final lecturas = pedidos.where((p) => p.method == 'GET').length;
    await tocarTexto(tester, 'VER LO ACTUALIZADO');
    expect(
      pedidos.where((p) => p.method == 'GET').length,
      greaterThan(lecturas),
    );
  });

  testWidgets(
    'si el servidor falla, avisa y la reserva sigue ofreciendo anular @supuesto:CU-15-SUP-08',
    (tester) async {
      await abrirPanel(tester, alAnular: (500, '{}'));

      await pedirAnular(tester);
      await tester.enterText(find.byType(TextField).last, 'Lluvia');
      await tocarTexto(tester, 'CONFIRMAR ANULACIÓN');

      expect(find.text('Error del servidor'), findsOneWidget);
      await tocarTexto(tester, 'ACEPTAR');
      expect(find.text('ANULAR RESERVA'), findsOneWidget);
    },
  );

  testWidgets(
    'una reserva que el servidor no da por anulable no lo ofrece @supuesto:CU-15-SUP-06',
    (tester) async {
      await abrirPanel(tester, anulable: false);

      expect(find.text('Nahuel Mosse'), findsOneWidget);
      expect(find.text('ANULAR RESERVA'), findsNothing);
    },
  );

  testWidgets(
    'el detalle también ofrece anular y avisa al volver @supuesto:CU-15-SUP-06',
    (tester) async {
      final pedidos = <http.Request>[];
      final api = apiRutas({
        'POST /bookings/00000000-0000-7000-8000-000000000001/void': (
          200,
          reservaJson(anulable: false, estado: 'voided'),
        ),
      }, pedidos: pedidos);
      final sesion = SesionFalsa(perfilAdmin);
      final reserva = parseBookingHistoryEntry(jsonDecode(reservaJson()));
      if (reserva == null) fail('la reserva de prueba no se lee');
      bool? resultado;
      await montar(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  resultado = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => BookingDetailScreen(
                        booking: reserva,
                        history: BookingHistory(api: api, sesion: sesion),
                        session: sesion,
                        spaces: Spaces(
                          repository: SpacesRepository(
                            api: api,
                            session: sesion,
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
        tema: darkTheme,
      );
      await tester.tap(find.text('ABRIR'));
      await tester.pumpAndSettle();

      await pedirAnular(tester);
      await tester.enterText(find.byType(TextField).last, 'Lluvia');
      await tocarTexto(tester, 'CONFIRMAR ANULACIÓN');
      await tocarTexto(tester, 'ACEPTAR');

      expect(anulaciones(pedidos), hasLength(1));
      expect(resultado, isTrue);
      expect(find.text('ABRIR'), findsOneWidget);
    },
  );

  testWidgets(
    'con el texto al 200% en 360 de ancho la confirmación no desborda',
    (tester) async {
      await abrirPanel(tester, tamano: const Size(360, 800), escala: 2);

      await pedirAnular(tester);
      await tocarTexto(tester, 'CONFIRMAR ANULACIÓN');

      expect(tester.takeException(), isNull);
      expect(find.text('El motivo es obligatorio para anular'), findsOneWidget);
    },
  );
}
