import 'package:clock/clock.dart';
import 'package:clubnahuelmosse/comun/boton.dart';
import 'package:clubnahuelmosse/comun/formato_fecha.dart';
import 'package:clubnahuelmosse/comun/formato_precio.dart';
import 'package:clubnahuelmosse/comun/reloj.dart';
import 'package:clubnahuelmosse/tema/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'interfaz_accesible_test.dart' show contraste;
import 'soporte/montar.dart';
import 'soporte/reloj_fijo.dart' show relojDeLasCapturas;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(cargarFuentes);

  test(
    'las capturas corren con el reloj fijo el 12 de noviembre de 2026 a las 15:00 del club '
    '@REV-04-S11 @assumption:REV-04-ASM-09',
    () {
      final ahora = withClock(relojDeLasCapturas, ahoraEnElClub);

      expect(
        (ahora.year, ahora.month, ahora.day, ahora.hour, ahora.minute),
        (2026, 11, 12, 15, 0),
      );
    },
  );
}
