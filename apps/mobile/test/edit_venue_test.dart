import 'dart:convert';

import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/admin.dart';

void main() {
  Future<List<http.Request>> open(
    WidgetTester tester, {
    List<(int, String)> onSave = const [],
    Size size = const Size(393, 852),
  }) async {
    final requests = <http.Request>[];
    final responses = [...onSave];
    await mountAdmin(
      tester,
      size: size,
      api: ApiClient(
        'http://api.falsa',
        client: MockClient((request) async {
          requests.add(request);
          final (status, body) = switch ((request.method, request.url.path)) {
            ('PUT', '/venues/00000000-0000-7000-8000-000000000001') =>
              responses.isEmpty ? (200, venueMoronJson) : responses.removeAt(0),
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
    await tester.tap(find.bySemanticsLabel('Editar sede Sede Morón'));
    await tester.pumpAndSettle();
    return requests;
  }

  Future<void> typeInto(WidgetTester tester, String field, String text) async {
    await tester.enterText(
      find.descendant(
        of: find.bySemanticsLabel(field),
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

  Map<String, Object?> bodyOf(http.Request request) =>
      switch (jsonDecode(request.body)) {
        final Map<String, Object?> data => data,
        _ => const {},
      };

  testWidgets('opens with the venue data loaded', (tester) async {
    await open(tester);

    expect(find.text('Editar sede'), findsOneWidget);
    expect(find.text('Sede Morón'), findsWidgets);
    expect(find.text('Av. Rivadavia 19850'), findsOneWidget);
    expect(find.text('09:00'), findsOneWidget);
    expect(find.text('00:00'), findsOneWidget);
    expect(find.text('Lunes a sábado'), findsOneWidget);
  });

  testWidgets('saves the new data, notifies and returns to the list', (
    tester,
  ) async {
    final requests = await open(tester);
    await typeInto(tester, 'Dirección', 'Av. Rivadavia 20000');

    await tapText(tester, 'GUARDAR CAMBIOS');

    final put = requests.singleWhere((p) => p.method == 'PUT');
    expect(bodyOf(put), {
      'name': 'Sede Morón',
      'address': 'Av. Rivadavia 20000',
      'opens_at': '09:00',
      'closes_at': '00:00',
      'open_days': [1, 2, 3, 4, 5, 6],
      'confirm': false,
    });
    expect(find.text('Los cambios se guardaron correctamente'), findsOneWidget);
    expect(find.text('AGREGAR SEDE'), findsOneWidget);
  });

  testWidgets(
    'with an empty required field, the notice shows and «GUARDAR CAMBIOS» can be tapped but sends nothing',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final requests = await open(tester);

      await typeInto(tester, 'Nombre de la sede', '');

      expect(find.text('El nombre es obligatorio'), findsOneWidget);
      final button = find.bySemanticsLabel('GUARDAR CAMBIOS');
      expect(tester.getSemantics(button).flagsCollection.isEnabled, isTrue);
      await tapText(tester, 'GUARDAR CAMBIOS');
      expect(find.text('El nombre es obligatorio'), findsOneWidget);
      expect(requests.where((p) => p.method == 'PUT'), isEmpty);
      semantics.dispose();
    },
  );

  testWidgets(
    'with bookings outside it asks to confirm and «GUARDAR IGUAL» confirms',
    (tester) async {
      final requests = await open(
        tester,
        onSave: [(409, '{"bookings_outside": 3}')],
      );
      await choose(tester, 'Horario de cierre', '22:00');

      await tapText(tester, 'GUARDAR CAMBIOS');

      expect(find.text('¿Guardar el horario nuevo?'), findsOneWidget);
      expect(
        find.text(
          '3 reservas futuras de Sede Morón terminan después de las 22:00. Si '
          'guardás, se mantienen en su horario original: el cambio rige para las '
          'reservas nuevas.',
        ),
        findsOneWidget,
      );
      await tapText(tester, 'GUARDAR IGUAL');

      final puts = requests.where((p) => p.method == 'PUT').toList();
      expect(puts.map((p) => bodyOf(p)['confirm']), [false, true]);
      expect(
        find.text('Los cambios se guardaron correctamente'),
        findsOneWidget,
      );
    },
  );

  testWidgets('with several reasons, the notice talks about the new hours', (
    tester,
  ) async {
    await open(tester, onSave: [(409, '{"bookings_outside": 1}')]);
    await choose(tester, 'Horario de apertura', '10:00');
    await choose(tester, 'Días que abre', 'Lunes a viernes');

    await tapText(tester, 'GUARDAR CAMBIOS');

    expect(
      find.textContaining(
        '1 reserva futura de Sede Morón queda fuera del horario nuevo. Si '
        'guardás, se mantiene',
      ),
      findsOneWidget,
    );
    await tapText(tester, 'REVISAR EL HORARIO');
    expect(find.text('Editar sede'), findsOneWidget);
    expect(find.text('10:00'), findsOneWidget);
  });

  testWidgets('a name already in use is flagged in the field', (tester) async {
    await open(
      tester,
      onSave: [
        (409, '{"errors": {"name": "Ya existe una sede con ese nombre"}}'),
      ],
    );
    await typeInto(tester, 'Nombre de la sede', 'Sede Castelar');

    await tapText(tester, 'GUARDAR CAMBIOS');

    expect(find.text('Ya existe una sede con ese nombre'), findsOneWidget);
  });

  testWidgets(
    'the venue deactivated in another session: the notice and the list',
    (tester) async {
      await open(tester, onSave: [(404, '')]);

      await tapText(tester, 'GUARDAR CAMBIOS');
      expect(find.text('Esto cambió mientras tanto'), findsOneWidget);
      await tapText(tester, 'VER LO ACTUALIZADO');

      expect(find.text('AGREGAR SEDE'), findsOneWidget);
    },
  );

  testWidgets('the server fails: the notice shows and what was typed stays', (
    tester,
  ) async {
    await open(tester, onSave: [(500, '{}')]);
    await typeInto(tester, 'Dirección', 'Av. Rivadavia 20000');

    await tapText(tester, 'GUARDAR CAMBIOS');
    expect(find.text('Error del servidor'), findsOneWidget);
    await tapText(tester, 'ACEPTAR');

    expect(find.text('Av. Rivadavia 20000'), findsOneWidget);
    expect(find.text('Editar sede'), findsOneWidget);
  });

  testWidgets('«DAR DE BAJA LA SEDE» opens the confirmation with the venue', (
    tester,
  ) async {
    await open(tester);

    await tapText(tester, 'DAR DE BAJA LA SEDE');

    expect(find.text('¿Dar de baja la sede?'), findsOneWidget);
    expect(
      find.text(
        'Sede Morón · Av. Rivadavia 19850. Sus espacios deportivos dejan de '
        'estar disponibles.',
      ),
      findsOneWidget,
    );
    await tapText(tester, 'CANCELAR');
    expect(find.text('Editar sede'), findsOneWidget);
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
