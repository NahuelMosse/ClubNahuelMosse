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
  Future<List<http.Request>> open(
    WidgetTester tester, {
    (int, String) onDeactivate = (204, ''),
    Size size = const Size(393, 852),
  }) async {
    final requests = <http.Request>[];
    var deactivated = false;
    await mountAdmin(
      tester,
      size: size,
      api: ApiClient(
        'http://api.falsa',
        cliente: MockClient((request) async {
          requests.add(request);
          final (status, body) = switch ((request.method, request.url.path)) {
            ('DELETE', '/venues/00000000-0000-7000-8000-000000000001') => () {
              deactivated = onDeactivate.$1 == 204 || onDeactivate.$1 == 404;
              return onDeactivate;
            }(),
            ('GET', '/venues') => (
              200,
              '{"venues": [${deactivated ? venueHaedoJson : '$venueHaedoJson, $venueMoronJson'}]}',
            ),
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

  Future<void> fromEdit(WidgetTester tester) async {
    await tapSettled(tester, find.bySemanticsLabel('Editar sede Sede Morón'));
    await tapSettled(tester, find.text('DAR DE BAJA LA SEDE'));
  }

  testWidgets(
    'from the edit screen: confirms, notifies and returns to the list without the venue',
    (tester) async {
      final requests = await open(tester);
      await fromEdit(tester);

      expect(find.text('¿Dar de baja la sede?'), findsOneWidget);
      await tapSettled(tester, find.text('DAR DE BAJA'));

      expect(requests.where((p) => p.method == 'DELETE'), hasLength(1));
      expect(
        find.text('La sede fue dada de baja correctamente'),
        findsOneWidget,
      );
      expect(find.text('Sede Morón'), findsNothing);
      expect(find.text('Sede Haedo'), findsOneWidget);
    },
  );

  testWidgets('from the list card, without going through the edit screen', (
    tester,
  ) async {
    final requests = await open(tester);

    await tapSettled(tester, find.bySemanticsLabel('Dar de baja Sede Morón'));
    expect(
      find.text(
        'Sede Morón · Av. Rivadavia 19850. Sus espacios deportivos dejan de '
        'estar disponibles.',
      ),
      findsOneWidget,
    );
    await tapSettled(tester, find.text('DAR DE BAJA'));

    expect(requests.where((p) => p.method == 'DELETE'), hasLength(1));
    expect(find.text('Sede Morón'), findsNothing);
  });

  testWidgets('CANCELAR sends nothing', (tester) async {
    final requests = await open(tester);
    await fromEdit(tester);

    await tapSettled(tester, find.text('CANCELAR'));

    expect(requests.where((p) => p.method == 'DELETE'), isEmpty);
    expect(find.text('Editar sede'), findsOneWidget);
  });

  testWidgets(
    'with pending bookings: the notice shows and it stays on the edit screen',
    (tester) async {
      await open(
        tester,
        onDeactivate: (
          409,
          '{"errors": {"venue": "No se puede dar de baja la sede porque posee '
              'reservas futuras asociadas."}}',
        ),
      );
      await fromEdit(tester);
      await tapSettled(tester, find.text('DAR DE BAJA'));

      expect(find.text('No se puede dar de baja la sede'), findsOneWidget);
      await tapSettled(tester, find.text('ACEPTAR'));
      expect(find.text('Editar sede'), findsOneWidget);
    },
  );

  testWidgets('already deactivated in another session: the notice and the list', (
    tester,
  ) async {
    await open(tester, onDeactivate: (404, ''));
    await fromEdit(tester);
    await tapSettled(tester, find.text('DAR DE BAJA'));

    expect(find.text('Esto cambió mientras tanto'), findsOneWidget);
    await tapSettled(tester, find.text('VER LO ACTUALIZADO'));
    expect(find.text('AGREGAR SEDE'), findsOneWidget);
    expect(find.text('Sede Morón'), findsNothing);
  });

  testWidgets(
    'the server fails: the notice shows and it stays on the edit screen',
    (tester) async {
      await open(tester, onDeactivate: (500, '{}'));
      await fromEdit(tester);
      await tapSettled(tester, find.text('DAR DE BAJA'));

      expect(find.text('Error del servidor'), findsOneWidget);
      await tapSettled(tester, find.text('ACEPTAR'));
      expect(find.text('Editar sede'), findsOneWidget);
    },
  );

  testWidgets(
    'the card with text at 200 % on a small phone stacks the buttons',
    (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await open(tester, size: const Size(360, 800));
      expect(tester.takeException(), isNull);
      final editRect = tester.getRect(find.text('Editar sede').first);
      final deactivateRect = tester.getRect(find.text('Dar de baja').first);
      expect(deactivateRect.top, greaterThan(editRect.bottom));
    },
  );

  Future<List<http.Request>> openWith(
    WidgetTester tester,
    Future<http.Response> Function(http.Request request, int attempt)
    onDeactivate,
  ) async {
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
      api: ApiClient(
        'http://api.falsa',
        cliente: MockClient((request) async {
          requests.add(request);
          if (request.method == 'DELETE') {
            final r = await onDeactivate(request, ++attempts);
            deactivated = true;
            return r;
          }
          if (request.url.path == '/venues') {
            return json(
              200,
              '{"venues": [${deactivated ? venueHaedoJson : '$venueHaedoJson, $venueMoronJson'}]}',
            );
          }
          return json(404, '{}');
        }),
      ),
    );
    return requests;
  }

  testWidgets('while the deactivation is in flight, the cards cannot be tapped', (
    tester,
  ) async {
    final response = Completer<http.Response>();
    final requests = await openWith(tester, (_, _) => response.future);

    await tapSettled(tester, find.bySemanticsLabel('Dar de baja Sede Morón'));
    await tester.tap(find.text('DAR DE BAJA'));
    // The dialog finishes closing; the request is still unanswered.
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.bySemanticsLabel('Dando de baja Sede Morón'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Dar de baja Sede Haedo'));
    await tester.tap(find.bySemanticsLabel('Editar sede Sede Haedo'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('¿Dar de baja la sede?'), findsNothing);
    expect(find.bySemanticsLabel('Nombre de la sede'), findsNothing);

    response.complete(http.Response('', 204));
    await tester.pumpAndSettle();
    expect(requests.where((p) => p.method == 'DELETE'), hasLength(1));
    expect(find.text('La sede fue dada de baja correctamente'), findsOneWidget);
    expect(find.text('Sede Morón'), findsNothing);
  });

  testWidgets(
    'if the interrupted request deactivated it, the retry reports success',
    (tester) async {
      await openWith(tester, (_, attempt) async {
        if (attempt == 1) throw const SocketException('connection dropped');
        return http.Response('', 404);
      });

      await tapSettled(tester, find.bySemanticsLabel('Dar de baja Sede Morón'));
      await tapSettled(tester, find.text('DAR DE BAJA'));
      expect(find.text('Error de conexión'), findsOneWidget);
      await tapSettled(tester, find.text('REINTENTAR'));

      expect(find.text('Esto cambió mientras tanto'), findsNothing);
      expect(
        find.text('La sede fue dada de baja correctamente'),
        findsOneWidget,
      );
      expect(find.text('Sede Morón'), findsNothing);
    },
  );

  testWidgets('with text at 130 % the card buttons stack', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await open(tester, size: const Size(360, 800));
    expect(tester.takeException(), isNull);
    final editRect = tester.getRect(find.text('Editar sede').first);
    final deactivateRect = tester.getRect(find.text('Dar de baja').first);
    expect(deactivateRect.top, greaterThan(editRect.bottom));
  });
}
