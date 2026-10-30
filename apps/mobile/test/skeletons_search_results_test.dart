import 'package:clubnahuelmosse/common/button.dart';
import 'package:clubnahuelmosse/common/selector.dart';
import 'package:clubnahuelmosse/features/venues/presentation/space_card.dart';
import 'package:clubnahuelmosse/features/venues/presentation/space_card_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/admin.dart';
import 'soporte/held_api.dart';
import 'soporte/montar.dart';
import 'soporte/skeleton_capture.dart';
import 'soporte/usuario.dart';

Rect _rect(Finder finder) {
  final box = finder.evaluate().first.renderObject! as RenderBox;
  return box.localToGlobal(Offset.zero) & box.size;
}

void main() {
  testWidgets(
    'Buscar cancha carga los resultados con la forma de su tarjeta @VIS-03-S1',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final held = HeldApi({
        ...rutasDeSedes(espacios: '[$espacioF5Json, $f5TechadaJson]'),
        'GET /spaces/available': (
          200,
          '{"spaces": [$espacioF5Json, $f5TechadaJson]}',
        ),
      });
      await mountApp(
        tester,
        api: held.client,
        session: SesionFalsa(perfilUsuario),
        route: '/inicio/buscar',
        pumps: 0,
      );
      await submitSearch(tester, held);

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
      await drainApp(tester);
      semantics.dispose();
    },
  );
}
