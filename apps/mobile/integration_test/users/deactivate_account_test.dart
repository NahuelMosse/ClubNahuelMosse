import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/actions.dart';
import '../support/network.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const password = 'ClubNahuel1';

  Future<void> requestDeletion(WidgetTester tester) async {
    await tapText(tester, 'PERFIL');
    await waitUntil(tester, find.text('DATOS PERSONALES'));
    await tapText(tester, 'ELIMINAR CUENTA');
    expect(find.text('¿Eliminar tu cuenta?'), findsOneWidget);
  }

  /// The button that confirms the deletion, the one in the dialog.
  Finder confirm() => find.descendant(
    of: find.byType(Dialog),
    matching: find.text('ELIMINAR CUENTA'),
  );

  testWidgets(
    'deletes its account, returns to the login and can no longer sign in with it @CU-07-H01-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final email = 'socio.${unique()}@correo.com';
      await signInAsUser(tester, email: email);
      await requestDeletion(tester);

      await tester.tap(confirm());
      await tester.pumpAndSettle();

      // Verifies: the session ends and the app returns to the login.
      await waitUntil(tester, find.text('INICIAR SESIÓN'));

      // Verifies: that account no longer gets in.
      await typeInto(tester, 'Correo', email);
      await typeInto(tester, 'Contraseña', password);
      await tapText(tester, 'INICIAR SESIÓN');
      await waitUntil(
        tester,
        find.text(
          'No se pudo iniciar sesión. Revisá tus datos e intentá de nuevo.',
        ),
      );
      expect(find.text('RESERVÁ TU CANCHA'), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets(
    'while the account is being deleted, the button shows «Eliminando tu cuenta…» and cannot be tapped again @CU-07-H01-03',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final api = await ProxyApi.open();
      await signInAsUser(
        tester,
        email: 'socio.${unique()}@correo.com',
        apiUrl: api.url,
      );
      await requestDeletion(tester);

      api.state = ApiState.slow;
      await tester.tap(confirm());
      await tester.pump(const Duration(milliseconds: 500));

      // Verifies: while it waits, the button says so and does not accept another tap.
      expect(find.text('ELIMINANDO TU CUENTA…'), findsOneWidget);
      final button = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'ELIMINANDO TU CUENTA…'),
      );
      expect(button.onPressed, isNull);

      await waitUntil(tester, find.text('INICIAR SESIÓN'));
      semantics.dispose();
    },
  );

  testWidgets(
    'cancels on the confirmation and the account stays intact @CU-07-H02-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final email = 'socio.${unique()}@correo.com';
      await signInAsUser(tester, email: email);
      await requestDeletion(tester);

      await tapText(tester, 'CANCELAR');

      // Verifies: it returns to the profile with the session open and the account still works.
      expect(find.text('¿Eliminar tu cuenta?'), findsNothing);
      expect(find.text('DATOS PERSONALES'), findsOneWidget);
      expect(await canSignIn(email, password), isTrue);
      semantics.dispose();
    },
  );

  testWidgets(
    'offline on confirming, it sees the alert and the account is not deleted @CU-07-H03-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final email = 'socio.${unique()}@correo.com';
      final api = await ProxyApi.open();
      await signInAsUser(tester, email: email, apiUrl: api.url);
      await requestDeletion(tester);

      api.state = ApiState.offline;
      await tester.tap(confirm());
      await tester.pumpAndSettle();

      // Verifies: it warns there is no connection and the account is left as it was.
      await waitUntil(tester, find.text('Error de conexión'));
      await tapText(tester, 'Volver');
      expect(find.text('DATOS PERSONALES'), findsOneWidget);
      expect(await canSignIn(email, password), isTrue);
      semantics.dispose();
    },
  );

  testWidgets(
    'the server fails on confirming and the account is not deleted @CU-07-H04-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final email = 'socio.${unique()}@correo.com';
      final api = await ProxyApi.open();
      await signInAsUser(tester, email: email, apiUrl: api.url);
      await requestDeletion(tester);

      api.state = ApiState.failing;
      await tester.tap(confirm());
      await tester.pumpAndSettle();

      // Verifies: it warns of the server and the account still works.
      await waitUntil(tester, find.text('Error del servidor'));
      await tapText(tester, 'ACEPTAR');
      api.state = ApiState.normal;
      expect(find.text('DATOS PERSONALES'), findsOneWidget);
      expect(await canSignIn(email, password), isTrue);
      semantics.dispose();
    },
  );
}
