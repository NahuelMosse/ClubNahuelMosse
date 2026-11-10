import 'dart:convert';

import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/admin.dart';

void main() {
  const edited =
      '{"id": "00000000-0000-7000-8000-000000000009", "name": "Moron_Rivadavia_19850_Futbol_F5_1", "venue_id": "00000000-0000-7000-8000-000000000001", '
      '"venue": "Sede Morón", "sport": "Futbol", "kind": "F5", "number": 1, '
      '"covered": false, "lit": true, "price_per_hour": 45000}';

  Future<List<http.Request>> open(
    WidgetTester tester, {
    (int, String) onSave = (200, edited),
    Size size = const Size(393, 852),
  }) async {
    final requests = <http.Request>[];
    var saved = false;
    await mountAdmin(
      tester,
      start: '/admin/espacios',
      size: size,
      api: ApiClient(
        'http://api.falsa',
        cliente: MockClient((request) async {
          requests.add(request);
          final (status, body) = switch ((request.method, request.url.path)) {
            ('PUT', '/spaces/00000000-0000-7000-8000-000000000009') => () {
              saved = onSave.$1 == 200;
              return onSave;
            }(),
            ('GET', '/spaces') => (
              200,
              '{"spaces": [${saved ? edited : spaceF5Json}]}',
            ),
            ('GET', '/spaces/catalog') => (200, catalogJson),
            ('GET', '/venues') => (200, '{"venues": [$venueMoronJson]}'),
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
    await tester.tap(
      find.bySemanticsLabel('Editar Moron_Rivadavia_19850_Futbol_F5_1'),
    );
    await tester.pumpAndSettle();
    return requests;
  }

  Future<void> typePrice(WidgetTester tester, String text) async {
    await tester.enterText(
      find.descendant(
        of: find.bySemanticsLabel('Precio por hora'),
        matching: find.byType(EditableText),
      ),
      text,
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.pumpAndSettle();
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  bool enabled(WidgetTester tester, String label) => tester
      .getSemantics(find.bySemanticsLabel(label))
      .flagsCollection
      .isEnabled;

  testWidgets('opens with the space data and what is not editable, disabled', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await open(tester);

    expect(find.text('Editar espacio deportivo'), findsOneWidget);
    expect(find.text('Sede Morón'), findsOneWidget);
    expect(find.text('Fútbol 5'), findsOneWidget);
    expect(find.text('Al aire libre'), findsOneWidget);
    expect(find.text('Iluminada'), findsOneWidget);
    expect(find.textContaining('38.000'), findsOneWidget);
    expect(find.text('Moron_Rivadavia_19850_Futbol_F5_1'), findsOneWidget);
    expect(enabled(tester, 'Sede'), isFalse);
    expect(enabled(tester, 'Deporte'), isFalse);
    expect(enabled(tester, 'Tipo'), isFalse);
    expect(enabled(tester, 'GUARDAR ESPACIO'), isFalse);
    semantics.dispose();
  });

  testWidgets('saves the new price, notifies and returns to the list', (
    tester,
  ) async {
    final requests = await open(tester);
    await typePrice(tester, '45000');

    await tapText(tester, 'GUARDAR ESPACIO');

    final put = requests.singleWhere((p) => p.method == 'PUT');
    // Only what changed.
    expect(jsonDecode(put.body), {'price_per_hour': 45000});
    expect(find.text('Los cambios se guardaron correctamente'), findsOneWidget);
    expect(find.text('ALTA ESPACIO'), findsOneWidget);
    expect(find.textContaining('45.000 por hora'), findsOneWidget);
  });

  testWidgets('an empty or zero price is flagged and cannot be saved', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await open(tester);

    await typePrice(tester, '');
    expect(find.text('Este campo es obligatorio'), findsOneWidget);
    expect(enabled(tester, 'GUARDAR ESPACIO'), isFalse);

    await typePrice(tester, '0');
    expect(
      find.text('Ingresá un precio entre \$ 1 y \$ 9.999.999'),
      findsOneWidget,
    );
    expect(enabled(tester, 'GUARDAR ESPACIO'), isFalse);
    semantics.dispose();
  });

  testWidgets('going back to the previous price leaves nothing to save again', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await open(tester);

    await typePrice(tester, '45000');
    expect(enabled(tester, 'GUARDAR ESPACIO'), isTrue);
    await typePrice(tester, '38000');
    expect(enabled(tester, 'GUARDAR ESPACIO'), isFalse);
    semantics.dispose();
  });

  testWidgets(
    'the space deactivated in another session: the notice and the list',
    (tester) async {
      await open(tester, onSave: (404, ''));
      await typePrice(tester, '45000');

      await tapText(tester, 'GUARDAR ESPACIO');
      expect(find.text('Esto cambió mientras tanto'), findsOneWidget);
      await tapText(tester, 'VER LO ACTUALIZADO');

      expect(find.text('ALTA ESPACIO'), findsOneWidget);
    },
  );

  testWidgets('the server fails: the notice shows and the typed price stays', (
    tester,
  ) async {
    await open(tester, onSave: (500, '{}'));
    await typePrice(tester, '45000');

    await tapText(tester, 'GUARDAR ESPACIO');
    expect(find.text('Error del servidor'), findsOneWidget);
    await tapText(tester, 'ACEPTAR');

    expect(find.textContaining('45.000'), findsOneWidget);
    expect(find.text('Editar espacio deportivo'), findsOneWidget);
  });

  testWidgets('«CANCELAR» returns to the list without sending anything', (
    tester,
  ) async {
    final requests = await open(tester);
    await typePrice(tester, '45000');

    await tapText(tester, 'CANCELAR');

    expect(requests.where((p) => p.method == 'PUT'), isEmpty);
    expect(find.text('ALTA ESPACIO'), findsOneWidget);
  });

  testWidgets('«DAR DE BAJA EL ESPACIO» opens the confirmation', (
    tester,
  ) async {
    await open(tester);

    await tapText(tester, 'DAR DE BAJA EL ESPACIO');

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

  testWidgets('with text at 200 % on a small phone nothing is cut off', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await open(tester, size: const Size(360, 800));
    expect(tester.takeException(), isNull);
  });
}
