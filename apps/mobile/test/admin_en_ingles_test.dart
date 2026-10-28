import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final _spanishWord = RegExp(
  r'(pantalla|tarjeta|dialogo|cabecera|reserva|sede|espacio|baja|filtro|historial|cuerpo|campo|formulario|lista|panel_admin|boton|anular|trazabilidad)',
);
final _declaration = RegExp(
  r'^(?:abstract\s+|final\s+|sealed\s+)*(?:class|enum|typedef|mixin|extension)\s+(\w+)',
  multiLine: true,
);
final _import = RegExp(
  r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

Iterable<File> _dartFiles(String dir) => Directory(dir).existsSync()
    ? Directory(dir)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
    : const [];

String _slash(String path) => path.replaceAll('\\', '/');

void main() {
  const root = 'lib/features/admin';

  test(
    'el panel de administración vive en features/admin con nombres en inglés y no queda lib/admin @ENG-09-S1 @assumption:ENG-09-ASM-02',
    () {
      expect(Directory('lib/admin').existsSync(), isFalse);
      final files = _dartFiles(root).toList();
      expect(files.length, greaterThan(30));
      final problems = <String>[];
      for (final f in files) {
        final name = _slash(f.path).split('/').last;
        if (_spanishWord.hasMatch(name)) problems.add('file $name');
        for (final m in _declaration.allMatches(f.readAsStringSync())) {
          final lower = m[1]!.replaceAllMapped(
            RegExp('[A-Z]'),
            (c) => '_${c[0]!.toLowerCase()}',
          );
          if (_spanishWord.hasMatch(lower)) problems.add('${f.path}: ${m[1]}');
        }
      }
      expect(problems, isEmpty);
    },
  );

  test(
    'features/admin está partido en data, domain y presentación y cumple la regla de capas @ENG-09-S2 @assumption:ENG-09-ASM-03',
    () {
      for (final layer in ['data', 'domain', 'presentation']) {
        expect(_dartFiles('$root/$layer'), isNotEmpty, reason: layer);
      }
      final problems = <String>[];
      for (final f in _dartFiles(root)) {
        final path = _slash(f.path);
        final layer = RegExp(
          r'features/admin/(data|domain|presentation)/',
        ).firstMatch(path)?[1];
        if (layer == null) {
          problems.add('$path: outside data/domain/presentation');
          continue;
        }
        for (final m in _import.allMatches(f.readAsStringSync())) {
          final i = m[1]!;
          final flutter = i.startsWith('package:flutter/');
          final http = i.startsWith('package:http/');
          final api =
              i.contains('api/') &&
              !i.contains('/data/') &&
              !i.startsWith('dart:');
          final data = i.contains('/data/');
          final presentation = i.contains('/presentation/');
          final bad = switch (layer) {
            'domain' => flutter || http || api || data || presentation,
            'data' => flutter || presentation,
            _ => api,
          };
          if (bad) problems.add('$path imports $i');
        }
      }
      for (final f in _dartFiles('lib')) {
        for (final m in _import.allMatches(f.readAsStringSync())) {
          if (m[1]!.contains('clubnahuelmosse/admin/'))
            problems.add('${f.path} imports ${m[1]}');
        }
      }
      expect(problems, isEmpty);
    },
  );

  test(
    'los textos, rutas de la API, claves JSON y rutas de pantalla del panel son los de antes @ENG-09-S3',
    () {
      final source = _dartFiles(
        root,
      ).map((f) => f.readAsStringSync()).join('\n');
      for (final kept in [
        'El motivo es obligatorio para anular',
        'Este campo es obligatorio',
        '/reservas/todas',
        '/anular',
        "'sede_id=",
        "'cancelada_por_nombre'",
        "'aviso_envio'",
        "'por_pagina'",
        "'contadores'",
        "'espacio_de_baja'",
        'reservas futuras',
      ]) {
        expect(source, contains(kept), reason: kept);
      }
      final router = File('lib/router.dart').readAsStringSync();
      for (final route in [
        '/admin/sedes',
        '/admin/espacios',
        '/admin/acceso-denegado',
      ]) {
        expect(router, contains(route));
      }
    },
  );

  test('ningún test importa lib/admin @assumption:ENG-09-ASM-01', () {
    final problems = <String>[];
    for (final f in _dartFiles('test')) {
      if (_slash(f.path).endsWith('test/admin_en_ingles_test.dart')) continue;
      for (final m in _import.allMatches(f.readAsStringSync())) {
        if (RegExp(r'(clubnahuelmosse/|lib/)admin/').hasMatch(m[1]!))
          problems.add('${f.path}: ${m[1]}');
      }
    }
    expect(problems, isEmpty);
  });
}
