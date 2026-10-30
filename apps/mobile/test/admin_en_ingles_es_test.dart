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
        '/bookings/all',
        '/void',
        "'venue_id=",
        "'canceled_by_name'",
        "'notice_delivery'",
        "'per_page'",
        "'counters'",
        "'space_deactivated'",
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
