import 'package:clubnahuelmosse/common/selectable_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../soporte/held_api.dart';
import '../soporte/montar.dart';
import '../soporte/skeleton_capture.dart';
import '../soporte/usuario.dart';

const _moron = '00000000-0000-7000-8000-000000000001';

/// Asserts nothing: it produces each loading state of the venues screens next to the same
/// screen loaded, dark, 393x852.
void main() {
  Future<HeldApi> mount(WidgetTester tester, String route) async {
    final held = HeldApi(rutasDeSedes());
    await mountApp(
      tester,
      api: held.client,
      session: SesionFalsa(perfilUsuario),
      route: route,
    );
    return held;
  }

  testWidgets('venues loading and loaded', (tester) async {
    final held = await mount(tester, '/venues');
    await _capture(tester, 'skeletons/sedes_cargando.png');
    held.release();
    await tester.pumpAndSettle();
    await _capture(tester, 'skeletons/sedes_cargada.png');
    await drainApp(tester);
  });

  testWidgets('venue loading and loaded', (tester) async {
    final held = await mount(tester, '/venues/$_moron');
    await _capture(tester, 'skeletons/sede_cargando.png');
    held.release();
    await tester.pumpAndSettle();
    await _capture(tester, 'skeletons/sede_cargada.png');
    await drainApp(tester);
  });

  testWidgets('venue filtering and filtered', (tester) async {
    final held = await mount(tester, '/venues/$_moron');
    held.release();
    await tester.pumpAndSettle();
    held.holdAgain();
    await tester.tap(find.byType(SelectableChip).first);
    await tester.pump();
    await tester.pump();
    await _capture(tester, 'skeletons/sede_filtrando.png');
    held.release();
    await tester.pumpAndSettle();
    await _capture(tester, 'skeletons/sede_filtrada.png');
    await drainApp(tester);
  });
}

Future<void> _capture(WidgetTester tester, String file) async {
  await decodeImages(tester);
  await expectLater(find.byType(MaterialApp), matchesGoldenFile(file));
}
