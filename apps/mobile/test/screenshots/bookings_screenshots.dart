import 'dart:convert';

import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide testWidgets;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../my_bookings_test.dart' show bookingJson;
import '../support/mount.dart';
import '../support/fixed_clock.dart';
import '../support/user.dart';

/// Asserts nothing: produces the step-9 strip to compare against the prototype.
void main() {
  setUpAll(loadFonts);

  const phones = {'360': Size(360, 800), '430': Size(430, 932)};
  const modes = {'dark': true, 'light': false};
  final upcoming =
      '[${bookingJson()}, '
      '${bookingJson(id: '00000000-0000-7000-8000-000000000002', start: '2026-11-15T13:00:00+00:00', end: '2026-11-15T14:00:00+00:00')}]';
  final history =
      '[${bookingJson(status: 'canceled', start: '2026-11-11T23:00:00+00:00', end: '2026-11-12T00:00:00+00:00')}, '
      '${bookingJson(id: '00000000-0000-7000-8000-000000000002', status: 'completed', start: '2026-11-04T23:00:00+00:00', end: '2026-11-05T00:00:00+00:00')}, '
      '${bookingJson(id: '00000000-0000-7000-8000-000000000003', status: 'voided', reason: 'mantenimiento de la cancha', start: '2026-10-30T22:00:00+00:00', end: '2026-10-30T23:00:00+00:00')}]';

  Future<void> capture(WidgetTester tester, String file) async {
    await tester.runAsync(() async {
      for (final element in find.byType(Image).evaluate()) {
        final image = element.widget;
        if (image is Image) await precacheImage(image.image, element);
      }
    });
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile(file));
  }

  for (final MapEntry(key: width, value: size) in phones.entries) {
    for (final MapEntry(key: mode, value: dark) in modes.entries) {
      Future<void> open(
        WidgetTester tester, {
        String upcomingJson = '[]',
        String historyJson = '[]',
      }) {
        // The 21:00 booking is the one being modified: the grid shows it as free.
        final routes = venueRoutes(grid: gridJson(taken: {9, 12, 16, 17}));
        return mountUser(
          tester,
          dark: dark,
          size: size,
          start: '/bookings',
          api: ApiClient(
            'http://api.falsa',
            client: MockClient((request) async {
              final (c, body) = request.url.path == '/bookings'
                  ? (
                      200,
                      '{"bookings": ${request.url.queryParameters['when'] == 'history' ? historyJson : upcomingJson}}',
                    )
                  : routes['${request.method} ${request.url.path}'] ??
                        (404, '{}');
              return http.Response.bytes(
                utf8.encode(body),
                c,
                headers: {'content-type': 'application/json; charset=utf-8'},
              );
            }),
          ),
        );
      }

      testWidgets('upcoming $width $mode', (tester) async {
        await open(tester, upcomingJson: upcoming);
        await capture(tester, 'bookings/upcoming_${width}_$mode.png');
      });

      testWidgets('confirm the cancellation $width $mode', (tester) async {
        await open(tester, upcomingJson: upcoming);
        await tester.tap(find.text('CANCELAR').first);
        await tester.pumpAndSettle();
        await capture(tester, 'bookings/cancel_${width}_$mode.png');
      });

      testWidgets('choose the new time $width $mode', (tester) async {
        await open(tester, upcomingJson: upcoming);
        await tester.tap(find.text('MODIFICAR').first);
        await tester.pumpAndSettle();
        await capture(tester, 'bookings/modify_${width}_$mode.png');
      });

      testWidgets('confirm the change $width $mode', (tester) async {
        await open(tester, upcomingJson: upcoming);
        await tester.tap(find.text('MODIFICAR').first);
        await tester.pumpAndSettle();
        final slot = find.text('19:00 – 20:00');
        await tester.ensureVisible(slot);
        await tester.pumpAndSettle();
        await tester.tap(slot);
        await tester.pumpAndSettle();
        await tester.tap(find.text('CONTINUAR CON EL CAMBIO'));
        await tester.pumpAndSettle();
        await capture(tester, 'bookings/confirm_change_${width}_$mode.png');
      });

      testWidgets('history $width $mode', (tester) async {
        await open(tester, historyJson: history);
        await tester.tap(find.text('Historial'));
        await tester.pumpAndSettle();
        await capture(tester, 'bookings/history_${width}_$mode.png');
      });

      testWidgets('no upcoming $width $mode', (tester) async {
        await open(tester);
        await capture(tester, 'bookings/no_upcoming_${width}_$mode.png');
      });

      testWidgets('no past $width $mode', (tester) async {
        await open(tester);
        await tester.tap(find.text('Historial'));
        await tester.pumpAndSettle();
        await capture(tester, 'bookings/no_past_${width}_$mode.png');
      });

      testWidgets('upcoming with text at 200 % $width $mode', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await open(tester, upcomingJson: upcoming);
        await capture(tester, 'bookings/upcoming_200_${width}_$mode.png');
      });
    }
  }
}
