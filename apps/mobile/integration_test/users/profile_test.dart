import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/actions.dart';
import '../support/network.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Brightness brightness(WidgetTester tester, String text) =>
      Theme.of(tester.element(find.text(text).first)).brightness;

  testWidgets(
    'opens Profile from the bottom bar and sees its personal data and the email as not editable @CU-05-H01-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final email = 'socio.${unique()}@correo.com';
      await signInAsUser(tester, email: email);

      await tapText(tester, 'PERFIL');

      // Verifies: the data the API holds for the account is shown.
      await waitUntil(tester, find.text('DATOS PERSONALES'));
      expect(find.text('Nahuel Mosse'), findsOneWidget);
      expect(find.text('MIEMBRO ACTIVO'), findsOneWidget);
      for (final item in ['Nombre', 'Apellido', 'DNI', 'Nacimiento']) {
        expect(find.text(item), findsOneWidget, reason: item);
      }
      expect(find.text('Mosse'), findsOneWidget);
      expect(find.text('14/03/2000'), findsOneWidget);

      // Verifies: the email is shown and announced as a value that cannot be changed.
      expect(
        find.bySemanticsLabel('Correo: $email. No se puede cambiar'),
        findsOneWidget,
      );
      expect(find.text('Cambiar contraseña'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets(
    'switches to light mode and the whole app changes theme without leaving the profile @CU-05-H01-02',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await signInAsUser(tester, email: 'socio.${unique()}@correo.com');
      await tapText(tester, 'PERFIL');
      await waitUntil(tester, find.text('DATOS PERSONALES'));
      expect(brightness(tester, 'DATOS PERSONALES'), Brightness.dark);

      await tester.ensureVisible(find.bySemanticsLabel('Modo oscuro'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Modo oscuro'));
      await tester.pumpAndSettle();

      // Verifies: the profile turns light and stays in view.
      expect(brightness(tester, 'DATOS PERSONALES'), Brightness.light);

      // Verifies: the change applies to the whole app, not only this screen.
      await tapText(tester, 'INICIO');
      expect(brightness(tester, 'RESERVÁ TU CANCHA'), Brightness.light);
      semantics.dispose();
    },
  );

  testWidgets(
    'from the profile it reaches Edit profile, Change password, Sign out and Delete account @CU-05-H01-03',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await signInAsUser(tester, email: 'socio.${unique()}@correo.com');
      Future<void> openProfile() async {
        await tapText(tester, 'PERFIL');
        await waitUntil(tester, find.text('DATOS PERSONALES'));
      }

      // Verifies: «Editar» switches the personal data to edit mode.
      await openProfile();
      await tapText(tester, 'Editar');
      expect(find.text('GUARDAR'), findsOneWidget);

      // Verifies: the Security row leads to changing the password.
      await tapText(tester, 'INICIO');
      await openProfile();
      await tapText(tester, 'Cambiar contraseña');
      expect(find.text('Cambiá tu contraseña'), findsOneWidget);
      await tester.tap(find.byTooltip('Volver'));
      await tester.pumpAndSettle();

      // Verifies: «ELIMINAR CUENTA» asks for confirmation, and cancelling changes nothing.
      await tapText(tester, 'ELIMINAR CUENTA');
      expect(find.text('¿Eliminar tu cuenta?'), findsOneWidget);
      await tapText(tester, 'CANCELAR');
      expect(find.text('DATOS PERSONALES'), findsOneWidget);

      // Verifies: «CERRAR SESIÓN» goes out to the login.
      await tapText(tester, 'CERRAR SESIÓN');
      expect(find.text('INICIAR SESIÓN'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets(
    'opens the profile from «Perfil completo» on the avatar card @CU-05-H02-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await signInAsUser(tester, email: 'socio.${unique()}@correo.com');

      await tester.tap(find.bySemanticsLabel('Tu cuenta'));
      await tester.pumpAndSettle();
      await tapText(tester, 'Perfil completo');

      // Verifies: it reaches the same profile as through the bottom bar.
      await waitUntil(tester, find.text('DATOS PERSONALES'));
      expect(find.text('14/03/2000'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets(
    'offline, it sees the connection alert and no profile data @CU-05-H03-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final api = await ProxyApi.open();
      await signInAsUser(
        tester,
        email: 'socio.${unique()}@correo.com',
        apiUrl: api.url,
      );

      api.state = ApiState.offline;
      await tapText(tester, 'PERFIL');

      // Verifies: it warns there is no connection and shows no stale data.
      await waitUntil(tester, find.text('Error de conexión'));
      expect(find.text('DATOS PERSONALES'), findsNothing);
      expect(find.text('14/03/2000'), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets('the server fails and the screen shows no data @CU-05-H04-01', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final api = await ProxyApi.open();
    await signInAsUser(
      tester,
      email: 'socio.${unique()}@correo.com',
      apiUrl: api.url,
    );

    api.state = ApiState.failing;
    await tapText(tester, 'PERFIL');

    // Verifies: it warns of the server and shows no data.
    await waitUntil(tester, find.text('Error del servidor'));
    expect(find.text('DATOS PERSONALES'), findsNothing);
    semantics.dispose();
  });

  testWidgets(
    'with an expired session, it sees no data and the app takes it to the login @CU-05-H05-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final email = 'socio.${unique()}@correo.com';
      await signInAsUser(tester, email: email);
      await changeFromAnotherDevice(email, 'ClubNahuel1', 'ClubNahuel3');

      await tapText(tester, 'PERFIL');

      // Verifies: it exposes no data and sends to sign in.
      await waitUntil(tester, find.text('Tu sesión expiró'));
      expect(find.text('DATOS PERSONALES'), findsNothing);
      await tapText(tester, 'IR AL INICIO DE SESIÓN');
      expect(find.text('INICIAR SESIÓN'), findsOneWidget);
      semantics.dispose();
    },
  );
}
