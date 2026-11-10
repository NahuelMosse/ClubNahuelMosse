import 'package:clubnahuelmosse/features/users/data/registration_service.dart';
import 'package:clubnahuelmosse/features/users/presentation/registration_done_screen.dart';
import 'package:clubnahuelmosse/features/users/presentation/registration_screen.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide testWidgets;

import '../support/mount.dart';
import '../support/fixed_clock.dart';

/// No afirma nada: produce la tira del paso 9 para mirarla contra el prototipo.
void main() {
  setUpAll(loadFonts);

  const telefonos = {'360': Size(360, 800), '430': Size(430, 932)};
  final temas = {'dark': darkTheme, 'light': lightTheme};

  for (final MapEntry(key: ancho, value: tamano) in telefonos.entries) {
    for (final MapEntry(key: modo, value: tema) in temas.entries) {
      testWidgets('registro vacío $ancho $modo', (tester) async {
        await mountScreen(
          tester,
          RegistrationScreen(registration: RegistrationService(fakeApi())),
          tema: tema,
          tamano: tamano,
        );
        await expectLater(
          find.byType(RegistrationScreen),
          matchesGoldenFile('registration/empty_${ancho}_$modo.png'),
        );
      });

      testWidgets('registro con errores $ancho $modo', (tester) async {
        final semantica = tester.ensureSemantics();
        await mountScreen(
          tester,
          RegistrationScreen(registration: RegistrationService(fakeApi())),
          tema: tema,
          tamano: tamano,
        );
        await tester.enterText(
          find.bySemanticsLabel('Nombre'),
          'Nahuel Agustín',
        );
        await tester.enterText(find.bySemanticsLabel('DNI'), '123');
        for (final campo in ['DNI', 'Fecha de nacimiento', 'Contraseña']) {
          await tester.tap(find.bySemanticsLabel(campo));
          await tester.pump();
        }
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(RegistrationScreen),
          matchesGoldenFile('registration/errors_${ancho}_$modo.png'),
        );
        semantica.dispose();
      });

      testWidgets('registro exitoso $ancho $modo', (tester) async {
        await mountScreen(
          tester,
          const RegistrationDoneScreen(),
          tema: tema,
          tamano: tamano,
        );
        await expectLater(
          find.byType(RegistrationDoneScreen),
          matchesGoldenFile('registration/successful_${ancho}_$modo.png'),
        );
      });
    }
  }
}
