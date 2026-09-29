import 'dart:convert';

import 'package:clubnahuelmosse/api/cliente_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'soporte/usuario.dart';

String reservaJson({
  int id = 1,
  String inicio = '2026-11-13T00:00:00+00:00',
  String fin = '2026-11-13T01:00:00+00:00',
  String estado = 'activa',
  String? motivo,
  bool? cancelable,
}) =>
    '{"id": $id, "espacio_id": 9, "sede_id": 1, "espacio": "Moron_Rivadavia_19850_Futbol_F5_1", '
    '"deporte": "Futbol", "tipo": "F5", "sede": "Sede Morón", '
    '"direccion": "Av. Rivadavia 19850", "inicio": "$inicio", "fin": "$fin", '
    '"precio_por_hora": 38000, "total": 38000, "estado": "$estado", '
    '"motivo": ${motivo == null ? 'null' : '"$motivo"'}, '
    '"cancelable": ${cancelable ?? estado == 'activa'}}';

void main() {
  const proximas = '[{"id": 1}]';

  Future<List<http.Request>> abrir(
    WidgetTester tester, {
    String proximas = '[]',
    String historial = '[]',
    int codigo = 200,
    Size tamano = const Size(393, 852),
  }) async {
    final pedidos = <http.Request>[];
    final rutas = rutasDeSedes();
    await montarUsuario(
      tester,
      inicio: '/reservas',
      tamano: tamano,
      api: ClienteApi(
        'http://api.falsa',
        cliente: MockClient((pedido) async {
          pedidos.add(pedido);
          final (c, cuerpo) = pedido.url.path == '/reservas'
              ? (
                  codigo,
                  '{"reservas": ${pedido.url.queryParameters['cuando'] == 'historial' ? historial : proximas}}',
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
    return pedidos;
  }

  testWidgets('las próximas con sus datos y en la hora del club', (
    tester,
  ) async {
    await abrir(tester, proximas: '[${reservaJson()}]');

    expect(find.text('Fútbol 5'), findsOneWidget);
    expect(find.text('Sede Morón · Av. Rivadavia 19850'), findsOneWidget);
    expect(find.text('Moron_Rivadavia_19850_Futbol_F5_1'), findsOneWidget);
    // 00:00 UTC del 13 son las 21:00 del 12 en el club.
    expect(find.text('Jue 12 de noviembre'), findsOneWidget);
    expect(find.text('21:00 – 22:00'), findsOneWidget);
    expect(find.text('ACTIVA'), findsOneWidget);
    expect(find.textContaining('38.000'), findsOneWidget);
  });

  testWidgets('el historial pide su lista y dice por qué se canceló o anuló', (
    tester,
  ) async {
    final pedidos = await abrir(
      tester,
      historial:
          '[${reservaJson(estado: 'cancelada')}, '
          '${reservaJson(id: 2, estado: 'anulada', motivo: 'lluvia')}, '
          '${reservaJson(id: 3, estado: 'completada')}]',
    );

    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();

    expect(pedidos.last.url.queryParameters['cuando'], 'historial');
    expect(find.text('CANCELADA'), findsOneWidget);
    expect(find.text('ANULADA'), findsOneWidget);
    expect(find.text('COMPLETADA'), findsOneWidget);
    expect(
      find.text('Cancelada por vos · el horario quedó liberado'),
      findsOneWidget,
    );
    expect(find.text('Anulada por el administrador · lluvia'), findsOneWidget);
  });

  testWidgets('sin reservas, el aviso de cada pestaña', (tester) async {
    await abrir(tester);
    expect(find.text('No hay próximas reservas'), findsOneWidget);

    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();
    expect(find.text('No hay reservas pasadas'), findsOneWidget);
  });

  testWidgets('una respuesta rota no deja datos a medias', (tester) async {
    await abrir(tester, proximas: proximas);

    expect(find.text('Error del servidor'), findsOneWidget);
    await tester.tap(find.text('ACEPTAR'));
    await tester.pumpAndSettle();
    expect(find.text('REINTENTAR'), findsOneWidget);
  });

  testWidgets('con el texto al 200 % en un teléfono chico no se corta nada', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await abrir(
      tester,
      tamano: const Size(360, 800),
      proximas: '[${reservaJson(estado: 'activa')}]',
    );
    expect(tester.takeException(), isNull);
  });
}
