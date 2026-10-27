import 'package:clubnahuelmosse/notificaciones/campana.dart';
import 'package:clubnahuelmosse/tema/tema.dart';
import 'package:clubnahuelmosse/tema/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'notificaciones_test.dart' show ApiFalsa, centroDe;
import 'soporte/montar.dart';
import 'soporte/usuario.dart';

Future<void> _montarCampana(
  WidgetTester tester, {
  required ThemeData tema,
  int noLeidas = 0,
}) async {
  final api = ApiFalsa()
    ..avisos = []
    ..noLeidas = noLeidas;
  final centro = centroDe(api, SesionFalsa(perfilUsuario));
  await montar(
    tester,
    Material(child: BotonNotificaciones(centro: centro)),
    tema: tema,
  );
  await tester.pumpAndSettle();
}

Color _colorDelIcono(WidgetTester tester) => tester
    .widget<Icon>(find.byIcon(Icons.notifications_none_rounded))
    .color!;

void main() {
  testWidgets(
    'en modo claro y oscuro la campana de la portada se pinta con el color sobre foto @NOT-04-S1',
    (tester) async {
      await _montarCampana(tester, tema: temaClaro);
      expect(_colorDelIcono(tester), Paleta.clara.textOnMedia);

      await _montarCampana(tester, tema: temaOscuro);
      expect(_colorDelIcono(tester), Paleta.oscura.textOnMedia);
    },
  );

  testWidgets(
    'con avisos sin leer el contador sigue en el acento @assumption:NOT-04-ASM-01',
    (tester) async {
      await _montarCampana(tester, tema: temaClaro, noLeidas: 2);

      final contador = tester.widget<Container>(
        find.ancestor(of: find.text('2'), matching: find.byType(Container)),
      );
      final decoracion = contador.decoration! as BoxDecoration;
      expect(decoracion.color, Paleta.clara.accentBase);
    },
  );
}
