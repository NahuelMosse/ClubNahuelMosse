import 'package:clubnahuelmosse/common/day_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide testWidgets;

import '../support/mount.dart';
import '../support/fixed_clock.dart';
import '../support/user.dart';

/// Each grid is mounted in its own test: mounting the app twice in the same test reuses the
/// API of the first mount.
Future<void> _openSchedule(WidgetTester tester, String grid) => mountUser(
  tester,
  start:
      '/venues/00000000-0000-7000-8000-000000000001/spaces/00000000-0000-7000-8000-000000000009',
  size: const Size(393, 2400),
  api: apiRoutes(venueRoutes(grid: grid)),
);

void main() {
  testWidgets(
    'with «No hay horarios disponibles» there is no day timeline @RED-03-ASM-08',
    (tester) async {
      await _openSchedule(tester, gridJson(opens: false));

      expect(find.text('No hay horarios disponibles'), findsOneWidget);
      expect(find.byType(DayTimeline), findsNothing);
    },
  );

  testWidgets(
    'with all the slots taken there is no day timeline either @RED-03-ASM-08',
    (tester) async {
      await _openSchedule(
        tester,
        gridJson(taken: {for (var h = 8; h < 23; h++) h}),
      );

      expect(find.text('No hay horarios disponibles'), findsOneWidget);
      expect(find.byType(DayTimeline), findsNothing);
    },
  );
}
