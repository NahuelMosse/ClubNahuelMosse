import 'package:clubnahuelmosse/common/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide testWidgets;

import '../support/admin.dart';
import '../support/mount.dart';
import '../support/fixed_clock.dart';
import '../support/user.dart';

/// Asserts nothing: produces the step-9 strip to compare against the prototype.
void main() {
  setUpAll(loadFonts);

  const phones = {'360': Size(360, 800), '430': Size(430, 932)};
  const modes = {'dark': true, 'light': false};
  const available =
      '{"spaces": [$spaceF5Json, '
      '{"id": "00000000-0000-7000-8000-000000000011", "name": "Moron_Rivadavia_19850_Futbol_F5_2", "venue_id": "00000000-0000-7000-8000-000000000001", '
      '"venue": "Sede Morón", "sport": "Futbol", "kind": "F5", "number": 2, '
      '"covered": true, "lit": true, "price_per_hour": 43000}]}';

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

  Future<void> choose(WidgetTester tester, String field, String option) async {
    await tester.ensureVisible(find.bySemanticsLabel(field));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(field));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: find.byType(Dialog), matching: find.text(option)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> fill(WidgetTester tester, {String until = '19:00'}) async {
    await choose(tester, 'Sede', 'Sede Morón');
    await choose(tester, 'Deporte', 'Fútbol');
    final d = clubNow().add(const Duration(days: 1));
    String two(int n) => n.toString().padLeft(2, '0');
    await tester.enterText(
      find.descendant(
        of: find.bySemanticsLabel('Fecha'),
        matching: find.byType(EditableText),
      ),
      '${two(d.day)} / ${two(d.month)} / ${d.year}',
    );
    await tester.pumpAndSettle();
    if (until != '19:00') await choose(tester, 'Hasta', until);
  }

  for (final MapEntry(key: width, value: size) in phones.entries) {
    for (final MapEntry(key: mode, value: dark) in modes.entries) {
      Future<void> open(
        WidgetTester tester, {
        (int, String) response = (200, available),
      }) => mountUser(
        tester,
        dark: dark,
        size: size,
        start: '/inicio/buscar',
        api: apiRoutes({...venueRoutes(), 'GET /spaces/available': response}),
      );

      testWidgets('home with shortcuts $width $mode', (tester) async {
        await mountUser(
          tester,
          dark: dark,
          size: size,
          start: '/inicio',
          api: apiRoutes({
            ...venueRoutes(),
            'GET /bookings': (200, '{"bookings": []}'),
            'GET /notifications': (200, '{"notifications": [], "unread": 0}'),
          }),
        );
        await capture(tester, 'search/home_${width}_$mode.png');
      });

      testWidgets('filters $width $mode', (tester) async {
        final semantics = tester.ensureSemantics();
        await open(tester);
        await capture(tester, 'search/filters_${width}_$mode.png');
        semantics.dispose();
      });

      testWidgets('invalid range $width $mode', (tester) async {
        final semantics = tester.ensureSemantics();
        await open(tester);
        await fill(tester, until: '18:00');
        await capture(tester, 'search/invalid_${width}_$mode.png');
        semantics.dispose();
      });

      testWidgets('results $width $mode', (tester) async {
        final semantics = tester.ensureSemantics();
        await open(tester);
        await fill(tester);
        await tester.tap(find.text('CONSULTAR'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.textContaining('CANCHAS DISPONIBLES'));
        await capture(tester, 'search/results_${width}_$mode.png');
        semantics.dispose();
      });

      testWidgets('no results $width $mode', (tester) async {
        final semantics = tester.ensureSemantics();
        await open(tester, response: (200, '{"spaces": []}'));
        await fill(tester);
        await tester.tap(find.text('CONSULTAR'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('No hay canchas disponibles'));
        await capture(tester, 'search/empty_${width}_$mode.png');
        semantics.dispose();
      });

      testWidgets('error $width $mode', (tester) async {
        final semantics = tester.ensureSemantics();
        await open(tester, response: (500, '{}'));
        await fill(tester);
        await tester.tap(find.text('CONSULTAR'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.text('No se pudo consultar la disponibilidad'),
        );
        await capture(tester, 'search/error_${width}_$mode.png');
        semantics.dispose();
      });
    }
  }
}
