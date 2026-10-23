import 'package:clubnahuelmosse/tema/tema.dart';
import 'package:clubnahuelmosse/usuarios/pantalla_registro.dart';
import 'package:clubnahuelmosse/usuarios/pantalla_registro_exitoso.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide testWidgets;

import '../soporte/montar.dart';
import '../soporte/reloj_fijo.dart';

/// No afirma nada: produce la tira del paso 9 para mirarla contra el prototipo.
void main() {
  setUpAll(cargarFuentes);

  const telefonos = {'360': Size(360, 800), '430': Size(430, 932)};
  final temas = {'oscuro': temaOscuro, 'claro': temaClaro};

  for (final MapEntry(key: ancho, value: tamano) in telefonos.entries) {
    for (final MapEntry(key: modo, value: tema) in temas.entries) {
      testWidgets('registro vacío $ancho $modo', (tester) async {
        await montar(
          tester,
          PantallaRegistro(api: apiFalsa()),
          tema: tema,
          tamano: tamano,
        );
        await expectLater(
          find.byType(PantallaRegistro),
          matchesGoldenFile('registro/vacio_${ancho}_$modo.png'),
        );
      });

      testWidgets('registro con errores $ancho $modo', (tester) async {
        final semantica = tester.ensureSemantics();
        await montar(
          tester,
          PantallaRegistro(api: apiFalsa()),
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
          find.byType(PantallaRegistro),
          matchesGoldenFile('registro/errores_${ancho}_$modo.png'),
        );
        semantica.dispose();
      });

      testWidgets('registro exitoso $ancho $modo', (tester) async {
        await montar(
          tester,
          const PantallaRegistroExitoso(),
          tema: tema,
          tamano: tamano,
        );
        await expectLater(
          find.byType(PantallaRegistroExitoso),
          matchesGoldenFile('registro/exitoso_${ancho}_$modo.png'),
        );
      });
    }
  }
}
