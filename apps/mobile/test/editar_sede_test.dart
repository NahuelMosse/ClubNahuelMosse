import 'dart:convert';

import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'soporte/admin.dart';

void main() {
  Future<List<http.Request>> abrir(
    WidgetTester tester, {
    List<(int, String)> alGuardar = const [],
    Size tamano = const Size(393, 852),
  }) async {
    final pedidos = <http.Request>[];
    final respuestas = [...alGuardar];
    await montarAdmin(
      tester,
      tamano: tamano,
      api: ApiClient(
        'http://api.falsa',
        cliente: MockClient((pedido) async {
          pedidos.add(pedido);
          final (codigo, cuerpo) = switch ((pedido.method, pedido.url.path)) {
            ('PUT', '/sedes/00000000-0000-7000-8000-000000000001') =>
              respuestas.isEmpty
                  ? (200, sedeMoronJson)
                  : respuestas.removeAt(0),
            ('GET', '/sedes') => (200, '{"sedes": [$sedeMoronJson]}'),
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
    await tester.tap(find.bySemanticsLabel('Editar sede Sede Morón'));
    await tester.pumpAndSettle();
    return pedidos;
  }

  Future<void> escribir(WidgetTester tester, String campo, String texto) async {
    await tester.enterText(
      find.descendant(
        of: find.bySemanticsLabel(campo),
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

  Map<String, Object?> cuerpo(http.Request pedido) =>
      switch (jsonDecode(pedido.body)) {
        final Map<String, Object?> datos => datos,
        _ => const {},
      };

  testWidgets('abre con los datos de la sede cargados', (tester) async {
    await abrir(tester);

    expect(find.text('Editar sede'), findsOneWidget);
    expect(find.text('Sede Morón'), findsWidgets);
    expect(find.text('Av. Rivadavia 19850'), findsOneWidget);
    expect(find.text('09:00'), findsOneWidget);
    expect(find.text('00:00'), findsOneWidget);
    expect(find.text('Lunes a sábado'), findsOneWidget);
  });

  testWidgets('guarda los datos nuevos, avisa y vuelve al listado', (
    tester,
  ) async {
    final pedidos = await abrir(tester);
    await escribir(tester, 'Dirección', 'Av. Rivadavia 20000');

    await tocar(tester, 'GUARDAR CAMBIOS');

    final put = pedidos.singleWhere((p) => p.method == 'PUT');
    expect(cuerpo(put), {
      'nombre': 'Sede Morón',
      'direccion': 'Av. Rivadavia 20000',
      'apertura': '09:00',
      'cierre': '00:00',
      'dias': [1, 2, 3, 4, 5, 6],
      'confirmar': false,
    });
    expect(find.text('Los cambios se guardaron correctamente'), findsOneWidget);
    expect(find.text('AGREGAR SEDE'), findsOneWidget);
  });

  testWidgets(
    'con un obligatorio vacío, el aviso y GUARDAR CAMBIOS se puede tocar pero no envía',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final pedidos = await abrir(tester);

      await escribir(tester, 'Nombre de la sede', '');

      expect(find.text('El nombre es obligatorio'), findsOneWidget);
      final boton = find.bySemanticsLabel('GUARDAR CAMBIOS');
      expect(tester.getSemantics(boton).flagsCollection.isEnabled, isTrue);
      await tocar(tester, 'GUARDAR CAMBIOS');
      expect(find.text('El nombre es obligatorio'), findsOneWidget);
      expect(pedidos.where((p) => p.method == 'PUT'), isEmpty);
      semantica.dispose();
    },
  );

  testWidgets('con reservas afuera pide confirmar y GUARDAR IGUAL confirma', (
    tester,
  ) async {
    final pedidos = await abrir(
      tester,
      alGuardar: [(409, '{"reservas_afuera": 3}')],
    );
    await elegir(tester, 'Horario de cierre', '22:00');

    await tocar(tester, 'GUARDAR CAMBIOS');

    expect(find.text('¿Guardar el horario nuevo?'), findsOneWidget);
    expect(
      find.text(
        '3 reservas futuras de Sede Morón terminan después de las 22:00. Si '
        'guardás, se mantienen en su horario original: el cambio rige para las '
        'reservas nuevas.',
      ),
      findsOneWidget,
    );
    await tocar(tester, 'GUARDAR IGUAL');

    final puts = pedidos.where((p) => p.method == 'PUT').toList();
    expect(puts.map((p) => cuerpo(p)['confirmar']), [false, true]);
    expect(find.text('Los cambios se guardaron correctamente'), findsOneWidget);
  });

  testWidgets('con varios motivos, el aviso habla del horario nuevo', (
    tester,
  ) async {
    await abrir(tester, alGuardar: [(409, '{"reservas_afuera": 1}')]);
    await elegir(tester, 'Horario de apertura', '10:00');
    await elegir(tester, 'Días que abre', 'Lunes a viernes');

    await tocar(tester, 'GUARDAR CAMBIOS');

    expect(
      find.textContaining(
        '1 reserva futura de Sede Morón queda fuera del horario nuevo. Si '
        'guardás, se mantiene',
      ),
      findsOneWidget,
    );
    await tocar(tester, 'REVISAR EL HORARIO');
    expect(find.text('Editar sede'), findsOneWidget);
    expect(find.text('10:00'), findsOneWidget);
  });

  testWidgets('un nombre en uso queda marcado en el campo', (tester) async {
    await abrir(
      tester,
      alGuardar: [
        (409, '{"errores": {"nombre": "Ya existe una sede con ese nombre"}}'),
      ],
    );
    await escribir(tester, 'Nombre de la sede', 'Sede Castelar');

    await tocar(tester, 'GUARDAR CAMBIOS');

    expect(find.text('Ya existe una sede con ese nombre'), findsOneWidget);
  });

  testWidgets('la sede dada de baja en otra sesión: el aviso y el listado', (
    tester,
  ) async {
    await abrir(tester, alGuardar: [(404, '')]);

    await tocar(tester, 'GUARDAR CAMBIOS');
    expect(find.text('Esto cambió mientras tanto'), findsOneWidget);
    await tocar(tester, 'VER LO ACTUALIZADO');

    expect(find.text('AGREGAR SEDE'), findsOneWidget);
  });

  testWidgets('el servidor falla: el aviso y lo escrito sigue', (tester) async {
    await abrir(tester, alGuardar: [(500, '{}')]);
    await escribir(tester, 'Dirección', 'Av. Rivadavia 20000');

    await tocar(tester, 'GUARDAR CAMBIOS');
    expect(find.text('Error del servidor'), findsOneWidget);
    await tocar(tester, 'ACEPTAR');

    expect(find.text('Av. Rivadavia 20000'), findsOneWidget);
    expect(find.text('Editar sede'), findsOneWidget);
  });

  testWidgets('DAR DE BAJA LA SEDE abre la confirmación con la sede', (
    tester,
  ) async {
    await abrir(tester);

    await tocar(tester, 'DAR DE BAJA LA SEDE');

    expect(find.text('¿Dar de baja la sede?'), findsOneWidget);
    expect(
      find.text(
        'Sede Morón · Av. Rivadavia 19850. Sus espacios deportivos dejan de '
        'estar disponibles.',
      ),
      findsOneWidget,
    );
    await tocar(tester, 'CANCELAR');
    expect(find.text('Editar sede'), findsOneWidget);
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
