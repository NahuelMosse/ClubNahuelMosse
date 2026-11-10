import 'package:clubnahuelmosse/common/day_timeline.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:clubnahuelmosse/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/mount.dart';

const _slots = [
  SlotState.free,
  SlotState.free,
  SlotState.taken,
  SlotState.chosen,
];

void main() {
  testWidgets(
    'free is accentLibre, taken stateDisabled and selected accentInk @RED-02-ASM-02 @RED-05-S2',
    (tester) async {
      for (final (theme, p) in [
        (darkTheme, Palette.dark),
        (lightTheme, Palette.light),
      ]) {
        await mountScreen(
          tester,
          const Scaffold(
            body: Center(child: DayTimeline(slots: _slots, from: 8)),
          ),
          theme: theme,
        );

        Color? slot(String hour) =>
            (tester
                        .widget<DecoratedBox>(
                          find.descendant(
                            of: find.byKey(ValueKey('franja-$hour')),
                            matching: find.byType(DecoratedBox),
                          ),
                        )
                        .decoration
                    as BoxDecoration)
                .color;

        Color? legend(String text) =>
            (tester
                        .widget<DecoratedBox>(
                          find.descendant(
                            of: find.ancestor(
                              of: find.text(text),
                              matching: find.byType(Row),
                            ),
                            matching: find.byType(DecoratedBox),
                          ),
                        )
                        .decoration
                    as BoxDecoration)
                .color;

        expect(slot('08'), p.accentFree);
        expect(slot('10'), p.stateDisabled);
        expect(slot('11'), p.accentInk);
        expect(legend('Libre'), p.accentFree);
        expect(legend('Ocupado'), p.stateDisabled);
        expect(legend('Elegido'), p.accentInk);
      }
    },
  );
}
