import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _sources(List<String> dirs) => [
  for (final dir in dirs)
    for (final f in Directory(dir).listSync(recursive: true).whereType<File>())
      if (f.path.endsWith('.dart')) f.readAsStringSync(),
].join('\n');

void main() {
  test(
    'los textos, rutas de la API, claves JSON y rutas de pantalla de reservas e inicio son los de antes @ENG-10-S3',
    () {
      final source = _sources(['lib/features/bookings', 'lib/features/home']);
      for (final piece in [
        "'/bookings?when=",
        '/cancel',
        '/modify',
        "'/spaces/available'",
        '/slots',
        "'space_id'",
        "'unavailable'",
        "'cancelable'",
        "'Reserva modificada'",
      ]) {
        expect(source, contains(piece), reason: piece);
      }
    },
  );
}
