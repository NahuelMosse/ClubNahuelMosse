import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/montar.dart';
import 'soporte/usuario.dart';

void main() {
  setUpAll(cargarFuentes);

  Future<void> cumpleLasGuias(WidgetTester tester) async {
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    // Las tarjetas tienen una etiqueta propia y la guía de contraste no ve sus textos: se
    // miden los que están enteros a la vista, arriba de la barra inferior.
    final pantalla = tester.view.physicalSize / tester.view.devicePixelRatio;
    final aLaVista = Rect.fromLTWH(0, 0, pantalla.width, pantalla.height - 90);
    final visibles = find.byElementPredicate((elemento) {
      if (elemento.widget is! Text) return false;
      final caja = elemento.renderObject;
      if (caja is! RenderBox || !caja.hasSize) return false;
      final lugar = caja.localToGlobal(Offset.zero) & caja.size;
      return aLaVista.contains(lugar.topLeft) &&
          aLaVista.contains(lugar.bottomRight);
    });
    await expectLater(
      tester,
      meetsGuideline(CustomMinimumContrastGuideline(finder: visibles)),
    );
  }

  /// Las fotos se decodifican fuera del reloj falso del test.
  Future<void> conFotos(WidgetTester tester) async {
    await tester.runAsync(() async {
      for (final elemento in find.byType(Image).evaluate()) {
        final imagen = elemento.widget;
        if (imagen is Image) await precacheImage(imagen.image, elemento);
      }
    });
    await tester.pumpAndSettle();
  }

  for (final oscuro in [true, false]) {
    final modo = oscuro ? 'oscuro' : 'claro';

    testWidgets('todas las sedes cumple las guías en modo $modo', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await montarUsuario(
        tester,
        oscuro: oscuro,
        api: apiRutas(rutasDeSedes()),
      );
      await conFotos(tester);
      await cumpleLasGuias(tester);
      semantica.dispose();
    });

    testWidgets('una sede con canchas cumple las guías en modo $modo', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await montarUsuario(
        tester,
        oscuro: oscuro,
        inicio: '/sedes/1',
        api: apiRutas(rutasDeSedes()),
      );
      await conFotos(tester);
      await cumpleLasGuias(tester);
      semantica.dispose();
    });

    testWidgets('los horarios de una cancha cumplen las guías en modo $modo', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await montarUsuario(
        tester,
        oscuro: oscuro,
        inicio: '/sedes/1/canchas/9',
        api: apiRutas(rutasDeSedes()),
      );
      await cumpleLasGuias(tester);
      semantica.dispose();
    });
  }
}
