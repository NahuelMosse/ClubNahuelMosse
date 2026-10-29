import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Iterable<File> _dartFiles(String dir) => Directory(dir).existsSync()
    ? Directory(dir)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
    : const [];

void main() {
  const root = 'lib/features/admin';

  test(
    'los textos, rutas de la API, claves JSON y rutas de pantalla del panel son los de antes @ENG-09-S3',
    () {
      final source = [
        File('lib/l10n/app_es.arb').readAsStringSync(),
        ..._dartFiles(root).map((f) => f.readAsStringSync()),
      ].join('\n');
      for (final kept in [
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
}
