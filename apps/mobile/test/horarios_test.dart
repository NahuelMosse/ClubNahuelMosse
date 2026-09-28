import 'dart:convert';

import 'package:clubnahuelmosse/api/cliente_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'soporte/montar.dart';
import 'soporte/usuario.dart';

void main() {
  const espacios =
      '[{"id": 9, "nombre": "Moron_Rivadavia_19850_Futbol_F5_1", "sede_id": 1, '
      '"sede": "Sede Morón", "deporte": "Futbol", "tipo": "F5", "numero": 1, '
      '"techada": false, "iluminada": true, "precio_por_hora": 38000}, '
      '{"id": 11, "nombre": "Moron_Rivadavia_19850_Futbol_F5_2", "sede_id": 1, '
      '"sede": "Sede Morón", "deporte": "Futbol", "tipo": "F5", "numero": 2, '
      '"techada": true, "iluminada": true, "precio_por_hora": 38000}]';

  Future<List<http.Request>> abrir(
    WidgetTester tester, {
    Map<String, (int, String)> cambios = const {},
  }) async {
    final pedidos = <http.Request>[];
    await montarUsuario(
      tester,
      inicio: '/sedes/1/canchas/9',
      api: apiRutas({
        ...rutasDeSedes(espacios: espacios),
        'GET /espacios/11/horarios': (200, grillaJson(ocupadas: {18})),
        ...cambios,
      }, pedidos: pedidos),
    );
    return pedidos;
  }

  bool habilitado(WidgetTester tester, String etiqueta) => tester
      .getSemantics(find.bySemanticsLabel(etiqueta))
      .flagsCollection
      .isEnabled;

  bool elegido(WidgetTester tester, String etiqueta) => tester
      .getSemantics(find.bySemanticsLabel(etiqueta))
      .flagsCollection
      .isSelected;

  Future<void> tocar(WidgetTester tester, String etiqueta) async {
    await tester.ensureVisible(find.bySemanticsLabel(etiqueta));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(etiqueta));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'muestra la grilla del día con las ocupadas atenuadas y la nota',
    (tester) async {
      final semantica = tester.ensureSemantics();
      await abrir(tester);

      expect(elegido(tester, 'Jueves 12'), isTrue);
      expect(find.bySemanticsLabel('Miércoles 18'), findsOneWidget);
      expect(habilitado(tester, '08:00 – 09:00'), isTrue);
      expect(habilitado(tester, '09:00 – 10:00'), isFalse);
      expect(
        find.text('Algunos horarios ya están ocupados · 6 no disponibles'),
        findsOneWidget,
      );
      expect(
        find.text('Horas completas, de 1 a 4 h. La sede cierra a las 23:00.'),
        findsOneWidget,
      );
      expect(find.text('Sin horario elegido'), findsOneWidget);
      expect(find.text('Jue 12 de noviembre'), findsOneWidget);
      expect(habilitado(tester, 'CONTINUAR'), isFalse);
      semantica.dispose();
    },
  );

  testWidgets('elegir una franja completa el resumen y habilita continuar', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    await abrir(tester);

    await tocar(tester, '18:00 – 19:00');

    expect(elegido(tester, '18:00 – 19:00'), isTrue);
    expect(find.textContaining('38.000 × 1'), findsOneWidget);
    expect(habilitado(tester, 'CONTINUAR'), isTrue);

    await tester.tap(find.text('CONTINUAR'));
    await tester.pumpAndSettle();
    expect(find.text('Confirmá tu reserva'), findsOneWidget);
    expect(find.text('Cancha 1 · Al aire libre'), findsOneWidget);
    expect(find.text('Jue 12 de noviembre'), findsOneWidget);
    expect(find.text('18:00 – 19:00 · 1 hora'), findsOneWidget);

    await tester.tap(find.text('CANCELAR'));
    await tester.pumpAndSettle();
    expect(find.text('SELECCIONÁ CANCHA'), findsOneWidget);
    semantica.dispose();
  });

  testWidgets(
    'cambiar de cancha pide su grilla y quita la franja que ya no está',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final pedidos = await abrir(tester);
      await tocar(tester, '18:00 – 19:00');

      await tocar(tester, 'Cancha 2, Techada');

      expect(pedidos.last.url.path, '/espacios/11/horarios');
      expect(elegido(tester, 'Cancha 2, Techada'), isTrue);
      expect(habilitado(tester, '18:00 – 19:00'), isFalse);
      expect(find.text('Sin horario elegido'), findsOneWidget);
      semantica.dispose();
    },
  );

  testWidgets('la fecha y la duración van en la consulta', (tester) async {
    final semantica = tester.ensureSemantics();
    final pedidos = await abrir(tester);

    await tocar(tester, 'Viernes 13');
    expect(pedidos.last.url.queryParameters['fecha'], '2026-11-13');

    await tocar(tester, 'Una hora más');
    expect(pedidos.last.url.queryParameters['horas'], '2');
    expect(find.text('2 horas'), findsOneWidget);
    expect(habilitado(tester, 'Una hora menos'), isTrue);
    semantica.dispose();
  });

  testWidgets('la sede cerrada ese día muestra el estado vacío', (
    tester,
  ) async {
    await abrir(
      tester,
      cambios: {'GET /espacios/9/horarios': (200, grillaJson(abre: false))},
    );

    expect(find.text('No hay horarios disponibles'), findsOneWidget);
    expect(
      find.text('La sede no abre ese día. Probá con otra fecha.'),
      findsOneWidget,
    );
  });

  testWidgets('sin franjas libres sugiere otra fecha u otra cancha', (
    tester,
  ) async {
    await abrir(
      tester,
      cambios: {
        'GET /espacios/9/horarios': (
          200,
          grillaJson(ocupadas: {for (var h = 8; h < 23; h++) h}),
        ),
      },
    );
    expect(
      find.text(
        'Ya no quedan turnos libres ese día. Probá con otra fecha u otra cancha.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('el servidor falla: el aviso y después REINTENTAR sin horarios', (
    tester,
  ) async {
    await abrir(tester, cambios: {'GET /espacios/9/horarios': (500, '{}')});

    expect(find.text('Error del servidor'), findsOneWidget);
    await tester.tap(find.text('ACEPTAR'));
    await tester.pumpAndSettle();
    expect(find.text('REINTENTAR'), findsOneWidget);
    expect(find.text('08:00 – 09:00'), findsNothing);
  });

  testWidgets('una cancha que ya no está vuelve a la sede', (tester) async {
    await abrir(
      tester,
      cambios: {
        'GET /espacios/9/horarios': (
          404,
          '{"errores": {"espacio_id": "Esta cancha ya no está disponible"}}',
        ),
      },
    );

    expect(find.text('Esta cancha ya no está disponible'), findsOneWidget);
    expect(find.text('SELECCIONÁ CANCHA'), findsNothing);
  });

  testWidgets('entrar a confirmar sin elegir vuelve a los horarios', (
    tester,
  ) async {
    await montarUsuario(
      tester,
      inicio: '/sedes/1/canchas/9/reservar',
      api: apiRutas(rutasDeSedes(espacios: espacios)),
    );

    expect(find.text('SELECCIONÁ CANCHA'), findsOneWidget);
  });

  testWidgets(
    'volver de la confirmación deja la cancha, la duración y la franja',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final pedidos = await abrir(tester);
      await tocar(tester, 'Cancha 2, Techada');
      await tocar(tester, 'Una hora más');
      await tocar(tester, '10:00 – 11:00');
      await tester.tap(find.text('CONTINUAR'));
      await tester.pumpAndSettle();
      expect(find.text('Cancha 2 · Techada'), findsOneWidget);
      final antes = pedidos.length;

      await tester.tap(find.text('CANCELAR'));
      await tester.pumpAndSettle();

      expect(pedidos.length, antes);
      expect(elegido(tester, 'Cancha 2, Techada'), isTrue);
      expect(find.text('2 horas'), findsOneWidget);
      expect(elegido(tester, '10:00 – 11:00'), isTrue);
      semantica.dispose();
    },
  );

  testWidgets('si el día elegido ya pasó, vuelve a consultar el de hoy', (
    tester,
  ) async {
    final pedidos = <http.Request>[];
    await montarUsuario(
      tester,
      inicio: '/sedes/1/canchas/9',
      api: ClienteApi(
        'http://api.falsa',
        cliente: MockClient((pedido) async {
          pedidos.add(pedido);
          final rutas = rutasDeSedes(espacios: espacios);
          final vencida =
              pedido.url.path == '/espacios/9/horarios' &&
              pedido.url.queryParameters.containsKey('fecha');
          final (codigo, cuerpo) = vencida
              ? (
                  422,
                  '{"errores": {"fecha": "Elegí un día de los próximos 7"}}',
                )
              : rutas['${pedido.method} ${pedido.url.path}'] ?? (404, '{}');
          return http.Response.bytes(
            utf8.encode(cuerpo),
            codigo,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      ),
    );

    await tester.ensureVisible(find.text('13'));
    await tester.tap(find.text('13'));
    await tester.pumpAndSettle();

    expect(pedidos.last.url.queryParameters.containsKey('fecha'), isFalse);
    expect(find.text('Error del servidor'), findsNothing);
    expect(find.text('08:00 – 09:00'), findsOneWidget);
  });

  testWidgets('con el texto al 200 % en un teléfono chico no se corta nada', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await montarUsuario(
      tester,
      tamano: const Size(360, 800),
      inicio: '/sedes/1/canchas/9',
      api: apiRutas(rutasDeSedes(espacios: espacios)),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('SELECCIONÁ CANCHA'), findsOneWidget);
  });
}
