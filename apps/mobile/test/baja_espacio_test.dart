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
  const nombre = 'Moron_Rivadavia_19850_Futbol_F5_1';

  Future<List<http.Request>> abrir(
    WidgetTester tester, {
    (int, String) alDarDeBaja = (204, ''),
    Size tamano = const Size(393, 852),
  }) async {
    final pedidos = <http.Request>[];
    var dadoDeBaja = false;
    await montarAdmin(
      tester,
      inicio: '/admin/espacios',
      tamano: tamano,
      api: ClienteApi(
        'http://api.falsa',
        cliente: MockClient((pedido) async {
          pedidos.add(pedido);
          final (codigo, cuerpo) = switch ((pedido.method, pedido.url.path)) {
            ('DELETE', '/espacios/9') => () {
              dadoDeBaja = alDarDeBaja.$1 == 204 || alDarDeBaja.$1 == 404;
              return alDarDeBaja;
            }(),
            ('GET', '/espacios') => (
              200,
              '{"espacios": [${dadoDeBaja ? espacioTenisJson : '$espacioF5Json, $espacioTenisJson'}]}',
            ),
            ('GET', '/espacios/catalogo') => (200, catalogoJson),
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

  testWidgets(
    'desde la tarjeta: confirma, avisa y el listado queda sin el espacio',
    (tester) async {
      final pedidos = await abrir(tester);

      await tocar(tester, find.bySemanticsLabel('Baja $nombre'));
      expect(find.text('¿Dar de baja el espacio?'), findsOneWidget);
      expect(find.text('$nombre. La acción es permanente.'), findsOneWidget);
      await tocar(tester, find.text('CONFIRMAR BAJA'));

      expect(pedidos.where((p) => p.method == 'DELETE'), hasLength(1));
      expect(
        find.text('El espacio fue dado de baja correctamente'),
        findsOneWidget,
      );
      expect(find.text(nombre), findsNothing);
      expect(find.text('Moron_Rivadavia_19850_Tenis_PDL_1'), findsOneWidget);
    },
  );

  testWidgets('desde la edición termina en el listado', (tester) async {
    await abrir(tester);
    await tocar(tester, find.bySemanticsLabel('Editar $nombre'));

    await tocar(tester, find.text('DAR DE BAJA EL ESPACIO'));
    await tocar(tester, find.text('CONFIRMAR BAJA'));

    expect(
      find.text('El espacio fue dado de baja correctamente'),
      findsOneWidget,
    );
    expect(find.text('ALTA ESPACIO'), findsOneWidget);
    expect(find.text(nombre), findsNothing);
  });

  testWidgets('CANCELAR no pide nada', (tester) async {
    final pedidos = await abrir(tester);

    await tocar(tester, find.bySemanticsLabel('Baja $nombre'));
    await tocar(tester, find.text('CANCELAR'));

    expect(pedidos.where((p) => p.method == 'DELETE'), isEmpty);
    expect(find.text(nombre), findsOneWidget);
  });

  testWidgets('con reservas pendientes: el aviso y el espacio sigue', (
    tester,
  ) async {
    await abrir(tester, alDarDeBaja: (409, '{"errores": {"espacio": "x"}}'));

    await tocar(tester, find.bySemanticsLabel('Baja $nombre'));
    await tocar(tester, find.text('CONFIRMAR BAJA'));

    expect(find.text('No se puede dar de baja el espacio'), findsOneWidget);
    await tocar(tester, find.text('ACEPTAR'));
    expect(find.text(nombre), findsOneWidget);
  });

  testWidgets('ya dado de baja en otra sesión: el aviso y el listado releído', (
    tester,
  ) async {
    await abrir(tester, alDarDeBaja: (404, ''));

    await tocar(tester, find.bySemanticsLabel('Baja $nombre'));
    await tocar(tester, find.text('CONFIRMAR BAJA'));

    expect(find.text('Esto cambió mientras tanto'), findsOneWidget);
    await tocar(tester, find.text('VER LO ACTUALIZADO'));
    expect(find.text(nombre), findsNothing);
  });

  testWidgets('el servidor falla: el aviso y el espacio sigue', (tester) async {
    await abrir(tester, alDarDeBaja: (500, '{}'));

    await tocar(tester, find.bySemanticsLabel('Baja $nombre'));
    await tocar(tester, find.text('CONFIRMAR BAJA'));

    expect(find.text('Error del servidor'), findsOneWidget);
    await tocar(tester, find.text('ACEPTAR'));
    expect(find.text(nombre), findsOneWidget);
  });

  testWidgets(
    'con el texto al 130 % en un teléfono chico los botones de la tarjeta se apilan',
    (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await abrir(tester, tamano: const Size(360, 800));
      expect(tester.takeException(), isNull);
      final editar = tester.getRect(find.text('Editar').first);
      final baja = tester.getRect(find.text('Baja').first);
      expect(baja.top, greaterThan(editar.bottom));
    },
  );

  Future<List<http.Request>> abrirCon(
    WidgetTester tester,
    Future<http.Response> Function(int intento) alDarDeBaja, {
    Size tamano = const Size(393, 852),
  }) async {
    final pedidos = <http.Request>[];
    var intentos = 0;
    var dadoDeBaja = false;
    http.Response json(int codigo, String cuerpo) => http.Response.bytes(
      utf8.encode(cuerpo),
      codigo,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
    await montarAdmin(
      tester,
      inicio: '/admin/espacios',
      tamano: tamano,
      api: ClienteApi(
        'http://api.falsa',
        cliente: MockClient((pedido) async {
          pedidos.add(pedido);
          if (pedido.method == 'DELETE') {
            final r = await alDarDeBaja(++intentos);
            dadoDeBaja = true;
            return r;
          }
          return switch (pedido.url.path) {
            '/espacios' => json(
              200,
              '{"espacios": [${dadoDeBaja ? espacioTenisJson : '$espacioF5Json, $espacioTenisJson'}]}',
            ),
            '/espacios/catalogo' => json(200, catalogoJson),
            _ => json(404, '{}'),
          };
        }),
      ),
    );
    return pedidos;
  }

  testWidgets('mientras la baja está en camino, las tarjetas no se tocan', (
    tester,
  ) async {
    final respuesta = Completer<http.Response>();
    final pedidos = await abrirCon(tester, (_) => respuesta.future);

    await tocar(tester, find.bySemanticsLabel('Baja $nombre'));
    await tester.tap(find.text('CONFIRMAR BAJA'));
    // El diálogo termina de cerrarse; el pedido sigue sin respuesta.
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.bySemanticsLabel('Dando de baja $nombre'), findsOneWidget);
    await tester.tap(find.text('Baja').first);
    await tester.tap(find.text('ALTA ESPACIO'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('¿Dar de baja el espacio?'), findsNothing);
    expect(find.text('Nuevo espacio'), findsNothing);

    respuesta.complete(http.Response('', 204));
    await tester.pumpAndSettle();
    expect(pedidos.where((p) => p.method == 'DELETE'), hasLength(1));
    expect(
      find.text('El espacio fue dado de baja correctamente'),
      findsOneWidget,
    );
  });

  testWidgets(
    'si el pedido cortado lo dio de baja, el reintento avisa el éxito',
    (tester) async {
      await abrirCon(tester, (intento) async {
        if (intento == 1) throw const SocketException('se cortó');
        return http.Response('', 404);
      });

      await tocar(tester, find.bySemanticsLabel('Baja $nombre'));
      await tocar(tester, find.text('CONFIRMAR BAJA'));
      expect(find.text('Error de conexión'), findsOneWidget);
      await tocar(tester, find.text('REINTENTAR'));

      expect(find.text('Esto cambió mientras tanto'), findsNothing);
      expect(
        find.text('El espacio fue dado de baja correctamente'),
        findsOneWidget,
      );
      expect(find.text(nombre), findsNothing);
    },
  );

  testWidgets('con el texto al 200 % en un teléfono chico no se corta nada', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await abrir(tester, tamano: const Size(360, 800));
    expect(tester.takeException(), isNull);
  });
}
