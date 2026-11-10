import 'package:clubnahuelmosse/common/bib.dart';
import 'package:clubnahuelmosse/features/venues/presentation/venues_screen.dart';
import 'package:clubnahuelmosse/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide testWidgets;

import '../support/mount.dart';
import '../support/fixed_clock.dart';
import '../support/user.dart';

void main() {
  testWidgets(
    'the venue card court count is the bib with the «CANCHAS» label, without the violet block @RED-03-ASM-14',
    (tester) async {
      await mountUser(
        tester,
        size: const Size(393, 1400),
        api: apiRoutes(venueRoutes(venues: '[$venueMoronWithSports]')),
      );

      final card = find.byType(VenueCard);
      expect(card, findsOneWidget);
      final bib = find.descendant(of: card, matching: find.byType(GiantBib));
      expect(tester.widget<GiantBib>(bib).color, Palette.dark.textOnMedia);
      final label = find.descendant(of: card, matching: find.text('CANCHAS'));
      expect(label, findsOneWidget);
      expect(
        tester.getTopLeft(label).dy,
        greaterThan(tester.getTopLeft(bib).dy),
      );
      final violets = tester
          .widgetList<Container>(
            find.descendant(of: card, matching: find.byType(Container)),
          )
          .map((c) => c.decoration)
          .whereType<BoxDecoration>()
          .where((d) => d.color == Palette.dark.accentBase);
      expect(violets, isEmpty);
    },
  );
}
