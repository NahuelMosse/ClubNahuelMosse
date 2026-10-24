import 'package:clubnahuelmosse/comun/dorsal.dart';
import 'package:clubnahuelmosse/sedes/pantalla_sedes.dart';
import 'package:clubnahuelmosse/tema/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide testWidgets;

import '../soporte/montar.dart';
import '../soporte/reloj_fijo.dart';
import '../soporte/usuario.dart';

void main() {
  testWidgets(
    'la cantidad de canchas de la tarjeta de sede es el dorsal con el rótulo CANCHAS, sin el bloque violeta @RED-03-ASM-14',
    (tester) async {
      await montarUsuario(
        tester,
        tamano: const Size(393, 1400),
        api: apiRutas(rutasDeSedes(sedes: '[$sedeMoronConDeportes]')),
      );

      final tarjeta = find.byType(TarjetaSede);
      expect(tarjeta, findsOneWidget);
      final dorsal = find.descendant(
        of: tarjeta,
        matching: find.byType(DorsalGigante),
      );
      expect(
        tester.widget<DorsalGigante>(dorsal).color,
        Paleta.oscura.textOnMedia,
      );
      final rotulo = find.descendant(
        of: tarjeta,
        matching: find.text('CANCHAS'),
      );
      expect(rotulo, findsOneWidget);
      expect(
        tester.getTopLeft(rotulo).dy,
        greaterThan(tester.getTopLeft(dorsal).dy),
      );
      final violetas = tester
          .widgetList<Container>(
            find.descendant(of: tarjeta, matching: find.byType(Container)),
          )
          .map((c) => c.decoration)
          .whereType<BoxDecoration>()
          .where((d) => d.color == Paleta.oscura.accentBase);
      expect(violetas, isEmpty);
    },
  );
}
