import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/actions.dart';
import '../support/network.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const current = 'ClubNahuel1';
  const newPassword = 'ClubNahuel2';

  Future<void> goToChange(
    WidgetTester tester,
    String email, {
    String? apiUrl,
  }) async {
    await signInAsUser(tester, email: email, apiUrl: apiUrl);
    await tester.tap(find.bySemanticsLabel('Tu cuenta'));
    await tester.pumpAndSettle();
    await tapText(tester, 'Perfil completo');
    await tapText(tester, 'Cambiar contraseña');
    expect(find.text('Cambiá tu contraseña'), findsOneWidget);
  }

  Future<void> fillIn(
    WidgetTester tester, {
    String currentPassword = current,
    String typedNew = newPassword,
    String? repeated,
  }) async {
    await typeInto(tester, 'Contraseña actual', currentPassword);
    await typeInto(tester, 'Contraseña nueva', typedNew);
    await typeInto(tester, 'Repetir contraseña', repeated ?? typedNew);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
  }

  String? typed(WidgetTester tester, String field) => tester
      .widget<TextField>(
        find.descendant(
          of: find.bySemanticsLabel(field),
          matching: find.byType(TextField),
        ),
      )
      .controller
      ?.text;

  bool saveEnabled(WidgetTester tester) =>
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'GUARDAR CONTRASEÑA'),
          )
          .onPressed !=
      null;

  testWidgets(
    'changes the password, returns to the profile with the session open and the new one works to sign in @CU-04-H01-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final email = 'socio.${unique()}@correo.com';
      await goToChange(tester, email);

      await fillIn(tester);
      expect(saveEnabled(tester), isTrue);
      await tapText(tester, 'GUARDAR CONTRASEÑA');

      // Verifies: it confirms the change and returns to the profile, not to the login.
      await waitUntil(tester, find.text('Contraseña actualizada'));
      await tapText(tester, 'VOLVER AL PERFIL');
      expect(find.text('MIEMBRO ACTIVO'), findsOneWidget);
      expect(find.text('INICIAR SESIÓN'), findsNothing);

      // Verifies: the new password is the one that counts in Firebase.
      expect(await canSignIn(email, newPassword), isTrue);

      // Verifies: this phone's session is still alive on reopening the app.
      await reopenApp(tester);
      expect(find.text('RESERVÁ TU CANCHA'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets(
    'after the change, the previous password no longer works to sign in @CU-04-H01-02',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final email = 'socio.${unique()}@correo.com';
      await goToChange(tester, email);
      await fillIn(tester);
      await tapText(tester, 'GUARDAR CONTRASEÑA');
      await waitUntil(tester, find.text('Contraseña actualizada'));

      // Verifies: the exposed password stops opening the account.
      expect(await canSignIn(email, current), isFalse);
      semantics.dispose();
    },
  );

  testWidgets(
    'mistypes the current password and sees the error without anything changing @CU-04-H02-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final email = 'socio.${unique()}@correo.com';
      await goToChange(tester, email);

      await fillIn(tester, currentPassword: 'OtraClave9');
      await tapText(tester, 'GUARDAR CONTRASEÑA');

      // Verifies: it flags the current password and keeps the rest.
      await waitUntil(tester, find.text('La contraseña actual no coincide'));
      expect(typed(tester, 'Contraseña nueva'), newPassword);
      expect(typed(tester, 'Repetir contraseña'), newPassword);
      expect(find.text('Contraseña actualizada'), findsNothing);

      // Verifies: the password did not change.
      expect(await canSignIn(email, current), isTrue);
      expect(await canSignIn(email, newPassword), isFalse);
      semantics.dispose();
    },
  );

  testWidgets(
    'the new password breaks a rule and the button stays disabled @CU-04-H03-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await goToChange(tester, 'socio.${unique()}@correo.com');

      await fillIn(tester, typedNew: 'ClubNahuel');

      // Verifies: the missing rule is shown and it cannot be saved.
      expect(find.text('Al menos un número'), findsOneWidget);
      expect(saveEnabled(tester), isFalse);
      semantics.dispose();
    },
  );

  testWidgets(
    'the repetition does not match and the button stays disabled @CU-04-H04-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await goToChange(tester, 'socio.${unique()}@correo.com');

      await fillIn(tester, repeated: 'ClubNahuel3');

      // Verifies: it flags the repetition and does not allow saving.
      expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
      expect(saveEnabled(tester), isFalse);
      semantics.dispose();
    },
  );

  testWidgets(
    'offline on saving, it sees the connection error and keeps what was typed @CU-04-H05-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final email = 'socio.${unique()}@correo.com';
      final api = await ProxyApi.open();
      await goToChange(tester, email, apiUrl: api.url);
      await fillIn(tester);

      api.state = ApiState.offline;
      await tapText(tester, 'GUARDAR CONTRASEÑA');

      // Verifies: it warns there is no connection and does not lose what was typed.
      await waitUntil(tester, find.text('Error de conexión'));
      await tapText(tester, 'Volver');
      expect(typed(tester, 'Contraseña actual'), current);
      expect(typed(tester, 'Contraseña nueva'), newPassword);
      expect(await canSignIn(email, current), isTrue);
      semantics.dispose();
    },
  );

  testWidgets(
    'the server fails on saving and the password does not change @CU-04-H06-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final email = 'socio.${unique()}@correo.com';
      final api = await ProxyApi.open();
      await goToChange(tester, email, apiUrl: api.url);
      await fillIn(tester);

      api.state = ApiState.failing;
      await tapText(tester, 'GUARDAR CONTRASEÑA');

      // Verifies: it warns of the server and the password is still the earlier one.
      await waitUntil(tester, find.text('Error del servidor'));
      expect(await canSignIn(email, current), isTrue);
      expect(await canSignIn(email, newPassword), isFalse);
      semantics.dispose();
    },
  );

  testWidgets(
    'with an expired session, the app takes it to the login @CU-04-H07-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final email = 'socio.${unique()}@correo.com';
      await goToChange(tester, email);
      // Another device changes the password: this phone's session is left expired.
      await changeFromAnotherDevice(email, current, 'ClubNahuel3');

      await fillIn(tester, currentPassword: 'ClubNahuel3');
      await tapText(tester, 'GUARDAR CONTRASEÑA');

      // Verifies: it warns the session expired and takes it to sign in.
      await waitUntil(tester, find.text('Tu sesión expiró'));
      await tapText(tester, 'IR AL INICIO DE SESIÓN');
      expect(find.text('INICIAR SESIÓN'), findsOneWidget);
      semantics.dispose();
    },
  );
}
