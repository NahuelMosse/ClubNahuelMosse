import 'package:clubnahuelmosse/features/users/data/registration_service.dart';
import 'package:clubnahuelmosse/features/users/presentation/registration_done_screen.dart';
import 'package:clubnahuelmosse/features/users/presentation/registration_screen.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:clubnahuelmosse/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/mount.dart';

void main() {
  final themes = {'dark': darkTheme, 'light': lightTheme};

  for (final MapEntry(key: mode, value: theme) in themes.entries) {
    testWidgets(
      'the registration meets the accessibility guidelines in $mode mode',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await mountScreen(
          tester,
          RegistrationScreen(registration: RegistrationService(fakeApi())),
          theme: theme,
        );
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        semantics.dispose();
      },
    );

    testWidgets(
      'the success screen meets the accessibility guidelines in $mode mode',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await mountScreen(tester, const RegistrationDoneScreen(), theme: theme);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        semantics.dispose();
      },
    );
  }

  testWidgets(
    'each field announces its name and the form says everything is required',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await mountScreen(
        tester,
        RegistrationScreen(registration: RegistrationService(fakeApi())),
        theme: darkTheme,
      );
      for (final field in [
        'Nombre',
        'Apellido',
        'DNI',
        'Fecha de nacimiento',
        'Correo electrónico',
        'Contraseña',
      ]) {
        expect(find.bySemanticsLabel(field), findsOneWidget, reason: field);
      }
      expect(find.text('Todos los campos son obligatorios.'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets('with text at 200 % nothing overflows', (tester) async {
    await mountScreen(
      tester,
      RegistrationScreen(registration: RegistrationService(fakeApi())),
      theme: darkTheme,
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    await mountScreen(
      tester,
      const RegistrationDoneScreen(),
      theme: darkTheme,
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });

  group('contrast of the theme ink and canvas pairs', () {
    double luminance(Color c) => c.computeLuminance();
    double contrast(Color a, Color b) {
      final (light, dark) = luminance(a) > luminance(b) ? (a, b) : (b, a);
      return (luminance(light) + 0.05) / (luminance(dark) + 0.05);
    }

    for (final MapEntry(key: mode, value: p) in {
      'dark': Palette.dark,
      'light': Palette.light,
    }.entries) {
      test('$mode mode', () {
        final pairs = {
          'primary text on the background': (p.textPrimary, p.bgBase),
          'secondary text on the background': (p.textSecondary, p.bgBase),
          'secondary text on the surface': (p.textSecondary, p.bgSurface),
          'muted text on the surface': (p.textMuted, p.bgSurface),
          'button text on the lime': (p.accentOn, p.accentBase),
          'accent ink on the background': (p.accentInk, p.bgBase),
          'error on the background': (p.stateDangerInk, p.bgBase),
        };
        for (final MapEntry(key: pair, value: (ink, canvas)) in pairs.entries) {
          expect(
            contrast(ink, canvas),
            greaterThanOrEqualTo(4.5),
            reason: pair,
          );
        }
      });
    }
  });
}
