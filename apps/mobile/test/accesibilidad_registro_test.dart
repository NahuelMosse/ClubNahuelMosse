import 'package:clubnahuelmosse/tema/tema.dart';
import 'package:clubnahuelmosse/tema/tokens.dart';
import 'package:clubnahuelmosse/usuarios/pantalla_registro.dart';
import 'package:clubnahuelmosse/usuarios/pantalla_registro_exitoso.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/montar.dart';

void main() {
  final temas = {'oscuro': temaOscuro, 'claro': temaClaro};

  for (final MapEntry(key: modo, value: tema) in temas.entries) {
    testWidgets('el registro cumple las guías de accesibilidad en modo $modo', (tester) async {
      final semantica = tester.ensureSemantics();
      await montar(tester, PantallaRegistro(api: apiFalsa()), tema: tema);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      semantica.dispose();
    });

    testWidgets('el éxito cumple las guías de accesibilidad en modo $modo', (tester) async {
      final semantica = tester.ensureSemantics();
      await montar(tester, const PantallaRegistroExitoso(), tema: tema);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      semantica.dispose();
    });
  }

  testWidgets('cada campo anuncia su nombre y el formulario avisa que todo es obligatorio',
      (tester) async {
    final semantica = tester.ensureSemantics();
    await montar(tester, PantallaRegistro(api: apiFalsa()), tema: temaOscuro);
    for (final campo in [
      'Nombre',
      'Apellido',
      'DNI',
      'Fecha de nacimiento',
      'Correo electrónico',
      'Contraseña',
    ]) {
      expect(find.bySemanticsLabel(campo), findsOneWidget, reason: campo);
    }
    expect(find.text('Todos los campos son obligatorios.'), findsOneWidget);
    semantica.dispose();
  });

  testWidgets('con el texto al 200 % nada se desborda', (tester) async {
    await montar(tester, PantallaRegistro(api: apiFalsa()), tema: temaOscuro, escalaTexto: 2);
    expect(tester.takeException(), isNull);
    await montar(tester, const PantallaRegistroExitoso(), tema: temaOscuro, escalaTexto: 2);
    expect(tester.takeException(), isNull);
  });

  group('contraste de los pares tinta y lienzo del tema', () {
    double luminancia(Color c) => c.computeLuminance();
    double contraste(Color a, Color b) {
      final (claro, oscuro) = luminancia(a) > luminancia(b) ? (a, b) : (b, a);
      return (luminancia(claro) + 0.05) / (luminancia(oscuro) + 0.05);
    }

    for (final MapEntry(key: modo, value: p) in {
      'oscuro': Paleta.oscura,
      'claro': Paleta.clara,
    }.entries) {
      test('modo $modo', () {
        final pares = {
          'texto principal sobre el fondo': (p.textPrimary, p.bgBase),
          'texto secundario sobre el fondo': (p.textSecondary, p.bgBase),
          'texto secundario sobre la superficie': (p.textSecondary, p.bgSurface),
          'texto apagado sobre la superficie': (p.textMuted, p.bgSurface),
          'texto del botón sobre el lima': (p.accentOn, p.accentBase),
          'tinta del acento sobre el fondo': (p.accentInk, p.bgBase),
          'error sobre el fondo': (p.stateDangerInk, p.bgBase),
        };
        for (final MapEntry(key: par, value: (tinta, lienzo)) in pares.entries) {
          expect(contraste(tinta, lienzo), greaterThanOrEqualTo(4.5), reason: par);
        }
      });
    }
  });
}
