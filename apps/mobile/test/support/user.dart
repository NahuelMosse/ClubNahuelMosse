import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:clubnahuelmosse/app.dart';
import 'package:clubnahuelmosse/common/appearance.dart';
import 'package:clubnahuelmosse/features/notifications/presentation/notification_center.dart';
import 'package:clubnahuelmosse/features/session/presentation/session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'admin.dart';
import 'mount.dart';

const venueMoronWithSports =
    '{"id": "00000000-0000-7000-8000-000000000001", "name": "Sede Morón", "address": "Av. Rivadavia 19850", '
    '"opens_at": "08:00", "closes_at": "23:00", "open_days": [1,2,3,4,5,6,7], '
    '"space_count": 2, "sports": ["Futbol", "Tenis"]}';
const venueHaedoWithoutCourts =
    '{"id": "00000000-0000-7000-8000-000000000005", "name": "Sede Haedo", "address": "Av. Vergara 1850", '
    '"opens_at": "08:00", "closes_at": "22:00", "open_days": [1,2,3,4,5,6,7], '
    '"space_count": 0, "sports": []}';

/// The prototype's grid: Thursday, November 12, 1 hour, six taken time slots.
String gridJson({
  String date = '2026-11-12',
  Set<int> taken = const {9, 12, 16, 17, 21, 22},
  bool opens = true,
}) {
  String hour(int h) => '${h.toString().padLeft(2, '0')}:00';
  final slots = [
    if (opens)
      for (var h = 8; h < 23; h++)
        '{"starts_at": "${hour(h)}", "ends_at": "${hour(h + 1)}", '
            '"available": ${!taken.contains(h)}}',
  ];
  return '{"date": "$date", "today": "2026-11-12", "opens": $opens, '
      '"slots": [${slots.join(', ')}], '
      '"unavailable": ${opens ? taken.length : 0}}';
}

/// The API responses to browse the venues as a user.
Map<String, (int, String)> venueRoutes({
  String venues = '[$venueMoronWithSports, $venueHaedoWithoutCourts]',
  String spaces = '[$spaceF5Json, $spaceTennisJson]',
  String? grid,
}) => {
  'GET /spaces/catalog': (200, catalogJson),
  'GET /venues': (200, '{"venues": $venues}'),
  'GET /spaces': (200, '{"spaces": $spaces}'),
  'GET /spaces/00000000-0000-7000-8000-000000000009/slots': (
    200,
    grid ?? gridJson(),
  ),
};

/// The whole app with a user's session, opened at [start].
Future<void> mountUser(
  WidgetTester tester, {
  required ApiClient api,
  String start = '/sedes',
  bool dark = true,
  Size size = const Size(393, 852),
  NotificationCenter Function(Session)? center,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final session = FakeSession(userProfile);
  await tester.pumpWidget(
    App(
      api: api,
      session: session,
      appearance: Appearance.inMemory(dark: dark),
      notificationCenter: center?.call(session),
      initialLocation: start,
    ),
  );
  await tester.pumpAndSettle();
}
