import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// El código de un archivo de `lib/`, sin comentarios.
String _codigo(String ruta) => File(
  'lib/$ruta',
).readAsLinesSync().where((l) => !l.trimLeft().startsWith('//')).join('\n');

/// Lo que va sobre una foto no lee la paleta de un modo fijo ni grises escritos a mano.
void _sinTonosFijos(String ruta) {
  final codigo = _codigo(ruta);
  expect(codigo, isNot(contains('Paleta.oscura')), reason: ruta);
  expect(codigo, isNot(contains('Paleta.clara')), reason: ruta);
  expect(codigo, isNot(contains('0xFFD4D4D8')), reason: ruta);
}

void _acentoSobreFoto(String ruta) {
  _sinTonosFijos(ruta);
  expect(_codigo(ruta), contains('accentOnMedia'), reason: ruta);
}

void main() {
  test('el botón sobre foto usa accentOnMedia @RED-01-S2', () {
    _acentoSobreFoto('comun/boton.dart');
  });

  test('el sobretítulo del inicio usa accentOnMedia @RED-01-S2', () {
    _acentoSobreFoto('inicio/pantalla_inicio.dart');
  });

  test('el sobretítulo de la sede usa accentOnMedia @RED-01-S2', () {
    _acentoSobreFoto('sedes/pantalla_sede.dart');
  });

  test('el sobretítulo de confirmar reserva usa accentOnMedia @RED-01-S2', () {
    _acentoSobreFoto('reservas/pantalla_confirmar_reserva.dart');
  });

  test('el sobretítulo de horarios usa accentOnMedia @RED-01-S2', () {
    _acentoSobreFoto('reservas/pantalla_horarios.dart');
  });

  test('el acento del login usa accentOnMedia @RED-01-S2', () {
    _acentoSobreFoto('sesion/pantalla_inicio_sesion.dart');
  });

  test(
    'el texto sobre foto de cada pantalla sale de los tokens on-media @RED-01-S3',
    () {
      for (final ruta in [
        'inicio/pantalla_inicio.dart',
        'sedes/pantalla_sede.dart',
        'sedes/pantalla_sedes.dart',
        'reservas/pantalla_confirmar_reserva.dart',
        'reservas/pantalla_horarios.dart',
        'sesion/pantalla_inicio_sesion.dart',
      ]) {
        _sinTonosFijos(ruta);
        expect(_codigo(ruta), contains('textOnMedia'), reason: ruta);
      }
    },
  );

  test('el botón de peligro relleno usa stateDangerStrong @RED-01-S4', () {
    final codigo = _codigo('comun/boton.dart');
    expect(codigo, contains('backgroundColor: p.stateDangerStrong'));
  });

  test(
    'la etiqueta sobre foto, como «Fútbol 5», es violeta con texto blanco @RED-01-ASM-03',
    () {
      _sinTonosFijos('comun/etiqueta.dart');
      expect(
        _codigo('comun/etiqueta.dart'),
        contains('(p.accentBase, p.accentOn)'),
      );
    },
  );

  test(
    'el contador de la tarjeta de sede es violeta con cifra blanca @RED-01-ASM-04',
    () {
      final codigo = _codigo('sedes/pantalla_sedes.dart');
      _sinTonosFijos('sedes/pantalla_sedes.dart');
      final contador = RegExp(
        r"color: p\.accentBase,[\s\S]{0,400}?'\$\{sede\.canchas\}',\s*style: Textos\.\w+\.copyWith\(color: p\.accentOn\)",
      );
      expect(contador.hasMatch(codigo), isTrue);
    },
  );

  test('la cabecera del perfil va de bgHeroFrom a bgHeroTo @RED-01-S5', () {
    expect(
      _codigo('usuarios/pantalla_mi_perfil.dart'),
      contains('[p.bgHeroFrom, p.bgHeroTo]'),
    );
  });
}
