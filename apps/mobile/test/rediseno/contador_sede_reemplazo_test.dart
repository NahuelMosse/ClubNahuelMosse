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
    'el contador de la tarjeta de sede es el dorsal sobre la foto, en el color del texto sobre foto @RED-01-ASM-04 @RED-03-ASM-14',
    (tester) async {
      await montarUsuario(
        tester,
        api: apiRutas(rutasDeSedes(sedes: '[$sedeMoronConDeportes]')),
      );

      final dorsal = find.descendant(
        of: find.byType(TarjetaSede),
        matching: find.byType(DorsalGigante),
      );
      final contador = tester.widget<DorsalGigante>(dorsal);
      expect(contador.texto, '02');
      expect(contador.color, Paleta.oscura.textOnMedia);
    },
  );
}
