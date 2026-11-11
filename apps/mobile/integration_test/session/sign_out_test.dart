import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

import '../support/actions.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> openCard(WidgetTester tester) async {
    await tester.tap(find.bySemanticsLabel('Tu cuenta'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'signs out from the avatar card and returns to the login @CU-02-H01-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final email = 'socio.${unique()}@correo.com';
      await signInAsUser(tester, email: email);

      await openCard(tester);
      // Verifies: the card shows who has the session open and their options.
      expect(find.text('Nahuel Mosse'), findsOneWidget);
      expect(find.text(email), findsOneWidget);
      expect(find.text('Perfil completo'), findsOneWidget);
      expect(find.text('Mis reservas'), findsOneWidget);

      await tapText(tester, 'Cerrar sesión');

      // Verifies: it returns to the login. If it fails, the session stays open on someone else's phone.
      expect(find.text('INICIAR SESIÓN'), findsOneWidget);
      expect(find.text('RESERVÁ TU CANCHA'), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets(
    'after signing out, going back does not reopen a signed-in screen @CU-02-H01-02',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await signInAsUser(tester, email: 'socio.${unique()}@correo.com');
      await openCard(tester);
      await tapText(tester, 'Cerrar sesión');

      // Verifies: going to the Home again without a session ends on the login.
      final login = tester.element(find.text('INICIAR SESIÓN'));
      expect(GoRouter.of(login).canPop(), isFalse);
      GoRouter.of(login).go('/home');
      await tester.pumpAndSettle();
      expect(find.text('INICIAR SESIÓN'), findsOneWidget);
      expect(find.text('RESERVÁ TU CANCHA'), findsNothing);

      // Verifies: on reopening the app the session is still closed.
      await reopenApp(tester);
      expect(find.text('INICIAR SESIÓN'), findsOneWidget);
      expect(find.text('RESERVÁ TU CANCHA'), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets(
    'signs out from «Mi perfil» and returns to the login @CU-02-H02-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await signInAsUser(tester, email: 'socio.${unique()}@correo.com');
      await openCard(tester);
      await tapText(tester, 'Perfil completo');
      expect(find.text('MIEMBRO ACTIVO'), findsOneWidget);

      await tapText(tester, 'CERRAR SESIÓN');

      // Verifies: from the profile it also leaves to the login.
      expect(find.text('INICIAR SESIÓN'), findsOneWidget);
      expect(find.text('MIEMBRO ACTIVO'), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets(
    'opens the avatar card, taps outside and the card closes without signing out @CU-02-H03-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await signInAsUser(tester, email: 'socio.${unique()}@correo.com');
      await openCard(tester);
      expect(find.text('Cerrar sesión'), findsOneWidget);

      // A point on the screen far from the card, which is at the top right.
      final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
      await tester.tapAt(Offset(screen.width / 4, screen.height * 0.8));
      await tester.pumpAndSettle();

      // Verifies: the card goes away and the person stays on the Home with their session.
      expect(find.text('Cerrar sesión'), findsNothing);
      expect(find.text('RESERVÁ TU CANCHA'), findsOneWidget);
      semantics.dispose();
    },
  );
}
