import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clubnahuelmosse/reservas/pantalla_mis_reservas.dart';

import 'mis_reservas_test.dart' show reservaJson;
import 'soporte/montar.dart';
import 'soporte/usuario.dart';

void main() {
  setUpAll(cargarFuentes);

  Future<void> cumpleLasGuias(WidgetTester tester) async {
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    // Las tarjetas tienen una etiqueta propia y la guía de contraste no ve sus textos: se
    // miden los que están enteros a la vista, arriba de la barra inferior. El texto de un
    // control deshabilitado —una franja ocupada— no tiene piso de contraste (WCAG 1.4.3).
    final pantalla = tester.view.physicalSize / tester.view.devicePixelRatio;
    final aLaVista = Rect.fromLTWH(0, 0, pantalla.width, pantalla.height - 90);
    bool deshabilitado(Element elemento) {
      var si = false;
      elemento.visitAncestorElements((ancestro) {
        final w = ancestro.widget;
        if (w is Semantics && w.properties.enabled == false) si = true;
        return !si;
      });
      return si;
    }

    final visibles = find.byElementPredicate((elemento) {
      final texto = elemento.widget;
      if (texto is! Text || deshabilitado(elemento)) return false;
      // El trazo fino de JetBrains Mono a 13 px sobre la superficie de la tarjeta de reserva
      // sale casi todo antialiasing y la guía lo toma como el color del texto: mide 1,5:1
      // hasta con textPrimary. Ese color se verifica en paleta_test.dart.
      if (texto.style?.fontFamily == 'JetBrains Mono' &&
          elemento.findAncestorWidgetOfExactType<TarjetaReserva>() != null) {
        return false;
      }
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
        inicio: '/sedes/00000000-0000-7000-8000-000000000001',
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
        inicio: '/sedes/00000000-0000-7000-8000-000000000001/canchas/00000000-0000-7000-8000-000000000009',
        api: apiRutas(rutasDeSedes()),
      );
      await cumpleLasGuias(tester);
      semantica.dispose();
    });

    testWidgets('la consulta de canchas cumple las guías en modo $modo', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await montarUsuario(
        tester,
        oscuro: oscuro,
        inicio: '/inicio/buscar',
        api: apiRutas(rutasDeSedes()),
      );
      await cumpleLasGuias(tester);
      semantica.dispose();
    });

    testWidgets('el inicio con sus accesos cumple las guías en modo $modo', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await montarUsuario(
        tester,
        oscuro: oscuro,
        inicio: '/inicio',
        api: apiRutas({
          ...rutasDeSedes(),
          'GET /reservas': (200, '{"reservas": [${reservaJson()}]}'),
        }),
      );
      await cumpleLasGuias(tester);
      semantica.dispose();
    });

    testWidgets('mis reservas cumple las guías en modo $modo', (tester) async {
      final semantica = tester.ensureSemantics();
      await montarUsuario(
        tester,
        oscuro: oscuro,
        inicio: '/reservas',
        api: apiRutas({
          ...rutasDeSedes(),
          'GET /reservas': (200, '{"reservas": [${reservaJson()}]}'),
        }),
      );
      await conFotos(tester);
      await cumpleLasGuias(tester);
      semantica.dispose();
    });
  }
}
