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

void main() {
  test(
    'las reservas y el inicio viven en features/bookings y features/home con nombres en inglés @ENG-10-S1 @assumption:ENG-10-ASM-02',
    () {
      expect(Directory('lib/reservas').existsSync(), isFalse);
      expect(Directory('lib/inicio').existsSync(), isFalse);
      final spanish = RegExp(
        r'(reserva|inicio|pantalla|tarjeta|barra|boton|cabecera|cancelacion|comprobante|detalle|eleccion|encabezado|etiqueta|fila|filtro|franja|fondo|grilla|horario|marco|nota|portada|precio|rango|reglas|resumen|seccion|seleccion|selector|saludo|titulo|velo|deportes|accesos?|animacion|esqueleto|pasos|acciones?|crece|techada|busqueda|confirmar)',
      );
      final files = [
        ..._dartFiles('lib/features/bookings'),
        ..._dartFiles('lib/features/home'),
      ];
      expect(files, isNotEmpty);
      final bad = [
        for (final f in files)
          if (spanish.hasMatch(f.path.replaceAll('\\', '/').split('/').last))
            f.path,
      ];
      expect(bad, isEmpty);
    },
  );

  test(
    'bookings y home están partidos en data, domain y presentation y cumplen la regla de capas @ENG-10-S2 @assumption:ENG-10-ASM-03',
    () {
      for (final layer in ['data', 'domain', 'presentation']) {
        expect(
          _dartFiles('lib/features/bookings/$layer'),
          isNotEmpty,
          reason: 'bookings/$layer',
        );
      }
      for (final layer in ['domain', 'presentation']) {
        expect(
          _dartFiles('lib/features/home/$layer'),
          isNotEmpty,
          reason: 'home/$layer',
        );
      }
      final outside = [
        for (final f in [
          ..._dartFiles('lib/features/bookings'),
          ..._dartFiles('lib/features/home'),
        ])
          if (!RegExp(
            r'features/(bookings|home)/(data|domain|presentation)/',
          ).hasMatch(f.path.replaceAll('\\', '/')))
            f.path,
      ];
      expect(outside, isEmpty);
      final bookingsData = _sources(['lib/features/bookings/data']);
      expect(bookingsData, isNot(contains('package:flutter/')));
    },
  );

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
        "'Reserva modificada'",
      ]) {
        expect(source, contains(piece), reason: piece);
      }
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
      expect(BookingStatus.values.map((s) => s.label), [
        'Activa',
        'Completada',
        'Cancelada',
        'Anulada',
      ]);
      expect(BookingStatus.fromApi('activa'), BookingStatus.active);
      expect(BookingStatus.fromApi('anulada'), BookingStatus.voided);
      expect(BookingStatus.fromApi('active'), isNull);
    },
  );
}
