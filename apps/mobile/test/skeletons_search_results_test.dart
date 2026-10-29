import 'package:clubnahuelmosse/app.dart';
import 'package:clubnahuelmosse/common/appearance.dart';
import 'package:clubnahuelmosse/common/button.dart';
import 'package:clubnahuelmosse/common/clock.dart';
import 'package:clubnahuelmosse/common/selector.dart';
import 'package:clubnahuelmosse/features/venues/presentation/space_card.dart';
import 'package:clubnahuelmosse/features/venues/presentation/space_card_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/admin.dart';
import 'soporte/held_api.dart';
import 'soporte/montar.dart';
import 'soporte/usuario.dart';

const _moron = '00000000-0000-7000-8000-000000000001';
const _f5Techada =
    '{"id": "00000000-0000-7000-8000-000000000011", "nombre": "Moron_Rivadavia_19850_Futbol_F5_2", "sede_id": "$_moron", '
    '"sede": "Sede Morón", "deporte": "Futbol", "tipo": "F5", "numero": 2, '
    '"techada": true, "iluminada": true, "precio_por_hora": 43000}';

Rect _rect(Finder finder) {
  final box = finder.evaluate().first.renderObject! as RenderBox;
  return box.localToGlobal(Offset.zero) & box.size;
}

Future<void> _choose(WidgetTester tester, String field, String option) async {
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

String _nextWorkingDay() {
  var d = clubNow().add(const Duration(days: 1));
  while (d.weekday == DateTime.sunday) {
    d = d.add(const Duration(days: 1));
  }
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)} / ${two(d.month)} / ${d.year}';
}

void main() {
  testWidgets(
    'Buscar cancha carga los resultados con la forma de su tarjeta @VIS-03-S1',
    (tester) async {
      final semantics = tester.ensureSemantics();
      tester.view.physicalSize = const Size(393, 852) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await cargarFuentes();
      final held = HeldApi({
        ...rutasDeSedes(espacios: '[$espacioF5Json, $_f5Techada]'),
        'GET /espacios/disponibles': (
          200,
          '{"espacios": [$espacioF5Json, $_f5Techada]}',
        ),
      });
      await tester.pumpWidget(
        App(
          api: held.client,
          session: SesionFalsa(perfilUsuario),
          appearance: Appearance.inMemory(dark: true),
          initialLocation: '/inicio/buscar',
        ),
      );
      held.release();
      await tester.pumpAndSettle();
      await _choose(tester, 'Sede', 'Sede Morón');
      await _choose(tester, 'Deporte', 'Fútbol');
      await tester.enterText(
        find.descendant(
          of: find.bySemanticsLabel('Fecha'),
          matching: find.byType(EditableText),
        ),
        _nextWorkingDay(),
      );
      await tester.pumpAndSettle();
      held.holdAgain();
      await tester.tap(find.text('CONSULTAR'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(SpaceCardSkeleton), findsWidgets);
      expect(find.byType(SelectorField), findsWidgets);
      // The only spinner is the CONSULTAR button's own (VIS-03-ASM-02).
      expect(
        find.descendant(
          of: find.byType(PrimaryButton),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final card = _rect(find.byType(SpaceCardSkeleton).first);

      held.release();
      await tester.pumpAndSettle();
      expect(find.byType(SpaceCardSkeleton), findsNothing);
      expectSameBox(card, _rect(find.byType(SpaceCard).first), reason: 'card');
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(minutes: 2));
      semantics.dispose();
    },
  );
}
