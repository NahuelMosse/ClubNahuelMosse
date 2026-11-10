import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'the panel texts, API routes, JSON keys and screen routes are the same as before @ENG-09-S3',
    () {
      final source = [
        File('lib/l10n/app_es.arb').readAsStringSync(),
        ...Directory('lib/features/admin')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))
            .map((f) => f.readAsStringSync()),
      ].join('\n');
      for (final kept in [
        'El motivo es obligatorio para anular',
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
