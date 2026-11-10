import 'package:clubnahuelmosse/app.dart';
import 'package:clubnahuelmosse/common/app_language.dart';
import 'package:clubnahuelmosse/common/appearance.dart';
import 'package:clubnahuelmosse/l10n/app_localizations.dart';
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
      initialLocation: '/screen',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Text('LOGIN')),
        GoRoute(path: '/screen', builder: (_, _) => screen),
        GoRoute(
          path: '/password-recovery',
          builder: (_, _) => const Text('PEDIR'),
        ),
      ],
    );
    addTearDown(routes.dispose);
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
  }

  PasswordRecovery recovery(Map<String, (int, String)> responses) {
    requests = [];
    return PasswordRecovery(apiRoutes(responses, requests: requests));
  }

  bool enabled(WidgetTester tester, String button) =>
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, button))
          .onPressed !=
      null;

  group('requesting the link', () {
    testWidgets(
      'with a badly written email it does not let you send and flags it on leaving the field',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await mountInRoutes(
          tester,
          ForgotPasswordScreen(
            recovery: recovery({'POST /password-recovery': (202, '')}),
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
        expect(enabled(tester, 'ENVIAR ENLACE'), isFalse);
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
          recovery: recovery({'POST /password-recovery': (202, '')}),
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
      expect(
        find.text(
          'Si el correo está registrado, te enviamos un enlace para crear una contraseña nueva. El enlace vence en 30 minutos.',
        ),
        findsOneWidget,
      );
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
          recovery: recovery({'POST /password-recovery': (500, '')}),
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

  group('creating the new password', () {
    Widget screen(Map<String, (int, String)> responses) => NewPasswordScreen(
      recovery: recovery(responses),
      session: FakeSession(null),
      code: 'abc',
    );

    testWidgets('a link that no longer works leads to requesting another', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await mountInRoutes(
        tester,
        screen({'POST /password-recovery/check': (410, '')}),
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
          recovery: recovery({}),
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
        screen({
          'POST /password-recovery/check': (204, ''),
          'PUT /password-recovery': (204, ''),
        }),
      );
      expect(enabled(tester, 'GUARDAR CONTRASEÑA'), isFalse);
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

    testWidgets('if the link was used while typing, it says so on saving', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await mountInRoutes(
        tester,
        screen({
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

    testWidgets('a different repetition does not let you save', (tester) async {
      final semantics = tester.ensureSemantics();
      await mountInRoutes(
        tester,
        screen({'POST /password-recovery/check': (204, '')}),
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
      expect(enabled(tester, 'GUARDAR CONTRASEÑA'), isFalse);
      semantics.dispose();
    });
  });

  group('opening the app from the link', () {
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
          initialLocation: '/recover?code=viejo',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('El enlace no es válido'), findsOneWidget);

      await open(tester, '/recover?code=nuevo');
      expect(requests.map((p) => p.body), [
        '{"code":"viejo"}',
        '{"code":"nuevo"}',
      ]);
    });

    testWidgets(
      'with the session open, on finishing it closes it and goes to the login',
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
            initialLocation: '/recover?code=abc',
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
