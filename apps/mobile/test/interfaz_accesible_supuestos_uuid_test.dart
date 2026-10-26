import 'package:clock/clock.dart';
import 'package:clubnahuelmosse/comun/boton.dart';
import 'package:clubnahuelmosse/comun/formato_fecha.dart';
import 'package:clubnahuelmosse/comun/formato_precio.dart';
import 'package:clubnahuelmosse/comun/reloj.dart';
import 'package:clubnahuelmosse/tema/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'interfaz_accesible_uuid_test.dart' show contraste;
import 'soporte/montar.dart';
import 'soporte/reloj_fijo.dart' show relojDeLasCapturas;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(cargarFuentes);

  test(
    'fechas y precios salen con el formato del club, es-AR con punto de miles y la hora a −3 h @REV-04-S10 @assumption:REV-04-ASM-06',
    () {
      expect(pesos(38000).replaceAll(' ', ' '), '\$ 38.000');
      expect(pesos(1250000).replaceAll(' ', ' '), '\$ 1.250.000');
      expect(formatearFecha(DateTime(2026, 3, 4)), '04 / 03 / 2026');
      final ahora = withClock(
        Clock.fixed(DateTime.utc(2026, 1, 1, 2)),
        ahoraEnElClub,
      );
      expect(
        (ahora.year, ahora.month, ahora.day, ahora.hour),
        (2025, 12, 31, 23),
      );
    },
  );

  testWidgets(
    'el botón atenuado se sigue viendo apagado y su texto llega a 4,5:1 @REV-04-S9 @assumption:REV-04-ASM-07',
    (tester) async {
      await montar(
        tester,
        Scaffold(
          body: Column(
            children: [
              BotonPrimario(texto: 'ACTIVO', alTocar: () {}),
              BotonPrimario(texto: 'APAGADO', alTocar: () {}, atenuado: true),
            ],
          ),
        ),
        tema: temaOscuro,
      );
      FilledButton boton(String texto) =>
          tester.widget<FilledButton>(find.widgetWithText(FilledButton, texto));
      final activo = boton('ACTIVO').style!;
      final apagado = boton('APAGADO').style!;
      final s = <WidgetState>{};

      expect(
        apagado.backgroundColor!.resolve(s)!.a,
        lessThan(activo.backgroundColor!.resolve(s)!.a),
      );
      final fondo = Color.alphaBlend(
        apagado.backgroundColor!.resolve(s)!,
        temaOscuro.scaffoldBackgroundColor,
      );
      expect(
        contraste(apagado.foregroundColor!.resolve(s)!, fondo),
        greaterThanOrEqualTo(4.5),
      );
    },
  );

  test(
    'las capturas corren con el reloj fijo el 12 de noviembre de 2026 a las 15:00 del club @REV-04-S11 @assumption:REV-04-ASM-09',
    () {
      final ahora = withClock(relojDeLasCapturas, ahoraEnElClub);

      expect(
        (ahora.year, ahora.month, ahora.day, ahora.hour, ahora.minute),
        (2026, 11, 12, 15, 0),
      );
    },
  );
}
