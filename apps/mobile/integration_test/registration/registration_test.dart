import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/actions.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> irAlRegistro(WidgetTester tester) async {
    await openApp(tester);
    await tapText(tester, 'COMENZAR');
    expect(find.text('Creá tu cuenta'), findsOneWidget);
  }

  Future<void> completar(
    WidgetTester tester, {
    required String correo,
    required String dni,
  }) async {
    await typeInto(tester, 'Nombre', 'Nahuel Agustín');
    await typeInto(tester, 'Apellido', 'Mosse');
    await typeInto(tester, 'DNI', dni);
    await typeInto(tester, 'Fecha de nacimiento', '14032000');
    await typeInto(tester, 'Correo electrónico', correo);
    await typeInto(tester, 'Contraseña', 'ClubNahuel1');
  }

  Future<void> registrar(WidgetTester tester, String correo, String dni) async {
    await irAlRegistro(tester);
    await completar(tester, correo: correo, dni: dni);
    await tapText(tester, 'CREAR CUENTA');
    await waitUntil(tester, find.text('¡Cuenta creada!'));
    await tapText(tester, 'VOLVER AL INICIO DE SESIÓN');
  }

  testWidgets(
    'completa todos los datos, crea la cuenta y vuelve al login @CU-03-H01-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final s = unique();

      await irAlRegistro(tester);
      await completar(tester, correo: 'nuevo.$s@correo.com', dni: dniOf(s));
      await tapText(tester, 'CREAR CUENTA');

      // Verifica: la cuenta se crea con los seis datos y la app lo confirma.
      await waitUntil(tester, find.text('¡Cuenta creada!'));
      expect(
        find.text(
          'Tu cuenta se registró con éxito. Ya podés iniciar sesión con tu correo y contraseña.',
        ),
        findsOneWidget,
      );

      // Verifica: vuelve al inicio de sesión. Si falla, queda en un callejón sin salida.
      await tapText(tester, 'VOLVER AL INICIO DE SESIÓN');
      expect(find.text('INICIAR SESIÓN'), findsOneWidget);
      semantica.dispose();
    },
  );

  testWidgets(
    'deja campos obligatorios vacíos y ve cuáles faltan, sin que se cree la cuenta @CU-03-H02-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final s = unique();
      final correo = 'incompleto.$s@correo.com';

      await irAlRegistro(tester);
      await typeInto(tester, 'Nombre', 'Nahuel Agustín');
      await typeInto(tester, 'Apellido', 'Mosse');
      await typeInto(tester, 'Correo electrónico', correo);
      await enterAndLeave(tester, 'DNI');
      await enterAndLeave(tester, 'Fecha de nacimiento');
      await enterAndLeave(tester, 'Contraseña');

      // Verifica: cada campo vacío dice que es obligatorio. Si falla, no sabe qué le falta.
      expect(find.text('El DNI es obligatorio'), findsOneWidget);
      expect(
        find.text('La fecha de nacimiento es obligatoria'),
        findsOneWidget,
      );
      expect(find.text('La contraseña es obligatoria'), findsOneWidget);

      // Verifica: con datos faltantes no se puede crear la cuenta.
      await tapText(tester, 'CREAR CUENTA');
      expect(find.text('¡Cuenta creada!'), findsNothing);
      expect(find.text('Creá tu cuenta'), findsOneWidget);

      // Verifica: no quedó nada creado; el mismo correo se registra después sin choque.
      await typeInto(tester, 'DNI', dniOf(s));
      await typeInto(tester, 'Fecha de nacimiento', '14032000');
      await typeInto(tester, 'Contraseña', 'ClubNahuel1');
      await tapText(tester, 'CREAR CUENTA');
      await waitUntil(tester, find.text('¡Cuenta creada!'));
      semantica.dispose();
    },
  );

  testWidgets(
    'se registra con un correo que ya tiene cuenta y queda en el formulario con el error @CU-03-H03-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final s = unique();
      final correo = 'repetido.$s@correo.com';
      await registrar(tester, correo, dniOf(s));

      await tapText(tester, 'COMENZAR');
      await completar(tester, correo: correo, dni: dniOf(unique()));
      await tapText(tester, 'CREAR CUENTA');

      // Verifica: el correo repetido se marca y la persona sigue en el formulario.
      await waitUntil(tester, find.text('Este correo ya está registrado'));
      expect(
        find.text(
          'El usuario ya está registrado. Modificá el correo o el DNI.',
        ),
        findsOneWidget,
      );
      expect(find.text('Creá tu cuenta'), findsOneWidget);
      expect(find.text('¡Cuenta creada!'), findsNothing);
      semantica.dispose();
    },
  );

  testWidgets(
    'se registra con un DNI que ya tiene cuenta y queda en el formulario con el error @CU-03-H03-02',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final s = unique();
      final dni = dniOf(s);
      await registrar(tester, 'primero.$s@correo.com', dni);

      await tapText(tester, 'COMENZAR');
      await completar(tester, correo: 'segundo.$s@correo.com', dni: dni);
      await tapText(tester, 'CREAR CUENTA');

      // Verifica: el DNI repetido se marca y no se crea una segunda cuenta.
      await waitUntil(tester, find.text('Este DNI ya está registrado'));
      expect(find.text('Creá tu cuenta'), findsOneWidget);
      expect(find.text('¡Cuenta creada!'), findsNothing);
      semantica.dispose();
    },
  );
}
