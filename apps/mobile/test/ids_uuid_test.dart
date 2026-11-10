import 'package:clubnahuelmosse/features/bookings/data/booking_json.dart';
import 'dart:convert';

import 'package:clubnahuelmosse/features/admin/data/booking_history_json.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'support/admin.dart';
import 'support/mount.dart';
import 'support/user.dart';
import 'package:clubnahuelmosse/features/notifications/domain/app_notification.dart';
import 'package:clubnahuelmosse/features/notifications/domain/notification_system.dart';
import 'package:clubnahuelmosse/features/spaces/domain/space.dart';
import 'package:clubnahuelmosse/features/venues/domain/venue.dart';

const _venue = '0192f3c4-7a10-7b2e-9c11-5d8e2a6f0001';
const _space = '0192f3c4-7a10-7b2e-9c11-5d8e2a6f0002';
const _booking = '0192f3c4-7a10-7b2e-9c11-5d8e2a6f0003';
const _user = '0192f3c4-7a10-7b2e-9c11-5d8e2a6f0004';
const _notice = '0192f3c4-7a10-7b2e-9c11-5d8e2a6f0005';

Map<String, Object?> _venueJson() => {
  'id': _venue,
  'name': 'Sede Morón',
  'address': 'Av. Rivadavia 19850',
  'opens_at': '08:00',
  'closes_at': '23:00',
  'open_days': [1, 2, 3, 4, 5, 6, 7],
  'space_count': 1,
  'sports': ['Futbol'],
};

Map<String, Object?> _spaceJson() => {
  'id': _space,
  'name': 'Moron_Rivadavia_19850_Futbol_F5_1',
  'venue_id': _venue,
  'venue': 'Sede Morón',
  'sport': 'Futbol',
  'kind': 'F5',
  'number': 1,
  'covered': false,
  'lit': true,
  'price_per_hour': 38000,
};

Map<String, Object?> _bookingJson() => {
  'id': _booking,
  'space_id': _space,
  'venue_id': _venue,
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
  setUpAll(loadFonts);

  group(
    'the app reads ids as UUID text and navigates with them @DAT-01-S3',
    () {
      test('the models keep the id as text', () {
        expect(Venue.fromJson(_venueJson())?.id, _venue);
        final space = Space.fromJson(_spaceJson());
        expect(space?.id, _space);
        expect(space?.venueId, _venue);
        final booking = bookingFromJson(_bookingJson());
        expect(booking?.id, _booking);
        expect(booking?.spaceId, _space);
        expect(booking?.venueId, _venue);
        final history = parseBookingHistoryEntry({
          ..._bookingJson(),
          'user_id': _user,
          'user': 'Nahuel Mosse',
          'created_at': '2026-11-01T10:00:00Z',
          'canceled_at': null,
          'canceled_by_name': null,
          'space_deactivated': false,
        });
        expect(history?.id, _booking);
        expect(history?.userId, _user);
        final notice = AppNotification.fromJson({
          'id': _notice,
          'kind': 'reminder',
          'title': 'Tu reserva es pronto',
          'body': 'Hoy',
          'created_at': '2026-11-12T20:00:00Z',
          'read': false,
          'booking_id': _booking,
        });
        expect(notice?.id, _notice);
        expect(notice?.bookingId, _booking);
      });

      test('a numeric id is no longer an id', () {
        expect(Venue.fromJson({..._venueJson(), 'id': 1}), isNull);
        expect(Space.fromJson({..._spaceJson(), 'venue_id': 2}), isNull);
      });

      testWidgets('the venue route asks for its courts with the UUID', (
        tester,
      ) async {
        final requests = <http.Request>[];
        await mountUser(
          tester,
          start: '/venues/$_venue',
          api: apiRoutes({
            'GET /spaces/catalog': (200, catalogJson),
            'GET /venues': (200, '{"venues": [${_json(_venueJson())}]}'),
            'GET /spaces': (200, '{"spaces": [${_json(_spaceJson())}]}'),
          }, requests: requests),
        );
        expect(find.text('SEDE MORÓN'), findsOneWidget);
        final courts = requests.where((p) => p.url.path == '/spaces').single;
        expect(courts.url.queryParameters, {'venue_id': _venue});
      });
    },
  );

  group(
    'a notice with a UUID booking_id opens the booking and one with a numeric '
    'booking_id opens the notification center '
    '@assumption:DAT-01-ASM-05',
    () {
      test('a notice with a UUID booking_id opens the booking', () {
        final notice = NoticeTapped.fromData({
          'kind': 'reminder',
          'booking_id': _booking,
        });
        expect(notice.route, '/bookings?booking=$_booking');
      });

      test('one with a numeric booking_id opens the notification center', () {
        final notice = NoticeTapped.fromData({
          'kind': 'reminder',
          'booking_id': '7',
        });
        expect(notice.route, '/notifications');
      });

      test('one without a booking_id opens «Mis reservas»', () {
        expect(NoticeTapped.fromData({'kind': 'reminder'}).route, '/bookings');
      });
    },
  );
}

String _json(Map<String, Object?> m) => jsonEncode(m);
