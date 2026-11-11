import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:clubnahuelmosse/app.dart';
import 'package:clubnahuelmosse/common/appearance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mount.dart';

const venueHaedoJson =
    '{"id": "00000000-0000-7000-8000-000000000005", "name": "Sede Haedo", "address": "Av. Vergara 1850", '
    '"opens_at": "08:00", "closes_at": "23:00", "open_days": [1,2,3,4,5,6,7], '
    '"space_count": 0}';
const venueMoronJson =
    '{"id": "00000000-0000-7000-8000-000000000001", "name": "Sede Morón", "address": "Av. Rivadavia 19850", '
    '"opens_at": "09:00", "closes_at": "00:00", "open_days": [1,2,3,4,5,6], '
    '"space_count": 1}';
const venueCastelarJson =
    '{"id": "00000000-0000-7000-8000-000000000002", "name": "Sede Castelar", "address": "Av. Rivadavia 23500", '
    '"opens_at": "08:00", "closes_at": "22:00", "open_days": [1,2,3,4,5,6,7], '
    '"space_count": 4}';

/// The whole app with an administrator's session, opened at [start].
Future<void> mountAdmin(
  WidgetTester tester, {
  required ApiClient api,
  String start = '/admin/venues',
  bool dark = true,
  Size size = const Size(393, 852),
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    App(
      api: api,
      session: FakeSession(adminProfile),
      appearance: Appearance.inMemory(dark: dark),
      initialLocation: start,
    ),
  );
  await tester.pumpAndSettle();
}

/// Opens the selector [field] and taps [option].
Future<void> choose(WidgetTester tester, String field, String option) async {
  await tester.ensureVisible(find.bySemanticsLabel(field));
  await tester.pumpAndSettle();
  await tester.tap(find.bySemanticsLabel(field));
  await tester.pumpAndSettle();
  final button = find.descendant(
    of: find.byType(Dialog),
    matching: find.text(option),
  );
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

const catalogJson =
    '{"sports": ['
    '{"key": "Futbol", "name": "Fútbol", "kinds": ['
    '{"key": "F5", "name": "Fútbol 5"}, {"key": "F7", "name": "Fútbol 7"}]},'
    '{"key": "Tenis", "name": "Tenis", "kinds": ['
    '{"key": "PDL", "name": "Polvo de ladrillo"}]}]}';

const spaceF5Json =
    '{"id": "00000000-0000-7000-8000-000000000009", "name": "Moron_Rivadavia_19850_Futbol_F5_1", "venue_id": "00000000-0000-7000-8000-000000000001", '
    '"venue": "Sede Morón", "sport": "Futbol", "kind": "F5", "number": 1, "covered": false, '
    '"lit": true, "price_per_hour": 38000}';
const spaceTennisJson =
    '{"id": "00000000-0000-7000-8000-000000000010", "name": "Moron_Rivadavia_19850_Tenis_PDL_1", "venue_id": "00000000-0000-7000-8000-000000000001", '
    '"venue": "Sede Morón", "sport": "Tenis", "kind": "PDL", "number": 1, "covered": false, '
    '"lit": false, "price_per_hour": 32000}';
const spaceCastelarJson =
    '{"id": "00000000-0000-7000-8000-000000000011", "name": "Castelar_Rivadavia_23500_Futbol_F7_1", "venue_id": "00000000-0000-7000-8000-000000000002", '
    '"venue": "Sede Castelar", "sport": "Futbol", "kind": "F7", "number": 1, "covered": true, '
    '"lit": true, "price_per_hour": 55000}';

/// The API responses the space creation uses, with [create] for the POST.
Map<String, (int, String)> spaceRoutes({
  (int, String) create = (201, spaceF5Json),
  String venues = '[$venueMoronJson, $venueCastelarJson]',
}) => {
  'GET /spaces/catalog': (200, catalogJson),
  'GET /spaces': (200, '{"spaces": [$spaceF5Json]}'),
  'GET /spaces/name': (
    200,
    '{"name": "Moron_Rivadavia_19850_Futbol_F5_1", "number": 1}',
  ),
  'GET /venues': (200, '{"venues": $venues}'),
  'POST /spaces': create,
};
