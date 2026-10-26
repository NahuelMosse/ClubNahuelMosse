import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clubnahuelmosse/api/cliente_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'soporte/admin.dart';

void main() {
  Future<List<http.Request>> abrir(
    WidgetTester tester, {
    (int, String) alDarDeBaja = (204, ''),
    Size tamano = const Size(393, 852),
  }) async {
    final pedidos = <http.Request>[];
    var dadaDeBaja = false;
    await montarAdmin(
      tester,
      tamano: tamano,
      api: ClienteApi(
        'http://api.falsa',
        cliente: MockClient((pedido) async {
          pedidos.add(pedido);
          final (codigo, cuerpo) = switch ((pedido.method, pedido.url.path)) {
            ('DELETE', '/sedes/00000000-0000-7000-8000-000000000001') => () {
              dadaDeBaja = alDarDeBaja.$1 == 204 || alDarDeBaja.$1 == 404;
              return alDarDeBaja;
            }(),
            ('GET', '/sedes') => (
              200,
              '{"sedes": [${dadaDeBaja ? sedeHaedoJson : '$sedeHaedoJson, $sedeMoronJson'}]}',
            ),
            _ => (404, '{}'),
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

  Future<void> desdeLaEdicion(WidgetTester tester) async {
    await tocar(tester, find.bySemanticsLabel('Editar sede Sede Morón'));
    await tocar(tester, find.text('DAR DE BAJA LA SEDE'));
  }

  testWidgets(
    'desde la edición: confirma, avisa y vuelve al listado sin la sede',
    (tester) async {
      final pedidos = await abrir(tester);
      await desdeLaEdicion(tester);

      expect(find.text('¿Dar de baja la sede?'), findsOneWidget);
      await tocar(tester, find.text('DAR DE BAJA'));

      expect(pedidos.where((p) => p.method == 'DELETE'), hasLength(1));
      expect(
        find.text('La sede fue dada de baja correctamente'),
        findsOneWidget,
      );
      expect(find.text('Sede Morón'), findsNothing);
      expect(find.text('Sede Haedo'), findsOneWidget);
    },
  );

  testWidgets('desde la tarjeta del listado, sin pasar por la edición', (
    tester,
  ) async {
    final pedidos = await abrir(tester);

    await tocar(tester, find.bySemanticsLabel('Dar de baja Sede Morón'));
    expect(
      find.text(
        'Sede Morón · Av. Rivadavia 19850. Sus espacios deportivos dejan de '
        'estar disponibles.',
      ),
      findsOneWidget,
    );
    await tocar(tester, find.text('DAR DE BAJA'));

    expect(pedidos.where((p) => p.method == 'DELETE'), hasLength(1));
    expect(find.text('Sede Morón'), findsNothing);
  });

  testWidgets('CANCELAR no pide nada', (tester) async {
    final pedidos = await abrir(tester);
    await desdeLaEdicion(tester);

    await tocar(tester, find.text('CANCELAR'));

    expect(pedidos.where((p) => p.method == 'DELETE'), isEmpty);
    expect(find.text('Editar sede'), findsOneWidget);
  });

  testWidgets('con reservas pendientes: el aviso y sigue en la edición', (
    tester,
  ) async {
    await abrir(
      tester,
      alDarDeBaja: (
        409,
        '{"errores": {"sede": "No se puede dar de baja la sede porque posee '
            'reservas futuras asociadas."}}',
      ),
    );
    await desdeLaEdicion(tester);
    await tocar(tester, find.text('DAR DE BAJA'));

    expect(find.text('No se puede dar de baja la sede'), findsOneWidget);
    await tocar(tester, find.text('ACEPTAR'));
    expect(find.text('Editar sede'), findsOneWidget);
  });

  testWidgets('ya dada de baja en otra sesión: el aviso y el listado', (
    tester,
  ) async {
    await abrir(tester, alDarDeBaja: (404, ''));
    await desdeLaEdicion(tester);
    await tocar(tester, find.text('DAR DE BAJA'));

    expect(find.text('Esto cambió mientras tanto'), findsOneWidget);
    await tocar(tester, find.text('VER LO ACTUALIZADO'));
    expect(find.text('AGREGAR SEDE'), findsOneWidget);
    expect(find.text('Sede Morón'), findsNothing);
  });

  testWidgets('el servidor falla: el aviso y sigue en la edición', (
    tester,
  ) async {
    await abrir(tester, alDarDeBaja: (500, '{}'));
    await desdeLaEdicion(tester);
    await tocar(tester, find.text('DAR DE BAJA'));

    expect(find.text('Error del servidor'), findsOneWidget);
    await tocar(tester, find.text('ACEPTAR'));
    expect(find.text('Editar sede'), findsOneWidget);
  });

  testWidgets(
    'la tarjeta con el texto al 200 % en un teléfono chico apila los botones',
    (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await abrir(tester, tamano: const Size(360, 800));
      expect(tester.takeException(), isNull);
      final editar = tester.getRect(find.text('Editar sede').first);
      final baja = tester.getRect(find.text('Dar de baja').first);
      expect(baja.top, greaterThan(editar.bottom));
    },
  );

  Future<List<http.Request>> abrirCon(
    WidgetTester tester,
    Future<http.Response> Function(http.Request pedido, int intento)
    alDarDeBaja,
  ) async {
    final pedidos = <http.Request>[];
    var intentos = 0;
    var dadaDeBaja = false;
    http.Response json(int codigo, String cuerpo) => http.Response.bytes(
      utf8.encode(cuerpo),
      codigo,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
    await montarAdmin(
      tester,
      api: ClienteApi(
        'http://api.falsa',
        cliente: MockClient((pedido) async {
          pedidos.add(pedido);
          if (pedido.method == 'DELETE') {
            final r = await alDarDeBaja(pedido, ++intentos);
            dadaDeBaja = true;
            return r;
          }
          if (pedido.url.path == '/sedes') {
            return json(
              200,
              '{"sedes": [${dadaDeBaja ? sedeHaedoJson : '$sedeHaedoJson, $sedeMoronJson'}]}',
            );
          }
          return json(404, '{}');
        }),
      ),
    );
    return pedidos;
  }

  testWidgets('mientras la baja está en camino, las tarjetas no se tocan', (
    tester,
  ) async {
    final respuesta = Completer<http.Response>();
    final pedidos = await abrirCon(tester, (_, _) => respuesta.future);

    await tocar(tester, find.bySemanticsLabel('Dar de baja Sede Morón'));
    await tester.tap(find.text('DAR DE BAJA'));
    // El diálogo termina de cerrarse; el pedido sigue sin respuesta.
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.bySemanticsLabel('Dando de baja Sede Morón'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Dar de baja Sede Haedo'));
    await tester.tap(find.bySemanticsLabel('Editar sede Sede Haedo'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('¿Dar de baja la sede?'), findsNothing);
    expect(find.bySemanticsLabel('Nombre de la sede'), findsNothing);

    respuesta.complete(http.Response('', 204));
    await tester.pumpAndSettle();
    expect(pedidos.where((p) => p.method == 'DELETE'), hasLength(1));
    expect(find.text('La sede fue dada de baja correctamente'), findsOneWidget);
    expect(find.text('Sede Morón'), findsNothing);
  });

  testWidgets(
    'si el pedido cortado la dio de baja, el reintento avisa el éxito',
    (tester) async {
      await abrirCon(tester, (_, intento) async {
        if (intento == 1) throw const SocketException('se cortó');
        return http.Response('', 404);
      });

      await tocar(tester, find.bySemanticsLabel('Dar de baja Sede Morón'));
      await tocar(tester, find.text('DAR DE BAJA'));
      expect(find.text('Error de conexión'), findsOneWidget);
      await tocar(tester, find.text('REINTENTAR'));

      expect(find.text('Esto cambió mientras tanto'), findsNothing);
      expect(
        find.text('La sede fue dada de baja correctamente'),
        findsOneWidget,
      );
      expect(find.text('Sede Morón'), findsNothing);
    },
  );

  testWidgets('con el texto al 130 % los botones de la tarjeta se apilan', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await abrir(tester, tamano: const Size(360, 800));
    expect(tester.takeException(), isNull);
    final editar = tester.getRect(find.text('Editar sede').first);
    final baja = tester.getRect(find.text('Dar de baja').first);
    expect(baja.top, greaterThan(editar.bottom));
  });
}
