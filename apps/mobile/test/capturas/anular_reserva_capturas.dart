import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide testWidgets;

import '../soporte/admin.dart';
import '../soporte/montar.dart';
import '../soporte/reloj_fijo.dart';

/// No afirma nada: produce la tira del paso 9 para mirarla contra el prototipo (CU-15).
void main() {
  setUpAll(cargarFuentes);

  const telefonos = {'360': Size(360, 800), '430': Size(430, 932)};
  const modos = {'oscuro': true, 'claro': false};

  const reservaJson =
      '{"id": 1, "espacio_id": 9, "sede_id": 1, "espacio":'
      ' "Moron_Rivadavia_19850_Futbol_F5_1", "deporte": "Futbol", "tipo": "F5", "sede":'
      ' "Sede Morón", "direccion": "Av. Rivadavia 19850", "inicio":'
      ' "2026-11-12T21:00:00-03:00", "fin": "2026-11-12T22:00:00-03:00", "total": 38000,'
      ' "estado": "activa", "motivo": null, "usuario_id": 1, "usuario": "Nahuel Mosse",'
      ' "creado_en": "2026-11-02T18:42:00-03:00", "cancelada_en": null,'
      ' "cancelada_por_nombre": null, "espacio_de_baja": false, "anulable": true}';

  Future<void> abrirConfirmacion(
    WidgetTester tester, {
    required bool oscuro,
    required Size tamano,
  }) async {
    await montarAdmin(
      tester,
      inicio: '/admin',
      oscuro: oscuro,
      tamano: tamano,
      api: apiRutas({
        'GET /reservas/todas': (
          200,
          '{"reservas": [$reservaJson], "total": 1, "pagina": 1, "por_pagina": 20,'
              ' "contadores": {"todas": 1, "activas": 1, "completadas": 0, "anuladas": 0}}',
        ),
        'GET /espacios/catalogo': (200, catalogoJson),
      }),
    );
  }

  Future<void> capturar(WidgetTester tester, String archivo) async {
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile(archivo));
  }

  for (final MapEntry(key: ancho, value: tamano) in telefonos.entries) {
    for (final MapEntry(key: modo, value: oscuro) in modos.entries) {
      testWidgets('listado con ANULAR RESERVA $ancho $modo', (tester) async {
        await abrirConfirmacion(tester, oscuro: oscuro, tamano: tamano);
        await capturar(tester, 'reservas/anular_listado_${ancho}_$modo.png');
      });

      testWidgets('confirmar anulación $ancho $modo', (tester) async {
        await abrirConfirmacion(tester, oscuro: oscuro, tamano: tamano);
        await tester.tap(find.text('ANULAR RESERVA'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextField).last,
          'Mantenimiento urgente del césped sintético.',
        );
        await capturar(tester, 'reservas/anular_confirmar_${ancho}_$modo.png');
      });

      testWidgets('anular sin motivo $ancho $modo', (tester) async {
        await abrirConfirmacion(tester, oscuro: oscuro, tamano: tamano);
        await tester.tap(find.text('ANULAR RESERVA'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('CONFIRMAR ANULACIÓN'));
        await capturar(tester, 'reservas/anular_sin_motivo_${ancho}_$modo.png');
      });
    }
  }
}
