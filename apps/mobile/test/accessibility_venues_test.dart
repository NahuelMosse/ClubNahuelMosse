import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clubnahuelmosse/features/bookings/presentation/my_bookings_screen.dart';

import 'my_bookings_test.dart' show bookingJson;
import 'support/mount.dart';
import 'support/user.dart';

void main() {
  setUpAll(loadFonts);

  Future<void> meetsGuidelines(WidgetTester tester) async {
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    // The cards have their own label and the contrast guideline does not see their texts: the
    // ones fully in view, above the bottom bar, are measured. The text of a disabled
    // control —a taken slot— has no contrast floor (WCAG 1.4.3).
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    final inView = Rect.fromLTWH(0, 0, screen.width, screen.height - 90);
    bool isDisabled(Element element) {
      var found = false;
      element.visitAncestorElements((ancestor) {
        final w = ancestor.widget;
        if (w is Semantics && w.properties.enabled == false) found = true;
        return !found;
      });
      return found;
    }

    final visible = find.byElementPredicate((element) {
      final text = element.widget;
      if (text is! Text || isDisabled(element)) return false;
      // The thin stroke of JetBrains Mono at 13 px on the booking card surface
      // is almost all antialiasing and the guideline takes it as the text color: it measures 1.5:1
      // even with textPrimary. That color is checked in palette_test.dart.
      if (text.style?.fontFamily == 'JetBrains Mono' &&
          element.findAncestorWidgetOfExactType<BookingCard>() != null) {
        return false;
      }
      final box = element.renderObject;
      if (box is! RenderBox || !box.hasSize) return false;
      final place = box.localToGlobal(Offset.zero) & box.size;
      return inView.contains(place.topLeft) &&
          inView.contains(place.bottomRight);
    });
    await expectLater(
      tester,
      meetsGuideline(CustomMinimumContrastGuideline(finder: visible)),
    );
  }

  /// The photos are decoded outside the test's fake clock.
  Future<void> withPhotos(WidgetTester tester) async {
    await tester.runAsync(() async {
      for (final element in find.byType(Image).evaluate()) {
        final image = element.widget;
        if (image is Image) await precacheImage(image.image, element);
      }
    });
    await tester.pumpAndSettle();
  }

  for (final dark in [true, false]) {
    final mode = dark ? 'dark' : 'light';

    testWidgets('all venues meet the guidelines in $mode mode', (tester) async {
      final semantics = tester.ensureSemantics();
      await mountUser(tester, dark: dark, api: apiRoutes(venueRoutes()));
      await withPhotos(tester);
      await meetsGuidelines(tester);
      semantics.dispose();
    });

    testWidgets('a venue with courts meets the guidelines in $mode mode', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await mountUser(
        tester,
        dark: dark,
        start: '/sedes/00000000-0000-7000-8000-000000000001',
        api: apiRoutes(venueRoutes()),
      );
      await withPhotos(tester);
      await meetsGuidelines(tester);
      semantics.dispose();
    });

    testWidgets('the time slots of a court meet the guidelines in $mode mode', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await mountUser(
        tester,
        dark: dark,
        start:
            '/sedes/00000000-0000-7000-8000-000000000001/canchas/00000000-0000-7000-8000-000000000009',
        api: apiRoutes(venueRoutes()),
      );
      await meetsGuidelines(tester);
      semantics.dispose();
    });

    testWidgets('the court search meets the guidelines in $mode mode', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await mountUser(
        tester,
        dark: dark,
        start: '/inicio/buscar',
        api: apiRoutes(venueRoutes()),
      );
      await meetsGuidelines(tester);
      semantics.dispose();
    });

    testWidgets(
      'the home with its shortcuts meets the guidelines in $mode mode',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await mountUser(
          tester,
          dark: dark,
          start: '/inicio',
          api: apiRoutes({
            ...venueRoutes(),
            'GET /bookings': (200, '{"bookings": [${bookingJson()}]}'),
          }),
        );
        await meetsGuidelines(tester);
        semantics.dispose();
      },
    );

    testWidgets('my bookings meets the guidelines in $mode mode', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await mountUser(
        tester,
        dark: dark,
        start: '/reservas',
        api: apiRoutes({
          ...venueRoutes(),
          'GET /bookings': (200, '{"bookings": [${bookingJson()}]}'),
        }),
      );
      await withPhotos(tester);
      await meetsGuidelines(tester);
      semantics.dispose();
    });
  }
}
