import 'dart:async';
import 'dart:io';

import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:clubnahuelmosse/features/users/data/registration_service.dart';
import 'package:clubnahuelmosse/features/users/presentation/registration_screen.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/mount.dart';

void main() {
  Future<void> fillIn(WidgetTester tester) async {
    for (final (field, value) in [
      ('Nombre', 'Ana'),
      ('Apellido', 'Pérez'),
      ('DNI', '12345678'),
      ('Fecha de nacimiento', '14032000'),
      ('Correo electrónico', 'ana@correo.com'),
      ('Contraseña', 'ClubNahuel1'),
    ]) {
      await tester.enterText(find.bySemanticsLabel(field), value);
    }
    await tester.pump();
  }

  Future<void> tapOn(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder, warnIfMissed: false);
  }

  bool buttonEnabled(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed != null;

  testWidgets('retrying after an outage does not send parallel requests', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var requests = 0;
    final second = Completer<http.Response>();
    final api = ApiClient(
      'http://api.falsa',
      client: MockClient((_) {
        requests++;
        if (requests == 1) throw const SocketException('sin red');
        return second.future;
      }),
    );
    await mountScreen(
      tester,
      RegistrationScreen(registration: RegistrationService(api)),
      theme: darkTheme,
    );
    await fillIn(tester);

    await tapOn(tester, find.text('CREAR CUENTA'));
    await tester.pumpAndSettle();
    expect(find.text('Error de conexión'), findsOneWidget);

    await tester.tap(find.text('REINTENTAR'));
    await tester.pump();
    await tester.pump();
    expect(requests, 2);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tapOn(
      tester,
      find.ancestor(
        of: find.byType(CircularProgressIndicator),
        matching: find.byType(FilledButton),
      ),
    );
    await tester.pump();
    expect(requests, 2);

    second.complete(
      http.Response('{"errors": {"dni": "El DNI tiene 7 u 8 numeros"}}', 422),
    );
    await tester.pumpAndSettle();
    expect(find.text('El DNI tiene 7 u 8 numeros'), findsOneWidget);
    expect(requests, 2);
    semantics.dispose();
  });

  testWidgets('the repeated user notice goes away when the email is fixed', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await mountScreen(
      tester,
      RegistrationScreen(
        registration: RegistrationService(
          fakeApi(
            status: 409,
            body:
                '{"message": "El usuario ya está registrado. Modificá el correo o el DNI.",'
                ' "campos": ["email"],'
                ' "errors": {"email": "Este correo ya está registrado"}}',
          ),
        ),
      ),
      theme: darkTheme,
    );
    await fillIn(tester);
    await tapOn(tester, find.text('CREAR CUENTA'));
    await tester.pumpAndSettle();
    expect(find.text('Este correo ya está registrado'), findsOneWidget);
    expect(
      find.text('El usuario ya está registrado. Modificá el correo o el DNI.'),
      findsOneWidget,
    );

    await tester.enterText(
      find.bySemanticsLabel('Correo electrónico'),
      'otra@correo.com',
    );
    await tester.pump();
    expect(find.text('Este correo ya está registrado'), findsNothing);
    expect(
      find.text('El usuario ya está registrado. Modificá el correo o el DNI.'),
      findsNothing,
    );
    expect(buttonEnabled(tester), isTrue);
    semantics.dispose();
  });

  testWidgets('an unexpected response shows the server error', (tester) async {
    final semantics = tester.ensureSemantics();
    await mountScreen(
      tester,
      RegistrationScreen(
        registration: RegistrationService(
          fakeApi(status: 404, body: '<html>no</html>'),
        ),
      ),
      theme: darkTheme,
    );
    await fillIn(tester);
    await tapOn(tester, find.text('CREAR CUENTA'));
    await tester.pumpAndSettle();
    expect(find.text('Error del servidor'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets(
    'an invalid value that was typed is flagged on leaving the field',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await mountScreen(
        tester,
        RegistrationScreen(registration: RegistrationService(fakeApi())),
        theme: darkTheme,
      );

      await tester.enterText(
        find.bySemanticsLabel('Correo electrónico'),
        'ana',
      );
      await tester.tap(find.bySemanticsLabel('Nombre'));
      await tester.pumpAndSettle();

      expect(find.text('Revisá el formato del correo'), findsOneWidget);
      semantics.dispose();
    },
  );
}
