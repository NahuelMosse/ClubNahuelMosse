import 'dart:convert';
import 'dart:ui' show Tristate;

import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'my_bookings_test.dart' show bookingJson;
import 'support/user.dart';

void main() {
  // The booking is Thursday the 12th at 21:00 at the club; the grid already shows it as free.
  final grid = gridJson(taken: {9, 12});

  Future<List<http.Request>> open(
    WidgetTester tester, {
    (int, String)? onModify,
    Size size = const Size(393, 852),
  }) async {
    final requests = <http.Request>[];
    var modified = false;
    final routes = venueRoutes(grid: grid);
    await mountUser(
      tester,
      start: '/bookings',
      size: size,
      api: ApiClient(
        'http://api.falsa',
        client: MockClient((request) async {
          requests.add(request);
          final (code, body) = switch ((request.method, request.url.path)) {
            ('POST', '/bookings/00000000-0000-7000-8000-000000000001/modify') =>
              () {
                final r =
                    onModify ??
                    (
                      200,
                      bookingJson(
                        start: '2026-11-12T22:00:00+00:00',
                        end: '2026-11-12T23:00:00+00:00',
                      ),
                    );
                modified = r.$1 == 200;
                return r;
              }(),
            ('GET', '/bookings') => (
              200,
              '{"bookings": [${modified ? bookingJson(start: '2026-11-12T22:00:00+00:00', end: '2026-11-12T23:00:00+00:00') : bookingJson()}]}',
            ),
            _ => routes['${request.method} ${request.url.path}'] ?? (404, '{}'),
          };
          return http.Response.bytes(
            utf8.encode(body),
            code,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      ),
    );
    return requests;
  }

  Future<void> tap(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  Future<void> upToConfirm(WidgetTester tester) async {
    await tap(tester, find.text('MODIFICAR'));
    await tap(tester, find.text('19:00 – 20:00'));
    await tap(tester, find.text('CONTINUAR CON EL CAMBIO'));
  }

  testWidgets(
    '«MODIFICAR» opens the grid of the booking\'s day, without duration and with its time marked',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final requests = await open(tester);

      await tap(tester, find.text('MODIFICAR'));

      final query = requests.last.url;
      expect(query.path, '/spaces/00000000-0000-7000-8000-000000000009/slots');
      expect(
        query.queryParameters['booking_id'],
        '00000000-0000-7000-8000-000000000001',
      );
      expect(query.queryParameters['date'], '2026-11-12');
      expect(query.queryParameters['hours'], '1');
      expect(
        find.textContaining(
          'Estás modificando tu reserva del Jue 12, 21:00 – 22:00',
        ),
        findsOneWidget,
      );
      expect(find.text('DURACIÓN'), findsNothing);
      expect(find.text('(actual)'), findsOneWidget);
      expect(find.bySemanticsLabel('21:00 – 22:00 (actual)'), findsOneWidget);
      final button = find.bySemanticsLabel('CONTINUAR CON EL CAMBIO');
      expect(tester.getSemantics(button).flagsCollection.isEnabled == Tristate.isTrue, isFalse);

      await tap(tester, find.text('19:00 – 20:00'));
      expect(tester.getSemantics(button).flagsCollection.isEnabled == Tristate.isTrue, isTrue);
      semantics.dispose();
    },
  );

  testWidgets(
    'saving moves the booking and returns to «Mis reservas» with the notice',
    (tester) async {
      final requests = await open(tester);
      await upToConfirm(tester);

      expect(find.text('Confirmá el cambio'), findsOneWidget);
      expect(find.text('ANTES'), findsOneWidget);
      expect(find.text('Jue 12 · 21:00 – 22:00'), findsOneWidget);
      expect(find.text('AHORA'), findsOneWidget);
      expect(find.text('Jue 12 · 19:00 – 20:00'), findsOneWidget);

      await tap(tester, find.text('GUARDAR EL CAMBIO'));

      final post = requests.singleWhere((p) => p.method == 'POST');
      expect(jsonDecode(post.body), {
        'space_id': '00000000-0000-7000-8000-000000000009',
        'date': '2026-11-12',
        'start_hour': '19:00',
      });
      expect(find.text('Reserva modificada'), findsOneWidget);
      expect(find.text('19:00 – 20:00'), findsOneWidget);
      expect(find.text('21:00 – 22:00'), findsNothing);
    },
  );

  testWidgets('leaving the booking as it is returns without sending anything', (
    tester,
  ) async {
    final requests = await open(tester);
    await upToConfirm(tester);

    await tap(tester, find.text('DEJAR LA RESERVA COMO ESTÁ'));

    expect(requests.where((p) => p.method == 'POST'), isEmpty);
    expect(find.text('21:00 – 22:00'), findsOneWidget);
    expect(find.text('MODIFICAR'), findsOneWidget);
  });

  testWidgets('the time slot was taken: the notice and the grid read again', (
    tester,
  ) async {
    final requests = await open(
      tester,
      onModify: (409, '{"errors": {"slot": "Ese horario se ocupó"}}'),
    );
    await upToConfirm(tester);
    final before = requests.where((p) => p.url.path.endsWith('/slots')).length;

    await tap(tester, find.text('GUARDAR EL CAMBIO'));
    expect(find.text('Esto cambió mientras tanto'), findsOneWidget);
    await tap(tester, find.text('VER LO ACTUALIZADO'));

    expect(find.textContaining('Estás modificando tu reserva'), findsOneWidget);
    expect(
      requests.where((p) => p.url.path.endsWith('/slots')).length,
      before + 1,
    );
  });

  testWidgets(
    'the booking can no longer be modified: the notice and «Mis reservas»',
    (tester) async {
      await open(
        tester,
        onModify: (
          409,
          '{"errors": {"reserva": "Esto cambió mientras tanto"}}',
        ),
      );
      await upToConfirm(tester);

      await tap(tester, find.text('GUARDAR EL CAMBIO'));
      expect(find.text('Esto cambió mientras tanto'), findsOneWidget);
      await tap(tester, find.text('VER LO ACTUALIZADO'));

      expect(find.text('Próximas'), findsOneWidget);
      expect(find.textContaining('Estás modificando'), findsNothing);
    },
  );

  testWidgets('the server fails: the notice and the confirmation stays open', (
    tester,
  ) async {
    await open(tester, onModify: (500, '{}'));
    await upToConfirm(tester);

    await tap(tester, find.text('GUARDAR EL CAMBIO'));
    expect(find.text('Error del servidor'), findsOneWidget);
    await tap(tester, find.text('ACEPTAR'));

    expect(find.text('Confirmá el cambio'), findsOneWidget);
  });

  testWidgets('with text at 200 % on a small phone nothing is cut off', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await open(tester, size: const Size(360, 800));
    expect(tester.takeException(), isNull);
    await upToConfirm(tester);
    expect(tester.takeException(), isNull);
  });
}
