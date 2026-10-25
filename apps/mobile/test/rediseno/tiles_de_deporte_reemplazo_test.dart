import 'package:clubnahuelmosse/comun/tile_deporte.dart';
import 'package:clubnahuelmosse/reservas/pantalla_buscar_cancha.dart';
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
          'GET /reservas': (200, '{"reservas": []}'),
        }),
        inicio: '/inicio',
        tamano: const Size(393, 1400),
      );

      final tiles = tester.widgetList<TileDeporte>(find.byType(TileDeporte));
      expect(tiles, isNotEmpty);
      for (final tile in tiles) {
        expect(tile.alTocar, isNotNull, reason: tile.nombre);
        expect(tile.elegido, isFalse, reason: tile.nombre);
      }
      expect(find.text('ELEGIDO'), findsNothing);
      final nodo = tester.getSemantics(find.bySemanticsLabel('Tenis'));
      expect(nodo.flagsCollection.isButton, isTrue);

      await tester.tap(
        find.ancestor(
          of: find.text('Tenis'),
          matching: find.byType(TileDeporte),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PantallaBuscarCancha), findsOneWidget);
      expect(
        tester
            .widget<PantallaBuscarCancha>(find.byType(PantallaBuscarCancha))
            .deporte,
        'Tenis',
      );
      expect(find.text('Tenis'), findsOneWidget);
      semantica.dispose();
    },
  );
}
