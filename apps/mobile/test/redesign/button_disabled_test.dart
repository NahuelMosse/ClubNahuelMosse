import 'package:clubnahuelmosse/common/button.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:clubnahuelmosse/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/mount.dart';

Future<void> _mount(WidgetTester tester, ThemeData theme, Widget button) =>
    mountScreen(
      tester,
      Scaffold(
        body: Padding(padding: const EdgeInsets.all(24), child: button),
      ),
      theme: theme,
    );

/// The color the button paints in [states], as its style resolves it.
(Color?, Color?) _colors(WidgetTester tester, Set<WidgetState> states) {
  final style = tester.widget<FilledButton>(find.byType(FilledButton)).style;
  return (
    style?.backgroundColor?.resolve(states),
    style?.foregroundColor?.resolve(states),
  );
}

/// No opacity below 1 between the button and the root.
void _noOpacity(WidgetTester tester) {
  final opacities = tester.widgetList<Opacity>(
    find.ancestor(
      of: find.byType(FilledButton),
      matching: find.byType(Opacity),
    ),
  );
  for (final o in opacities) {
    expect(o.opacity, 1);
  }
}

void main() {
  testWidgets(
    'the disabled primary button is gray, with secondary text and no opacity @RED-05-S3',
    (tester) async {
      for (final (theme, p) in [
        (darkTheme, Palette.dark),
        (lightTheme, Palette.light),
      ]) {
        await _mount(
          tester,
          theme,
          const PrimaryButton(label: 'CONFIRMAR', onTap: null),
        );
        expect(_colors(tester, {WidgetState.disabled}), (
          p.stateDisabled,
          p.textSecondary,
        ));
        _noOpacity(tester);
      }
    },
  );

  testWidgets(
    'the dimmed button uses the same gray and accepts the tap @RED-05-ASM-03',
    (tester) async {
      for (final (theme, p) in [
        (darkTheme, Palette.dark),
        (lightTheme, Palette.light),
      ]) {
        var taps = 0;
        await _mount(
          tester,
          theme,
          PrimaryButton(label: 'CONFIRMAR', onTap: () => taps++, dimmed: true),
        );
        expect(_colors(tester, {}), (p.stateDisabled, p.textSecondary));
        _noOpacity(tester);
        await tester.tap(find.text('CONFIRMAR'));
        await tester.pump(const Duration(milliseconds: 200));
        expect(taps, 1);
      }
    },
  );
}
