import 'dart:convert';

import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/mount.dart';
import 'support/user.dart';

void main() {
  const spaces =
      '[{"id": "00000000-0000-7000-8000-000000000009", "name": "Moron_Rivadavia_19850_Futbol_F5_1", "venue_id": "00000000-0000-7000-8000-000000000001", '
      '"venue": "Sede Morón", "sport": "Futbol", "kind": "F5", "number": 1, '
      '"covered": false, "lit": true, "price_per_hour": 38000}, '
      '{"id": "00000000-0000-7000-8000-000000000011", "name": "Moron_Rivadavia_19850_Futbol_F5_2", "venue_id": "00000000-0000-7000-8000-000000000001", '
      '"venue": "Sede Morón", "sport": "Futbol", "kind": "F5", "number": 2, '
      '"covered": true, "lit": true, "price_per_hour": 38000}]';

  Future<List<http.Request>> open(
    WidgetTester tester, {
    Map<String, (int, String)> overrides = const {},
  }) async {
    final requests = <http.Request>[];
    await mountUser(
      tester,
      start:
          '/venues/00000000-0000-7000-8000-000000000001/spaces/00000000-0000-7000-8000-000000000009',
      api: apiRoutes({
        ...venueRoutes(spaces: spaces),
        'GET /spaces/00000000-0000-7000-8000-000000000011/slots': (
          200,
          gridJson(taken: {18}),
        ),
        ...overrides,
      }, requests: requests),
    );
    return requests;
  }

  bool enabled(WidgetTester tester, String label) => tester
      .getSemantics(find.bySemanticsLabel(label))
      .flagsCollection
      .isEnabled;

  bool chosen(WidgetTester tester, String label) => tester
      .getSemantics(find.bySemanticsLabel(label))
      .flagsCollection
      .isSelected;

  Future<void> tapLabel(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.bySemanticsLabel(label));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(label));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the day grid with the taken slots dimmed and the note', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await open(tester);

    expect(chosen(tester, 'Jueves 12'), isTrue);
    expect(find.bySemanticsLabel('Miércoles 18'), findsOneWidget);
    expect(enabled(tester, '08:00 – 09:00'), isTrue);
    expect(enabled(tester, '09:00 – 10:00'), isFalse);
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
    expect(enabled(tester, 'CONTINUAR'), isFalse);
    semantics.dispose();
  });

  testWidgets('choosing a slot completes the summary and enables continue', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await open(tester);

    await tapLabel(tester, '18:00 – 19:00');

    expect(chosen(tester, '18:00 – 19:00'), isTrue);
    expect(find.textContaining('38.000 × 1'), findsOneWidget);
    expect(enabled(tester, 'CONTINUAR'), isTrue);

    await tester.tap(find.text('CONTINUAR'));
    await tester.pumpAndSettle();
    expect(find.text('Confirmá tu reserva'), findsOneWidget);
    expect(find.text('Cancha 1 · Al aire libre'), findsOneWidget);
    expect(find.text('Jue 12 de noviembre'), findsOneWidget);
    expect(find.text('18:00 – 19:00 · 1 hora'), findsOneWidget);

    await tester.tap(find.text('CANCELAR'));
    await tester.pumpAndSettle();
    expect(find.text('SELECCIONÁ CANCHA'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets(
    'switching court requests its grid and drops the slot that is no longer there',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final requests = await open(tester);
      await tapLabel(tester, '18:00 – 19:00');

      await tapLabel(tester, 'Cancha 2, Techada');

      expect(
        requests.last.url.path,
        '/spaces/00000000-0000-7000-8000-000000000011/slots',
      );
      expect(chosen(tester, 'Cancha 2, Techada'), isTrue);
      expect(enabled(tester, '18:00 – 19:00'), isFalse);
      expect(find.text('Sin horario elegido'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets('the date and the duration go in the query', (tester) async {
    final semantics = tester.ensureSemantics();
    final requests = await open(tester);

    await tapLabel(tester, 'Viernes 13');
    expect(requests.last.url.queryParameters['date'], '2026-11-13');

    await tapLabel(tester, 'Una hora más');
    expect(requests.last.url.queryParameters['hours'], '2');
    expect(find.text('2 horas'), findsOneWidget);
    expect(enabled(tester, 'Una hora menos'), isTrue);
    semantics.dispose();
  });

  testWidgets('the venue closed that day shows the empty state', (
    tester,
  ) async {
    await open(
      tester,
      overrides: {
        'GET /spaces/00000000-0000-7000-8000-000000000009/slots': (
          200,
          gridJson(opens: false),
        ),
      },
    );

    expect(find.text('No hay horarios disponibles'), findsOneWidget);
    expect(
      find.text('La sede no abre ese día. Probá con otra fecha.'),
      findsOneWidget,
    );
  });

  testWidgets('with no free slots it suggests another date or another court', (
    tester,
  ) async {
    await open(
      tester,
      overrides: {
        'GET /spaces/00000000-0000-7000-8000-000000000009/slots': (
          200,
          gridJson(taken: {for (var h = 8; h < 23; h++) h}),
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

  testWidgets('the server fails: the notice and then RETRY with no slots', (
    tester,
  ) async {
    await open(
      tester,
      overrides: {
        'GET /spaces/00000000-0000-7000-8000-000000000009/slots': (500, '{}'),
      },
    );

    expect(find.text('Error del servidor'), findsOneWidget);
    await tester.tap(find.text('ACEPTAR'));
    await tester.pumpAndSettle();
    expect(find.text('REINTENTAR'), findsOneWidget);
    expect(find.text('08:00 – 09:00'), findsNothing);
  });

  testWidgets('a court that no longer exists returns to the venue', (
    tester,
  ) async {
    await open(
      tester,
      overrides: {
        'GET /spaces/00000000-0000-7000-8000-000000000009/slots': (
          404,
          '{"errors": {"space_id": "Esta cancha ya no está disponible"}}',
        ),
      },
    );

    expect(find.text('Esto cambió mientras tanto'), findsOneWidget);
    await tester.tap(find.text('VER LO ACTUALIZADO'));
    await tester.pumpAndSettle();
    expect(find.text('Esto cambió mientras tanto'), findsNothing);
    expect(find.text('SELECCIONÁ CANCHA'), findsNothing);
  });

  testWidgets('entering the confirmation without choosing returns to the slots', (
    tester,
  ) async {
    await mountUser(
      tester,
      start:
          '/venues/00000000-0000-7000-8000-000000000001/spaces/00000000-0000-7000-8000-000000000009/book',
      api: apiRoutes(venueRoutes(spaces: spaces)),
    );

    expect(find.text('SELECCIONÁ CANCHA'), findsOneWidget);
  });

  testWidgets(
    'going back from the confirmation keeps the court, the duration and the slot',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final requests = await open(tester);
      await tapLabel(tester, 'Cancha 2, Techada');
      await tapLabel(tester, 'Una hora más');
      await tapLabel(tester, '10:00 – 11:00');
      await tester.tap(find.text('CONTINUAR'));
      await tester.pumpAndSettle();
      expect(find.text('Cancha 2 · Techada'), findsOneWidget);
      final before = requests.length;

      await tester.tap(find.text('CANCELAR'));
      await tester.pumpAndSettle();

      expect(requests.length, before);
      expect(chosen(tester, 'Cancha 2, Techada'), isTrue);
      expect(find.text('2 horas'), findsOneWidget);
      expect(chosen(tester, '10:00 – 11:00'), isTrue);
      semantics.dispose();
    },
  );

  testWidgets('if the chosen day has already passed, it queries today again', (
    tester,
  ) async {
    final requests = <http.Request>[];
    await mountUser(
      tester,
      start:
          '/venues/00000000-0000-7000-8000-000000000001/spaces/00000000-0000-7000-8000-000000000009',
      api: ApiClient(
        'http://api.falsa',
        client: MockClient((request) async {
          requests.add(request);
          final routes = venueRoutes(spaces: spaces);
          final expired =
              request.url.path ==
                  '/spaces/00000000-0000-7000-8000-000000000009/slots' &&
              request.url.queryParameters.containsKey('fecha');
          final (status, body) = expired
              ? (422, '{"errors": {"date": "Elegí un día de los próximos 7"}}')
              : routes['${request.method} ${request.url.path}'] ?? (404, '{}');
          return http.Response.bytes(
            utf8.encode(body),
            status,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      ),
    );

    await tester.ensureVisible(find.text('13'));
    await tester.tap(find.text('13'));
    await tester.pumpAndSettle();

    expect(requests.last.url.queryParameters.containsKey('fecha'), isFalse);
    expect(find.text('Error del servidor'), findsNothing);
    expect(find.text('08:00 – 09:00'), findsOneWidget);
  });

  testWidgets('with text at 200 % on a small phone nothing is cut off', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await mountUser(
      tester,
      size: const Size(360, 800),
      start:
          '/venues/00000000-0000-7000-8000-000000000001/spaces/00000000-0000-7000-8000-000000000009',
      api: apiRoutes(venueRoutes(spaces: spaces)),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('SELECCIONÁ CANCHA'), findsOneWidget);
  });
}
