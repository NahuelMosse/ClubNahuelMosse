import 'dart:math' as math;

import 'package:clubnahuelmosse/common/button.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:clubnahuelmosse/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/mount.dart';

double _contrast(Color text, Color background) {
  final composite = Color.alphaBlend(text, background);
  final (light, dark) = (
    math.max(composite.computeLuminance(), background.computeLuminance()),
    math.min(composite.computeLuminance(), background.computeLuminance()),
  );
  return (light + 0.05) / (dark + 0.05);
}

void main() {
  testWidgets(
    'the dimmed button lowers only the lime background, keeps the primary text and accepts the tap @RED-05-ASM-03',
    (tester) async {
      for (final (theme, p) in [
        (darkTheme, Palette.dark),
        (lightTheme, Palette.light),
      ]) {
        var taps = 0;
        await mountScreen(
          tester,
          Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: PrimaryButton(
                label: 'CONFIRMAR',
                onTap: () => taps++,
                dimmed: true,
              ),
            ),
          ),
          theme: theme,
        );
        final style = tester
            .widget<FilledButton>(find.byType(FilledButton))
            .style;
        final background = style?.backgroundColor?.resolve({});
        final text = style?.foregroundColor?.resolve({});

        expect(background, p.accentBase.withValues(alpha: 0.4));
        expect(text, p.textPrimary);
        expect(
          _contrast(
            p.textPrimary,
            Color.alphaBlend(p.accentBase.withValues(alpha: 0.4), p.bgBase),
          ),
          greaterThanOrEqualTo(4.5),
        );
        for (final o in tester.widgetList<Opacity>(
          find.ancestor(
            of: find.byType(FilledButton),
            matching: find.byType(Opacity),
          ),
        )) {
          expect(o.opacity, 1);
        }
        await tester.tap(find.text('CONFIRMAR'));
        await tester.pump(const Duration(milliseconds: 200));
        expect(taps, 1);
      }
    },
  );
}
