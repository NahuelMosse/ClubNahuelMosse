import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Los archivos de `lib/`, por ruta relativa, con su texto.
Map<String, String> _lib() => {
  for (final archivo in Directory(
    'lib',
  ).listSync(recursive: true).whereType<File>())
    if (archivo.path.endsWith('.dart'))
      archivo.path.replaceAll(r'\', '/').substring(4): archivo
          .readAsStringSync(),
};

Set<String> _queContienen(Pattern patron) => {
  for (final MapEntry(key: ruta, value: texto) in _lib().entries)
    if (texto.contains(patron)) ruta,
};

void main() {
  test(
    'las fechas, las horas y el DNI salen de intl y ningún archivo usa padLeft @ARQ-03-S1',
    () {
      expect(_queContienen('padLeft('), isEmpty);
      expect(_lib()['comun/fechas.dart'], contains('DateFormat'));
      expect(
        _queContienen('package:intl/intl.dart'),
        contains('comun/fechas.dart'),
      );
    },
  );

  test(
    'sólo fallo_de_carga.dart avisa la sesión vencida y el error de red @ARQ-03-S2 @ARQ-03-ASM-02',
    () {
      final llamadas = RegExp(r'mostrar(SesionVencida|ErrorDeRed)\(context');
      expect(_queContienen(llamadas), {'sesion/fallo_de_carga.dart'});
    },
  );

  test(
    'los chips y pestañas seleccionables son un solo ChipElegible @ARQ-03-S2 @ARQ-03-ASM-03',
    () {
      final copias = RegExp(r'class _(Chip|ChipCondicion|Pestanas|Elegible) ');
      expect(_queContienen(copias), isEmpty);
      expect(
        _lib()['comun/chip_elegible.dart'],
        contains('class ChipElegible '),
      );
      expect(_queContienen('ChipElegible(').length, greaterThanOrEqualTo(5));
    },
  );

  test(
    'el registro exitoso es una PantallaResultado y las bajas en curso usan EnCurso @ARQ-03-S2',
    () {
      expect(
        _lib()['usuarios/pantalla_registro_exitoso.dart'],
        contains('PantallaResultado('),
      );
      expect(_lib()['comun/en_curso.dart'], contains('class EnCurso '));
      expect(_queContienen('EnCurso(').length, greaterThanOrEqualTo(4));
    },
  );

  test(
    'los errores por campo que manda el servidor se leen sólo en errores_de_campo.dart @ARQ-03-S2',
    () {
      expect(_queContienen("['errores']"), {'comun/errores_de_campo.dart'});
    },
  );

  test('ninguna pantalla pasa de 500 líneas @ARQ-03-S3', () {
    final largas = {
      for (final MapEntry(key: ruta, value: texto) in _lib().entries)
        if (ruta.split('/').last.startsWith('pantalla_') &&
            '\n'.allMatches(texto).length > 500)
          ruta,
    };
    expect(largas, isEmpty);
  });

  test(
    'las capturas se comparan sin regenerarlas @ARQ-03-S3 @ARQ-03-ASM-01',
    () {
      final capturas = Directory('test/capturas')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('_capturas.dart'))
          .toList();
      expect(capturas, isNotEmpty);
      for (final archivo in capturas) {
        final texto = archivo.readAsStringSync();
        expect(texto, contains('matchesGoldenFile'), reason: archivo.path);
        expect(
          texto,
          isNot(contains('autoUpdateGoldenFiles')),
          reason: archivo.path,
        );
      }
    },
  );

  test(
    'mi perfil valida el nacimiento con el reloj del club y nadie usa DateTime.now @ARQ-03-ASM-04',
    () {
      expect(
        _lib()['usuarios/pantalla_mi_perfil.dart'],
        contains('ahoraEnElClub'),
      );
      expect(_queContienen('DateTime.now()'), isEmpty);
    },
  );
}
