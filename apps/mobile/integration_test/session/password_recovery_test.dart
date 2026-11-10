import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/actions.dart';
import '../support/network.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const oldPassword = 'ClubNahuel1';
  const newPassword = 'ClubNahuel2';
  const notice =
      'Si el correo está registrado, te enviamos un enlace para crear una contraseña '
      'nueva. El enlace vence en 30 minutos.';

  Future<void> requestLink(WidgetTester tester, String email) async {
    await tapText(tester, '¿Olvidaste tu contraseña?');
    await typeInto(tester, 'Correo electrónico', email);
    await tapText(tester, 'ENVIAR ENLACE');
  }

  Future<void> createNew(
    WidgetTester tester, {
    String repeated = newPassword,
  }) async {
    await typeInto(tester, 'Contraseña nueva', newPassword);
    await typeInto(tester, 'Repetir contraseña', repeated);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
  }

  bool enabled(WidgetTester tester, String button) =>
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, button))
          .onPressed !=
      null;

  testWidgets(
    'requests the link, creates a new password and signs in with it @CU-04b-H01-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final email = 'socio.${unique()}@correo.com';
      await createAccount(email: email, password: oldPassword);
      await openApp(tester);

      await requestLink(tester, email);
      await waitUntil(tester, find.text('Revisá tu correo'));
      expect(find.text(notice), findsOneWidget);

      // Verifies: the email has a link that opens the app on the new password.
      await openRecoveryLink(tester, await lastCode(email));
      await waitUntil(tester, find.text('Creá una contraseña nueva'));
      await createNew(tester);
      await tapText(tester, 'GUARDAR CONTRASEÑA');
      await waitUntil(tester, find.text('Contraseña actualizada'));

      // Verifies: it returns to the login and the new password opens the account.
      await tapText(tester, 'VOLVER AL INICIO DE SESIÓN');
      await typeInto(tester, 'Correo', email);
      await typeInto(tester, 'Contraseña', newPassword);
      await tapText(tester, 'INICIAR SESIÓN');
      await waitUntil(tester, find.text('RESERVÁ TU CANCHA'));
      semantics.dispose();
    },
  );

  testWidgets(
    'after recovering, the previous password no longer works @CU-04b-H01-02',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final email = 'socio.${unique()}@correo.com';
      await createAccount(email: email, password: oldPassword);
      await openApp(tester);
      await requestLink(tester, email);
      await waitUntil(tester, find.text('Revisá tu correo'));
      await openRecoveryLink(tester, await lastCode(email));
      await waitUntil(tester, find.text('Creá una contraseña nueva'));
      await createNew(tester);
      await tapText(tester, 'GUARDAR CONTRASEÑA');
      await waitUntil(tester, find.text('Contraseña actualizada'));

      // Verifies: the forgotten password stops opening the account.
      expect(await canSignIn(email, oldPassword), isFalse);
      expect(await canSignIn(email, newPassword), isTrue);
      semantics.dispose();
    },
  );

  testWidgets(
    'requests the link with an email without an account and sees the same message, without any mail being sent @CU-04b-H02-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final email = 'nadie.${unique()}@correo.com';
      await openApp(tester);

      await requestLink(tester, email);

      // Verifies: the response does not say whether the email has an account, and no mail goes out.
      await waitUntil(tester, find.text('Revisá tu correo'));
      expect(find.text(notice), findsOneWidget);
      expect(await emailsFor(email), isEmpty);
      semantics.dispose();
    },
  );

  testWidgets(
    'types an email with an invalid format and the button stays disabled @CU-04b-H03-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await openApp(tester);
      await tapText(tester, '¿Olvidaste tu contraseña?');

      await typeInto(tester, 'Correo electrónico', 'nmosse@unimoron');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();

      // Verifies: it flags the format and does not allow sending.
      expect(find.text('Revisá el formato del correo'), findsOneWidget);
      expect(enabled(tester, 'ENVIAR ENLACE'), isFalse);
      semantics.dispose();
    },
  );

  testWidgets(
    'opens an expired link and sees «El enlace no es válido» @CU-04b-H04-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final email = 'socio.${unique()}@correo.com';
      await createAccount(email: email, password: oldPassword);
      await openApp(tester);
      await requestLink(tester, email);
      await waitUntil(tester, find.text('Revisá tu correo'));
      final code = await lastCode(email);
      await expireLink(code);

      await openRecoveryLink(tester, code);

      // Verifies: the expired link does not allow changing the password and offers to request another.
      await waitUntil(tester, find.text('El enlace no es válido'));
      expect(find.text('PEDIR UN ENLACE NUEVO'), findsOneWidget);
      expect(find.text('Creá una contraseña nueva'), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets(
    'opens an already used link and sees «El enlace no es válido» @CU-04b-H04-02',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final email = 'socio.${unique()}@correo.com';
      await createAccount(email: email, password: oldPassword);
      await openApp(tester);
      await requestLink(tester, email);
      await waitUntil(tester, find.text('Revisá tu correo'));
      final code = await lastCode(email);
      await openRecoveryLink(tester, code);
      await waitUntil(tester, find.text('Creá una contraseña nueva'));
      await createNew(tester);
      await tapText(tester, 'GUARDAR CONTRASEÑA');
      await waitUntil(tester, find.text('Contraseña actualizada'));
      await tapText(tester, 'VOLVER AL INICIO DE SESIÓN');

      await openRecoveryLink(tester, code);

      // Verifies: the link works only once.
      await waitUntil(tester, find.text('El enlace no es válido'));
      expect(await canSignIn(email, newPassword), isTrue);
      semantics.dispose();
    },
  );

  testWidgets(
    'the repetition does not match and the button stays disabled @CU-04b-H05-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final email = 'socio.${unique()}@correo.com';
      await createAccount(email: email, password: oldPassword);
      await openApp(tester);
      await requestLink(tester, email);
      await waitUntil(tester, find.text('Revisá tu correo'));
      await openRecoveryLink(tester, await lastCode(email));
      await waitUntil(tester, find.text('Creá una contraseña nueva'));

      await createNew(tester, repeated: 'ClubNahuel3');

      // Verifies: it flags the repetition and does not allow saving.
      expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
      expect(enabled(tester, 'GUARDAR CONTRASEÑA'), isFalse);
      semantics.dispose();
    },
  );

  testWidgets(
    'resends the email and the previous link stops working @CU-04b-H06-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final email = 'socio.${unique()}@correo.com';
      await createAccount(email: email, password: oldPassword);
      await openApp(tester);
      await requestLink(tester, email);
      await waitUntil(tester, find.text('Revisá tu correo'));
      final first = await lastCode(email);

      await tapText(tester, 'Reenviar el correo');
      await waitUntil(tester, find.text('Revisá tu correo'));

      // Verifies: a second email arrives and the first link is no longer valid.
      final emails = await emailsFor(email);
      expect(emails, hasLength(2));
      expect(await lastCode(email), isNot(first));
      await openRecoveryLink(tester, first);
      await waitUntil(tester, find.text('El enlace no es válido'));
      semantics.dispose();
    },
  );

  testWidgets(
    'offline or with the server down when requesting the link, it sees the overlay and nothing changes @CU-04b-H07-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final email = 'socio.${unique()}@correo.com';
      await createAccount(email: email, password: oldPassword);
      final api = await ProxyApi.open();
      await openApp(tester, apiUrl: api.url);

      api.state = ApiState.offline;
      await requestLink(tester, email);
      // Verifies: offline the connection notice is shown and no email goes out.
      await waitUntil(tester, find.text('Error de conexión'));
      await tapText(tester, 'Volver');
      expect(find.text('Revisá tu correo'), findsNothing);

      api.state = ApiState.failing;
      await tapText(tester, 'ENVIAR ENLACE');
      // Verifies: with the server down its notice is shown, and the password stays the same.
      await waitUntil(tester, find.text('Error del servidor'));
      expect(await emailsFor(email), isEmpty);
      expect(await canSignIn(email, oldPassword), isTrue);
      semantics.dispose();
    },
  );
}
