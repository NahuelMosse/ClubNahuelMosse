import 'package:clubnahuelmosse/common/sport_tile.dart';
import 'package:clubnahuelmosse/features/bookings/presentation/space_search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide testWidgets;

import '../support/mount.dart';
import '../support/fixed_clock.dart';
import '../support/user.dart';

void main() {
  testWidgets(
    'the tiles use the app photos, none is selected and tapping one opens «Buscar cancha» with that sport @RED-03-ASM-03',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await mountUser(
        tester,
        api: apiRoutes({
          ...venueRoutes(),
          'GET /bookings': (200, '{"bookings": []}'),
        }),
        start: '/inicio',
        size: const Size(393, 1400),
      );

      final tiles = tester.widgetList<SportTile>(find.byType(SportTile));
      expect(tiles, isNotEmpty);
      for (final tile in tiles) {
        expect(tile.onTap, isNotNull, reason: tile.name);
        expect(tile.selected, isFalse, reason: tile.name);
      }
      expect(find.text('ELEGIDO'), findsNothing);
      final node = tester.getSemantics(find.bySemanticsLabel('Tenis'));
      expect(node.flagsCollection.isButton, isTrue);

      await tester.tap(
        find.ancestor(of: find.text('Tenis'), matching: find.byType(SportTile)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SpaceSearchScreen), findsOneWidget);
      expect(
        tester
            .widget<SpaceSearchScreen>(find.byType(SpaceSearchScreen))
            .deporte,
        'Tenis',
      );
      expect(find.text('Tenis'), findsOneWidget);
      semantics.dispose();
    },
  );
}
