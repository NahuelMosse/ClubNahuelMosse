import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

import '../support/actions.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> abrirTarjeta(WidgetTester tester) async {
    await tester.tap(find.bySemanticsLabel('Tu cuenta'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'cierra la sesión desde la tarjeta del avatar y vuelve al login @CU-02-H01-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final correo = 'socio.${unique()}@correo.com';
      await signInAsUser(tester, correo: correo);

      await abrirTarjeta(tester);
      // Verifica: la tarjeta muestra quién tiene la sesión abierta y sus opciones.
      expect(find.text('Nahuel Mosse'), findsOneWidget);
      expect(find.text(correo), findsOneWidget);
      expect(find.text('Perfil completo'), findsOneWidget);
      expect(find.text('Mis reservas'), findsOneWidget);

      await tapText(tester, 'Cerrar sesión');

      // Verifica: vuelve al login. Si falla, la sesión queda abierta en un teléfono ajeno.
      expect(find.text('INICIAR SESIÓN'), findsOneWidget);
      expect(find.text('RESERVÁ TU CANCHA'), findsNothing);
      semantica.dispose();
    },
  );

  testWidgets(
    'después de cerrar la sesión, volver atrás no reabre una pantalla con sesión @CU-02-H01-02',
    (tester) async {
      final semantica = tester.ensureSemantics();
      await signInAsUser(tester, correo: 'socio.${unique()}@correo.com');
      await abrirTarjeta(tester);
      await tapText(tester, 'Cerrar sesión');

      // Verifica: ir de nuevo al Home sin sesión termina en el login.
      final login = tester.element(find.text('INICIAR SESIÓN'));
      expect(GoRouter.of(login).canPop(), isFalse);
      GoRouter.of(login).go('/inicio');
      await tester.pumpAndSettle();
      expect(find.text('INICIAR SESIÓN'), findsOneWidget);
      expect(find.text('RESERVÁ TU CANCHA'), findsNothing);

      // Verifica: al reabrir la app la sesión sigue cerrada.
      await reopenApp(tester);
      expect(find.text('INICIAR SESIÓN'), findsOneWidget);
      expect(find.text('RESERVÁ TU CANCHA'), findsNothing);
      semantica.dispose();
    },
  );

  testWidgets(
    'cierra la sesión desde Mi perfil y vuelve al login @CU-02-H02-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      await signInAsUser(tester, correo: 'socio.${unique()}@correo.com');
      await abrirTarjeta(tester);
      await tapText(tester, 'Perfil completo');
      expect(find.text('MIEMBRO ACTIVO'), findsOneWidget);

      await tapText(tester, 'CERRAR SESIÓN');

      // Verifica: desde el perfil también se sale al login.
      expect(find.text('INICIAR SESIÓN'), findsOneWidget);
      expect(find.text('MIEMBRO ACTIVO'), findsNothing);
      semantica.dispose();
    },
  );

  testWidgets(
    'abre la tarjeta del avatar, toca afuera y la tarjeta se cierra sin cerrar la sesión @CU-02-H03-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      await signInAsUser(tester, correo: 'socio.${unique()}@correo.com');
      await abrirTarjeta(tester);
      expect(find.text('Cerrar sesión'), findsOneWidget);

      // Un punto de la pantalla lejos de la tarjeta, que está arriba a la derecha.
      final pantalla = tester.view.physicalSize / tester.view.devicePixelRatio;
      await tester.tapAt(Offset(pantalla.width / 4, pantalla.height * 0.8));
      await tester.pumpAndSettle();

      // Verifica: la tarjeta se va y la persona sigue en el Home con su sesión.
      expect(find.text('Cerrar sesión'), findsNothing);
      expect(find.text('RESERVÁ TU CANCHA'), findsOneWidget);
      semantica.dispose();
    },
  );
}
