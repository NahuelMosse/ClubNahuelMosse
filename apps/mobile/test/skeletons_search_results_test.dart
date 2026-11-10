import 'package:clubnahuelmosse/common/button.dart';
import 'package:clubnahuelmosse/common/selector.dart';
import 'package:clubnahuelmosse/features/venues/presentation/space_card.dart';
import 'package:clubnahuelmosse/features/venues/presentation/space_card_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/admin.dart';
import 'support/held_api.dart';
import 'support/mount.dart';
import 'support/skeleton_capture.dart';
import 'support/user.dart';

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
        ...venueRoutes(spaces: '[$spaceF5Json, $f5CoveredJson]'),
        'GET /spaces/available': (
          200,
          '{"spaces": [$spaceF5Json, $f5CoveredJson]}',
        ),
      });
      await mountApp(
        tester,
        api: held.client,
        session: FakeSession(userProfile),
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
