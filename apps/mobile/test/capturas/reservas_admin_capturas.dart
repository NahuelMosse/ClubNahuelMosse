import 'package:clubnahuelmosse/comun/pantalla_acceso_denegado.dart';
import 'package:clubnahuelmosse/tema/tema.dart';
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
      '"contadores": {"todas": 49, "activas": 12, "completadas": 31, "anuladas": 5}';

  const reservaActivaJson =
      '{"id": 1, "espacio_id": 9, "sede_id": 1, "espacio":'
      ' "Moron_Rivadavia_19850_Futbol_F5_1", "deporte": "Futbol", "tipo": "F5", "sede":'
      ' "Sede Morón", "direccion": "Av. Rivadavia 19850", "inicio":'
      ' "2026-11-12T21:00:00-03:00", "fin": "2026-11-12T22:00:00-03:00", "total": 38000,'
      ' "estado": "activa", "motivo": null, "usuario_id": 1, "usuario": "Nahuel Mosse",'
      ' "creado_en": "2026-11-02T18:42:00-03:00", "cancelada_en": null,'
      ' "cancelada_por_nombre": null, "espacio_de_baja": false, "anulable": true}';

  const reservaCompletadaJson =
      '{"id": 2, "espacio_id": 10, "sede_id": 2, "espacio":'
      ' "RamosMejia_Belgrano_1240_Voley_IND_1", "deporte": "Voley", "tipo": "IND", "sede":'
      ' "Sede Ramos Mejía", "direccion": "Calle Belgrano 1240", "inicio":'
      ' "2026-11-04T20:00:00-03:00", "fin": "2026-11-04T21:00:00-03:00", "total": 33000,'
      ' "estado": "completada", "motivo": null, "usuario_id": 1, "usuario": "Nahuel Mosse",'
      ' "creado_en": "2026-10-20T09:10:00-03:00", "cancelada_en": null,'
      ' "cancelada_por_nombre": null, "espacio_de_baja": false}';

  const reservaAnuladaJson =
      '{"id": 3, "espacio_id": 11, "sede_id": 2, "espacio":'
      ' "RamosMejia_Belgrano_1240_Hockey_H7_1", "deporte": "Hockey", "tipo": "H7", "sede":'
      ' "Sede Ramos Mejía", "direccion": "Calle Belgrano 1240", "inicio":'
      ' "2026-10-30T19:00:00-03:00", "fin": "2026-10-30T20:00:00-03:00", "total": 48000,'
      ' "estado": "anulada", "motivo": "mantenimiento de la cancha", "usuario_id": 1,'
      ' "usuario": "Nahuel Mosse", "creado_en": "2026-10-21T11:07:00-03:00",'
      ' "cancelada_en": "2026-10-28T09:15:00-03:00", "cancelada_por_nombre":'
      ' "Admin Sistema", "espacio_de_baja": false, "aviso_envio": "enviada",'
      ' "aviso_en": "2026-10-28T09:15:00-03:00"}';

  for (final MapEntry(key: ancho, value: tamano) in telefonos.entries) {
    for (final MapEntry(key: modo, value: oscuro) in modos.entries) {
      testWidgets('listado con reservas $ancho $modo', (tester) async {
        await montarAdmin(
          tester,
          inicio: '/admin',
          oscuro: oscuro,
          tamano: tamano,
          api: apiRutas({
            'GET /reservas/todas': (
              200,
              '{"reservas": [$reservaActivaJson, $reservaCompletadaJson,'
                  ' $reservaAnuladaJson], "total": 49, "pagina": 1, "por_pagina": 20,'
                  ' $contadores}',
            ),
            'GET /espacios/catalogo': (200, catalogoJson),
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
            'GET /reservas/todas': (
              200,
              '{"reservas": [], "total": 0, "pagina": 1, "por_pagina": 20, $contadores}',
            ),
            'GET /espacios/catalogo': (200, catalogoJson),
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
            'GET /reservas/todas': (
              200,
              '{"reservas": [], "total": 0, "pagina": 1, "por_pagina": 20,'
                  ' "contadores": {"todas": 0, "activas": 0, "completadas": 0,'
                  ' "anuladas": 0}}',
            ),
            'GET /espacios/catalogo': (200, catalogoJson),
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
            'GET /reservas/todas': (
              200,
              '{"reservas": [], "total": 0, "pagina": 1, "por_pagina": 20,'
                  ' "contadores": {"todas": 0, "activas": 0, "completadas": 0,'
                  ' "anuladas": 0}}',
            ),
            'GET /espacios/catalogo': (200, catalogoJson),
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
            'GET /reservas/todas': (
              200,
              '{"reservas": [$reservaActivaJson], "total": 49, "pagina": 1,'
                  ' "por_pagina": 20, $contadores}',
            ),
            'GET /espacios/catalogo': (200, catalogoJson),
            'GET /sedes': (
              200,
              '{"sedes": [$sedeMoronJson, $sedeCastelarJson]}',
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
            'GET /reservas/todas': (
              200,
              '{"reservas": [], "total": 0, "pagina": 1, "por_pagina": 20,'
                  ' "contadores": {"todas": 0, "activas": 0, "completadas": 0,'
                  ' "anuladas": 0}}',
            ),
            'GET /espacios/catalogo': (200, catalogoJson),
            'GET /sedes': (200, '{"sedes": [$sedeMoronJson]}'),
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
            'GET /reservas/todas': (
              200,
              '{"reservas": [$reservaActivaJson], "total": 1, "pagina": 1,'
                  ' "por_pagina": 20, $contadores}',
            ),
            'GET /espacios/catalogo': (200, catalogoJson),
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
            'GET /reservas/todas': (
              200,
              '{"reservas": [$reservaAnuladaJson], "total": 1, "pagina": 1,'
                  ' "por_pagina": 20, $contadores}',
            ),
            'GET /espacios/catalogo': (200, catalogoJson),
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
          PantallaAccesoDenegado(sesion: SesionFalsa(perfilUsuario)),
          tema: oscuro ? temaOscuro : temaClaro,
          tamano: tamano,
        );
        await capturar(tester, 'admin/acceso_denegado_${ancho}_$modo.png');
      });
    }
  }
}
