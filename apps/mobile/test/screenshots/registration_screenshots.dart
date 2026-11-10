import 'package:clubnahuelmosse/features/users/data/registration_service.dart';
import 'package:clubnahuelmosse/features/users/presentation/registration_done_screen.dart';
import 'package:clubnahuelmosse/features/users/presentation/registration_screen.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide testWidgets;

import '../support/mount.dart';
import '../support/fixed_clock.dart';

/// Asserts nothing: produces the step-9 strip to compare against the prototype.
void main() {
  setUpAll(loadFonts);

  const phones = {'360': Size(360, 800), '430': Size(430, 932)};
  final themes = {'dark': darkTheme, 'light': lightTheme};

  for (final MapEntry(key: width, value: size) in phones.entries) {
    for (final MapEntry(key: mode, value: theme) in themes.entries) {
      testWidgets('empty registration $width $mode', (tester) async {
        await mountScreen(
          tester,
          RegistrationScreen(registration: RegistrationService(fakeApi())),
          theme: theme,
          size: size,
        );
        await expectLater(
          find.byType(RegistrationScreen),
          matchesGoldenFile('registration/empty_${width}_$mode.png'),
        );
      });

      testWidgets('registration with errors $width $mode', (tester) async {
        final semantics = tester.ensureSemantics();
        await mountScreen(
          tester,
          RegistrationScreen(registration: RegistrationService(fakeApi())),
          theme: theme,
          size: size,
        );
        await tester.enterText(
          find.bySemanticsLabel('Nombre'),
          'Nahuel Agustín',
        );
        await tester.enterText(find.bySemanticsLabel('DNI'), '123');
        for (final field in ['DNI', 'Fecha de nacimiento', 'Contraseña']) {
          await tester.tap(find.bySemanticsLabel(field));
          await tester.pump();
        }
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(RegistrationScreen),
          matchesGoldenFile('registration/errors_${width}_$mode.png'),
        );
        semantics.dispose();
      });

      testWidgets('successful registration $width $mode', (tester) async {
        await mountScreen(
          tester,
          const RegistrationDoneScreen(),
          theme: theme,
          size: size,
        );
        await expectLater(
          find.byType(RegistrationDoneScreen),
          matchesGoldenFile('registration/successful_${width}_$mode.png'),
        );
      });
    }
  }
}
