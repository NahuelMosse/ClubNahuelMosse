import 'dart:convert';

import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'soporte/admin.dart';

void main() {
  const editado =
      '{"id": "00000000-0000-7000-8000-000000000009", "name": "Moron_Rivadavia_19850_Futbol_F5_1", "venue_id": "00000000-0000-7000-8000-000000000001", '
      '"venue": "Sede Morón", "sport": "Futbol", "kind": "F5", "number": 1, '
      '"covered": false, "lit": true, "price_per_hour": 45000}';

  Future<List<http.Request>> abrir(
    WidgetTester tester, {
    (int, String) alGuardar = (200, editado),
    Size tamano = const Size(393, 852),
  }) async {
    final pedidos = <http.Request>[];
    var guardado = false;
    await montarAdmin(
      tester,
      inicio: '/admin/espacios',
      tamano: tamano,
      api: ApiClient(
        'http://api.falsa',
        cliente: MockClient((pedido) async {
          pedidos.add(pedido);
          final (codigo, cuerpo) = switch ((pedido.method, pedido.url.path)) {
            ('PUT', '/spaces/00000000-0000-7000-8000-000000000009') => () {
              guardado = alGuardar.$1 == 200;
              return alGuardar;
            }(),
            ('GET', '/spaces') => (
              200,
              '{"spaces": [${guardado ? editado : espacioF5Json}]}',
            ),
            ('GET', '/spaces/catalog') => (200, catalogoJson),
            ('GET', '/venues') => (200, '{"venues": [$sedeMoronJson]}'),
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
    await tester.tap(
      find.bySemanticsLabel('Editar Moron_Rivadavia_19850_Futbol_F5_1'),
    );
    await tester.pumpAndSettle();
    return pedidos;
  }

  Future<void> escribirPrecio(WidgetTester tester, String texto) async {
    await tester.enterText(
      find.descendant(
        of: find.bySemanticsLabel('Precio por hora'),
        matching: find.byType(EditableText),
      ),
      texto,
    );
    await tester.pumpAndSettle();
  }

  Future<void> tocar(WidgetTester tester, String texto) async {
    await tester.ensureVisible(find.text(texto));
    await tester.pumpAndSettle();
    await tester.tap(find.text(texto));
    await tester.pumpAndSettle();
  }

  bool habilitado(WidgetTester tester, String etiqueta) => tester
      .getSemantics(find.bySemanticsLabel(etiqueta))
      .flagsCollection
      .isEnabled;

  testWidgets(
    'abre con los datos del espacio y lo que no se edita, deshabilitado',
    (tester) async {
      final semantica = tester.ensureSemantics();
      await abrir(tester);

      expect(find.text('Editar espacio deportivo'), findsOneWidget);
      expect(find.text('Sede Morón'), findsOneWidget);
      expect(find.text('Fútbol 5'), findsOneWidget);
      expect(find.text('Al aire libre'), findsOneWidget);
      expect(find.text('Iluminada'), findsOneWidget);
      expect(find.textContaining('38.000'), findsOneWidget);
      expect(find.text('Moron_Rivadavia_19850_Futbol_F5_1'), findsOneWidget);
      expect(habilitado(tester, 'Sede'), isFalse);
      expect(habilitado(tester, 'Deporte'), isFalse);
      expect(habilitado(tester, 'Tipo'), isFalse);
      expect(habilitado(tester, 'GUARDAR ESPACIO'), isFalse);
      semantica.dispose();
    },
  );

  testWidgets('guarda el precio nuevo, avisa y vuelve al listado', (
    tester,
  ) async {
    final pedidos = await abrir(tester);
    await escribirPrecio(tester, '45000');

    await tocar(tester, 'GUARDAR ESPACIO');

    final put = pedidos.singleWhere((p) => p.method == 'PUT');
    // Sólo lo que cambió.
    expect(jsonDecode(put.body), {'price_per_hour': 45000});
    expect(find.text('Los cambios se guardaron correctamente'), findsOneWidget);
    expect(find.text('ALTA ESPACIO'), findsOneWidget);
    expect(find.textContaining('45.000 por hora'), findsOneWidget);
  });

  testWidgets('un precio vacío o en cero se marca y no deja guardar', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    await abrir(tester);

    await escribirPrecio(tester, '');
    expect(find.text('Este campo es obligatorio'), findsOneWidget);
    expect(habilitado(tester, 'GUARDAR ESPACIO'), isFalse);

    await escribirPrecio(tester, '0');
    expect(
      find.text('Ingresá un precio entre \$ 1 y \$ 9.999.999'),
      findsOneWidget,
    );
    expect(habilitado(tester, 'GUARDAR ESPACIO'), isFalse);
    semantica.dispose();
  });

  testWidgets('volver al precio de antes deja otra vez sin nada que guardar', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    await abrir(tester);

    await escribirPrecio(tester, '45000');
    expect(habilitado(tester, 'GUARDAR ESPACIO'), isTrue);
    await escribirPrecio(tester, '38000');
    expect(habilitado(tester, 'GUARDAR ESPACIO'), isFalse);
    semantica.dispose();
  });

  testWidgets('el espacio dado de baja en otra sesión: el aviso y el listado', (
    tester,
  ) async {
    await abrir(tester, alGuardar: (404, ''));
    await escribirPrecio(tester, '45000');

    await tocar(tester, 'GUARDAR ESPACIO');
    expect(find.text('Esto cambió mientras tanto'), findsOneWidget);
    await tocar(tester, 'VER LO ACTUALIZADO');

    expect(find.text('ALTA ESPACIO'), findsOneWidget);
  });

  testWidgets('el servidor falla: el aviso y el precio escrito sigue', (
    tester,
  ) async {
    await abrir(tester, alGuardar: (500, '{}'));
    await escribirPrecio(tester, '45000');

    await tocar(tester, 'GUARDAR ESPACIO');
    expect(find.text('Error del servidor'), findsOneWidget);
    await tocar(tester, 'ACEPTAR');

    expect(find.textContaining('45.000'), findsOneWidget);
    expect(find.text('Editar espacio deportivo'), findsOneWidget);
  });

  testWidgets('CANCELAR vuelve al listado sin pedir nada', (tester) async {
    final pedidos = await abrir(tester);
    await escribirPrecio(tester, '45000');

    await tocar(tester, 'CANCELAR');

    expect(pedidos.where((p) => p.method == 'PUT'), isEmpty);
    expect(find.text('ALTA ESPACIO'), findsOneWidget);
  });

  testWidgets('DAR DE BAJA EL ESPACIO abre la confirmación', (tester) async {
    await abrir(tester);

    await tocar(tester, 'DAR DE BAJA EL ESPACIO');

    expect(find.text('¿Dar de baja el espacio?'), findsOneWidget);
    expect(
      find.text('Moron_Rivadavia_19850_Futbol_F5_1. La acción es permanente.'),
      findsOneWidget,
    );
    await tester.tap(
      find.descendant(of: find.byType(Dialog), matching: find.text('CANCELAR')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Editar espacio deportivo'), findsOneWidget);
  });

  testWidgets('con el texto al 200 % en un teléfono chico no se corta nada', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await abrir(tester, tamano: const Size(360, 800));
    expect(tester.takeException(), isNull);
  });
}
