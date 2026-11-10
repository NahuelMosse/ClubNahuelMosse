import 'package:clubnahuelmosse/features/session/data/session_repository.dart';
import 'package:clubnahuelmosse/features/session/presentation/session.dart';
import 'package:clubnahuelmosse/features/users/presentation/change_password_screen.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'support/mount.dart';

void main() {
  setUpAll(loadFonts);

  late FakeCredentials credentials;
  late List<http.Request> requests;

  Future<Session> sessionWith((int, String) change) async {
    credentials = FakeCredentials();
    requests = [];
    final session = Session(
      repository: SessionRepository(
        credentials: credentials,
        api: apiRoutes({
          'GET /me': (200, profileJson()),
          'PUT /me/password': change,
        }, requests: requests),
      ),
    );
    await session.signIn('nahuel@correo.com', 'ClubNahuel1');
    return session;
  }

  Future<void> mountChangeScreen(WidgetTester tester, Session session) =>
      mountScreen(
        tester,
        ChangePasswordScreen(session: session),
        theme: darkTheme,
      );

  Future<void> fill(
    WidgetTester tester, {
    String current = 'ClubNahuel1',
    String next = 'ClubNahuel2',
    String? repeated,
  }) async {
    await tester.enterText(find.bySemanticsLabel('Contraseña actual'), current);
    await tester.enterText(find.bySemanticsLabel('Contraseña nueva'), next);
    await tester.enterText(
      find.bySemanticsLabel('Repetir contraseña'),
      repeated ?? next,
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
  }

  bool enabled(WidgetTester tester) =>
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'GUARDAR CONTRASEÑA'),
          )
          .onPressed !=
      null;

  testWidgets('starts empty and with the button disabled', (tester) async {
    final semantics = tester.ensureSemantics();
    await mountChangeScreen(tester, await sessionWith((204, '')));
    expect(enabled(tester), isFalse);
    expect(find.text('Al menos 8 caracteres'), findsNothing);
    semantics.dispose();
  });

  testWidgets('shows the rules while any is missing', (tester) async {
    final semantics = tester.ensureSemantics();
    await mountChangeScreen(tester, await sessionWith((204, '')));
    await tester.enterText(find.bySemanticsLabel('Contraseña nueva'), 'club');
    await tester.pump();
    expect(
      find.bySemanticsLabel('Al menos 8 caracteres: falta'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Una letra mayúscula: falta'), findsOneWidget);
    expect(find.bySemanticsLabel('Al menos un número: falta'), findsOneWidget);

    await tester.enterText(
      find.bySemanticsLabel('Contraseña nueva'),
      'ClubNahuel',
    );
    await tester.pump();
    expect(
      find.bySemanticsLabel('Una letra mayúscula: cumplida'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Al menos un número: falta'), findsOneWidget);

    await tester.enterText(
      find.bySemanticsLabel('Contraseña nueva'),
      'ClubNahuel2',
    );
    await tester.pump();
    expect(find.text('Al menos un número'), findsNothing);
    semantics.dispose();
  });

  testWidgets('a different repetition cannot be saved and sends nothing', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await mountChangeScreen(tester, await sessionWith((204, '')));
    await fill(tester, repeated: 'ClubNahuel3');
    expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
    expect(enabled(tester), isFalse);
    expect(requests.where((p) => p.method == 'PUT'), isEmpty);
    semantics.dispose();
  });

  testWidgets('saves, signs in again with the new one and shows success', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await mountChangeScreen(tester, await sessionWith((204, '')));
    await fill(tester);

    await tester.tap(find.text('GUARDAR CONTRASEÑA'));
    await tester.pumpAndSettle();

    expect(find.text('Contraseña actualizada'), findsOneWidget);
    expect(credentials.attempts.last, ('nahuel@correo.com', 'ClubNahuel2'));
    final put = requests.singleWhere((p) => p.method == 'PUT');
    expect(put.headers['authorization'], 'Bearer token-falso');
    expect(
      put.body,
      '{"current_password":"ClubNahuel1","new_password":"ClubNahuel2"}',
    );
    semantics.dispose();
  });

  testWidgets('a wrong current password marks the field until corrected', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await mountChangeScreen(
      tester,
      await sessionWith((
        422,
        '{"errors": {"current_password": "La contraseña actual no coincide"}}',
      )),
    );
    await fill(tester, current: 'OtraClave9');
    await tester.tap(find.text('GUARDAR CONTRASEÑA'));
    await tester.pumpAndSettle();

    expect(find.text('La contraseña actual no coincide'), findsOneWidget);
    expect(enabled(tester), isFalse);

    await tester.enterText(find.bySemanticsLabel('Contraseña actual'), 'Otra');
    await tester.pump();
    expect(find.text('La contraseña actual no coincide'), findsNothing);
    expect(enabled(tester), isTrue);
    semantics.dispose();
  });

  testWidgets('with an expired session it warns and signs out', (tester) async {
    final semantics = tester.ensureSemantics();
    await mountChangeScreen(tester, await sessionWith((401, '{}')));
    await fill(tester);
    await tester.tap(find.text('GUARDAR CONTRASEÑA'));
    await tester.pumpAndSettle();

    expect(find.text('Tu sesión expiró'), findsOneWidget);
    await tester.tap(find.text('IR AL INICIO DE SESIÓN'));
    await tester.pumpAndSettle();
    expect(credentials.signOuts, 1);
    semantics.dispose();
  });

  testWidgets('too many attempts show up as a server error', (tester) async {
    // Verifies CU-04-SUP-03.
    final semantics = tester.ensureSemantics();
    await mountChangeScreen(tester, await sessionWith((429, '')));
    await fill(tester);
    await tester.tap(find.text('GUARDAR CONTRASEÑA'));
    await tester.pumpAndSettle();
    expect(find.text('Error del servidor'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('if Firebase no longer refreshes the session, it warns it expired', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final session = await sessionWith((204, ''));
    credentials.tokenFails = true;
    await mountChangeScreen(tester, session);
    await fill(tester);
    await tester.tap(find.text('GUARDAR CONTRASEÑA'));
    await tester.pumpAndSettle();

    expect(find.text('Tu sesión expiró'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('tapping the field without typing does not clear the server error', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await mountChangeScreen(
      tester,
      await sessionWith((
        422,
        '{"errors": {"current_password": "La contraseña actual no coincide"}}',
      )),
    );
    await fill(tester, current: 'OtraClave9');
    await tester.tap(find.text('GUARDAR CONTRASEÑA'));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Contraseña actual'));
    await tester.pumpAndSettle();
    expect(find.text('La contraseña actual no coincide'), findsOneWidget);
    expect(enabled(tester), isFalse);
    semantics.dispose();
  });
}
