import 'dart:convert';

import 'package:clubnahuelmosse/admin/historial_reservas.dart';
import 'package:clubnahuelmosse/admin/pantalla_detalle_reserva.dart';
import 'package:clubnahuelmosse/admin/pantalla_panel_admin.dart';
import 'package:clubnahuelmosse/comun/formato_precio.dart';
import 'package:clubnahuelmosse/espacios/espacios.dart';
import 'package:clubnahuelmosse/sedes/sedes.dart';
import 'package:clubnahuelmosse/tema/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'soporte/admin.dart';
import 'soporte/montar.dart';

String reservaJson({bool anulable = true, String estado = 'activa'}) =>
    '{"id": 1, "espacio_id": 9, "sede_id": 1, "espacio":'
    ' "Moron_Rivadavia_19850_Futbol_F5_1", "deporte": "Futbol", "tipo": "F5", "sede":'
    ' "Sede Morón", "direccion": "Av. Rivadavia 19850", "inicio":'
    ' "2026-11-12T21:00:00-03:00", "fin": "2026-11-12T22:00:00-03:00", "total": 38000,'
    ' "estado": "$estado", "motivo": ${estado == 'anulada' ? '"lluvia"' : 'null'},'
    ' "usuario_id": 1, "usuario": "Nahuel Mosse",'
    ' "creado_en": "2026-11-02T18:42:00-03:00", "cancelada_en": null,'
    ' "cancelada_por_nombre": null, "espacio_de_baja": false,'
    ' "anulable": $anulable}';

String listado(String reserva) =>
    '{"reservas": [$reserva], "total": 1, "pagina": 1, "por_pagina": 20,'
    ' "contadores": {"todas": 1, "activas": 1, "completadas": 0, "anuladas": 0}}';

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
      'GET /reservas/todas': (200, listado(reservaJson(anulable: anulable))),
      'GET /espacios/catalogo': (200, catalogoJson),
      'POST /reservas/1/anular':
          alAnular ?? (200, reservaJson(anulable: false, estado: 'anulada')),
    }, pedidos: pedidos);
    final sesion = SesionFalsa(perfilAdmin);
    await montar(
      tester,
      PantallaPanelAdmin(
        historial: HistorialDeReservas(api: api, sesion: sesion),
        sedes: Sedes(api: api, sesion: sesion),
        espacios: Espacios(api: api, sesion: sesion),
        sesion: sesion,
        pendientes: FiltrosDePanelPendientes(),
      ),
      tema: temaOscuro,
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
    for (final dato in ['Nahuel Mosse', 'Sede Morón', pesos(38000)]) {
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
        'motivo': 'Mantenimiento',
        'espacio_id': 9,
        'inicio': '2026-11-13T00:00:00.000Z',
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
      alAnular: (409, '{"errores": {"reserva": "Esto cambió mientras tanto"}}'),
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
        'POST /reservas/1/anular': (
          200,
          reservaJson(anulable: false, estado: 'anulada'),
        ),
      }, pedidos: pedidos);
      final sesion = SesionFalsa(perfilAdmin);
      final reserva = ReservaHistorial.desdeJson(jsonDecode(reservaJson()));
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
                      builder: (_) => PantallaDetalleReserva(
                        reserva: reserva,
                        historial: HistorialDeReservas(
                          api: api,
                          sesion: sesion,
                        ),
                        sesion: sesion,
                      ),
                    ),
                  );
                },
                child: const Text('ABRIR'),
              ),
            ),
          ),
        ),
        tema: temaOscuro,
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
