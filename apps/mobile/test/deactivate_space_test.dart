import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/admin.dart';

void main() {
  const name = 'Moron_Rivadavia_19850_Futbol_F5_1';

  Future<List<http.Request>> open(
    WidgetTester tester, {
    (int, String) onDeactivate = (204, ''),
    Size size = const Size(393, 852),
  }) async {
    final requests = <http.Request>[];
    var deactivated = false;
    await mountAdmin(
      tester,
      start: '/admin/espacios',
      size: size,
      api: ApiClient(
        'http://api.falsa',
        cliente: MockClient((request) async {
          requests.add(request);
          final (status, body) = switch ((request.method, request.url.path)) {
            ('DELETE', '/spaces/00000000-0000-7000-8000-000000000009') => () {
              deactivated = onDeactivate.$1 == 204 || onDeactivate.$1 == 404;
              return onDeactivate;
            }(),
            ('GET', '/spaces') => (
              200,
              '{"spaces": [${deactivated ? spaceTennisJson : '$spaceF5Json, $spaceTennisJson'}]}',
            ),
            ('GET', '/spaces/catalog') => (200, catalogJson),
            _ => (404, '{}'),
          };
          return http.Response.bytes(
            utf8.encode(body),
            status,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      ),
    );
    return requests;
  }

  Future<void> tapSettled(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'from the card: confirms, notifies and the list ends up without the space',
    (tester) async {
      final requests = await open(tester);

      await tapSettled(tester, find.bySemanticsLabel('Baja $name'));
      expect(find.text('¿Dar de baja el espacio?'), findsOneWidget);
      expect(find.text('$name. La acción es permanente.'), findsOneWidget);
      await tapSettled(tester, find.text('CONFIRMAR BAJA'));

      expect(requests.where((p) => p.method == 'DELETE'), hasLength(1));
      expect(
        find.text('El espacio fue dado de baja correctamente'),
        findsOneWidget,
      );
      expect(find.text(name), findsNothing);
      expect(find.text('Moron_Rivadavia_19850_Tenis_PDL_1'), findsOneWidget);
    },
  );

  testWidgets('from the edit screen it ends in the list', (tester) async {
    await open(tester);
    await tapSettled(tester, find.bySemanticsLabel('Editar $name'));

    await tapSettled(tester, find.text('DAR DE BAJA EL ESPACIO'));
    await tapSettled(tester, find.text('CONFIRMAR BAJA'));

    expect(
      find.text('El espacio fue dado de baja correctamente'),
      findsOneWidget,
    );
    expect(find.text('ALTA ESPACIO'), findsOneWidget);
    expect(find.text(name), findsNothing);
  });

  testWidgets('«CANCELAR» sends nothing', (tester) async {
    final requests = await open(tester);

    await tapSettled(tester, find.bySemanticsLabel('Baja $name'));
    await tapSettled(tester, find.text('CANCELAR'));

    expect(requests.where((p) => p.method == 'DELETE'), isEmpty);
    expect(find.text(name), findsOneWidget);
  });

  testWidgets('with pending bookings: the notice shows and the space stays', (
    tester,
  ) async {
    await open(tester, onDeactivate: (409, '{"errors": {"space": "x"}}'));

    await tapSettled(tester, find.bySemanticsLabel('Baja $name'));
    await tapSettled(tester, find.text('CONFIRMAR BAJA'));

    expect(find.text('No se puede dar de baja el espacio'), findsOneWidget);
    await tapSettled(tester, find.text('ACEPTAR'));
    expect(find.text(name), findsOneWidget);
  });

  testWidgets(
    'already deactivated in another session: the notice and the re-read list',
    (tester) async {
      await open(tester, onDeactivate: (404, ''));

      await tapSettled(tester, find.bySemanticsLabel('Baja $name'));
      await tapSettled(tester, find.text('CONFIRMAR BAJA'));

      expect(find.text('Esto cambió mientras tanto'), findsOneWidget);
      await tapSettled(tester, find.text('VER LO ACTUALIZADO'));
      expect(find.text(name), findsNothing);
    },
  );

  testWidgets('the server fails: the notice shows and the space stays', (
    tester,
  ) async {
    await open(tester, onDeactivate: (500, '{}'));

    await tapSettled(tester, find.bySemanticsLabel('Baja $name'));
    await tapSettled(tester, find.text('CONFIRMAR BAJA'));

    expect(find.text('Error del servidor'), findsOneWidget);
    await tapSettled(tester, find.text('ACEPTAR'));
    expect(find.text(name), findsOneWidget);
  });

  testWidgets('with text at 130 % on a small phone the card buttons stack', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await open(tester, size: const Size(360, 800));
    expect(tester.takeException(), isNull);
    final editRect = tester.getRect(find.text('Editar').first);
    final deactivateRect = tester.getRect(find.text('Baja').first);
    expect(deactivateRect.top, greaterThan(editRect.bottom));
  });

  Future<List<http.Request>> openWith(
    WidgetTester tester,
    Future<http.Response> Function(int attempt) onDeactivate, {
    Size size = const Size(393, 852),
  }) async {
    final requests = <http.Request>[];
    var attempts = 0;
    var deactivated = false;
    http.Response json(int status, String body) => http.Response.bytes(
      utf8.encode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
    await mountAdmin(
      tester,
      start: '/admin/espacios',
      size: size,
      api: ApiClient(
        'http://api.falsa',
        cliente: MockClient((request) async {
          requests.add(request);
          if (request.method == 'DELETE') {
            final r = await onDeactivate(++attempts);
            deactivated = true;
            return r;
          }
          return switch (request.url.path) {
            '/spaces' => json(
              200,
              '{"spaces": [${deactivated ? spaceTennisJson : '$spaceF5Json, $spaceTennisJson'}]}',
            ),
            '/spaces/catalog' => json(200, catalogJson),
            _ => json(404, '{}'),
          };
        }),
      ),
    );
    return requests;
  }

  testWidgets(
    'while the deactivation is in flight, the cards cannot be tapped',
    (tester) async {
      final response = Completer<http.Response>();
      final requests = await openWith(tester, (_) => response.future);

      await tapSettled(tester, find.bySemanticsLabel('Baja $name'));
      await tester.tap(find.text('CONFIRMAR BAJA'));
      // The dialog finishes closing; the request is still unanswered.
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.bySemanticsLabel('Dando de baja $name'), findsOneWidget);
      await tester.tap(find.text('Baja').first);
      await tester.tap(find.text('ALTA ESPACIO'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('¿Dar de baja el espacio?'), findsNothing);
      expect(find.text('Nuevo espacio'), findsNothing);

      response.complete(http.Response('', 204));
      await tester.pumpAndSettle();
      expect(requests.where((p) => p.method == 'DELETE'), hasLength(1));
      expect(
        find.text('El espacio fue dado de baja correctamente'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'if the interrupted request deactivated it, the retry reports success',
    (tester) async {
      await openWith(tester, (attempt) async {
        if (attempt == 1) throw const SocketException('connection dropped');
        return http.Response('', 404);
      });

      await tapSettled(tester, find.bySemanticsLabel('Baja $name'));
      await tapSettled(tester, find.text('CONFIRMAR BAJA'));
      expect(find.text('Error de conexión'), findsOneWidget);
      await tapSettled(tester, find.text('REINTENTAR'));

      expect(find.text('Esto cambió mientras tanto'), findsNothing);
      expect(
        find.text('El espacio fue dado de baja correctamente'),
        findsOneWidget,
      );
      expect(find.text(name), findsNothing);
    },
  );

  testWidgets('with text at 200 % on a small phone nothing is cut off', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await open(tester, size: const Size(360, 800));
    expect(tester.takeException(), isNull);
  });
}
