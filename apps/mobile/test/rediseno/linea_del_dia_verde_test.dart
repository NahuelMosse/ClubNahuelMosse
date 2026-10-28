import 'package:clubnahuelmosse/common/day_timeline.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:clubnahuelmosse/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../soporte/montar.dart';

const _franjas = [
  SlotState.free,
  SlotState.free,
  SlotState.taken,
  SlotState.chosen,
];

void main() {
  testWidgets(
    'libre es accentLibre, ocupado stateDisabled y elegido accentInk @RED-02-ASM-02 @RED-05-S2',
    (tester) async {
      for (final (tema, p) in [
        (darkTheme, Palette.dark),
        (lightTheme, Palette.light),
      ]) {
        await montar(
          tester,
          const Scaffold(
            body: Center(child: DayTimeline(slots: _franjas, from: 8)),
          ),
          tema: tema,
        );

        Color? franja(String hora) =>
            (tester
                        .widget<DecoratedBox>(
                          find.descendant(
                            of: find.byKey(ValueKey('franja-$hora')),
                            matching: find.byType(DecoratedBox),
                          ),
                        )
                        .decoration
                    as BoxDecoration)
                .color;

        Color? leyenda(String texto) =>
            (tester
                        .widget<DecoratedBox>(
                          find.descendant(
                            of: find.ancestor(
                              of: find.text(texto),
                              matching: find.byType(Row),
                            ),
                            matching: find.byType(DecoratedBox),
                          ),
                        )
                        .decoration
                    as BoxDecoration)
                .color;

        expect(franja('08'), p.accentFree);
        expect(franja('10'), p.stateDisabled);
        expect(franja('11'), p.accentInk);
        expect(leyenda('Libre'), p.accentFree);
        expect(leyenda('Ocupado'), p.stateDisabled);
        expect(leyenda('Elegido'), p.accentInk);
      }
    },
  );
}
