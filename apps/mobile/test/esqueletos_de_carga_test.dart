import 'dart:async';

import 'package:clubnahuelmosse/api/cliente_api.dart';
import 'package:clubnahuelmosse/app.dart';
import 'package:clubnahuelmosse/comun/apariencia.dart';
import 'package:clubnahuelmosse/comun/boton.dart';
import 'package:clubnahuelmosse/comun/esqueleto.dart';
import 'package:clubnahuelmosse/comun/pantalla_de_carga.dart';
import 'package:clubnahuelmosse/tema/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'soporte/montar.dart';

/// Una API que nunca contesta: la pantalla se queda cargando.
ClienteApi _apiColgada() => ClienteApi(
  'http://api.falsa',
  cliente: MockClient((_) => Completer<http.Response>().future),
);

Future<void> _cargando(
  WidgetTester tester, {
  required String inicio,
  bool admin = false,
  bool oscuro = true,
}) async {
  tester.view.physicalSize = const Size(393, 852) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    App(
      api: _apiColgada(),
      sesion: SesionFalsa(admin ? perfilAdmin : perfilUsuario),
      apariencia: Apariencia.enMemoria(oscuro: oscuro),
      inicio: inicio,
    ),
  );
  await tester.pump();
  await tester.pump();
}

Future<void> _forma(
  WidgetTester tester,
  FormaDeEsqueleto forma, {
  ThemeData? tema,
}) => tester.pumpWidget(
  MaterialApp(
    theme: tema ?? temaOscuro,
    home: Scaffold(body: EsqueletoDeLista(forma: forma)),
  ),
);

void main() {
  group('esqueletos de carga', () {
    for (final (ruta, admin) in [
      ('/sedes', false),
      ('/reservas', false),
      ('/inicio', false),
      ('/admin/sedes', true),
    ]) {
      testWidgets(
        'cada pantalla que carga muestra skeletons con la forma de su contenido y no un spinner @VIS-02-S1 @assumption:VIS-02-ASM-02 $ruta',
        (tester) async {
          await _cargando(tester, inicio: ruta, admin: admin);
          expect(find.byType(Esqueleto), findsWidgets);
          expect(find.byType(CircularProgressIndicator), findsNothing);
        },
      );
    }

    for (final forma in FormaDeEsqueleto.values) {
      for (final tema in [temaOscuro, temaClaro]) {
        testWidgets(
          'cada pantalla que carga muestra skeletons con la forma de su contenido y no un spinner @VIS-02-S1 forma ${forma.name} ${tema.brightness.name}',
          (tester) async {
            await _forma(tester, forma, tema: tema);
            expect(find.byType(Esqueleto), findsWidgets);
            expect(find.byType(CircularProgressIndicator), findsNothing);
            final bloque = tester.widget<Esqueleto>(
              find.byType(Esqueleto).first,
            );
            expect(bloque.alto, greaterThan(0));
          },
        );
      }
    }

    testWidgets(
      'el brillo se detiene con reducir movimiento y el lector anuncia Cargando una vez @VIS-02-S2',
      (tester) async {
        final semantica = tester.ensureSemantics();
        await _forma(tester, FormaDeEsqueleto.reserva);
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.hasRunningAnimations, isTrue);
        expect(find.bySemanticsLabel('Cargando'), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp('.+')), findsOneWidget);

        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        await _forma(tester, FormaDeEsqueleto.aviso);
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.hasRunningAnimations, isFalse);
        expect(find.byType(Esqueleto), findsWidgets);
        expect(find.bySemanticsLabel('Cargando'), findsOneWidget);
        semantica.dispose();
      },
    );

    testWidgets(
      'los spinners de botones y la espera de arranque siguen igual @assumption:VIS-02-ASM-01',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: temaOscuro,
            home: Scaffold(
              body: BotonPrimario(
                texto: 'ENVIAR',
                alTocar: () {},
                cargando: true,
              ),
            ),
          ),
        );
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        await tester.pumpWidget(
          MaterialApp(theme: temaOscuro, home: const PantallaDeCarga()),
        );
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );
  });
}
