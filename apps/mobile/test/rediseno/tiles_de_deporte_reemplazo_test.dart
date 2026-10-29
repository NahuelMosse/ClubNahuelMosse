import 'package:clubnahuelmosse/common/sport_tile.dart';
import 'package:clubnahuelmosse/features/bookings/presentation/space_search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide testWidgets;

import '../soporte/montar.dart';
import '../soporte/reloj_fijo.dart';
import '../soporte/usuario.dart';

void main() {
  testWidgets(
    'los tiles usan las fotos de la app, ninguno está elegido y tocar uno abre «Buscar cancha» con ese deporte @RED-03-ASM-03',
    (tester) async {
      final semantica = tester.ensureSemantics();
      await montarUsuario(
        tester,
        api: apiRutas({
          ...rutasDeSedes(),
          'GET /bookings': (200, '{"bookings": []}'),
        }),
        inicio: '/inicio',
        tamano: const Size(393, 1400),
      );

      final tiles = tester.widgetList<SportTile>(find.byType(SportTile));
      expect(tiles, isNotEmpty);
      for (final tile in tiles) {
        expect(tile.onTap, isNotNull, reason: tile.name);
        expect(tile.selected, isFalse, reason: tile.name);
      }
      expect(find.text('ELEGIDO'), findsNothing);
      final nodo = tester.getSemantics(find.bySemanticsLabel('Tenis'));
      expect(nodo.flagsCollection.isButton, isTrue);

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
      semantica.dispose();
    },
  );
}
