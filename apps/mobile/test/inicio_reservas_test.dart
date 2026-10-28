import 'dart:async';
import 'dart:convert';

import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:clubnahuelmosse/features/home/presentation/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'mis_reservas_test.dart' show reservaJson;
import 'soporte/usuario.dart';

/// Una API con una reserva activa que se puede cancelar, y que cancela cuando [frenar]
/// termina.
class _Servidor {
  _Servidor({this.frenar});

  final Future<void>? frenar;
  final pedidos = <http.Request>[];
  var _activa = true;

  int get lecturas => pedidos
      .where((p) => p.method == 'GET' && p.url.path == '/reservas')
      .length;

  ApiClient get api =>
      ApiClient('http://api.falsa', cliente: MockClient(_responder));

  Future<http.Response> _responder(http.Request pedido) async {
    pedidos.add(pedido);
    final rutas = rutasDeSedes();
    final (codigo, cuerpo) = switch ((pedido.method, pedido.url.path)) {
      ('GET', '/reservas') => (
        200,
        '{"reservas": [${_activa ? reservaJson() : ''}]}',
      ),
      ('POST', '/reservas/00000000-0000-7000-8000-000000000001/cancelar') =>
        await _cancelar(),
      _ => rutas['${pedido.method} ${pedido.url.path}'] ?? (404, '{}'),
    };
    return http.Response.bytes(
      utf8.encode(cuerpo),
      codigo,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }

  Future<(int, String)> _cancelar() async {
    await frenar;
    _activa = false;
    return (200, reservaJson(estado: 'cancelada'));
  }
}

void main() {
  Future<void> tocar(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'cancelar desde Mis reservas y volver: el Home ya no la muestra',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final servidor = _Servidor();
      await montarUsuario(tester, api: servidor.api, inicio: '/inicio');
      expect(find.text('TU PRÓXIMA RESERVA'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Tu cuenta'));
      await tester.pumpAndSettle();
      await tocar(tester, find.text('Mis reservas'));
      await tocar(tester, find.text('CANCELAR'));
      await tocar(tester, find.text('CANCELAR RESERVA'));
      await tocar(tester, find.text('ACEPTAR'));
      await tocar(tester, find.text('INICIO'));

      expect(find.text('RESERVÁ TU CANCHA'), findsOneWidget);
      expect(find.text('TU PRÓXIMA RESERVA'), findsNothing);
      semantica.dispose();
    },
  );

  testWidgets('con la cancelación en curso no se puede salir del Home', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    final cancelacion = Completer<void>();
    final servidor = _Servidor(frenar: cancelacion.future);
    await montarUsuario(tester, api: servidor.api, inicio: '/inicio');

    await tocar(tester, find.text('CANCELAR'));
    await tester.tap(find.text('CANCELAR RESERVA'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('VER TODAS →'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('TU PRÓXIMA RESERVA'), findsOneWidget);
    expect(find.text('Mis reservas'), findsNothing);
    expect(
      find.descendant(
        of: find.byType(HomeScreen),
        matching: find.byWidgetPredicate((w) => w is PopScope && !w.canPop),
      ),
      findsOneWidget,
    );

    cancelacion.complete();
    await tester.pumpAndSettle();
    expect(find.text('Reserva cancelada con éxito'), findsOneWidget);
    await tester.tap(find.text('ACEPTAR'));
    await tester.pumpAndSettle();
    expect(find.text('TU PRÓXIMA RESERVA'), findsNothing);
    semantica.dispose();
  });

  testWidgets('MODIFICAR vuelve al Home, que lee las reservas de nuevo', (
    tester,
  ) async {
    final servidor = _Servidor();
    await montarUsuario(tester, api: servidor.api, inicio: '/inicio');
    final antes = servidor.lecturas;

    await tocar(tester, find.text('MODIFICAR'));
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Mis reservas'), findsNothing);

    await tocar(tester, find.text('Inicio'));

    expect(find.text('TU PRÓXIMA RESERVA'), findsOneWidget);
    expect(servidor.lecturas, greaterThan(antes));
  });
}
