import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _raiz = '(raiz)';

/// La carpeta de `lib/` a la que pertenece [ruta] (relativa a `lib/`); los archivos sueltos
/// de la raíz cuentan como una carpeta más.
String _carpeta(String ruta) {
  final partes = ruta.split('/');
  return partes.length == 1 ? _raiz : partes.first;
}

final _importacion = RegExp(
  r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

/// Cada archivo de `lib/` con los archivos de `lib/` que importa o reexporta (rutas
/// relativas a `lib/`).
Map<String, Set<String>> _archivos() {
  final lib = Directory('lib');
  final salida = <String, Set<String>>{};
  for (final f in lib.listSync(recursive: true).whereType<File>()) {
    if (!f.path.endsWith('.dart')) continue;
    final ruta = f.path
        .replaceAll('\\', '/')
        .split('lib/')
        .skip(1)
        .join('lib/');
    final destinos = <String>{};
    for (final m in _importacion.allMatches(f.readAsStringSync())) {
      final uso = m.group(1)!;
      if (uso.startsWith('package:clubnahuelmosse/')) {
        destinos.add(uso.substring('package:clubnahuelmosse/'.length));
      } else if (!uso.contains(':')) {
        destinos.add(Uri.parse(ruta).resolve(uso).path);
      }
    }
    salida[ruta] = destinos;
  }
  return salida;
}

/// Las dependencias entre carpetas de `lib/`, sin las de una carpeta consigo misma.
Map<String, Set<String>> _grafo() {
  final grafo = <String, Set<String>>{};
  for (final MapEntry(:key, :value) in _archivos().entries) {
    final de = _carpeta(key);
    grafo.putIfAbsent(de, () => {});
    for (final a in value) {
      final hacia = _carpeta(a);
      if (hacia != de) grafo[de]!.add(hacia);
    }
  }
  return grafo;
}

void main() {
  test(
    'la app tiene un test de imports y comun importa sólo api, tema y l10n, que no importan otras carpetas de lib @REV-06-S2 @assumption:REV-06-ASM-02 @assumption:REV-06-ASM-13',
    () {
      final grafo = _grafo();
      expect(
        grafo['common']!.difference({'api', 'theme', 'l10n'}),
        isEmpty,
        reason: 'comun sólo puede importar api, tema y l10n',
      );
      expect(grafo['api'] ?? <String>{}, isEmpty);
      expect(grafo['theme'] ?? <String>{}, isEmpty);
      expect(grafo['l10n'] ?? <String>{}, isEmpty);
    },
  );
}
