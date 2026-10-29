import 'package:clubnahuelmosse/app.dart';
import 'package:clubnahuelmosse/common/appearance.dart';
import 'package:clubnahuelmosse/common/selectable_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../soporte/held_api.dart';
import '../soporte/montar.dart';
import '../soporte/usuario.dart';

const _moron = '00000000-0000-7000-8000-000000000001';

/// Asserts nothing: it produces each loading state of the venues screens next to the same
/// screen loaded, dark, 393x852.
void main() {
  Future<HeldApi> mount(WidgetTester tester, String route) async {
    tester.view.physicalSize = const Size(393, 852) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await cargarFuentes();
    final held = HeldApi(rutasDeSedes());
    await tester.pumpWidget(
      App(
        api: held.client,
        session: SesionFalsa(perfilUsuario),
        appearance: Appearance.inMemory(dark: true),
        initialLocation: route,
      ),
    );
    await tester.pump();
    await tester.pump();
    return held;
  }

  Future<void> capture(WidgetTester tester, String file) async {
    await tester.runAsync(() async {
      for (final element in find.byType(Image).evaluate()) {
        final image = element.widget;
        if (image is Image) await precacheImage(image.image, element);
      }
    });
    await tester.pump();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile(file));
  }

  Future<void> drain(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 2));
  }

  testWidgets('venues loading and loaded', (tester) async {
    final held = await mount(tester, '/sedes');
    await capture(tester, 'skeletons/sedes_cargando.png');
    held.release();
    await tester.pumpAndSettle();
    await capture(tester, 'skeletons/sedes_cargada.png');
    await drain(tester);
  });

  testWidgets('venue loading and loaded', (tester) async {
    final held = await mount(tester, '/sedes/$_moron');
    await capture(tester, 'skeletons/sede_cargando.png');
    held.release();
    await tester.pumpAndSettle();
    await capture(tester, 'skeletons/sede_cargada.png');
    await drain(tester);
  });

  testWidgets('venue filtering and filtered', (tester) async {
    final held = await mount(tester, '/sedes/$_moron');
    held.release();
    await tester.pumpAndSettle();
    held.holdAgain();
    await tester.tap(find.byType(SelectableChip).first);
    await tester.pump();
    await tester.pump();
    await capture(tester, 'skeletons/sede_filtrando.png');
    held.release();
    await tester.pumpAndSettle();
    await capture(tester, 'skeletons/sede_filtrada.png');
    await drain(tester);
  });
}
