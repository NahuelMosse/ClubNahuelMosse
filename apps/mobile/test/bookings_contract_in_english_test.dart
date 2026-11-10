import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _sources(List<String> dirs) => [
  for (final dir in dirs)
    for (final f in Directory(dir).listSync(recursive: true).whereType<File>())
      if (f.path.endsWith('.dart')) f.readAsStringSync(),
].join('\n');

void main() {
  test(
    'the texts, API routes, JSON keys and screen routes of bookings and home are the same as before @ENG-10-S3',
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
      ]) {
        expect(source, contains(piece), reason: piece);
      }
      expect(
        File('lib/l10n/app_es.arb').readAsStringSync(),
        contains('"Reserva modificada"'),
      );
    },
  );
}
