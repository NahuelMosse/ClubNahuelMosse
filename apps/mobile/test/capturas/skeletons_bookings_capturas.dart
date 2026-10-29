import 'package:clubnahuelmosse/features/bookings/presentation/date_strip.dart';
import 'package:clubnahuelmosse/features/bookings/presentation/selectable_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../mis_reservas_test.dart' show reservaJson;
import '../soporte/admin.dart';
import '../soporte/held_api.dart';
import '../soporte/montar.dart';
import '../soporte/skeleton_capture.dart';
import '../soporte/usuario.dart';

const _moron = '00000000-0000-7000-8000-000000000001';
const _f5 = '00000000-0000-7000-8000-000000000009';

/// Asserts nothing: it produces each loading state of the bookings screens next to the same
/// screen loaded, dark, 393x852.
Future<void> _capture(WidgetTester tester, String file) async {
  await decodeImages(tester);
  await expectLater(find.byType(MaterialApp), matchesGoldenFile(file));
}

void main() {
  Future<HeldApi> mount(
    WidgetTester tester,
    String route, {
    Map<String, (int, String)> extra = const {},
  }) async {
    final held = HeldApi({
      ...rutasDeSedes(espacios: '[$espacioF5Json, $f5TechadaJson]'),
      ...extra,
    });
    await mountApp(
      tester,
      api: held.client,
      session: SesionFalsa(perfilUsuario),
      route: route,
    );
    return held;
  }

  testWidgets('availability loading and loaded', (tester) async {
    final held = await mount(tester, '/sedes/$_moron/canchas/$_f5');
    await _capture(tester, 'skeletons/horarios_cargando.png');
    held.release();
    await tester.pumpAndSettle();
    await _capture(tester, 'skeletons/horarios_cargada.png');
    await drainApp(tester);
  });

  testWidgets('availability changing the day and changed', (tester) async {
    final held = await mount(tester, '/sedes/$_moron/canchas/$_f5');
    held.release();
    await tester.pumpAndSettle();
    held.holdAgain();
    await tester.tap(
      find
          .descendant(
            of: find.byType(DateStrip),
            matching: find.byType(SelectableFrame),
          )
          .at(1),
    );
    await tester.pump();
    await tester.pump();
    await _capture(tester, 'skeletons/horarios_cambiando_dia.png');
    held.release();
    await tester.pumpAndSettle();
    await _capture(tester, 'skeletons/horarios_dia_cambiado.png');
    await drainApp(tester);
  });

  testWidgets('search form loading and loaded', (tester) async {
    final held = await mount(tester, '/inicio/buscar');
    await _capture(tester, 'skeletons/buscar_formulario_cargando.png');
    held.release();
    await tester.pumpAndSettle();
    await _capture(tester, 'skeletons/buscar_formulario_cargado.png');
    await drainApp(tester);
  });

  testWidgets('search results loading and loaded', (tester) async {
    final semantics = tester.ensureSemantics();
    final held = await mount(
      tester,
      '/inicio/buscar',
      extra: {
        'GET /spaces/available': (
          200,
          '{"spaces": [$espacioF5Json, $f5TechadaJson]}',
        ),
      },
    );
    await submitSearch(tester, held);
    await tester.ensureVisible(find.text('LIMPIAR'));
    await _capture(tester, 'skeletons/buscar_resultados_cargando.png');
    held.release();
    await tester.pumpAndSettle();
    await _capture(tester, 'skeletons/buscar_resultados_cargados.png');
    await drainApp(tester);
    semantics.dispose();
  });

  testWidgets('my bookings loading and loaded', (tester) async {
    final second = reservaJson(id: '00000000-0000-7000-8000-000000000002');
    final held = await mount(
      tester,
      '/bookings',
      extra: {
        'GET /bookings': (200, '{"bookings": [${reservaJson()}, $second]}'),
      },
    );
    await _capture(tester, 'skeletons/reservas_cargando.png');
    held.release();
    await tester.pumpAndSettle();
    await _capture(tester, 'skeletons/reservas_cargadas.png');
    await drainApp(tester);
  });
}
