import 'dart:convert';

import 'package:clubnahuelmosse/api/cliente_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../mis_reservas_test.dart' show reservaJson;
import '../soporte/montar.dart';
import '../soporte/usuario.dart';

/// No afirma nada: produce la tira del paso 9 para mirarla contra el prototipo.
void main() {
  setUpAll(cargarFuentes);

  const telefonos = {'360': Size(360, 800), '430': Size(430, 932)};
  const modos = {'oscuro': true, 'claro': false};
  final proximas =
      '[${reservaJson()}, '
      '${reservaJson(id: 2, inicio: '2026-11-15T13:00:00+00:00', fin: '2026-11-15T14:00:00+00:00')}]';
  final historial =
      '[${reservaJson(estado: 'cancelada', inicio: '2026-11-11T23:00:00+00:00', fin: '2026-11-12T00:00:00+00:00')}, '
      '${reservaJson(id: 2, estado: 'completada', inicio: '2026-11-04T23:00:00+00:00', fin: '2026-11-05T00:00:00+00:00')}, '
      '${reservaJson(id: 3, estado: 'anulada', motivo: 'mantenimiento de la cancha', inicio: '2026-10-30T22:00:00+00:00', fin: '2026-10-30T23:00:00+00:00')}]';

  Future<void> capturar(WidgetTester tester, String archivo) async {
    await tester.runAsync(() async {
      for (final elemento in find.byType(Image).evaluate()) {
        final imagen = elemento.widget;
        if (imagen is Image) await precacheImage(imagen.image, elemento);
      }
    });
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile(archivo));
  }

  for (final MapEntry(key: ancho, value: tamano) in telefonos.entries) {
    for (final MapEntry(key: modo, value: oscuro) in modos.entries) {
      Future<void> abrir(
        WidgetTester tester, {
        String proximasJson = '[]',
        String historialJson = '[]',
      }) {
        final rutas = rutasDeSedes();
        return montarUsuario(
          tester,
          oscuro: oscuro,
          tamano: tamano,
          inicio: '/reservas',
          api: ClienteApi(
            'http://api.falsa',
            cliente: MockClient((pedido) async {
              final (c, cuerpo) = pedido.url.path == '/reservas'
                  ? (
                      200,
                      '{"reservas": ${pedido.url.queryParameters['cuando'] == 'historial' ? historialJson : proximasJson}}',
                    )
                  : rutas['${pedido.method} ${pedido.url.path}'] ?? (404, '{}');
              return http.Response.bytes(
                utf8.encode(cuerpo),
                c,
                headers: {'content-type': 'application/json; charset=utf-8'},
              );
            }),
          ),
        );
      }

      testWidgets('próximas $ancho $modo', (tester) async {
        await abrir(tester, proximasJson: proximas);
        await capturar(tester, 'reservas/proximas_${ancho}_$modo.png');
      });

      testWidgets('confirmar la cancelación $ancho $modo', (tester) async {
        await abrir(tester, proximasJson: proximas);
        await tester.tap(find.text('CANCELAR').first);
        await tester.pumpAndSettle();
        await capturar(tester, 'reservas/cancelar_${ancho}_$modo.png');
      });

      testWidgets('historial $ancho $modo', (tester) async {
        await abrir(tester, historialJson: historial);
        await tester.tap(find.text('Historial'));
        await tester.pumpAndSettle();
        await capturar(tester, 'reservas/historial_${ancho}_$modo.png');
      });

      testWidgets('sin próximas $ancho $modo', (tester) async {
        await abrir(tester);
        await capturar(tester, 'reservas/sin_proximas_${ancho}_$modo.png');
      });

      testWidgets('sin pasadas $ancho $modo', (tester) async {
        await abrir(tester);
        await tester.tap(find.text('Historial'));
        await tester.pumpAndSettle();
        await capturar(tester, 'reservas/sin_pasadas_${ancho}_$modo.png');
      });

      testWidgets('próximas con el texto al 200 % $ancho $modo', (
        tester,
      ) async {
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await abrir(tester, proximasJson: proximas);
        await capturar(tester, 'reservas/proximas_200_${ancho}_$modo.png');
      });
    }
  }
}
