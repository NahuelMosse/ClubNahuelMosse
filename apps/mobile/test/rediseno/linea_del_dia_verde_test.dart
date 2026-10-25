import 'package:clubnahuelmosse/comun/linea_del_dia.dart';
import 'package:clubnahuelmosse/tema/tema.dart';
import 'package:clubnahuelmosse/tema/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../soporte/montar.dart';

const _franjas = [
  EstadoFranja.libre,
  EstadoFranja.libre,
  EstadoFranja.ocupada,
  EstadoFranja.elegida,
];

void main() {
  testWidgets(
    'libre es accentLibre, ocupado stateDisabled y elegido accentInk @RED-02-ASM-02 @RED-05-S2',
    (tester) async {
      for (final (tema, p) in [
        (temaOscuro, Paleta.oscura),
        (temaClaro, Paleta.clara),
      ]) {
        await montar(
          tester,
          const Scaffold(
            body: Center(child: LineaDelDia(franjas: _franjas, desde: 8)),
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

        expect(franja('08'), p.accentLibre);
        expect(franja('10'), p.stateDisabled);
        expect(franja('11'), p.accentInk);
        expect(leyenda('Libre'), p.accentLibre);
        expect(leyenda('Ocupado'), p.stateDisabled);
        expect(leyenda('Elegido'), p.accentInk);
      }
    },
  );
}
