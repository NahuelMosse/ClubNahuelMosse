import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/actions.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const password = 'ClubNahuel1';
  const generic =
      'No se pudo iniciar sesión. Revisá tus datos e intentá de nuevo.';

  Future<void> signIn(WidgetTester tester, String email, String secret) async {
    if (email.isNotEmpty) await typeInto(tester, 'Correo', email);
    if (secret.isNotEmpty) await typeInto(tester, 'Contraseña', secret);
    await tapText(tester, 'INICIAR SESIÓN');
  }

  testWidgets(
    'signs in with correct email and password and reaches the Home @CU-01-H01-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final email = 'socio.${unique()}@correo.com';
      await createAccount(email: email, password: password);
      await openApp(tester);

      // Verifies CU-01-SUP-03: the email in uppercase and with surrounding spaces gets in anyway.
      await signIn(tester, '  ${email.toUpperCase()} ', password);

      // Verifies: it reaches the Home with its name. If it fails, it stays on the login unable to book.
      await waitUntil(tester, find.text('RESERVÁ TU CANCHA'));
      expect(find.text('Nahuel'), findsOneWidget);
      expect(find.text('INICIAR SESIÓN'), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets(
    'signs in with an administrator account and reaches the administration panel @CU-01-H01-02',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await openApp(tester);

      await signIn(tester, adminEmail, adminPassword);

      // Verifies: the role comes from the account, without choosing it on the login. If it fails, the admin
      // lands on the user Home and does not reach the administration tools.
      await waitUntil(tester, find.text('PANEL ADMIN'));
      expect(find.text('RESERVÁ TU CANCHA'), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets(
    'tries to sign in with an empty email and nothing is sent to the backend @CU-01-H02-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      // Offline: if the app sent the credentials, by the time the screen settled the
      // connection error would already be there.
      await openApp(tester, apiUrl: offlineApi, authEmulator: offline);

      await signIn(tester, '', password);

      // Verifies: it flags the missing email and sends nothing. If it fails, the person does not know what
      // is missing, or the app queries the backend with incomplete data.
      expect(find.text('Completá tu correo electrónico'), findsOneWidget);
      expect(find.text('Completá tu contraseña'), findsNothing);
      expect(find.text('Error de conexión'), findsNothing);
      expect(find.text('INICIAR SESIÓN'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets(
    'tries to sign in with an empty password and nothing is sent to the backend @CU-01-H02-02',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await openApp(tester, apiUrl: offlineApi, authEmulator: offline);

      await signIn(tester, 'socio@correo.com', '');

      // Verifies: it flags the missing password and sends nothing.
      expect(find.text('Completá tu contraseña'), findsOneWidget);
      expect(find.text('Completá tu correo electrónico'), findsNothing);
      expect(find.text('Error de conexión'), findsNothing);
      expect(find.text('INICIAR SESIÓN'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets(
    'enters an email that is not registered and sees the generic message @CU-01-H03-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await openApp(tester);

      await signIn(tester, 'nadie.${unique()}@correo.com', password);

      // Verifies: the message does not say which piece of data is wrong. If it fails, the app reveals which emails
      // have an account.
      await waitUntil(tester, find.text(generic));
      expect(find.text('INICIAR SESIÓN'), findsOneWidget);
      expect(find.text('RESERVÁ TU CANCHA'), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets(
    'enters a wrong password and sees the same generic message @CU-01-H03-02',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final email = 'socio.${unique()}@correo.com';
      await createAccount(email: email, password: password);
      await openApp(tester);

      await signIn(tester, email, 'OtraClave9');

      // Verifies: the same text as with an email without an account, and it does not get in.
      await waitUntil(tester, find.text(generic));
      expect(find.text('INICIAR SESIÓN'), findsOneWidget);
      expect(find.text('RESERVÁ TU CANCHA'), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets(
    'taps «¿Olvidaste tu contraseña?» and reaches «Recuperar contraseña» @CU-01-H04-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await openApp(tester);

      await tapText(tester, '¿Olvidaste tu contraseña?');

      // Verifies: the link leads to recovering the password. If it fails, whoever forgot it has no
      // way to sign in again.
      expect(find.text('Recuperar contraseña'), findsOneWidget);
      expect(find.text('INICIAR SESIÓN'), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets(
    'the server fails on signing in and it is asked to retry later @CU-01-H05-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final email = 'socio.${unique()}@correo.com';
      await createAccount(email: email, password: password);
      await openApp(tester, apiUrl: await failingApi());

      await signIn(tester, email, password);

      // Verifies: it says the server failed and asks to try later.
      await waitUntil(tester, find.text('Error del servidor'));
      expect(
        find.text(
          'No pudimos procesar la operación en este momento. Intentá más tarde.',
        ),
        findsOneWidget,
      );

      // Verifies: on closing the notice it stays on the login, without a half-made session.
      await tapText(tester, 'ACEPTAR');
      expect(find.text('INICIAR SESIÓN'), findsOneWidget);
      expect(find.text('RESERVÁ TU CANCHA'), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets(
    'without an internet connection, it is asked to restore the connection @CU-01-H06-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await openApp(tester, apiUrl: offlineApi, authEmulator: offline);

      await signIn(tester, 'socio@correo.com', password);

      // Verifies: it says there is no connection and offers to retry, instead of the message of
      // invalid credentials.
      await waitUntil(tester, find.text('Error de conexión'));
      expect(
        find.text(
          'No pudimos conectarnos. Revisá tu conexión a internet y volvé a intentar.',
        ),
        findsOneWidget,
      );
      expect(find.text('REINTENTAR'), findsOneWidget);
      expect(find.text(generic), findsNothing);
      semantics.dispose();
    },
  );
}
