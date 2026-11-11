import 'dart:async';
import 'dart:convert';

import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:clubnahuelmosse/features/home/presentation/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'my_bookings_test.dart' show bookingJson;
import 'support/user.dart';

/// An API with an active booking that can be canceled, and that cancels when [hold]
/// completes.
class _Server {
  _Server({this.hold});

  final Future<void>? hold;
  final requests = <http.Request>[];
  var _active = true;

  int get reads => requests
      .where((p) => p.method == 'GET' && p.url.path == '/bookings')
      .length;

  ApiClient get api =>
      ApiClient('http://api.falsa', client: MockClient(_respond));

  Future<http.Response> _respond(http.Request request) async {
    requests.add(request);
    final routes = venueRoutes();
    final (status, body) = switch ((request.method, request.url.path)) {
      ('GET', '/bookings') => (
        200,
        '{"bookings": [${_active ? bookingJson() : ''}]}',
      ),
      ('POST', '/bookings/00000000-0000-7000-8000-000000000001/cancel') =>
        await _cancel(),
      _ => routes['${request.method} ${request.url.path}'] ?? (404, '{}'),
    };
    return http.Response.bytes(
      utf8.encode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }

  Future<(int, String)> _cancel() async {
    await hold;
    _active = false;
    return (200, bookingJson(status: 'canceled'));
  }
}

void main() {
  Future<void> tapAndSettle(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'canceling from «Mis reservas» and going back: the Home no longer shows it',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final server = _Server();
      await mountUser(tester, api: server.api, start: '/home');
      expect(find.text('TU PRÓXIMA RESERVA'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Tu cuenta'));
      await tester.pumpAndSettle();
      await tapAndSettle(tester, find.text('Mis reservas'));
      await tapAndSettle(tester, find.text('CANCELAR'));
      await tapAndSettle(tester, find.text('CANCELAR RESERVA'));
      await tapAndSettle(tester, find.text('ACEPTAR'));
      await tapAndSettle(tester, find.text('INICIO'));

      expect(find.text('RESERVÁ TU CANCHA'), findsOneWidget);
      expect(find.text('TU PRÓXIMA RESERVA'), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets('with the cancellation in progress the Home cannot be left', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final cancellation = Completer<void>();
    final server = _Server(hold: cancellation.future);
    await mountUser(tester, api: server.api, start: '/home');

    await tapAndSettle(tester, find.text('CANCELAR'));
    await tester.tap(find.text('CANCELAR RESERVA'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('VER TODAS →'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('TU PRÓXIMA RESERVA'), findsOneWidget);
    expect(find.text('Mis reservas'), findsNothing);
    expect(
      find.descendant(
        of: find.byType(HomeScreen),
        matching: find.byWidgetPredicate((w) => w is PopScope && !w.canPop),
      ),
      findsOneWidget,
    );

    cancellation.complete();
    await tester.pumpAndSettle();
    expect(find.text('Reserva cancelada con éxito'), findsOneWidget);
    await tester.tap(find.text('ACEPTAR'));
    await tester.pumpAndSettle();
    expect(find.text('TU PRÓXIMA RESERVA'), findsNothing);
    semantics.dispose();
  });

  testWidgets(
    'MODIFICAR goes back to the Home, which reads the bookings again',
    (tester) async {
      final server = _Server();
      await mountUser(tester, api: server.api, start: '/home');
      final before = server.reads;

      await tapAndSettle(tester, find.text('MODIFICAR'));
      expect(find.text('Inicio'), findsOneWidget);
      expect(find.text('Mis reservas'), findsNothing);

      await tapAndSettle(tester, find.text('Inicio'));

      expect(find.text('TU PRÓXIMA RESERVA'), findsOneWidget);
      expect(server.reads, greaterThan(before));
    },
  );
}
