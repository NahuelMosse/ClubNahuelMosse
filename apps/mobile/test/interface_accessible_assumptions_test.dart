import 'package:clock/clock.dart';
import 'package:clubnahuelmosse/common/button.dart';
import 'package:clubnahuelmosse/common/clock.dart';
import 'package:clubnahuelmosse/common/date_format.dart';
import 'package:clubnahuelmosse/common/price_format.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'interface_accessible_test.dart' show contrast;
import 'support/mount.dart';
import 'support/fixed_clock.dart' show screenshotClock;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadFonts);

  test(
    'dates and prices come out in the club format, es-AR with a thousands dot and the time at −3 h @REV-04-S10 @assumption:REV-04-ASM-06',
    () {
      expect(formatPesos(38000).replaceAll(' ', ' '), '\$ 38.000');
      expect(formatPesos(1250000).replaceAll(' ', ' '), '\$ 1.250.000');
      expect(formatDate(DateTime(2026, 3, 4)), '04 / 03 / 2026');
      final now = withClock(Clock.fixed(DateTime.utc(2026, 1, 1, 2)), clubNow);
      expect((now.year, now.month, now.day, now.hour), (2025, 12, 31, 23));
    },
  );

  testWidgets(
    'the dimmed button still looks off and its text reaches 4.5:1 @REV-04-S9 @assumption:REV-04-ASM-07',
    (tester) async {
      await mountScreen(
        tester,
        Scaffold(
          body: Column(
            children: [
              PrimaryButton(label: 'ACTIVO', onTap: () {}),
              PrimaryButton(label: 'APAGADO', onTap: () {}, dimmed: true),
            ],
          ),
        ),
        theme: darkTheme,
      );
      FilledButton button(String text) =>
          tester.widget<FilledButton>(find.widgetWithText(FilledButton, text));
      final active = button('ACTIVO').style!;
      final off = button('APAGADO').style!;
      final s = <WidgetState>{};

      expect(
        off.backgroundColor!.resolve(s)!.a,
        lessThan(active.backgroundColor!.resolve(s)!.a),
      );
      final background = Color.alphaBlend(
        off.backgroundColor!.resolve(s)!,
        darkTheme.scaffoldBackgroundColor,
      );
      expect(
        contrast(off.foregroundColor!.resolve(s)!, background),
        greaterThanOrEqualTo(4.5),
      );
    },
  );

  test(
    'screenshots run with the clock fixed on 12 November 2026 at 15:00 club time @REV-04-S11 @assumption:REV-04-ASM-09',
    () {
      final now = withClock(screenshotClock, clubNow);

      expect(
        (now.year, now.month, now.day, now.hour, now.minute),
        (2026, 11, 12, 15, 0),
      );
    },
  );
}
