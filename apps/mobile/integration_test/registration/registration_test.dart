import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/actions.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> goToRegistration(WidgetTester tester) async {
    await openApp(tester);
    await tapText(tester, 'COMENZAR');
    expect(find.text('Creá tu cuenta'), findsOneWidget);
  }

  Future<void> fillIn(
    WidgetTester tester, {
    required String email,
    required String dni,
  }) async {
    await typeInto(tester, 'Nombre', 'Nahuel Agustín');
    await typeInto(tester, 'Apellido', 'Mosse');
    await typeInto(tester, 'DNI', dni);
    await typeInto(tester, 'Fecha de nacimiento', '14032000');
    await typeInto(tester, 'Correo electrónico', email);
    await typeInto(tester, 'Contraseña', 'ClubNahuel1');
  }

  Future<void> register(WidgetTester tester, String email, String dni) async {
    await goToRegistration(tester);
    await fillIn(tester, email: email, dni: dni);
    await tapText(tester, 'CREAR CUENTA');
    await waitUntil(tester, find.text('¡Cuenta creada!'));
    await tapText(tester, 'VOLVER AL INICIO DE SESIÓN');
  }

  testWidgets(
    'fills in all the data, creates the account and returns to the login @CU-03-H01-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final s = unique();

      await goToRegistration(tester);
      await fillIn(tester, email: 'nuevo.$s@correo.com', dni: dniOf(s));
      await tapText(tester, 'CREAR CUENTA');

      // Verifies: the account is created with the six fields and the app confirms it.
      await waitUntil(tester, find.text('¡Cuenta creada!'));
      expect(
        find.text(
          'Tu cuenta se registró con éxito. Ya podés iniciar sesión con tu correo y contraseña.',
        ),
        findsOneWidget,
      );

      // Verifies: it returns to the sign-in. If it fails, it is left in a dead end.
      await tapText(tester, 'VOLVER AL INICIO DE SESIÓN');
      expect(find.text('INICIAR SESIÓN'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets(
    'leaves required fields empty and sees which are missing, without the account being created @CU-03-H02-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final s = unique();
      final email = 'incompleto.$s@correo.com';

      await goToRegistration(tester);
      await typeInto(tester, 'Nombre', 'Nahuel Agustín');
      await typeInto(tester, 'Apellido', 'Mosse');
      await typeInto(tester, 'Correo electrónico', email);
      await enterAndLeave(tester, 'DNI');
      await enterAndLeave(tester, 'Fecha de nacimiento');
      await enterAndLeave(tester, 'Contraseña');

      // Verifies: each empty field says it is required. If it fails, it does not know what is missing.
      expect(find.text('El DNI es obligatorio'), findsOneWidget);
      expect(
        find.text('La fecha de nacimiento es obligatoria'),
        findsOneWidget,
      );
      expect(find.text('La contraseña es obligatoria'), findsOneWidget);

      // Verifies: with missing data the account cannot be created.
      await tapText(tester, 'CREAR CUENTA');
      expect(find.text('¡Cuenta creada!'), findsNothing);
      expect(find.text('Creá tu cuenta'), findsOneWidget);

      // Verifies: nothing was created; the same email registers later without a clash.
      await typeInto(tester, 'DNI', dniOf(s));
      await typeInto(tester, 'Fecha de nacimiento', '14032000');
      await typeInto(tester, 'Contraseña', 'ClubNahuel1');
      await tapText(tester, 'CREAR CUENTA');
      await waitUntil(tester, find.text('¡Cuenta creada!'));
      semantics.dispose();
    },
  );

  testWidgets(
    'registers with an email that already has an account and stays on the form with the error @CU-03-H03-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final s = unique();
      final email = 'repetido.$s@correo.com';
      await register(tester, email, dniOf(s));

      await tapText(tester, 'COMENZAR');
      await fillIn(tester, email: email, dni: dniOf(unique()));
      await tapText(tester, 'CREAR CUENTA');

      // Verifies: the repeated email is flagged and the person stays on the form.
      await waitUntil(tester, find.text('Este correo ya está registrado'));
      expect(
        find.text(
          'El usuario ya está registrado. Modificá el correo o el DNI.',
        ),
        findsOneWidget,
      );
      expect(find.text('Creá tu cuenta'), findsOneWidget);
      expect(find.text('¡Cuenta creada!'), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets(
    'registers with a DNI that already has an account and stays on the form with the error @CU-03-H03-02',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final s = unique();
      final dni = dniOf(s);
      await register(tester, 'primero.$s@correo.com', dni);

      await tapText(tester, 'COMENZAR');
      await fillIn(tester, email: 'segundo.$s@correo.com', dni: dni);
      await tapText(tester, 'CREAR CUENTA');

      // Verifies: the repeated DNI is flagged and a second account is not created.
      await waitUntil(tester, find.text('Este DNI ya está registrado'));
      expect(find.text('Creá tu cuenta'), findsOneWidget);
      expect(find.text('¡Cuenta creada!'), findsNothing);
      semantics.dispose();
    },
  );
}
