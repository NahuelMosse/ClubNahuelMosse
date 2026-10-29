import 'dart:async';

import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:clubnahuelmosse/app.dart';
import 'package:clubnahuelmosse/common/appearance.dart';
import 'package:clubnahuelmosse/common/button.dart';
import 'package:clubnahuelmosse/common/loading_screen.dart';
import 'package:clubnahuelmosse/common/skeleton.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'soporte/montar.dart';

/// Una API que nunca contesta: la pantalla se queda cargando.
ApiClient _apiColgada() => ApiClient(
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
      session: SesionFalsa(admin ? perfilAdmin : perfilUsuario),
      appearance: Appearance.inMemory(dark: oscuro),
      initialLocation: inicio,
    ),
  );
  await tester.pump();
  await tester.pump();
}

Future<void> _forma(
  WidgetTester tester,
  SkeletonShape forma, {
  ThemeData? tema,
}) => tester.pumpWidget(
  MaterialApp(
    theme: tema ?? darkTheme,
    home: Scaffold(body: SkeletonList(shape: forma)),
  ),
);

void main() {
  group('esqueletos de carga', () {
    for (final (ruta, admin) in [
      ('/venues', false),
      ('/bookings', false),
      ('/inicio', false),
      ('/admin/sedes', true),
    ]) {
      testWidgets(
        'cada pantalla que carga muestra skeletons con la forma de su contenido y no un spinner @VIS-02-S1 @assumption:VIS-02-ASM-02 $ruta',
        (tester) async {
          await _cargando(tester, inicio: ruta, admin: admin);
          expect(find.byType(Skeleton), findsWidgets);
          expect(find.byType(CircularProgressIndicator), findsNothing);
        },
      );
    }

    for (final forma in SkeletonShape.values) {
      for (final tema in [darkTheme, lightTheme]) {
        testWidgets(
          'cada pantalla que carga muestra skeletons con la forma de su contenido y no un spinner @VIS-02-S1 forma ${forma.name} ${tema.brightness.name}',
          (tester) async {
            await _forma(tester, forma, tema: tema);
            expect(find.byType(Skeleton), findsWidgets);
            expect(find.byType(CircularProgressIndicator), findsNothing);
            final bloque = tester.widget<Skeleton>(find.byType(Skeleton).first);
            expect(bloque.height, greaterThan(0));
          },
        );
      }
    }

    testWidgets(
      'el brillo se detiene con reducir movimiento y el lector anuncia Cargando una vez @VIS-02-S2',
      (tester) async {
        final semantica = tester.ensureSemantics();
        await _forma(tester, SkeletonShape.booking);
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.hasRunningAnimations, isTrue);
        expect(find.bySemanticsLabel('Cargando'), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp('.+')), findsOneWidget);

        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        await _forma(tester, SkeletonShape.notice);
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.hasRunningAnimations, isFalse);
        expect(find.byType(Skeleton), findsWidgets);
        expect(find.bySemanticsLabel('Cargando'), findsOneWidget);
        semantica.dispose();
      },
    );

    testWidgets(
      'los spinners de botones y la espera de arranque siguen igual @assumption:VIS-02-ASM-01',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: darkTheme,
            home: Scaffold(
              body: PrimaryButton(label: 'ENVIAR', onTap: () {}, loading: true),
            ),
          ),
        );
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        await tester.pumpWidget(
          MaterialApp(theme: darkTheme, home: const LoadingScreen()),
        );
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );
  });
}
