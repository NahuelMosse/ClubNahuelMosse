import 'dart:convert';
import 'dart:io';

import 'package:clubnahuelmosse/features/bookings/domain/booking_status.dart';
import 'package:flutter_test/flutter_test.dart';

Iterable<File> _dartFiles(String dir) => Directory(dir).existsSync()
    ? Directory(dir)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
    : const [];

String _sources(List<String> dirs) => [
  for (final dir in dirs)
    for (final f in _dartFiles(dir)) f.readAsStringSync(),
].join('\n');

Map<String, Object?> _catalog(String name) =>
    jsonDecode(File('lib/l10n/$name').readAsStringSync())
        as Map<String, Object?>;

void main() {
  test(
    'los textos, rutas de la API, claves JSON y rutas de pantalla de reservas e inicio son los de antes @ENG-10-S3',
    () {
      final source = _sources(['lib/features/bookings', 'lib/features/home']);
      for (final piece in [
        "'/reservas?cuando=",
        '/cancelar',
        '/modificar',
        "'/espacios/disponibles'",
        '/horarios',
        "'espacio_id'",
        "'no_disponibles'",
        "'cancelable'",
      ]) {
        expect(source, contains(piece), reason: piece);
      }
      expect(_catalog('app_es.arb')['bookingModified'], 'Reserva modificada');
    },
  );

  test(
    'BookingStatus muestra su label en castellano y lee el valor de la API de siempre @assumption:ENG-10-ASM-01',
    () {
      expect(BookingStatus.values.map((s) => s.apiValue), [
        'activa',
        'completada',
        'cancelada',
        'anulada',
      ]);
      final spanish = _catalog('app_es.arb');
      expect(
        [
          spanish['bookingStatusActive'],
          spanish['bookingStatusCompleted'],
          spanish['bookingStatusCanceled'],
          spanish['bookingStatusVoided'],
        ],
        ['Activa', 'Completada', 'Cancelada', 'Anulada'],
      );
      expect(BookingStatus.fromApi('activa'), BookingStatus.active);
      expect(BookingStatus.fromApi('anulada'), BookingStatus.voided);
      expect(BookingStatus.fromApi('active'), isNull);
    },
  );
}
