import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../soporte/admin.dart';
import '../soporte/held_api.dart';
import '../soporte/montar.dart';
import '../soporte/skeleton_capture.dart';

String _booking(int n) {
  final start = DateTime.utc(2026, 12, 1, 18);
  final end = start.add(const Duration(hours: 1));
  return '{"id": "00000000-0000-7000-8000-${n.toString().padLeft(12, '0')}",'
      ' "space_id": "00000000-0000-7000-8000-000000000009",'
      ' "venue_id": "00000000-0000-7000-8000-000000000001",'
      ' "space": "Moron_Rivadavia_19850_Futbol_F5_1", "sport": "Futbol",'
      ' "kind": "F5", "venue": "Sede Morón", "address": "Av. Rivadavia 19850",'
      ' "starts_at": "${start.toIso8601String()}", "ends_at": "${end.toIso8601String()}",'
      ' "total": 38000, "status": "active", "reason": null,'
      ' "user_id": "00000000-0000-7000-8000-000000000001",'
      ' "user": "Socio $n", "created_at": "2026-11-02T18:42:00-03:00",'
      ' "canceled_at": null, "canceled_by_name": null,'
      ' "space_deactivated": false}';
}

final _history =
    '{"bookings": [${_booking(1)}, ${_booking(2)}, ${_booking(3)}], "total": 3,'
    ' "page": 1, "per_page": 20, "counters": {"all": 3,'
    ' "active": 3, "completed": 0, "voided": 0}}';

/// Asserts nothing: it produces each loading state of the admin screens next to the same
/// screen loaded, dark, 393x852.
void main() {
  Future<HeldApi> mount(
    WidgetTester tester,
    String route,
    Map<String, (int, String)> routes,
  ) async {
    final held = HeldApi(routes);
    await mountApp(
      tester,
      api: held.client,
      session: SesionFalsa(perfilAdmin),
      route: route,
    );
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
    await drainApp(tester);
  }

  final spaces = {
    ...rutasDeEspacios(),
    'GET /venues': (200, '{"venues": [$sedeMoronJson]}'),
  };

  testWidgets('admin spaces loading and loaded', (tester) async {
    await loadingAndLoaded(tester, '/admin/espacios', spaces, 'admin_espacios');
  });

  testWidgets('admin venues loading and loaded', (tester) async {
    await loadingAndLoaded(tester, '/admin/sedes', spaces, 'admin_sedes');
  });

  testWidgets('admin history loading and loaded', (tester) async {
    await loadingAndLoaded(tester, '/admin', {
      'GET /bookings/all': (200, _history),
      'GET /spaces/catalog': (200, catalogoJson),
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
