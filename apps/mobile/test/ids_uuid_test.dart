import 'package:clubnahuelmosse/features/bookings/data/booking_json.dart';
import 'dart:convert';

import 'package:clubnahuelmosse/features/admin/data/booking_history_json.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'soporte/admin.dart';
import 'soporte/montar.dart';
import 'soporte/usuario.dart';
import 'package:clubnahuelmosse/features/notifications/domain/app_notification.dart';
import 'package:clubnahuelmosse/features/notifications/domain/notification_system.dart';
import 'package:clubnahuelmosse/features/spaces/domain/space.dart';
import 'package:clubnahuelmosse/features/venues/domain/venue.dart';

const _sede = '0192f3c4-7a10-7b2e-9c11-5d8e2a6f0001';
const _espacio = '0192f3c4-7a10-7b2e-9c11-5d8e2a6f0002';
const _reserva = '0192f3c4-7a10-7b2e-9c11-5d8e2a6f0003';
const _usuario = '0192f3c4-7a10-7b2e-9c11-5d8e2a6f0004';
const _aviso = '0192f3c4-7a10-7b2e-9c11-5d8e2a6f0005';

Map<String, Object?> _sedeJson() => {
  'id': _sede,
  'name': 'Sede Morón',
  'address': 'Av. Rivadavia 19850',
  'opens_at': '08:00',
  'closes_at': '23:00',
  'open_days': [1, 2, 3, 4, 5, 6, 7],
  'space_count': 1,
  'sports': ['Futbol'],
};

Map<String, Object?> _espacioJson() => {
  'id': _espacio,
  'name': 'Moron_Rivadavia_19850_Futbol_F5_1',
  'venue_id': _sede,
  'venue': 'Sede Morón',
  'sport': 'Futbol',
  'kind': 'F5',
  'number': 1,
  'covered': false,
  'lit': true,
  'price_per_hour': 38000,
};

Map<String, Object?> _reservaJson() => {
  'id': _reserva,
  'space_id': _espacio,
  'venue_id': _sede,
  'space': 'Moron_Rivadavia_19850_Futbol_F5_1',
  'sport': 'Futbol',
  'kind': 'F5',
  'venue': 'Sede Morón',
  'address': 'Av. Rivadavia 19850',
  'starts_at': '2026-11-13T00:00:00Z',
  'ends_at': '2026-11-13T01:00:00Z',
  'total': 38000,
  'status': 'active',
  'reason': null,
  'cancelable': true,
};

void main() {
  setUpAll(cargarFuentes);

  group('la app lee los ids como texto UUID y navega con ellos @DAT-01-S3', () {
    test('los modelos conservan el id como texto', () {
      expect(Venue.fromJson(_sedeJson())?.id, _sede);
      final espacio = Space.fromJson(_espacioJson());
      expect(espacio?.id, _espacio);
      expect(espacio?.venueId, _sede);
      final reserva = bookingFromJson(_reservaJson());
      expect(reserva?.id, _reserva);
      expect(reserva?.spaceId, _espacio);
      expect(reserva?.venueId, _sede);
      final historial = parseBookingHistoryEntry({
        ..._reservaJson(),
        'user_id': _usuario,
        'user': 'Nahuel Mosse',
        'created_at': '2026-11-01T10:00:00Z',
        'canceled_at': null,
        'canceled_by_name': null,
        'space_deactivated': false,
      });
      expect(historial?.id, _reserva);
      expect(historial?.userId, _usuario);
      final aviso = AppNotification.fromJson({
        'id': _aviso,
        'kind': 'reminder',
        'title': 'Tu reserva es pronto',
        'body': 'Hoy',
        'created_at': '2026-11-12T20:00:00Z',
        'read': false,
        'booking_id': _reserva,
      });
      expect(aviso?.id, _aviso);
      expect(aviso?.bookingId, _reserva);
    });

    test('un id numérico ya no es un id', () {
      expect(Venue.fromJson({..._sedeJson(), 'id': 1}), isNull);
      expect(Space.fromJson({..._espacioJson(), 'venue_id': 2}), isNull);
    });

    testWidgets('la ruta de una sede pide sus canchas con el UUID', (
      tester,
    ) async {
      final pedidos = <http.Request>[];
      await montarUsuario(
        tester,
        inicio: '/sedes/$_sede',
        api: apiRutas({
          'GET /spaces/catalog': (200, catalogoJson),
          'GET /venues': (200, '{"venues": [${_json(_sedeJson())}]}'),
          'GET /spaces': (200, '{"spaces": [${_json(_espacioJson())}]}'),
        }, pedidos: pedidos),
      );
      expect(find.text('SEDE MORÓN'), findsOneWidget);
      final canchas = pedidos.where((p) => p.url.path == '/spaces').single;
      expect(canchas.url.queryParameters, {'venue_id': _sede});
    });
  });

  group('un aviso con reserva_id UUID abre la reserva y uno con reserva_id '
      'numérico abre el centro de notificaciones '
      '@assumption:DAT-01-ASM-05', () {
    test('un aviso con reserva_id UUID abre la reserva', () {
      final aviso = NoticeTapped.fromData({
        'kind': 'reminder',
        'booking_id': _reserva,
      });
      expect(aviso.route, '/reservas?reserva=$_reserva');
    });

    test('uno con reserva_id numérico abre el centro de notificaciones', () {
      final aviso = NoticeTapped.fromData({
        'kind': 'reminder',
        'booking_id': '7',
      });
      expect(aviso.route, '/notificaciones');
    });

    test('uno sin reserva_id abre Mis reservas', () {
      expect(
        NoticeTapped.fromData({'kind': 'reminder'}).route,
        '/bookings',
      );
    });
  });
}

String _json(Map<String, Object?> m) => jsonEncode(m);
