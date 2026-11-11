import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'my_bookings_test.dart' show bookingJson;
import 'support/mount.dart';
import 'support/user.dart';

void main() {
  Future<List<http.Request>> untilConfirm(
    WidgetTester tester, {
    (int, String) response = (201, ''),
    Size size = const Size(393, 852),
  }) async {
    final requests = <http.Request>[];
    final (status, body) = response;
    await mountUser(
      tester,
      start:
          '/venues/00000000-0000-7000-8000-000000000001/spaces/00000000-0000-7000-8000-000000000009',
      size: size,
      api: apiRoutes({
        ...venueRoutes(),
        'POST /bookings': (status, body.isEmpty ? bookingJson() : body),
      }, requests: requests),
    );
    final slot = find.bySemanticsLabel('18:00 – 19:00');
    await tester.ensureVisible(slot);
    await tester.pumpAndSettle();
    await tester.tap(slot);
    await tester.pumpAndSettle();
    await tester.tap(find.text('CONTINUAR'));
    await tester.pumpAndSettle();
    return requests;
  }

  testWidgets('confirming sends the choice and shows the receipt', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final requests = await untilConfirm(tester);

    await tester.tap(find.text('CONFIRMAR RESERVA'));
    await tester.pumpAndSettle();

    final request = requests.lastWhere((p) => p.method == 'POST');
    expect(request.url.path, '/bookings');
    expect(
      request.body,
      contains('"space_id":"00000000-0000-7000-8000-000000000009"'),
    );
    expect(request.body, contains('"start_hour":"18:00"'));
    expect(request.body, contains('"hours":1'));
    expect(find.text('¡Reserva confirmada!'), findsOneWidget);
    expect(find.text('Moron_Rivadavia_19850_Futbol_F5_1'), findsOneWidget);
    expect(find.text('21:00 – 22:00 · 1 hora'), findsOneWidget);

    await tester.tap(find.text('VER MIS RESERVAS'));
    await tester.pumpAndSettle();
    expect(find.text('Próximas'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('if the time slot got taken, it warns and returns to the grid', (
    tester,
  ) async {
    final requests = await untilConfirm(
      tester,
      response: (409, '{"errors": {"slot": "Ese horario se ocupó"}}'),
    );

    await tester.tap(find.text('CONFIRMAR RESERVA'));
    await tester.pumpAndSettle();

    expect(find.text('Ese horario se ocupó'), findsOneWidget);
    expect(
      find.textContaining('Cancha 1 · Jue 12, 18:00 – 19:00'),
      findsOneWidget,
    );
    final before = requests.length;
    await tester.tap(find.text('ELEGIR OTRO HORARIO'));
    await tester.pumpAndSettle();
    expect(find.text('HORARIO DISPONIBLE'), findsOneWidget);
    expect(find.text('Sin horario elegido'), findsOneWidget);
    expect(
      requests.skip(before).where((p) => p.url.path.endsWith('/slots')),
      isNotEmpty,
    );
  });

  testWidgets(
    'the server fails: the notice shows and it stays on confirmation',
    (tester) async {
      await untilConfirm(tester, response: (500, '{}'));

      await tester.tap(find.text('CONFIRMAR RESERVA'));
      await tester.pumpAndSettle();

      expect(find.text('Error del servidor'), findsOneWidget);
      await tester.tap(find.text('ACEPTAR'));
      await tester.pumpAndSettle();
      expect(find.text('Confirmá tu reserva'), findsOneWidget);
    },
  );

  testWidgets('with text at 200 % the confirmation is not cut off', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await untilConfirm(tester, size: const Size(360, 800));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('CONFIRMAR RESERVA'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
