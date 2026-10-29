import 'package:clubnahuelmosse/features/session/presentation/access_denied_screen.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide testWidgets;

import '../soporte/admin.dart';
import '../soporte/montar.dart';
import '../soporte/reloj_fijo.dart';

/// No afirma nada: produce la tira del paso 9 para mirarla contra el prototipo (CU-14).
void main() {
  setUpAll(cargarFuentes);

  const telefonos = {'360': Size(360, 800), '430': Size(430, 932)};
  const modos = {'oscuro': true, 'claro': false};

  Future<void> capturar(WidgetTester tester, String archivo) async {
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile(archivo));
  }

  const contadores =
      '"counters": {"all": 49, "active": 12, "completed": 31, "voided": 5}';

  const reservaActivaJson =
      '{"id": "00000000-0000-7000-8000-000000000001", "space_id": "00000000-0000-7000-8000-000000000009", "venue_id": "00000000-0000-7000-8000-000000000001", "space":'
      ' "Moron_Rivadavia_19850_Futbol_F5_1", "sport": "Futbol", "kind": "F5", "venue":'
      ' "Sede Morón", "address": "Av. Rivadavia 19850", "starts_at":'
      ' "2026-11-12T21:00:00-03:00", "ends_at": "2026-11-12T22:00:00-03:00", "total": 38000,'
      ' "status": "active", "reason": null, "user_id": "00000000-0000-7000-8000-000000000001", "user": "Nahuel Mosse",'
      ' "created_at": "2026-11-02T18:42:00-03:00", "canceled_at": null,'
      ' "canceled_by_name": null, "space_deactivated": false, "voidable": true}';

  const reservaCompletadaJson =
      '{"id": "00000000-0000-7000-8000-000000000002", "space_id": "00000000-0000-7000-8000-000000000010", "venue_id": "00000000-0000-7000-8000-000000000002", "space":'
      ' "RamosMejia_Belgrano_1240_Voley_IND_1", "sport": "Voley", "kind": "IND", "venue":'
      ' "Sede Ramos Mejía", "address": "Calle Belgrano 1240", "starts_at":'
      ' "2026-11-04T20:00:00-03:00", "ends_at": "2026-11-04T21:00:00-03:00", "total": 33000,'
      ' "status": "completed", "reason": null, "user_id": "00000000-0000-7000-8000-000000000001", "user": "Nahuel Mosse",'
      ' "created_at": "2026-10-20T09:10:00-03:00", "canceled_at": null,'
      ' "canceled_by_name": null, "space_deactivated": false}';

  const reservaAnuladaJson =
      '{"id": "00000000-0000-7000-8000-000000000003", "space_id": "00000000-0000-7000-8000-000000000011", "venue_id": "00000000-0000-7000-8000-000000000002", "space":'
      ' "RamosMejia_Belgrano_1240_Hockey_H7_1", "sport": "Hockey", "kind": "H7", "venue":'
      ' "Sede Ramos Mejía", "address": "Calle Belgrano 1240", "starts_at":'
      ' "2026-10-30T19:00:00-03:00", "ends_at": "2026-10-30T20:00:00-03:00", "total": 48000,'
      ' "status": "voided", "reason": "mantenimiento de la cancha", "user_id": "00000000-0000-7000-8000-000000000001",'
      ' "user": "Nahuel Mosse", "created_at": "2026-10-21T11:07:00-03:00",'
      ' "canceled_at": "2026-10-28T09:15:00-03:00", "canceled_by_name":'
      ' "Admin Sistema", "space_deactivated": false, "notice_delivery": "sent",'
      ' "notice_at": "2026-10-28T09:15:00-03:00"}';

  for (final MapEntry(key: ancho, value: tamano) in telefonos.entries) {
    for (final MapEntry(key: modo, value: oscuro) in modos.entries) {
      testWidgets('listado con reservas $ancho $modo', (tester) async {
        await montarAdmin(
          tester,
          inicio: '/admin',
          oscuro: oscuro,
          tamano: tamano,
          api: apiRutas({
            'GET /bookings/all': (
              200,
              '{"bookings": [$reservaActivaJson, $reservaCompletadaJson,'
                  ' $reservaAnuladaJson], "total": 49, "page": 1, "per_page": 20,'
                  ' $contadores}',
            ),
            'GET /spaces/catalog': (200, catalogoJson),
          }),
        );
        await capturar(tester, 'admin/reservas_${ancho}_$modo.png');
      });

      testWidgets('listado cargando $ancho $modo', (tester) async {
        await montarAdmin(
          tester,
          inicio: '/admin',
          oscuro: oscuro,
          tamano: tamano,
          api: apiRutas({
            'GET /bookings/all': (
              200,
              '{"bookings": [], "total": 0, "page": 1, "per_page": 20, $contadores}',
            ),
            'GET /spaces/catalog': (200, catalogoJson),
          }),
        );
        // Un solo cuadro, antes de que el pedido vuelva.
        await tester.pump();
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('admin/reservas_cargando_${ancho}_$modo.png'),
        );
      });

      testWidgets('sin resultados $ancho $modo', (tester) async {
        await montarAdmin(
          tester,
          inicio: '/admin',
          oscuro: oscuro,
          tamano: tamano,
          api: apiRutas({
            'GET /bookings/all': (
              200,
              '{"bookings": [], "total": 0, "page": 1, "per_page": 20,'
                  ' "counters": {"all": 0, "active": 0, "completed": 0,'
                  ' "voided": 0}}',
            ),
            'GET /spaces/catalog': (200, catalogoJson),
          }),
        );
        await tester.enterText(
          find.bySemanticsLabel('Buscar reserva'),
          'sin coincidencia',
        );
        await capturar(
          tester,
          'admin/reservas_sin_resultados_${ancho}_$modo.png',
        );
      });

      testWidgets('historial vacío $ancho $modo', (tester) async {
        await montarAdmin(
          tester,
          inicio: '/admin',
          oscuro: oscuro,
          tamano: tamano,
          api: apiRutas({
            'GET /bookings/all': (
              200,
              '{"bookings": [], "total": 0, "page": 1, "per_page": 20,'
                  ' "counters": {"all": 0, "active": 0, "completed": 0,'
                  ' "voided": 0}}',
            ),
            'GET /spaces/catalog': (200, catalogoJson),
          }),
        );
        await capturar(tester, 'admin/reservas_vacio_${ancho}_$modo.png');
      });

      testWidgets('panel de filtros $ancho $modo', (tester) async {
        await montarAdmin(
          tester,
          inicio: '/admin',
          oscuro: oscuro,
          tamano: tamano,
          api: apiRutas({
            'GET /bookings/all': (
              200,
              '{"bookings": [$reservaActivaJson], "total": 49, "page": 1,'
                  ' "per_page": 20, $contadores}',
            ),
            'GET /spaces/catalog': (200, catalogoJson),
            'GET /venues': (
              200,
              '{"venues": [$sedeMoronJson, $sedeCastelarJson]}',
            ),
          }),
        );
        await tester.tap(find.text('Filtros'));
        await capturar(tester, 'admin/reservas_filtros_${ancho}_$modo.png');
      });

      testWidgets('rango de fechas inválido $ancho $modo', (tester) async {
        await montarAdmin(
          tester,
          inicio: '/admin',
          oscuro: oscuro,
          tamano: tamano,
          api: apiRutas({
            'GET /bookings/all': (
              200,
              '{"bookings": [], "total": 0, "page": 1, "per_page": 20,'
                  ' "counters": {"all": 0, "active": 0, "completed": 0,'
                  ' "voided": 0}}',
            ),
            'GET /spaces/catalog': (200, catalogoJson),
            'GET /venues': (200, '{"venues": [$sedeMoronJson]}'),
          }),
        );
        await tester.tap(find.text('Filtros'));
        await tester.pumpAndSettle();
        await tester.enterText(find.bySemanticsLabel('Desde'), '30112026');
        await tester.enterText(find.bySemanticsLabel('Hasta'), '01112026');
        await capturar(
          tester,
          'admin/reservas_rango_invalido_${ancho}_$modo.png',
        );
      });

      testWidgets('detalle de reserva $ancho $modo', (tester) async {
        await montarAdmin(
          tester,
          inicio: '/admin',
          oscuro: oscuro,
          tamano: tamano,
          api: apiRutas({
            'GET /bookings/all': (
              200,
              '{"bookings": [$reservaActivaJson], "total": 1, "page": 1,'
                  ' "per_page": 20, $contadores}',
            ),
            'GET /spaces/catalog': (200, catalogoJson),
          }),
        );
        await tester.tap(find.text('Moron_Rivadavia_19850_Futbol_F5_1'));
        await capturar(tester, 'admin/reservas_detalle_${ancho}_$modo.png');
      });

      testWidgets('detalle de reserva anulada $ancho $modo', (tester) async {
        await montarAdmin(
          tester,
          inicio: '/admin',
          oscuro: oscuro,
          tamano: tamano,
          api: apiRutas({
            'GET /bookings/all': (
              200,
              '{"bookings": [$reservaAnuladaJson], "total": 1, "page": 1,'
                  ' "per_page": 20, $contadores}',
            ),
            'GET /spaces/catalog': (200, catalogoJson),
          }),
        );
        await tester.tap(find.text('RamosMejia_Belgrano_1240_Hockey_H7_1'));
        await capturar(
          tester,
          'admin/reservas_detalle_anulada_${ancho}_$modo.png',
        );
      });

      testWidgets('acceso denegado $ancho $modo', (tester) async {
        await montar(
          tester,
          AccessDeniedScreen(session: SesionFalsa(perfilUsuario)),
          tema: oscuro ? darkTheme : lightTheme,
          tamano: tamano,
        );
        await capturar(tester, 'admin/acceso_denegado_${ancho}_$modo.png');
      });
    }
  }
}
