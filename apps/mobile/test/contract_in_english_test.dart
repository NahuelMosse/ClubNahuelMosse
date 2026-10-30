import 'dart:convert';
import 'dart:io';

import 'package:clubnahuelmosse/api/rutas.dart';
import 'package:clubnahuelmosse/features/bookings/data/booking_json.dart';
import 'package:clubnahuelmosse/features/bookings/domain/booking_status.dart';
import 'package:clubnahuelmosse/features/notifications/domain/notification_kind.dart';
import 'package:clubnahuelmosse/features/notifications/domain/notification_system.dart';
import 'package:clubnahuelmosse/features/session/domain/role.dart';
import 'package:clubnahuelmosse/features/venues/domain/venue.dart';
import 'package:flutter_test/flutter_test.dart';

const _bookingId = '00000000-0000-7000-8000-0000000000b1';
const _venueId = '00000000-0000-7000-8000-000000000001';

Iterable<File> _dartFiles(String dir) => Directory(dir)
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'));

/// Every API path literal the data layer asks for, with interpolations as one segment.
Set<String> _requestedPaths() {
  final literal = RegExp(r'''(?:_api\.\w+\(\s*|path:\s*)'(/[^'?]*)''');
  final paths = <String>{};
  final files = [
    ..._dartFiles(
      'lib/features',
    ).where((f) => f.path.replaceAll('\\', '/').contains('/data/')),
  ];
  for (final f in files) {
    for (final m in literal.allMatches(f.readAsStringSync())) {
      paths.add(m[1]!.replaceAll(RegExp(r'\$\{[^}]*\}|\$\w+'), 'x'));
    }
  }
  return paths;
}

String _booking({String status = 'active'}) =>
    '{"id": "$_bookingId", "space_id": "$_venueId", "venue_id": "$_venueId", '
    '"space": "Futbol 5", "sport": "Futbol", "kind": "synthetic", '
    '"venue": "Sede Moron", "address": "Av. 1", '
    '"starts_at": "2026-11-12T13:00:00Z", "ends_at": "2026-11-12T14:00:00Z", '
    '"total": 1000, "status": "$status", "reason": null, "cancelable": true}';

void main() {
  test(
    'the app asks only for routes of the published English contract @ENG-18-S7',
    () {
      final paths = _requestedPaths();
      expect(paths, isNotEmpty);
      for (final path in paths) {
        final segments = path.split('/');
        final known = rutasDeLaApi.any(
          (r) => [
            'GET',
            'POST',
            'PUT',
            'DELETE',
          ].any((method) => r.coincideCon(method, segments)),
        );
        expect(known, isTrue, reason: path);
      }
      final templates = rutasDeLaApi.map((r) => r.ruta).toSet();
      for (final old in [
        '/sedes',
        '/espacios',
        '/reservas',
        '/yo',
        '/notificaciones',
        '/dispositivos',
        '/registro',
        '/recuperacion',
      ]) {
        expect(
          templates.any((t) => t == old || t.startsWith('$old/')),
          isFalse,
          reason: old,
        );
      }
    },
  );

  test(
    'the data layer sends and reads the English fields and values @ENG-18-S7 @assumption:ENG-18-ASM-08',
    () {
      final booking = bookingFromJson(_decode(_booking(status: 'canceled')));
      expect(booking?.status, BookingStatus.canceled);
      expect(booking?.spaceId, _venueId);
      expect(booking?.cancelable, isTrue);
      expect(
        bookingFromJson(
          _decode(
            '{"id": "$_bookingId", "espacio_id": "$_venueId", "estado": "activa"}',
          ),
        ),
        isNull,
      );
      expect(bookingFromJson(_decode(_booking(status: 'activa'))), isNull);

      final venue = Venue.fromJson(
        _decode(
          '{"id": "$_venueId", "name": "Sede Moron", "address": "Av. 1", '
          '"opens_at": "08:00", "closes_at": "23:00", '
          '"open_days": [1,2,3], "space_count": 2, "sports": ["Futbol"]}',
        ),
      );
      expect(venue?.name, 'Sede Moron');
      expect(
        Venue.fromJson(
          _decode(
            '{"id": "$_venueId", "nombre": "Sede Moron", "direccion": "Av. 1"}',
          ),
        ),
        isNull,
      );
    },
  );

  test(
    'the push data with kind and booking_id becomes the notification of that booking @ENG-18-S5',
    () {
      final tapped = NoticeTapped.fromData({
        'kind': 'forced_cancellation',
        'booking_id': _bookingId,
      });
      expect(tapped.kind, NotificationKind.forcedCancellation);
      expect(tapped.bookingId, _bookingId);
      expect(tapped.route, '/reservas?historial=1&reserva=$_bookingId');

      final reminder = NoticeTapped.fromData({
        'kind': 'five_minute_reminder',
        'booking_id': _bookingId,
      });
      expect(reminder.kind, NotificationKind.fiveMinuteReminder);

      final old = NoticeTapped.fromData({
        'tipo': 'recordatorio',
        'reserva_id': _bookingId,
      });
      expect(old.kind, isNull);
      expect(old.bookingId, isNull);
    },
  );

  test(
    'each booking status, role and notification kind shows the same Spanish word as before @ENG-18-S10 @assumption:ENG-18-ASM-07',
    () {
      expect(
        {for (final s in BookingStatus.values) s.apiValue: s.label},
        {
          'active': 'Activa',
          'completed': 'Completada',
          'canceled': 'Cancelada',
          'voided': 'Anulada',
        },
      );
      expect(
        {for (final r in Role.values) r.apiValue: r.label},
        {'user': 'usuario', 'admin': 'admin'},
      );
      expect({
        for (final k in NotificationKind.values) k.apiValue: k.label,
      }, containsPair('forced_cancellation', 'cancelación del club'));
      expect(
        NotificationKind.values.map((k) => k.apiValue),
        containsAll([
          'forced_cancellation',
          'reminder',
          'five_minute_reminder',
          'user_cancellation',
        ]),
      );
    },
  );
}

Object? _decode(String json) => jsonDecode(json);
