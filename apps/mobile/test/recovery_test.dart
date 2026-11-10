import 'package:clubnahuelmosse/app.dart';
import 'package:clubnahuelmosse/common/appearance.dart';
import 'package:clubnahuelmosse/features/session/data/password_recovery.dart';
import 'package:clubnahuelmosse/features/session/presentation/forgot_password_screen.dart';
import 'package:clubnahuelmosse/features/session/presentation/new_password_screen.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import 'support/mount.dart';

void main() {
  setUpAll(loadFonts);

  late List<http.Request> requests;

  /// Mounts [screen] inside minimal routes, to see where each button leads.
  Future<void> mountInRoutes(WidgetTester tester, Widget screen) async {
    final routes = GoRouter(
      initialLocation: '/pantalla',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Text('LOGIN')),
        GoRoute(path: '/pantalla', builder: (_, _) => screen),
        GoRoute(
          path: '/recuperar-contrasena',
          builder: (_, _) => const Text('PEDIR'),
        ),
      ],
    );
    addTearDown(routes.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: darkTheme, routerConfig: routes),
    );
    await tester.pumpAndSettle();
  }

  PasswordRecovery recoveryWith(Map<String, (int, String)> responses) {
    requests = [];
    return PasswordRecovery(apiRoutes(responses, requests: requests));
  }

  bool isEnabled(WidgetTester tester, String button) =>
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, button))
          .onPressed !=
      null;

  group('request the link', () {
    testWidgets(
      'a misspelled email cannot be sent and is flagged on leaving the field',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await mountInRoutes(
          tester,
          ForgotPasswordScreen(
            recovery: recoveryWith({'POST /password-recovery': (202, '')}),
          ),
        );
        await tester.enterText(
          find.bySemanticsLabel('Correo electrónico'),
          'nmosse@unimoron',
        );
        await tester.pump();
        expect(find.text('Revisá el formato del correo'), findsNothing);
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        expect(find.text('Revisá el formato del correo'), findsOneWidget);
        expect(isEnabled(tester, 'ENVIAR ENLACE'), isFalse);
        expect(requests, isEmpty);
        semantics.dispose();
      },
    );

    testWidgets('sends the normalized email, shows the notice and resends', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await mountInRoutes(
        tester,
        ForgotPasswordScreen(
          recovery: recoveryWith({'POST /password-recovery': (202, '')}),
        ),
      );
      await tester.enterText(
        find.bySemanticsLabel('Correo electrónico'),
        ' Nahuel@Correo.com ',
      );
      await tester.pump();
      await tester.tap(find.text('ENVIAR ENLACE'));
      await tester.pumpAndSettle();

      expect(find.text('Revisá tu correo'), findsOneWidget);
      expect(find.text(linkSentNotice), findsOneWidget);
      expect(requests.single.body, '{"email":"nahuel@correo.com"}');

      await tester.tap(find.text('Reenviar el correo'));
      await tester.pumpAndSettle();
      expect(requests, hasLength(2));

      await tester.tap(find.text('VOLVER AL INICIO DE SESIÓN'));
      await tester.pumpAndSettle();
      expect(find.text('LOGIN'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('if the server fails it does not show the sent notice', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await mountInRoutes(
        tester,
        ForgotPasswordScreen(
          recovery: recoveryWith({'POST /password-recovery': (500, '')}),
        ),
      );
      await tester.enterText(
        find.bySemanticsLabel('Correo electrónico'),
        'nahuel@correo.com',
      );
      await tester.pump();
      await tester.tap(find.text('ENVIAR ENLACE'));
      await tester.pumpAndSettle();
      expect(find.text('Error del servidor'), findsOneWidget);
      expect(find.text('Revisá tu correo'), findsNothing);
      semantics.dispose();
    });
  });

  group('create the new password', () {
    Widget screenWith(Map<String, (int, String)> responses) =>
        NewPasswordScreen(
          recovery: recoveryWith(responses),
          session: FakeSession(null),
          code: 'abc',
        );

    testWidgets('a link that no longer works leads to requesting another', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await mountInRoutes(
        tester,
        screenWith({'POST /password-recovery/check': (410, '')}),
      );
      expect(find.text('El enlace no es válido'), findsOneWidget);
      await tester.tap(find.text('PEDIR UN ENLACE NUEVO'));
      await tester.pumpAndSettle();
      expect(find.text('PEDIR'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('without a code it does not even query the API', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await mountInRoutes(
        tester,
        NewPasswordScreen(
          recovery: recoveryWith({}),
          session: FakeSession(null),
          code: '',
        ),
      );
      expect(find.text('El enlace no es válido'), findsOneWidget);
      expect(requests, isEmpty);
      semantics.dispose();
    });

    testWidgets('saves with a valid link and returns to the login', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await mountInRoutes(
        tester,
        screenWith({
          'POST /password-recovery/check': (204, ''),
          'PUT /password-recovery': (204, ''),
        }),
      );
      expect(isEnabled(tester, 'GUARDAR CONTRASEÑA'), isFalse);
      await tester.enterText(
        find.bySemanticsLabel('Contraseña nueva'),
        'ClubNahuel2',
      );
      await tester.enterText(
        find.bySemanticsLabel('Repetir contraseña'),
        'ClubNahuel2',
      );
      await tester.pump();
      await tester.tap(find.text('GUARDAR CONTRASEÑA'));
      await tester.pumpAndSettle();

      expect(find.text('Contraseña actualizada'), findsOneWidget);
      expect(requests.last.body, '{"code":"abc","new_password":"ClubNahuel2"}');
      await tester.tap(find.text('VOLVER AL INICIO DE SESIÓN'));
      await tester.pumpAndSettle();
      expect(find.text('LOGIN'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('if the link was used while typing, it says so on save', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await mountInRoutes(
        tester,
        screenWith({
          'POST /password-recovery/check': (204, ''),
          'PUT /password-recovery': (410, ''),
        }),
      );
      await tester.enterText(
        find.bySemanticsLabel('Contraseña nueva'),
        'ClubNahuel2',
      );
      await tester.enterText(
        find.bySemanticsLabel('Repetir contraseña'),
        'ClubNahuel2',
      );
      await tester.pump();
      await tester.tap(find.text('GUARDAR CONTRASEÑA'));
      await tester.pumpAndSettle();
      expect(find.text('El enlace no es válido'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('a mismatched repeat does not allow saving', (tester) async {
      final semantics = tester.ensureSemantics();
      await mountInRoutes(
        tester,
        screenWith({'POST /password-recovery/check': (204, '')}),
      );
      await tester.enterText(
        find.bySemanticsLabel('Contraseña nueva'),
        'ClubNahuel2',
      );
      await tester.enterText(
        find.bySemanticsLabel('Repetir contraseña'),
        'ClubNahuel3',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
      expect(isEnabled(tester, 'GUARDAR CONTRASEÑA'), isFalse);
      semantics.dispose();
    });
  });

  group('open the app from the link', () {
    Future<void> open(WidgetTester tester, String route) async {
      await tester.binding.handlePushRoute(route);
      await tester.pumpAndSettle();
    }

    testWidgets('a new link with the screen open is checked again', (
      tester,
    ) async {
      final requests = <http.Request>[];
      final api = apiRoutes({
        'POST /password-recovery/check': (410, ''),
      }, requests: requests);
      await tester.pumpWidget(
        App(
          api: api,
          session: FakeSession(null),
          appearance: Appearance.inMemory(),
          initialLocation: '/recuperar?codigo=viejo',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('El enlace no es válido'), findsOneWidget);

      await open(tester, '/recuperar?codigo=nuevo');
      expect(requests.map((p) => p.body), [
        '{"code":"viejo"}',
        '{"code":"nuevo"}',
      ]);
    });

    testWidgets(
      'with the session open, finishing closes it and goes to login',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final session = FakeSession(userProfile);
        await tester.pumpWidget(
          App(
            api: apiRoutes({
              'POST /password-recovery/check': (204, ''),
              'PUT /password-recovery': (204, ''),
            }),
            session: session,
            appearance: Appearance.inMemory(),
            initialLocation: '/recuperar?codigo=abc',
          ),
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.bySemanticsLabel('Contraseña nueva'),
          'ClubNahuel2',
        );
        await tester.enterText(
          find.bySemanticsLabel('Repetir contraseña'),
          'ClubNahuel2',
        );
        await tester.pump();
        await tester.tap(find.text('GUARDAR CONTRASEÑA'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('VOLVER AL INICIO DE SESIÓN'));
        await tester.pumpAndSettle();

        expect(session.closes, 1);
        expect(find.text('INICIAR SESIÓN'), findsOneWidget);
        semantics.dispose();
      },
    );
  });
}
