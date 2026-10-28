import 'package:clock/clock.dart';
import 'package:clubnahuelmosse/inicio/saludo_de_inicio.dart';
import 'package:clubnahuelmosse/tema/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/montar.dart';

/// El reloj a [hora]:[minuto] del club (UTC−3) del 27/10/2026.
Clock _relojDelClub(int hora, int minuto) => Clock.fixed(
  DateTime.utc(2026, 10, 27, hora, minuto).add(const Duration(hours: 3)),
);

Future<void> _montarSaludo(WidgetTester tester, {Key? key}) => montar(
  tester,
  Scaffold(
    body: SaludoDeInicio(key: key, sesion: SesionFalsa(perfilUsuario)),
  ),
  tema: temaOscuro,
);

void main() {
  setUpAll(cargarFuentes);

  testWidgets('el saludo sigue la hora del club: días de 06:00 a 11:59,'
      ' tardes de 12:00 a 19:59, noches de 20:00 a 05:59'
      ' @SAL-01-S1 @assumption:SAL-01-ASM-01', (tester) async {
    const casos = {
      (6, 0): 'BUENOS DÍAS,',
      (11, 59): 'BUENOS DÍAS,',
      (12, 0): 'BUENAS TARDES,',
      (19, 59): 'BUENAS TARDES,',
      (20, 0): 'BUENAS NOCHES,',
      (23, 59): 'BUENAS NOCHES,',
      (0, 0): 'BUENAS NOCHES,',
      (5, 59): 'BUENAS NOCHES,',
    };
    for (final MapEntry(key: (hora, minuto), value: saludo) in casos.entries) {
      await withClock(_relojDelClub(hora, minuto), () async {
        await _montarSaludo(tester, key: UniqueKey());
        expect(
          find.text(saludo),
          findsOneWidget,
          reason: 'a las $hora:$minuto del club',
        );
      });
    }
    expect(find.text('Nahuel'), findsOneWidget);
  });

  testWidgets(
    'el saludo se calcula al armar el inicio @assumption:SAL-01-ASM-02',
    (tester) async {
      await withClock(_relojDelClub(11, 59), () => _montarSaludo(tester));
      expect(find.text('BUENOS DÍAS,'), findsOneWidget);

      await withClock(_relojDelClub(12, 0), () async {
        await tester.pump(const Duration(minutes: 1));
        expect(find.text('BUENOS DÍAS,'), findsOneWidget);

        await _montarSaludo(tester, key: UniqueKey());
        expect(find.text('BUENAS TARDES,'), findsOneWidget);
      });
    },
  );
}
