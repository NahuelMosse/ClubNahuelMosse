import 'package:clock/clock.dart';
import 'package:clubnahuelmosse/features/home/presentation/home_greeting.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/mount.dart';

/// The clock at [hour]:[minute] club time (UTC−3) on 27/10/2026.
Clock _clubClock(int hour, int minute) => Clock.fixed(
  DateTime.utc(2026, 10, 27, hour, minute).add(const Duration(hours: 3)),
);

Future<void> _mountGreeting(WidgetTester tester, {Key? key}) => mountScreen(
  tester,
  Scaffold(
    body: HomeGreeting(key: key, session: FakeSession(userProfile)),
  ),
  theme: darkTheme,
);

void main() {
  setUpAll(loadFonts);

  testWidgets(
    'the greeting follows the club hour: mornings from 06:00 to 11:59,'
    ' afternoons from 12:00 to 19:59, nights from 20:00 to 05:59'
    ' @SAL-01-S1 @assumption:SAL-01-ASM-01',
    (tester) async {
      const cases = {
        (6, 0): 'BUENOS DÍAS,',
        (11, 59): 'BUENOS DÍAS,',
        (12, 0): 'BUENAS TARDES,',
        (19, 59): 'BUENAS TARDES,',
        (20, 0): 'BUENAS NOCHES,',
        (23, 59): 'BUENAS NOCHES,',
        (0, 0): 'BUENAS NOCHES,',
        (5, 59): 'BUENAS NOCHES,',
      };
      for (final MapEntry(key: (hour, minute), value: greeting)
          in cases.entries) {
        await withClock(_clubClock(hour, minute), () async {
          await _mountGreeting(tester, key: UniqueKey());
          expect(
            find.text(greeting),
            findsOneWidget,
            reason: 'at $hour:$minute club time',
          );
        });
      }
      expect(find.text('Nahuel'), findsOneWidget);
    },
  );

  testWidgets(
    'the greeting is computed when the home is built @assumption:SAL-01-ASM-02',
    (tester) async {
      await withClock(_clubClock(11, 59), () => _mountGreeting(tester));
      expect(find.text('BUENOS DÍAS,'), findsOneWidget);

      await withClock(_clubClock(12, 0), () async {
        await tester.pump(const Duration(minutes: 1));
        expect(find.text('BUENOS DÍAS,'), findsOneWidget);

        await _mountGreeting(tester, key: UniqueKey());
        expect(find.text('BUENAS TARDES,'), findsOneWidget);
      });
    },
  );
}
