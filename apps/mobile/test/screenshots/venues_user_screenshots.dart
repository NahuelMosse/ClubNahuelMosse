import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide testWidgets;

import '../my_bookings_test.dart' show bookingJson;
import '../support/admin.dart';
import '../support/mount.dart';
import '../support/fixed_clock.dart';
import '../support/user.dart';

/// Asserts nothing: produces the step-9 strip to compare against the prototype.
void main() {
  setUpAll(loadFonts);

  const phones = {'360': Size(360, 800), '430': Size(430, 932)};
  const modes = {'dark': true, 'light': false};
  // Each venue's cover comes from the sum of the characters of its id: the fourth group
  // (8001) leaves Moron, Ramos Mejia and Haedo with the same covers they had with numeric ids.
  const venueMoron = '00000000-0000-7000-8001-000000000001';
  const venueRamos = '00000000-0000-7000-8001-000000000002';
  const venueHaedo = '00000000-0000-7000-8001-000000000005';
  const moronId = '00000000-0000-7000-8000-000000000001';
  const haedoId = '00000000-0000-7000-8000-000000000005';
  final venues =
      '[${venueMoronWithSports.replaceAll(moronId, venueMoron)}, '
      '{"id": "$venueRamos", "name": "Sede Ramos Mejía", "address": "Calle Belgrano 1240", '
      '"opens_at": "09:00", "closes_at": "22:00", "open_days": [1,2,3,4,5,6], '
      '"space_count": 2, "sports": ["Hockey", "Voley"]}, '
      '${venueHaedoWithoutCourts.replaceAll(haedoId, venueHaedo)}]';
  const fullCatalog =
      '{"sports": ['
      '{"key": "Futbol", "name": "Fútbol", "kinds": ['
      '{"key": "F5", "name": "Fútbol 5"}]},'
      '{"key": "Tenis", "name": "Tenis", "kinds": ['
      '{"key": "PDL", "name": "Polvo de ladrillo"}]},'
      '{"key": "Voley", "name": "Vóley", "kinds": ['
      '{"key": "IND", "name": "Indoor"}]},'
      '{"key": "Hockey", "name": "Hockey", "kinds": ['
      '{"key": "H7", "name": "Hockey 7"}]}]}';

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
      Future<void> open(WidgetTester tester, String start, {String? spaces}) =>
          mountUser(
            tester,
            dark: dark,
            size: size,
            start: start,
            api: apiRoutes({
              ...venueRoutes(
                venues: venues,
                spaces:
                    spaces ??
                    '[$spaceF5Json, $spaceTennisJson]'.replaceAll(
                      moronId,
                      venueMoron,
                    ),
              ),
              'GET /spaces/catalog': (200, fullCatalog),
              'POST /bookings': (
                201,
                bookingJson(
                  start: '2026-11-12T21:00:00+00:00',
                  end: '2026-11-12T22:00:00+00:00',
                ),
              ),
            }),
          );

      testWidgets('all venues $width $mode', (tester) async {
        await open(tester, '/sedes');
        await capture(tester, 'venues/all_${width}_$mode.png');
      });

      testWidgets('venue with courts $width $mode', (tester) async {
        await open(tester, '/sedes/$venueMoron');
        await capture(tester, 'venues/venue_${width}_$mode.png');
      });

      testWidgets('venue filtered by sport $width $mode', (tester) async {
        final semantics = tester.ensureSemantics();
        await open(tester, '/sedes/$venueMoron');
        await tester.tap(find.bySemanticsLabel('Deporte Fútbol'));
        await tester.pumpAndSettle();
        await capture(tester, 'venues/venue_filtered_${width}_$mode.png');
        semantics.dispose();
      });

      testWidgets('venue without courts $width $mode', (tester) async {
        await open(tester, '/sedes/$venueHaedo', spaces: '[]');
        await capture(tester, 'venues/venue_empty_${width}_$mode.png');
      });

      testWidgets('schedule $width $mode', (tester) async {
        await open(
          tester,
          '/sedes/$venueMoron/canchas/00000000-0000-7000-8000-000000000009',
        );
        await capture(tester, 'venues/availability_${width}_$mode.png');
      });

      testWidgets('schedule with a chosen slot $width $mode', (tester) async {
        final semantics = tester.ensureSemantics();
        await open(
          tester,
          '/sedes/$venueMoron/canchas/00000000-0000-7000-8000-000000000009',
        );
        final slot = find.bySemanticsLabel('18:00 – 19:00');
        await tester.ensureVisible(slot);
        await tester.pumpAndSettle();
        await tester.tap(slot);
        await tester.pumpAndSettle();
        await capture(tester, 'venues/availability_chosen_${width}_$mode.png');
        await tester.tap(find.text('CONTINUAR'));
        await tester.pumpAndSettle();
        await capture(tester, 'venues/confirm_${width}_$mode.png');
        await tester.tap(find.text('CONFIRMAR RESERVA'));
        await tester.pumpAndSettle();
        await capture(tester, 'venues/confirmed_${width}_$mode.png');
        semantics.dispose();
      });

      testWidgets('schedule without slots $width $mode', (tester) async {
        await mountUser(
          tester,
          dark: dark,
          size: size,
          start:
              '/sedes/$venueMoron/canchas/00000000-0000-7000-8000-000000000009',
          api: apiRoutes({
            ...venueRoutes(venues: venues, grid: gridJson(opens: false)),
            'GET /spaces/catalog': (200, fullCatalog),
          }),
        );
        await capture(tester, 'venues/availability_empty_${width}_$mode.png');
      });
    }
  }
}
