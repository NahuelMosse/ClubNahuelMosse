import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, String> _lib() => {
  for (final f in Directory('lib').listSync(recursive: true).whereType<File>())
    if (f.path.endsWith('.dart'))
      f.path.replaceAll('\\', '/').substring('lib/'.length): f
          .readAsStringSync(),
};

/// El código sin comentarios ni contenido de strings, con los saltos de línea intactos.
String _limpiar(String s) {
  final out = StringBuffer();
  var i = 0;
  while (i < s.length) {
    final c = s[i];
    if (s.startsWith('//', i)) {
      while (i < s.length && s[i] != '\n') {
        i++;
      }
    } else if (s.startsWith('/*', i)) {
      final fin = s.indexOf('*/', i + 2);
      final hasta = fin < 0 ? s.length : fin + 2;
      out.write('\n' * '\n'.allMatches(s.substring(i, hasta)).length);
      i = hasta;
    } else if (c == "'" || c == '"') {
      final raw = i > 0 && s[i - 1] == 'r';
      final fin = _finDeString(s, i, raw);
      out.write("''");
      out.write('\n' * '\n'.allMatches(s.substring(i, fin)).length);
      i = fin;
    } else {
      out.write(c);
      i++;
    }
  }
  return out.toString();
}

int _finDeString(String s, int inicio, bool raw) {
  final q = s[inicio];
  final triple = s.startsWith(q * 3, inicio);
  final cierre = triple ? q * 3 : q;
  var i = inicio + cierre.length;
  while (i < s.length) {
    if (s.startsWith(cierre, i)) return i + cierre.length;
    if (!raw && s[i] == r'\') {
      i += 2;
    } else if (!raw && s.startsWith(r'${', i)) {
      i = _finDeInterpolacion(s, i + 2);
    } else {
      i++;
    }
  }
  return s.length;
}

int _finDeInterpolacion(String s, int desde) {
  var prof = 1;
  var i = desde;
  while (i < s.length && prof > 0) {
    final c = s[i];
    if (c == "'" || c == '"') {
      i = _finDeString(s, i, false);
      continue;
    }
    if (c == '{') prof++;
    if (c == '}') prof--;
    i++;
  }
  return i;
}

enum _Cuerpo { tipo, funcion, interno }

/// Largo en líneas de cada función, método o constructor con cuerpo de `lib`,
/// con `build` incluido: la clave es `archivo:línea`.
Map<String, int> _largos(String archivo, String texto) {
  final s = _limpiar(texto);
  final largos = <String, int>{};
  final pila = <(_Cuerpo, int)>[];
  var parentesis = 0;
  var segmento = -1;
  var linea = 1;
  bool admite() => pila.isEmpty || pila.last.$1 == _Cuerpo.tipo;
  var i = 0;
  while (i < s.length) {
    final c = s[i];
    if (c == '\n') {
      linea++;
    } else if (segmento < 0 && admite() && c.trim().isNotEmpty) {
      segmento = i;
    }
    if ('([<'.contains(c) && c != '<') parentesis++;
    if (')]'.contains(c)) parentesis--;
    if (c == '=' &&
        s.startsWith('=>', i) &&
        parentesis == 0 &&
        admite() &&
        segmento >= 0) {
      final fin = _finDeFlecha(s, i + 2);
      final lineas = '\n'.allMatches(s.substring(segmento, fin)).length + 1;
      final inicio = linea - '\n'.allMatches(s.substring(segmento, i)).length;
      largos['$archivo:$inicio'] = lineas;
      linea += '\n'.allMatches(s.substring(i, fin)).length;
      i = fin;
      segmento = -1;
      continue;
    }
    if (c == '{') {
      if (admite() && parentesis == 0 && segmento >= 0) {
        final previo = s.substring(segmento, i).trimRight();
        final esFuncion = RegExp(r'(\)|\basync\*?|\bsync\*)$').hasMatch(previo);
        final inicio = linea - '\n'.allMatches(s.substring(segmento, i)).length;
        pila.add((esFuncion ? _Cuerpo.funcion : _Cuerpo.tipo, inicio));
      } else {
        pila.add((_Cuerpo.interno, linea));
      }
      if (pila.last.$1 != _Cuerpo.interno) segmento = -1;
    } else if (c == '}' && pila.isNotEmpty) {
      final (tipo, inicio) = pila.removeLast();
      if (tipo == _Cuerpo.funcion)
        largos['$archivo:$inicio'] = linea - inicio + 1;
      if (admite()) segmento = -1;
    } else if (c == ';' && parentesis == 0 && admite()) {
      segmento = -1;
    }
    i++;
  }
  return largos;
}

/// El índice del `;` que cierra la expresión que empieza en [desde].
int _finDeFlecha(String s, int desde) {
  var nivel = 0;
  for (var i = desde; i < s.length; i++) {
    final c = s[i];
    if ('([{'.contains(c)) nivel++;
    if (')]}'.contains(c)) nivel--;
    if (c == ';' && nivel <= 0) return i + 1;
  }
  return s.length;
}

void main() {
  test(
    'el análisis de la app pide imports ordenados y ningún booleano posicional, y no excluye tests arreglados @SIM-03-S2 @SIM-03-S3',
    () {
      final opciones = File('analysis_options.yaml').readAsStringSync();
      expect(opciones, contains('- directives_ordering'));
      expect(opciones, contains('- avoid_positional_boolean_parameters'));
      expect(opciones, isNot(contains('anular_desde_el_detalle_test')));
    },
  );

  test(
    'ninguna función de lib pasa de 80 líneas, build incluido @SIM-03-S2 @assumption:SIM-03-ASM-03',
    () {
      final largas = <String, int>{};
      for (final MapEntry(key: ruta, value: texto) in _lib().entries) {
        _largos(ruta, texto).forEach((donde, largo) {
          if (largo > 80) largas[donde] = largo;
        });
      }
      expect(largas, isEmpty);
    },
  );

  test('no queda paginaQueSube ni otro código sin uso en lib @SIM-03-S3', () {
    final usan = [
      for (final MapEntry(key: ruta, value: texto) in _lib().entries)
        if (texto.contains('paginaQueSube')) ruta,
    ];
    expect(usan, isEmpty);
  });

  test(
    'movimiento.dart reexporta sus widgets desde comun/movimiento sin cambiar los imports @assumption:SIM-03-ASM-02',
    () {
      final indice = File('lib/comun/movimiento.dart').readAsStringSync();
      final exports = RegExp(
        r'^export .*$',
        multiLine: true,
      ).allMatches(indice).map((m) => m.group(0)!).toList();
      expect(exports, isNotEmpty);
      for (final e in exports) {
        expect(e, contains("'movimiento/"));
        expect(e, contains(' show '), reason: e);
      }
      expect(indice, isNot(contains('Widget')));
      for (final widget in [
        'Aparecer',
        'EntradaEscalonada',
        'Temblor',
        'PulsoDeExito',
        'Latido',
        'Presionable',
        'Festejo',
        'Movimiento',
      ]) {
        expect(indice, contains(widget), reason: widget);
      }
      final piezas = Directory(
        'lib/comun/movimiento',
      ).listSync().whereType<File>().where((f) => f.path.endsWith('.dart'));
      expect(piezas.length, greaterThanOrEqualTo(6));
    },
  );

  test('el router de la app vive fuera de app.dart @SIM-03-S2', () {
    final lib = _lib();
    expect(lib['app.dart'], isNot(contains('GoRoute(')));
    expect(lib['app.dart'], isNot(contains('GoRouter(')));
    expect(lib['rutas.dart'], contains('GoRouter('));
  });

  test(
    'las piezas de un build largo viven en archivos propios del módulo @assumption:SIM-03-ASM-01',
    () {
      final lib = _lib();
      for (final ruta in [
        'reservas/tarjeta_reserva.dart',
        'admin/pantalla_filtros_reservas.dart',
        'admin/pantalla_panel_admin.dart',
        'reservas/pantalla_reserva_confirmada.dart',
        'sesion/tarjeta_cuenta.dart',
        'admin/pantalla_alta_espacio.dart',
      ]) {
        final texto = lib[ruta]!;
        final clases = RegExp(
          r'^class (\w+)',
          multiLine: true,
        ).allMatches(texto).map((m) => m.group(1)!).toList();
        expect(clases.length, lessThanOrEqualTo(2), reason: '$ruta $clases');
        expect(
          '\n'.allMatches(texto).length,
          lessThan(250),
          reason: '$ruta es larga',
        );
      }
    },
  );

  test(
    'la app muestra lo mismo: las capturas se comparan sin regenerarlas @SIM-03-S1',
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
}
