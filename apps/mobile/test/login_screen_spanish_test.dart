import 'package:clubnahuelmosse/common/app_language.dart';
import 'package:clubnahuelmosse/l10n/app_localizations.dart';
import 'dart:async';

import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:clubnahuelmosse/common/pending_booking.dart';
import 'package:clubnahuelmosse/features/session/data/session_repository.dart';
import 'package:clubnahuelmosse/features/session/domain/session_exceptions.dart';
import 'package:clubnahuelmosse/features/session/presentation/login_screen.dart';
import 'package:clubnahuelmosse/features/session/presentation/session.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/mount.dart';

void main() {
  setUpAll(loadFonts);

  Future<void> mountLogin(
    WidgetTester tester,
    FakeCredentials credentials, {
    ApiClient? api,
  }) async {
    final session = Session(
      repository: SessionRepository(
        credentials: credentials,
        api: api ?? fakeApi(status: 200, body: profileJson()),
      ),
    );
    final routes = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) =>
              LoginScreen(session: session, pending: PendingBooking()),
        ),
        GoRoute(path: '/inicio', builder: (_, _) => const Text('HOME')),
        GoRoute(path: '/admin', builder: (_, _) => const Text('PANEL')),
        GoRoute(
          path: '/recuperar-contrasena',
          builder: (_, _) => const Text('RECUPERAR'),
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
  }

  Future<void> signIn(
    WidgetTester tester,
    String email,
    String password,
  ) async {
    await tester.enterText(find.bySemanticsLabel('Correo'), email);
    await tester.enterText(find.bySemanticsLabel('Contraseña'), password);
    await tester.tap(find.text('INICIAR SESIÓN'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'with both fields empty it flags both and does not try to sign in',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final credentials = FakeCredentials();
      await mountLogin(tester, credentials);

      await signIn(tester, '   ', '');

      expect(find.text('Completá tu correo electrónico'), findsOneWidget);
      expect(find.text('Completá tu contraseña'), findsOneWidget);
      expect(credentials.attempts, isEmpty);

      // Typing clears the field's error.
      await tester.enterText(find.bySemanticsLabel('Correo'), 'a');
      await tester.pump();
      expect(find.text('Completá tu correo electrónico'), findsNothing);
      expect(find.text('Completá tu contraseña'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets('sends the email without spaces and in lowercase', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final credentials = FakeCredentials();
    await mountLogin(tester, credentials);

    await signIn(tester, '  Nahuel@Correo.COM ', ' Clave 1 ');

    // The password goes as typed: spaces may be part of it.
    expect(credentials.attempts, [('nahuel@correo.com', ' Clave 1 ')]);
    expect(find.text('HOME'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('the admin lands on the panel', (tester) async {
    final semantics = tester.ensureSemantics();
    await mountLogin(
      tester,
      FakeCredentials(),
      api: fakeApi(status: 200, body: profileJson(role: 'admin')),
    );

    await signIn(tester, 'admin@club.com', 'Clave1234');

    expect(find.text('PANEL'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('invalid credentials: generic notice closed with the X', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await mountLogin(
      tester,
      FakeCredentials(
        onSignIn: (_, _) async => throw const InvalidCredentials(),
      ),
    );

    await signIn(tester, 'nahuel@correo.com', 'Mala1234');
    expect(find.text(invalidCredentialsMessage), findsOneWidget);

    await tester.tap(find.byTooltip('Cerrar aviso'));
    await tester.pumpAndSettle();
    expect(find.text(invalidCredentialsMessage), findsNothing);
    semantics.dispose();
  });

  testWidgets(
    'an account without an active profile does not get in and is left signed out',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final credentials = FakeCredentials();
      await mountLogin(
        tester,
        credentials,
        api: fakeApi(status: 401, body: '{"detail": "Sesión inválida"}'),
      );

      await signIn(tester, 'baja@correo.com', 'Clave1234');

      expect(find.text(invalidCredentialsMessage), findsOneWidget);
      expect(credentials.signOuts, 1);
      expect(credentials.hasAccount, isFalse);
      semantics.dispose();
    },
  );

  testWidgets(
    'if the API fails, it warns about the server and signs out of Firebase',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final credentials = FakeCredentials();
      await mountLogin(
        tester,
        credentials,
        api: fakeApi(status: 500, body: 'Internal Server Error'),
      );

      await signIn(tester, 'nahuel@correo.com', 'Clave1234');

      expect(find.text('Error del servidor'), findsOneWidget);
      expect(find.text('REINTENTAR'), findsNothing);
      expect(credentials.hasAccount, isFalse);
      await tester.tap(find.text('ACEPTAR'));
      await tester.pumpAndSettle();
      expect(find.text('INICIAR SESIÓN'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets(
    'without a connection, «REINTENTAR» tries again with the same data',
    (tester) async {
      final semantics = tester.ensureSemantics();
      var shouldFail = true;
      final credentials = FakeCredentials(
        onSignIn: (_, _) async {
          if (shouldFail) throw const SinConexion();
        },
      );
      await mountLogin(tester, credentials);

      await signIn(tester, 'nahuel@correo.com', 'Clave1234');
      expect(find.text('Error de conexión'), findsOneWidget);

      shouldFail = false;
      await tester.tap(find.text('REINTENTAR'));
      await tester.pumpAndSettle();
      expect(credentials.attempts, hasLength(2));
      expect(find.text('HOME'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets('a second tap while signing in does not send another attempt', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final wait = Completer<void>();
    final credentials = FakeCredentials(onSignIn: (_, _) => wait.future);
    await mountLogin(tester, credentials);

    await tester.enterText(find.bySemanticsLabel('Correo'), 'n@correo.com');
    await tester.enterText(find.bySemanticsLabel('Contraseña'), 'Clave1234');
    await tester.tap(find.text('INICIAR SESIÓN'));
    await tester.pump();
    await tester.tap(find.byType(FilledButton), warnIfMissed: false);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(credentials.attempts, hasLength(1));

    wait.complete();
    await tester.pumpAndSettle();
    expect(find.text('HOME'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('«¿Olvidaste tu contraseña?» leads to recovering it', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await mountLogin(tester, FakeCredentials());

    await tester.tap(find.text('¿Olvidaste tu contraseña?'));
    await tester.pumpAndSettle();

    expect(find.text('RECUPERAR'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('the eye shows and hides the password', (tester) async {
    final semantics = tester.ensureSemantics();
    await mountLogin(tester, FakeCredentials());
    bool hidden() => tester
        .widget<TextField>(
          find.descendant(
            of: find.bySemanticsLabel('Contraseña'),
            matching: find.byType(TextField),
          ),
        )
        .obscureText;

    expect(hidden(), isTrue);
    await tester.tap(find.byTooltip('Mostrar contraseña'));
    await tester.pump();
    expect(hidden(), isFalse);
    semantics.dispose();
  });
}
