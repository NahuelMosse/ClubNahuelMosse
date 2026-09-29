import 'dart:convert';

import 'package:clubnahuelmosse/api/cliente_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'mis_reservas_test.dart' show reservaJson;
import 'soporte/montar.dart';
import 'soporte/usuario.dart';

void main() {
  // Siempre en el futuro, así la tarjeta ofrece CANCELAR.
  final futura = DateTime.now().toUtc().add(const Duration(days: 2));
  final inicio = DateTime.utc(futura.year, futura.month, futura.day, 21);
  final proxima = reservaJson(
    inicio: inicio.toIso8601String(),
    fin: inicio.add(const Duration(hours: 1)).toIso8601String(),
  );

  Future<List<http.Request>> abrir(
    WidgetTester tester, {
    (int, String)? alCancelar,
    String proximasDespues = '[]',
  }) async {
    final pedidos = <http.Request>[];
    var cancelada = false;
    final rutas = rutasDeSedes();
    await montarUsuario(
      tester,
      inicio: '/reservas',
      api: ClienteApi(
        'http://api.falsa',
        cliente: MockClient((pedido) async {
          pedidos.add(pedido);
          final (codigo, cuerpo) = switch ((pedido.method, pedido.url.path)) {
            ('POST', '/reservas/1/cancelar') => () {
              final respuesta =
                  alCancelar ?? (200, reservaJson(estado: 'cancelada'));
              // Un 409 también deja la lista sin esa reserva: ya no estaba activa.
              cancelada = respuesta.$1 == 200 || respuesta.$1 == 409;
              return respuesta;
            }(),
            ('GET', '/reservas') => (
              200,
              '{"reservas": ${cancelada ? proximasDespues : '[$proxima]'}}',
            ),
            _ => rutas['${pedido.method} ${pedido.url.path}'] ?? (404, '{}'),
          };
          return http.Response.bytes(
            utf8.encode(cuerpo),
            codigo,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      ),
    );
    return pedidos;
  }

  Future<void> pedirCancelar(WidgetTester tester) async {
    await tester.ensureVisible(find.text('CANCELAR'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CANCELAR'));
    await tester.pumpAndSettle();
  }

  testWidgets('confirmar cancela, avisa y vuelve a leer la lista', (
    tester,
  ) async {
    final pedidos = await abrir(tester);

    await pedirCancelar(tester);
    expect(find.text('¿Cancelar la reserva?'), findsOneWidget);
    expect(find.textContaining('Fútbol 5 · Sede Morón ·'), findsOneWidget);
    await tester.tap(find.text('CANCELAR RESERVA'));
    await tester.pumpAndSettle();

    expect(pedidos.where((p) => p.method == 'POST'), hasLength(1));
    expect(find.text('Reserva cancelada con éxito'), findsOneWidget);
    await tester.tap(find.text('ACEPTAR'));
    await tester.pumpAndSettle();
    expect(find.text('No hay próximas reservas'), findsOneWidget);
  });

  testWidgets('NO CANCELAR cierra sin pedir nada', (tester) async {
    final pedidos = await abrir(tester);

    await pedirCancelar(tester);
    await tester.tap(find.text('NO CANCELAR'));
    await tester.pumpAndSettle();

    expect(pedidos.where((p) => p.method == 'POST'), isEmpty);
    expect(find.text('ACTIVA'), findsOneWidget);
  });

  testWidgets('si la reserva cambió, el aviso y la lista actualizada', (
    tester,
  ) async {
    await abrir(
      tester,
      alCancelar: (
        409,
        '{"errores": {"reserva": "Esto cambió mientras tanto"}}',
      ),
    );

    await pedirCancelar(tester);
    await tester.tap(find.text('CANCELAR RESERVA'));
    await tester.pumpAndSettle();

    expect(find.text('Esto cambió mientras tanto'), findsOneWidget);
    await tester.tap(find.text('VER LO ACTUALIZADO'));
    await tester.pumpAndSettle();
    expect(find.text('No hay próximas reservas'), findsOneWidget);
  });

  testWidgets('el servidor falla: el aviso y la reserva sigue', (tester) async {
    await abrir(tester, alCancelar: (500, '{}'));

    await pedirCancelar(tester);
    await tester.tap(find.text('CANCELAR RESERVA'));
    await tester.pumpAndSettle();

    expect(find.text('Error del servidor'), findsOneWidget);
    await tester.tap(find.text('ACEPTAR'));
    await tester.pumpAndSettle();
    expect(find.text('ACTIVA'), findsOneWidget);
  });

  testWidgets(
    'una reserva que el servidor no da por cancelable no ofrece CANCELAR',
    (tester) async {
      final ahora = DateTime.now().toUtc();
      final empezada = reservaJson(
        inicio: ahora.subtract(const Duration(minutes: 10)).toIso8601String(),
        fin: ahora.add(const Duration(minutes: 50)).toIso8601String(),
        cancelable: false,
      );
      await montarUsuario(
        tester,
        inicio: '/reservas',
        api: apiRutas({
          ...rutasDeSedes(),
          'GET /reservas': (200, '{"reservas": [$empezada]}'),
        }),
      );

      expect(find.text('ACTIVA'), findsOneWidget);
      expect(find.text('CANCELAR'), findsNothing);
    },
  );
}
