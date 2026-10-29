import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'soporte/admin.dart';
import 'soporte/montar.dart';

const _english = [Locale('en', 'US')];

const _bookingJson =
    '{"id": "00000000-0000-7000-8000-000000000001", "espacio_id": "00000000-0000-7000-8000-000000000009", "sede_id": "00000000-0000-7000-8000-000000000001", "espacio":'
    ' "Moron_Rivadavia_19850_Futbol_F5_1", "deporte": "Futbol", "tipo": "F5", "sede":'
    ' "Sede Morón", "direccion": "Av. Rivadavia 19850", "inicio":'
    ' "2026-11-12T21:00:00-03:00", "fin": "2026-11-12T22:00:00-03:00", "total": 38000,'
    ' "estado": "activa", "motivo": null, "usuario_id": "00000000-0000-7000-8000-000000000001", "usuario": "Nahuel Mosse",'
    ' "creado_en": "2026-11-02T18:42:00-03:00", "cancelada_en": null,'
    ' "cancelada_por_nombre": null, "espacio_de_baja": false}';

void main() {
  setUpAll(cargarFuentes);

  testWidgets(
    'the admin panel, its lists and its forms show English @ENG-19-S1',
    (tester) async {
      tester.platformDispatcher.localesTestValue = _english;
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      final semantics = tester.ensureSemantics();

      await montarAdmin(
        tester,
        inicio: '/admin',
        api: apiRutas({
          'GET /reservas/todas': (
            200,
            '{"reservas": [$_bookingJson], "total": 1, "pagina": 1,'
                ' "por_pagina": 20, "contadores": {"todas": 1, "activas": 1,'
                ' "completadas": 0, "anuladas": 0}}',
          ),
          'GET /espacios/catalogo': (200, catalogoJson),
        }),
      );
      expect(find.text('ADMIN PANEL'), findsOneWidget);
      expect(find.text('Bookings'), findsOneWidget);
      expect(find.textContaining('1 BOOKING IN TOTAL'), findsOneWidget);
      expect(find.text('Active (1)'), findsOneWidget);
      expect(find.text('VOID BOOKING'), findsOneWidget);
      expect(find.text('Activas (1)'), findsNothing);

      await montarAdmin(
        tester,
        api: apiRutas({
          'GET /sedes': (200, '{"sedes": [$sedeMoronJson]}'),
        }),
      );
      expect(find.text('Venues'), findsOneWidget);
      expect(find.text('ADD VENUE'), findsOneWidget);
      expect(find.text('1 ACTIVE VENUE'), findsOneWidget);
      expect(find.bySemanticsLabel('Edit venue Sede Morón'), findsOneWidget);
      expect(find.text('AGREGAR SEDE'), findsNothing);

      await montarAdmin(
        tester,
        inicio: '/admin/espacios',
        api: apiRutas(rutasDeEspacios()),
      );
      expect(find.text('Spaces'), findsOneWidget);
      expect(find.text('ADD SPACE'), findsOneWidget);
      expect(find.textContaining('1 ACTIVE SPACE'), findsOneWidget);
      expect(find.text('ALTA ESPACIO'), findsNothing);

      await montarAdmin(
        tester,
        inicio: '/admin/sedes/nueva',
        api: apiRutas({'GET /sedes': (200, '{"sedes": []}')}),
      );
      expect(find.text('New venue'), findsOneWidget);
      expect(find.text('VENUE NAME'), findsOneWidget);
      expect(find.text('ADDRESS'), findsOneWidget);
      expect(find.text('OPENING TIME'), findsOneWidget);
      expect(find.text('CLOSING TIME'), findsOneWidget);
      expect(find.text('SAVE VENUE'), findsOneWidget);
      expect(find.text('GUARDAR SEDE'), findsNothing);

      await montarAdmin(
        tester,
        inicio: '/admin/espacios/nuevo',
        api: apiRutas(rutasDeEspacios()),
      );
      expect(find.text('New sports space'), findsOneWidget);
      expect(find.text('SAVE SPACE'), findsOneWidget);
      expect(find.text('CANCEL'), findsOneWidget);
      expect(find.text('PRICE PER HOUR'), findsOneWidget);
      expect(find.text('GUARDAR ESPACIO'), findsNothing);
      semantics.dispose();
    },
  );
}
