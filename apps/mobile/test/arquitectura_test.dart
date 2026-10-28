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

/// Un ciclo del [grafo] (la primera carpeta se repite al final), o `null` si no hay.
List<String>? _ciclo(Map<String, Set<String>> grafo) {
  final estado = <String, int>{};
  final camino = <String>[];
  List<String>? hallado;

  void visitar(String nodo) {
    if (hallado != null) return;
    estado[nodo] = 1;
    camino.add(nodo);
    for (final v in grafo[nodo] ?? const <String>{}) {
      if (estado[v] == 1) {
        hallado ??= [...camino.sublist(camino.indexOf(v)), v];
        return;
      }
      if (estado[v] == null) visitar(v);
    }
    camino.removeLast();
    estado[nodo] = 2;
  }

  for (final n in grafo.keys) {
    if (estado[n] == null) visitar(n);
  }
  return hallado;
}

/// El texto de [ruta] (relativa a `lib/`) sin los comentarios de línea.
String _codigo(String ruta) => File(
  'lib/$ruta',
).readAsLinesSync().map((l) => l.replaceFirst(RegExp(r'//.*'), '')).join('\n');

void main() {
  test(
    'ninguna carpeta de lib forma un ciclo de imports @REV-06-S4 @assumption:REV-06-ASM-02',
    () {
      expect(_ciclo(_grafo()), isNull);
    },
  );

  test(
    'los archivos de la raíz de lib cuentan como una carpeta en el test de ciclos @REV-06-S4 @assumption:REV-06-ASM-12',
    () {
      expect(
        _ciclo({
          _raiz: {'a'},
          'a': {_raiz},
        }),
        [_raiz, 'a', _raiz],
      );
      expect(
        _ciclo({
          _raiz: {'a'},
          'a': <String>{},
        }),
        isNull,
      );
      final grafo = _grafo();
      expect(grafo.containsKey(_raiz), isTrue);
      expect(grafo.entries.where((e) => e.value.contains(_raiz)), isEmpty);
    },
  );

  test(
    'la app tiene un test de imports y comun importa sólo api y tema, que no importan otras carpetas de lib @REV-06-S2 @assumption:REV-06-ASM-02 @assumption:REV-06-ASM-13',
    () {
      final grafo = _grafo();
      expect(
        grafo['common']!.difference({'api', 'theme'}),
        isEmpty,
        reason: 'comun sólo puede importar api y tema',
      );
      expect(grafo['api'] ?? <String>{}, isEmpty);
      expect(grafo['theme'] ?? <String>{}, isEmpty);
    },
  );

  test(
    'historial_reservas.dart no fuerza nulos con el operador ! @REV-06-S7 @assumption:REV-06-ASM-06',
    () {
      final forzados = RegExp(r'[\w)\]]!(?!=)');
      expect(
        forzados.hasMatch(
          _codigo('features/admin/domain/booking_history_entry.dart'),
        ),
        isFalse,
      );
    },
  );

  test(
    'la zona del club se define una sola vez en la app @REV-06-S10 @assumption:REV-06-ASM-07',
    () {
      final desfase = RegExp(r'hours:\s*3\b');
      final donde = [
        for (final ruta in _archivos().keys)
          if (desfase.hasMatch(_codigo(ruta))) ruta,
      ];
      expect(donde, ['common/club_timezone.dart']);
    },
  );
}
