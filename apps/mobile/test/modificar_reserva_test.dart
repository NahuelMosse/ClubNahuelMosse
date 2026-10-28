import 'dart:convert';

import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'mis_reservas_test.dart' show reservaJson;
import 'soporte/usuario.dart';

void main() {
  // La reserva es del jueves 12 a las 21 en el club; la grilla ya la da por libre.
  final grilla = grillaJson(ocupadas: {9, 12});

  Future<List<http.Request>> abrir(
    WidgetTester tester, {
    (int, String)? alModificar,
    Size tamano = const Size(393, 852),
  }) async {
    final pedidos = <http.Request>[];
    var modificada = false;
    final rutas = rutasDeSedes(grilla: grilla);
    await montarUsuario(
      tester,
      inicio: '/reservas',
      tamano: tamano,
      api: ApiClient(
        'http://api.falsa',
        cliente: MockClient((pedido) async {
          pedidos.add(pedido);
          final (codigo, cuerpo) = switch ((pedido.method, pedido.url.path)) {
            (
              'POST',
              '/reservas/00000000-0000-7000-8000-000000000001/modificar',
            ) =>
              () {
                final r =
                    alModificar ??
                    (
                      200,
                      reservaJson(
                        inicio: '2026-11-12T22:00:00+00:00',
                        fin: '2026-11-12T23:00:00+00:00',
                      ),
                    );
                modificada = r.$1 == 200;
                return r;
              }(),
            ('GET', '/reservas') => (
              200,
              '{"reservas": [${modificada ? reservaJson(inicio: '2026-11-12T22:00:00+00:00', fin: '2026-11-12T23:00:00+00:00') : reservaJson()}]}',
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

  Future<void> tocar(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  Future<void> hastaConfirmar(WidgetTester tester) async {
    await tocar(tester, find.text('MODIFICAR'));
    await tocar(tester, find.text('19:00 – 20:00'));
    await tocar(tester, find.text('CONTINUAR CON EL CAMBIO'));
  }

  testWidgets(
    'MODIFICAR abre la grilla del día de la reserva, sin duración y con su horario marcado',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final pedidos = await abrir(tester);

      await tocar(tester, find.text('MODIFICAR'));

      final consulta = pedidos.last.url;
      expect(
        consulta.path,
        '/espacios/00000000-0000-7000-8000-000000000009/horarios',
      );
      expect(
        consulta.queryParameters['reserva_id'],
        '00000000-0000-7000-8000-000000000001',
      );
      expect(consulta.queryParameters['fecha'], '2026-11-12');
      expect(consulta.queryParameters['horas'], '1');
      expect(
        find.textContaining(
          'Estás modificando tu reserva del Jue 12, 21:00 – 22:00',
        ),
        findsOneWidget,
      );
      expect(find.text('DURACIÓN'), findsNothing);
      expect(find.text('(actual)'), findsOneWidget);
      expect(find.bySemanticsLabel('21:00 – 22:00 (actual)'), findsOneWidget);
      final boton = find.bySemanticsLabel('CONTINUAR CON EL CAMBIO');
      expect(tester.getSemantics(boton).flagsCollection.isEnabled, isFalse);

      await tocar(tester, find.text('19:00 – 20:00'));
      expect(tester.getSemantics(boton).flagsCollection.isEnabled, isTrue);
      semantica.dispose();
    },
  );

  testWidgets('guardar mueve la reserva y vuelve a Mis reservas con el aviso', (
    tester,
  ) async {
    final pedidos = await abrir(tester);
    await hastaConfirmar(tester);

    expect(find.text('Confirmá el cambio'), findsOneWidget);
    expect(find.text('ANTES'), findsOneWidget);
    expect(find.text('Jue 12 · 21:00 – 22:00'), findsOneWidget);
    expect(find.text('AHORA'), findsOneWidget);
    expect(find.text('Jue 12 · 19:00 – 20:00'), findsOneWidget);

    await tocar(tester, find.text('GUARDAR EL CAMBIO'));

    final post = pedidos.singleWhere((p) => p.method == 'POST');
    expect(jsonDecode(post.body), {
      'espacio_id': '00000000-0000-7000-8000-000000000009',
      'fecha': '2026-11-12',
      'desde': '19:00',
    });
    expect(find.text('Reserva modificada'), findsOneWidget);
    expect(find.text('19:00 – 20:00'), findsOneWidget);
    expect(find.text('21:00 – 22:00'), findsNothing);
  });

  testWidgets('dejar la reserva como está vuelve sin pedir nada', (
    tester,
  ) async {
    final pedidos = await abrir(tester);
    await hastaConfirmar(tester);

    await tocar(tester, find.text('DEJAR LA RESERVA COMO ESTÁ'));

    expect(pedidos.where((p) => p.method == 'POST'), isEmpty);
    expect(find.text('21:00 – 22:00'), findsOneWidget);
    expect(find.text('MODIFICAR'), findsOneWidget);
  });

  testWidgets('el horario se ocupó: el aviso y la grilla vuelta a leer', (
    tester,
  ) async {
    final pedidos = await abrir(
      tester,
      alModificar: (409, '{"errores": {"horario": "Ese horario se ocupó"}}'),
    );
    await hastaConfirmar(tester);
    final antes = pedidos.where((p) => p.url.path.endsWith('/horarios')).length;

    await tocar(tester, find.text('GUARDAR EL CAMBIO'));
    expect(find.text('Esto cambió mientras tanto'), findsOneWidget);
    await tocar(tester, find.text('VER LO ACTUALIZADO'));

    expect(find.textContaining('Estás modificando tu reserva'), findsOneWidget);
    expect(
      pedidos.where((p) => p.url.path.endsWith('/horarios')).length,
      antes + 1,
    );
  });

  testWidgets('la reserva ya no se puede modificar: el aviso y Mis reservas', (
    tester,
  ) async {
    await abrir(
      tester,
      alModificar: (
        409,
        '{"errores": {"reserva": "Esto cambió mientras tanto"}}',
      ),
    );
    await hastaConfirmar(tester);

    await tocar(tester, find.text('GUARDAR EL CAMBIO'));
    expect(find.text('Esto cambió mientras tanto'), findsOneWidget);
    await tocar(tester, find.text('VER LO ACTUALIZADO'));

    expect(find.text('Próximas'), findsOneWidget);
    expect(find.textContaining('Estás modificando'), findsNothing);
  });

  testWidgets('el servidor falla: el aviso y la confirmación sigue abierta', (
    tester,
  ) async {
    await abrir(tester, alModificar: (500, '{}'));
    await hastaConfirmar(tester);

    await tocar(tester, find.text('GUARDAR EL CAMBIO'));
    expect(find.text('Error del servidor'), findsOneWidget);
    await tocar(tester, find.text('ACEPTAR'));

    expect(find.text('Confirmá el cambio'), findsOneWidget);
  });

  testWidgets('con el texto al 200 % en un teléfono chico no se corta nada', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await abrir(tester, tamano: const Size(360, 800));
    expect(tester.takeException(), isNull);
    await hastaConfirmar(tester);
    expect(tester.takeException(), isNull);
  });
}
