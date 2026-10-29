import 'package:clubnahuelmosse/app.dart';
import 'package:clubnahuelmosse/common/appearance.dart';
import 'package:clubnahuelmosse/common/clock.dart';
import 'package:clubnahuelmosse/features/bookings/presentation/date_strip.dart';
import 'package:clubnahuelmosse/features/bookings/presentation/selectable_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../mis_reservas_test.dart' show reservaJson;
import '../soporte/admin.dart';
import '../soporte/held_api.dart';
import '../soporte/montar.dart';
import '../soporte/usuario.dart';

const _moron = '00000000-0000-7000-8000-000000000001';
const _f5 = '00000000-0000-7000-8000-000000000009';
const _f5Techada =
    '{"id": "00000000-0000-7000-8000-000000000011", "nombre": "Moron_Rivadavia_19850_Futbol_F5_2", "sede_id": "$_moron", '
    '"sede": "Sede Morón", "deporte": "Futbol", "tipo": "F5", "numero": 2, '
    '"techada": true, "iluminada": true, "precio_por_hora": 43000}';

/// Asserts nothing: it produces each loading state of the bookings screens next to the same
/// screen loaded, dark, 393x852.
void main() {
  Future<HeldApi> mount(
    WidgetTester tester,
    String route, {
    Map<String, (int, String)> extra = const {},
  }) async {
    tester.view.physicalSize = const Size(393, 852) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await cargarFuentes();
    final held = HeldApi({
      ...rutasDeSedes(espacios: '[$espacioF5Json, $_f5Techada]'),
      ...extra,
    });
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

  Future<void> choose(WidgetTester tester, String field, String option) async {
    await tester.ensureVisible(find.bySemanticsLabel(field));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(field));
    await tester.pumpAndSettle();
    final button = find.descendant(
      of: find.byType(Dialog),
      matching: find.text(option),
    );
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  String nextWorkingDay() {
    var d = clubNow().add(const Duration(days: 1));
    while (d.weekday == DateTime.sunday) {
      d = d.add(const Duration(days: 1));
    }
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)} / ${two(d.month)} / ${d.year}';
  }

  testWidgets('availability loading and loaded', (tester) async {
    final held = await mount(tester, '/sedes/$_moron/canchas/$_f5');
    await capture(tester, 'skeletons/horarios_cargando.png');
    held.release();
    await tester.pumpAndSettle();
    await capture(tester, 'skeletons/horarios_cargada.png');
    await drain(tester);
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
    await capture(tester, 'skeletons/horarios_cambiando_dia.png');
    held.release();
    await tester.pumpAndSettle();
    await capture(tester, 'skeletons/horarios_dia_cambiado.png');
    await drain(tester);
  });

  testWidgets('search form loading and loaded', (tester) async {
    final held = await mount(tester, '/inicio/buscar');
    await capture(tester, 'skeletons/buscar_formulario_cargando.png');
    held.release();
    await tester.pumpAndSettle();
    await capture(tester, 'skeletons/buscar_formulario_cargado.png');
    await drain(tester);
  });

  testWidgets('search results loading and loaded', (tester) async {
    final semantics = tester.ensureSemantics();
    final held = await mount(
      tester,
      '/inicio/buscar',
      extra: {
        'GET /espacios/disponibles': (
          200,
          '{"espacios": [$espacioF5Json, $_f5Techada]}',
        ),
      },
    );
    held.release();
    await tester.pumpAndSettle();
    await choose(tester, 'Sede', 'Sede Morón');
    await choose(tester, 'Deporte', 'Fútbol');
    await tester.enterText(
      find.descendant(
        of: find.bySemanticsLabel('Fecha'),
        matching: find.byType(EditableText),
      ),
      nextWorkingDay(),
    );
    await tester.pumpAndSettle();
    held.holdAgain();
    await tester.tap(find.text('CONSULTAR'));
    await tester.pump();
    await tester.pump();
    await tester.ensureVisible(find.text('LIMPIAR'));
    await capture(tester, 'skeletons/buscar_resultados_cargando.png');
    held.release();
    await tester.pumpAndSettle();
    await capture(tester, 'skeletons/buscar_resultados_cargados.png');
    await drain(tester);
    semantics.dispose();
  });

  testWidgets('my bookings loading and loaded', (tester) async {
    final second = reservaJson(id: '00000000-0000-7000-8000-000000000002');
    final held = await mount(
      tester,
      '/reservas',
      extra: {
        'GET /reservas': (200, '{"reservas": [${reservaJson()}, $second]}'),
      },
    );
    await capture(tester, 'skeletons/reservas_cargando.png');
    held.release();
    await tester.pumpAndSettle();
    await capture(tester, 'skeletons/reservas_cargadas.png');
    await drain(tester);
  });
}
