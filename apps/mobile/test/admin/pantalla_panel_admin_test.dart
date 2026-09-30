import 'package:clubnahuelmosse/admin/historial_reservas.dart';
import 'package:clubnahuelmosse/admin/pantalla_panel_admin.dart';
import 'package:clubnahuelmosse/api/cliente_api.dart';
import 'package:clubnahuelmosse/espacios/espacios.dart';
import 'package:clubnahuelmosse/sedes/sedes.dart';
import 'package:clubnahuelmosse/tema/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../soporte/admin.dart';
import '../soporte/montar.dart';

void main() {
  setUpAll(cargarFuentes);

  const reservaJson =
      '{"id": 1, "espacio_id": 9, "sede_id": 1, "espacio":'
      ' "Moron_Rivadavia_19850_Futbol_F5_1", "deporte": "Futbol", "tipo": "F5", "sede":'
      ' "Sede Morón", "direccion": "Av. Rivadavia 19850", "inicio":'
      ' "2026-11-12T21:00:00-03:00", "fin": "2026-11-12T22:00:00-03:00", "total": 38000,'
      ' "estado": "activa", "motivo": null, "usuario_id": 1, "usuario": "Nahuel Mosse",'
      ' "creado_en": "2026-11-02T18:42:00-03:00", "cancelada_en": null,'
      ' "cancelada_por_nombre": null, "espacio_de_baja": false}';

  Widget pantalla({required ClienteApi api}) {
    final sesion = SesionFalsa(perfilAdmin);
    return PantallaPanelAdmin(
      historial: HistorialDeReservas(api: api, sesion: sesion),
      sedes: Sedes(api: api, sesion: sesion),
      espacios: Espacios(api: api, sesion: sesion),
      sesion: sesion,
      pendientes: FiltrosDePanelPendientes(),
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
      tema: temaOscuro,
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
      tema: temaOscuro,
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
        tema: temaOscuro,
        tamano: const Size(360, 800),
        escalaTexto: 2,
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Reservas'), findsOneWidget);
    },
  );
}
