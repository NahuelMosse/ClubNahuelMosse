import 'dart:convert';

import 'package:clubnahuelmosse/comun/movimiento.dart';
import 'package:clubnahuelmosse/comun/tile_deporte.dart';
import 'package:clubnahuelmosse/notificaciones/panel_avisos.dart';
import 'package:clubnahuelmosse/reservas/pantalla_reserva_confirmada.dart';
import 'package:clubnahuelmosse/reservas/reservas.dart';
import 'package:clubnahuelmosse/tema/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../mis_reservas_test.dart' show reservaJson;
import '../notificaciones_test.dart'
    show ApiFalsa, ahoraClub, centroDe, recordatorio;
import '../soporte/montar.dart';

final _uno = closeTo(1, 1e-6);

Future<void> _montarLibre(WidgetTester tester, Widget pantalla) async {
  tester.view.physicalSize = const Size(393, 852) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: temaOscuro,
      locale: const Locale('es', 'AR'),
      supportedLocales: const [Locale('es', 'AR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: pantalla,
    ),
  );
}

Future<void> _desmontar(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
}

void _reducirMovimiento(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

Future<void> _hastaQue(WidgetTester tester, bool Function() condicion) async {
  for (var i = 0; i < 20 && !condicion(); i++) {
    await tester.pump();
  }
  expect(condicion(), isTrue);
}

double _opacidad(WidgetTester tester, Finder aparecer) => tester
    .widget<FadeTransition>(
      find
          .descendant(of: aparecer, matching: find.byType(FadeTransition))
          .first,
    )
    .opacity
    .value;

double _visibilidad(WidgetTester tester, Finder f) {
  if (f.evaluate().isEmpty) return 0;
  var visible = 1.0;
  for (final fundido in tester.widgetList<FadeTransition>(
    find.ancestor(of: f, matching: find.byType(FadeTransition)),
  )) {
    visible *= fundido.opacity.value;
  }
  return visible;
}

bool _todasEnSuFinal(WidgetTester tester) {
  final cuantas = find.byType(Aparecer).evaluate().length;
  return cuantas > 0 &&
      [
        for (var i = 0; i < cuantas; i++)
          _opacidad(tester, find.byType(Aparecer).at(i)),
      ].every((o) => o == 1);
}

double _ancho(WidgetTester tester, Finder f) =>
    tester.getBottomRight(f).dx - tester.getTopLeft(f).dx;

Reserva _reservaConfirmada() {
  final reserva = Reserva.desdeJson(jsonDecode(reservaJson()));
  if (reserva == null) fail('la reserva de prueba no se lee');
  return reserva;
}

void main() {
  setUpAll(cargarFuentes);

  testWidgets(
    'con reducir movimiento el festejo, el aviso y la entrada muestran su final en el primer cuadro @RED-04-S14',
    (tester) async {
      _reducirMovimiento(tester);

      // El festejo.
      await _montarLibre(
        tester,
        PantallaReservaConfirmada(reserva: _reservaConfirmada()),
      );
      final titulo = find.text('¡Reserva confirmada!');
      final comprobante = find.text('Horario');
      expect(find.byType(Festejo), findsOneWidget);
      final ancho = _ancho(tester, titulo);
      expect(_visibilidad(tester, comprobante), _uno);
      // El primer montaje de MaterialApp siempre deja agendado el cuadro de su ruta inicial.
      await tester.pump();
      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.pumpAndSettle();
      expect(_ancho(tester, titulo), closeTo(ancho, 1e-6));
      await _desmontar(tester);

      // El aviso dentro de la app.
      final api = ApiFalsa();
      final sesion = SesionFalsa(perfilUsuario);
      final centro = centroDe(api, sesion);
      await _montarLibre(
        tester,
        Stack(
          children: [
            const Scaffold(body: Center(child: Text('la pantalla de abajo'))),
            PanelDeAvisos(
              centro: centro,
              ahora: () => ahoraClub,
              alAbrir: (_) {},
            ),
          ],
        ),
      );
      api
        ..avisos = [recordatorio]
        ..noLeidas = 1;
      await tester.runAsync(centro.cargar);
      await tester.pump();
      await tester.pump();
      final aviso = find.text('NOTIFICACIONES');
      expect(aviso, findsOneWidget);
      final arriba = tester.getTopLeft(aviso).dy;
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(aviso).dy, closeTo(arriba, 1e-6));
      await _desmontar(tester);

      // La entrada escalonada del inicio.
      await _montarLibre(tester, inicioFalso(SesionFalsa(perfilUsuario)));
      await _hastaQue(
        tester,
        () => find.byType(TileDeporte).evaluate().isNotEmpty,
      );
      expect(_todasEnSuFinal(tester), isTrue);
    },
  );
}
