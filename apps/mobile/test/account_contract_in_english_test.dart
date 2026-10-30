import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Iterable<File> _dartFiles(String dir) => Directory(dir)
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'));

void main() {
  test(
    'los textos, rutas de la API, claves JSON y rutas de pantalla son los de antes @ENG-11-S3 @assumption:ENG-11-ASM-03',
    () {
      final features = _dartFiles(
        'lib/features',
      ).map((f) => f.readAsStringSync()).join('\n');
      for (final path in [
        "'/venues'",
        "'/spaces'",
        "'/me'",
        "'/me/password'",
        "'/notifications'",
        "'/devices'",
      ]) {
        expect(features, contains(path), reason: path);
      }
      for (final key in [
        "'birth_date'",
        "'unread'",
        "'created_at'",
        "'bookings_outside'",
      ]) {
        expect(features, contains(key), reason: key);
      }
      final router = File('lib/router.dart').readAsStringSync();
      for (final route in [
        "'/inicio'",
        "'/sedes",
        "'/notificaciones'",
        "'/perfil'",
      ]) {
        expect(router, contains(route), reason: route);
      }
    },
  );
}
