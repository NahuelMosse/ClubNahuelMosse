import 'package:clubnahuelmosse/app.dart';
import 'package:clubnahuelmosse/common/appearance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../soporte/admin.dart';
import '../soporte/held_api.dart';
import '../soporte/montar.dart';

String _booking(int n) {
  final start = DateTime.utc(2026, 12, 1, 18);
  final end = start.add(const Duration(hours: 1));
  return '{"id": "00000000-0000-7000-8000-${n.toString().padLeft(12, '0')}",'
      ' "espacio_id": "00000000-0000-7000-8000-000000000009",'
      ' "sede_id": "00000000-0000-7000-8000-000000000001",'
      ' "espacio": "Moron_Rivadavia_19850_Futbol_F5_1", "deporte": "Futbol",'
      ' "tipo": "F5", "sede": "Sede Morón", "direccion": "Av. Rivadavia 19850",'
      ' "inicio": "${start.toIso8601String()}", "fin": "${end.toIso8601String()}",'
      ' "total": 38000, "estado": "activa", "motivo": null,'
      ' "usuario_id": "00000000-0000-7000-8000-000000000001",'
      ' "usuario": "Socio $n", "creado_en": "2026-11-02T18:42:00-03:00",'
      ' "cancelada_en": null, "cancelada_por_nombre": null,'
      ' "espacio_de_baja": false}';
}

final _history =
    '{"reservas": [${_booking(1)}, ${_booking(2)}, ${_booking(3)}], "total": 3,'
    ' "pagina": 1, "por_pagina": 20, "contadores": {"todas": 3,'
    ' "activas": 3, "completadas": 0, "anuladas": 0}}';

/// Asserts nothing: it produces each loading state of the admin screens next to the same
/// screen loaded, dark, 393x852.
void main() {
  Future<HeldApi> mount(
    WidgetTester tester,
    String route,
    Map<String, (int, String)> routes,
  ) async {
    tester.view.physicalSize = const Size(393, 852) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await cargarFuentes();
    final held = HeldApi(routes);
    await tester.pumpWidget(
      App(
        api: held.client,
        session: SesionFalsa(perfilAdmin),
        appearance: Appearance.inMemory(dark: true),
        initialLocation: route,
      ),
    );
    await tester.pump();
    await tester.pump();
    return held;
  }

  Future<void> capture(WidgetTester tester, String file) =>
      expectLater(find.byType(MaterialApp), matchesGoldenFile(file));

  Future<void> loadingAndLoaded(
    WidgetTester tester,
    String route,
    Map<String, (int, String)> routes,
    String name,
  ) async {
    final held = await mount(tester, route, routes);
    await capture(tester, 'skeletons/${name}_cargando.png');
    held.release();
    await tester.pumpAndSettle();
    await capture(tester, 'skeletons/${name}_cargada.png');
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 2));
  }

  final spaces = {
    ...rutasDeEspacios(),
    'GET /sedes': (200, '{"sedes": [$sedeMoronJson]}'),
  };

  testWidgets('admin spaces loading and loaded', (tester) async {
    await loadingAndLoaded(tester, '/admin/espacios', spaces, 'admin_espacios');
  });

  testWidgets('admin venues loading and loaded', (tester) async {
    await loadingAndLoaded(tester, '/admin/sedes', spaces, 'admin_sedes');
  });

  testWidgets('admin history loading and loaded', (tester) async {
    await loadingAndLoaded(tester, '/admin', {
      'GET /reservas/todas': (200, _history),
      'GET /espacios/catalogo': (200, catalogoJson),
    }, 'admin_historial');
  });

  testWidgets('new space loading and loaded', (tester) async {
    await loadingAndLoaded(
      tester,
      '/admin/espacios/nuevo',
      rutasDeEspacios(),
      'admin_nuevo_espacio',
    );
  });
}
