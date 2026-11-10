import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/actions.dart';
import '../support/network.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const invalid = 'El formato de los datos no es válido';

  Future<void> openProfile(WidgetTester tester) async {
    await tapText(tester, 'PERFIL');
    await waitUntil(tester, find.text('DATOS PERSONALES'));
  }

  Future<void> edit(WidgetTester tester) async {
    await openProfile(tester);
    await tapText(tester, 'Editar');
    expect(find.text('GUARDAR'), findsOneWidget);
  }

  TextField field(WidgetTester tester, String label) =>
      tester.widget<TextField>(
        find.descendant(
          of: find.bySemanticsLabel(label),
          matching: find.byType(TextField),
        ),
      );

  Brightness brightness(WidgetTester tester) =>
      Theme.of(tester.element(find.text('DATOS PERSONALES'))).brightness;

  testWidgets(
    'edits its name, saves, and the profile shows the new value when reopened @CU-06-H01-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await signInAsUser(tester, email: 'socio.${unique()}@correo.com');
      await edit(tester);

      await typeInto(tester, 'Nombre', 'Agustín');
      await tapText(tester, 'GUARDAR');

      // Verifies: it returns to read mode with the new name.
      await waitUntil(tester, find.text('Agustín'));
      expect(find.text('GUARDAR'), findsNothing);
      expect(find.text('Agustín Mosse'), findsOneWidget);

      // Verifies: the change was saved in the API, not only on screen.
      await tapText(tester, 'INICIO');
      await openProfile(tester);
      expect(find.text('Agustín'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets('the email cannot be edited @CU-06-H01-02', (tester) async {
    final semantics = tester.ensureSemantics();
    final email = 'socio.${unique()}@correo.com';
    await signInAsUser(tester, email: email);
    await edit(tester);

    // Verifies: the email is in the form but disabled, with its value.
    final emailInEdit = field(tester, 'Correo electrónico');
    expect(emailInEdit.enabled, isFalse);
    expect(emailInEdit.controller?.text, email);
    expect(field(tester, 'Nombre').enabled, isTrue);
    semantics.dispose();
  });

  testWidgets(
    'toggles dark mode and the theme switches to the opposite @CU-06-H01-03',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await signInAsUser(tester, email: 'socio.${unique()}@correo.com');
      await edit(tester);
      final before = brightness(tester);

      Future<void> toggle() async {
        await tester.ensureVisible(find.bySemanticsLabel('Modo oscuro'));
        await tester.pumpAndSettle();
        await tester.tap(find.bySemanticsLabel('Modo oscuro'));
        await tester.pumpAndSettle();
      }

      // Verifies: each tap flips the theme to the opposite of the one it had.
      await toggle();
      expect(brightness(tester), isNot(before));
      await toggle();
      expect(brightness(tester), before);
      semantics.dispose();
    },
  );

  testWidgets(
    'saves an ID number or a date with an invalid format, sees the error and nothing is saved @CU-06-H02-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await signInAsUser(tester, email: 'socio.${unique()}@correo.com');
      await edit(tester);

      await typeInto(tester, 'Nombre', 'Agustín');
      await typeInto(tester, 'DNI', '42118');
      await typeInto(tester, 'Fecha de nacimiento', '32132000');
      await tapText(tester, 'GUARDAR');

      // Verifies: it flags both invalid values and stays in edit mode.
      expect(find.text(invalid), findsNWidgets(2));
      expect(find.text('GUARDAR'), findsOneWidget);

      // Verifies: nothing was saved, not even the valid name.
      await tapText(tester, 'INICIO');
      await openProfile(tester);
      expect(find.text('Agustín'), findsNothing);
      expect(find.text('14/03/2000'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets(
    'offline on saving, it sees the connectivity error and keeps what was typed @CU-06-H03-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final api = await ProxyApi.open();
      await signInAsUser(
        tester,
        email: 'socio.${unique()}@correo.com',
        apiUrl: api.url,
      );
      await edit(tester);
      await typeInto(tester, 'Nombre', 'Agustín');

      api.state = ApiState.offline;
      await tapText(tester, 'GUARDAR');

      // Verifies: it warns there is no connection and what was typed stays in the field.
      await waitUntil(tester, find.text('Error de conexión'));
      await tapText(tester, 'Volver');
      expect(field(tester, 'Nombre').controller?.text, 'Agustín');
      expect(find.text('GUARDAR'), findsOneWidget);
      semantics.dispose();
    },
  );
}
