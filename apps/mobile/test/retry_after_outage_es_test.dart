import 'dart:convert';
import 'dart:io';

import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:clubnahuelmosse/common/app_language.dart';
import 'package:clubnahuelmosse/features/users/data/registration_service.dart';
import 'package:clubnahuelmosse/features/users/presentation/registration_screen.dart';
import 'package:clubnahuelmosse/l10n/app_localizations.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/mount.dart';

/// Answers [responses] in order to each POST to [route] (the last one repeats); a `null` is
/// a network outage. Anything that is not that POST is answered by [rest].
MockClient _withOutage(
  String route,
  List<(int, String)?> responses,
  (int, String) Function(http.Request) rest,
) {
  var n = 0;
  return MockClient((request) async {
    final (int, String) response;
    if (request.url.path == route && request.method == 'POST') {
      final next = responses[n < responses.length ? n : responses.length - 1];
      n++;
      if (next == null) throw const SocketException('sin red');
      response = next;
    } else {
      response = rest(request);
    }
    return http.Response.bytes(
      utf8.encode(response.$2),
      response.$1,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  });
}

void main() {
  setUpAll(loadFonts);

  group('registration', () {
    const alreadyRegistered =
        '{"errors": {"email": "Ese correo ya está registrado"}, '
        '"message": "Ese correo ya está registrado"}';

    Future<void> openRegistration(
      WidgetTester tester,
      List<(int, String)?> responses,
    ) async {
      final routes = GoRouter(
        initialLocation: '/register',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, _) =>
                const Scaffold(body: Text('Iniciar sesión')),
          ),
          GoRoute(
            path: '/register',
            builder: (context, _) => RegistrationScreen(
              registration: RegistrationService(
                ApiClient(
                  'http://api.falsa',
                  client: _withOutage(
                    '/register',
                    responses,
                    (_) => (404, '{}'),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
      addTearDown(routes.dispose);
      tester.view.physicalSize = const Size(393, 852) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp.router(
          theme: darkTheme,
          localeListResolutionCallback: resolveLanguage,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          routerConfig: routes,
        ),
      );
      await tester.pumpAndSettle();
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
      await tester.ensureVisible(find.text('CREAR CUENTA'));
      await tester.pump();
      await tester.tap(find.text('CREAR CUENTA'), warnIfMissed: false);
      await tester.pumpAndSettle();
    }

    testWidgets(
      'a 409 after an outage says the account already exists and offers to sign in',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await openRegistration(tester, [null, (409, alreadyRegistered)]);
        expect(find.text('Error de conexión'), findsOneWidget);

        await tester.tap(find.text('REINTENTAR'));
        await tester.pumpAndSettle();

        expect(find.textContaining('Tu cuenta ya existe'), findsOneWidget);
        expect(find.text('Ese correo ya está registrado'), findsNothing);
        await tester.ensureVisible(find.text('INICIAR SESIÓN'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('INICIAR SESIÓN'));
        await tester.pumpAndSettle();
        expect(find.text('Iniciar sesión'), findsOneWidget);
        semantics.dispose();
      },
    );

    testWidgets('a 409 without an outage still flags the repeated email', (
      tester,
    ) async {
      await openRegistration(tester, [(409, alreadyRegistered)]);

      expect(find.text('Ese correo ya está registrado'), findsWidgets);
      expect(find.textContaining('Tu cuenta ya existe'), findsNothing);
    });
  });
}
