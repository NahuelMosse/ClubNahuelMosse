import 'dart:async';
import 'dart:convert';

import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:clubnahuelmosse/app.dart';
import 'package:clubnahuelmosse/common/appearance.dart';
import 'package:clubnahuelmosse/common/button.dart';
import 'package:clubnahuelmosse/common/selector.dart';
import 'package:clubnahuelmosse/common/skeleton.dart';
import 'package:clubnahuelmosse/features/admin/presentation/admin_booking_card.dart';
import 'package:clubnahuelmosse/features/admin/presentation/admin_space_card.dart';
import 'package:clubnahuelmosse/features/admin/presentation/admin_venue_card.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:clubnahuelmosse/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/admin.dart';
import 'support/held_api.dart';
import 'support/mount.dart';

const _frame = ValueKey('skeleton-card');

String _booking(int n) {
  final start = DateTime.now().toUtc().add(const Duration(days: 30));
  final end = start.add(const Duration(hours: 1));
  return '{"id": "00000000-0000-7000-8000-${n.toString().padLeft(12, '0')}",'
      ' "space_id": "00000000-0000-7000-8000-000000000009",'
      ' "venue_id": "00000000-0000-7000-8000-000000000001",'
      ' "space": "Moron_Rivadavia_19850_Futbol_F5_1", "sport": "Futbol",'
      ' "kind": "F5", "venue": "Sede Morón", "address": "Av. Rivadavia 19850",'
      ' "starts_at": "${start.toIso8601String()}", "ends_at": "${end.toIso8601String()}",'
      ' "total": 38000, "status": "active", "reason": null,'
      ' "user_id": "00000000-0000-7000-8000-000000000001",'
      ' "user": "Socio $n", "created_at": "2026-11-02T18:42:00-03:00",'
      ' "canceled_at": null, "canceled_by_name": null,'
      ' "space_deactivated": false}';
}

String _page(Iterable<int> ids, int number) =>
    '{"bookings": [${ids.map(_booking).join(',')}], "total": 40,'
    ' "page": $number, "per_page": 20, "counters": {"all": 40,'
    ' "active": 40, "completed": 0, "voided": 0}}';

Future<void> _open(WidgetTester tester, ApiClient api, String start) async {
  tester.view.physicalSize = const Size(393, 852) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    App(
      api: api,
      session: FakeSession(adminProfile),
      appearance: Appearance.inMemory(dark: true),
      initialLocation: start,
    ),
  );
  await tester.pump();
  await tester.pump();
}

Rect _rect(WidgetTester tester, Finder finder) {
  final box = tester.renderObject<RenderBox>(finder);
  return box.localToGlobal(Offset.zero) & box.size;
}

Future<void> _cardShape(
  WidgetTester tester, {
  required String start,
  required Type card,
}) async {
  final held = HeldApi({
    ...spaceRoutes(),
    'GET /venues': (200, '{"venues": [$venueMoronJson]}'),
  });
  await _open(tester, held.client, start);
  expect(find.byType(CircularProgressIndicator), findsNothing);
  final frame = find.byKey(_frame).first;
  final frameRect = _rect(tester, frame);
  expect(skeletonRects(tester, within: frame), hasLength(greaterThan(2)));

  held.release();
  await tester.pumpAndSettle();
  expectSameBox(
    frameRect,
    _rect(tester, find.byType(card).first),
    reason: 'the loading card takes the place of the real one',
  );
}

void main() {
  setUpAll(loadFonts);

  testWidgets(
    'admin spaces load with the shape of their card @VIS-03-S1',
    (tester) =>
        _cardShape(tester, start: '/admin/spaces', card: AdminSpaceCard),
  );

  testWidgets(
    'admin venues load with the shape of their card @VIS-03-S1',
    (tester) =>
        _cardShape(tester, start: '/admin/venues', card: AdminVenueCard),
  );

  testWidgets('the next history page is a block shaped like a booking '
      '@VIS-03-S1 @assumption:VIS-03-ASM-04', (tester) async {
    final second = Completer<http.Response>();
    final api = ApiClient(
      'http://api.falsa',
      client: MockClient((request) {
        final headers = {'content-type': 'application/json; charset=utf-8'};
        if (request.url.path == '/bookings/all') {
          if (request.url.queryParameters['page'] == '2') {
            return second.future;
          }
          return Future.value(
            http.Response.bytes(
              utf8.encode(_page(List.generate(20, (i) => i + 1), 1)),
              200,
              headers: headers,
            ),
          );
        }
        return Future.value(
          http.Response.bytes(
            utf8.encode(catalogJson),
            request.url.path == '/spaces/catalog' ? 200 : 404,
            headers: headers,
          ),
        );
      }),
    );
    await _open(tester, api, '/admin');
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    final real = _rect(tester, find.byType(AdminBookingCard).first);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -20000));
    await tester.pump();
    await tester.pump();

    final block = find.byType(Skeleton, skipOffstage: false);
    expect(block, findsOneWidget);
    final skeleton = tester.widget<Skeleton>(block);
    expect(skeleton.radius, Spacing.radiusLg);
    expect(skeleton.height, moreOrLessEquals(real.height, epsilon: 8));

    second.complete(
      http.Response.bytes(
        utf8.encode(_page([21], 2)),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      ),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('the panel history loads with its loading text and skeleton rows '
      '@VIS-03-S2 @assumption:VIS-03-ASM-03', (tester) async {
    final held = HeldApi({
      'GET /bookings/all': (200, _page([1, 2], 1)),
      'GET /spaces/catalog': (200, catalogJson),
    });
    await _open(tester, held.client, '/admin');
    expect(find.text('Cargando reservas…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    final frames = find.byKey(_frame);
    expect(frames, findsWidgets);
    final first = _rect(tester, frames.first);
    expect(skeletonRects(tester, within: frames.first), isNotEmpty);

    held.release();
    await tester.pumpAndSettle();
    final real = _rect(tester, find.byType(AdminBookingCard).first);
    expect(first.left, moreOrLessEquals(real.left, epsilon: 1));
    expect(first.right, moreOrLessEquals(real.right, epsilon: 1));
    expect(first.height, moreOrLessEquals(real.height, epsilon: 8));
  });

  testWidgets(
    'the new space screen loads with the shape of its form, not a spinner '
    '@VIS-03-S2',
    (tester) async {
      final held = HeldApi(spaceRoutes());
      await _open(tester, held.client, '/admin/spaces/new');
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Nuevo espacio'), findsOneWidget);
      expect(find.text('Nuevo espacio deportivo'), findsOneWidget);
      final blocks = skeletonRects(tester);
      expect(blocks.length, greaterThanOrEqualTo(5));

      held.release();
      await tester.pumpAndSettle();
      final fields = find.byType(SelectorField);
      expect(fields, findsNWidgets(5));
      for (var i = 0; i < 5; i++) {
        expectSameBox(
          blocks[i],
          _rect(tester, fields.at(i)),
          reason: 'selector $i',
        );
      }
    },
  );

  testWidgets(
    'screens that receive their data already loaded show no skeleton and the '
    'button spinners remain @assumption:VIS-03-ASM-02',
    (tester) async {
      final held = HeldApi(spaceRoutes());
      await _open(tester, held.client, '/admin/spaces/new');
      held.release();
      await tester.pumpAndSettle();
      expect(find.byType(Skeleton), findsNothing);

      await tester.pumpWidget(
        MaterialApp(
          theme: darkTheme,
          home: Scaffold(
            body: PrimaryButton(label: 'GUARDAR', loading: true, onTap: () {}),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(Skeleton), findsNothing);
    },
  );
}
