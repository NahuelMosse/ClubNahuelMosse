import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'mis_reservas_test.dart' show reservaJson;
import 'soporte/montar.dart';
import 'soporte/usuario.dart';

void main() {
  Future<List<http.Request>> hastaConfirmar(
    WidgetTester tester, {
    (int, String) respuesta = (201, ''),
    Size tamano = const Size(393, 852),
  }) async {
    final pedidos = <http.Request>[];
    final (codigo, cuerpo) = respuesta;
    await montarUsuario(
      tester,
      inicio:
          '/sedes/00000000-0000-7000-8000-000000000001/canchas/00000000-0000-7000-8000-000000000009',
      tamano: tamano,
      api: apiRutas({
        ...rutasDeSedes(),
        'POST /reservas': (codigo, cuerpo.isEmpty ? reservaJson() : cuerpo),
      }, pedidos: pedidos),
    );
    final franja = find.bySemanticsLabel('18:00 – 19:00');
    await tester.ensureVisible(franja);
    await tester.pumpAndSettle();
    await tester.tap(franja);
    await tester.pumpAndSettle();
    await tester.tap(find.text('CONTINUAR'));
    await tester.pumpAndSettle();
    return pedidos;
  }

  testWidgets('confirmar manda la elección y muestra el comprobante', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    final pedidos = await hastaConfirmar(tester);

    await tester.tap(find.text('CONFIRMAR RESERVA'));
    await tester.pumpAndSettle();

    final pedido = pedidos.lastWhere((p) => p.method == 'POST');
    expect(pedido.url.path, '/reservas');
    expect(
      pedido.body,
      contains('"espacio_id":"00000000-0000-7000-8000-000000000009"'),
    );
    expect(pedido.body, contains('"desde":"18:00"'));
    expect(pedido.body, contains('"horas":1'));
    expect(find.text('¡Reserva confirmada!'), findsOneWidget);
    expect(find.text('Moron_Rivadavia_19850_Futbol_F5_1'), findsOneWidget);
    expect(find.text('21:00 – 22:00 · 1 hora'), findsOneWidget);

    await tester.tap(find.text('VER MIS RESERVAS'));
    await tester.pumpAndSettle();
    expect(find.text('Próximas'), findsOneWidget);
    semantica.dispose();
  });

  testWidgets('si el horario se ocupó, avisa y vuelve a la grilla', (
    tester,
  ) async {
    final pedidos = await hastaConfirmar(
      tester,
      respuesta: (409, '{"errores": {"horario": "Ese horario se ocupó"}}'),
    );

    await tester.tap(find.text('CONFIRMAR RESERVA'));
    await tester.pumpAndSettle();

    expect(find.text('Ese horario se ocupó'), findsOneWidget);
    expect(
      find.textContaining('Cancha 1 · Jue 12, 18:00 – 19:00'),
      findsOneWidget,
    );
    final antes = pedidos.length;
    await tester.tap(find.text('ELEGIR OTRO HORARIO'));
    await tester.pumpAndSettle();
    expect(find.text('HORARIO DISPONIBLE'), findsOneWidget);
    expect(find.text('Sin horario elegido'), findsOneWidget);
    expect(
      pedidos.skip(antes).where((p) => p.url.path.endsWith('/horarios')),
      isNotEmpty,
    );
  });

  testWidgets('el servidor falla: el aviso y sigue en la confirmación', (
    tester,
  ) async {
    await hastaConfirmar(tester, respuesta: (500, '{}'));

    await tester.tap(find.text('CONFIRMAR RESERVA'));
    await tester.pumpAndSettle();

    expect(find.text('Error del servidor'), findsOneWidget);
    await tester.tap(find.text('ACEPTAR'));
    await tester.pumpAndSettle();
    expect(find.text('Confirmá tu reserva'), findsOneWidget);
  });

  testWidgets('con el texto al 200 % la confirmación no se corta', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await hastaConfirmar(tester, tamano: const Size(360, 800));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('CONFIRMAR RESERVA'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
