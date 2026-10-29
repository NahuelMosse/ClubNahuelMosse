import 'dart:convert';

import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:clubnahuelmosse/features/bookings/presentation/my_bookings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'soporte/usuario.dart';

String reservaJson({
  String id = '00000000-0000-7000-8000-000000000001',
  String inicio = '2026-11-13T00:00:00+00:00',
  String fin = '2026-11-13T01:00:00+00:00',
  String estado = 'activa',
  String? motivo,
  bool? cancelable,
}) =>
    '{"id": "$id", "space_id": "00000000-0000-7000-8000-000000000009", "venue_id": "00000000-0000-7000-8000-000000000001", "space": "Moron_Rivadavia_19850_Futbol_F5_1", '
    '"sport": "Futbol", "kind": "F5", "venue": "Sede Morón", '
    '"address": "Av. Rivadavia 19850", "starts_at": "$inicio", "ends_at": "$fin", '
    '"price_per_hour": 38000, "total": 38000, "status": "$estado", '
    '"reason": ${motivo == null ? 'null' : '"$motivo"'}, '
    '"cancelable": ${cancelable ?? estado == 'activa'}}';

void main() {
  const proximas = '[{"id": "00000000-0000-7000-8000-000000000001"}]';

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
      api: ApiClient(
        'http://api.falsa',
        cliente: MockClient((pedido) async {
          pedidos.add(pedido);
          final (c, cuerpo) = pedido.url.path == '/bookings'
              ? (
                  codigo,
                  '{"bookings": ${pedido.url.queryParameters['cuando'] == 'historial' ? historial : proximas}}',
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
          '[${reservaJson(estado: 'canceled')}, '
          '${reservaJson(id: '00000000-0000-7000-8000-000000000002', estado: 'voided', motivo: 'lluvia')}, '
          '${reservaJson(id: '00000000-0000-7000-8000-000000000003', estado: 'completed')}]',
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
      proximas: '[${reservaJson(estado: 'active')}]',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'un aviso agrupado tocado desde Próximas abre el historial sin reserva puntual',
    (tester) async {
      final pedidos = await abrir(
        tester,
        proximas: '[${reservaJson()}]',
        historial:
            '[${reservaJson(id: '00000000-0000-7000-8000-000000000002', estado: 'voided', motivo: 'Lluvia')}]',
      );
      expect(find.text('ACTIVA'), findsOneWidget);

      GoRouter.of(
        tester.element(find.byType(MyBookingsScreen)),
      ).go('/reservas?historial=1');
      await tester.pumpAndSettle();

      expect(pedidos.last.url.queryParameters['cuando'], 'historial');
      expect(find.text('ANULADA'), findsOneWidget);
      expect(find.text('ACTIVA'), findsNothing);
    },
  );
}
