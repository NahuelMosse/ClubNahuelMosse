import 'package:clubnahuelmosse/common/die_cut.dart';
import 'package:clubnahuelmosse/common/empty_state.dart';
import 'package:clubnahuelmosse/common/motion/celebration.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:clubnahuelmosse/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/mount.dart';

const _p = Palette.dark;

/// Counts what a painter draws, without rasterizing it.
class _CountingCanvas implements Canvas {
  int lines = 0;
  int circles = 0;
  int arcs = 0;

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) => lines++;

  @override
  void drawCircle(Offset c, double radius, Paint paint) => circles++;

  @override
  void drawArc(
    Rect rect,
    double startAngle,
    double sweepAngle,
    bool useCenter,
    Paint paint,
  ) => arcs++;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Future<void> _mount(WidgetTester tester, Widget child) => mountScreen(
  tester,
  Scaffold(body: Center(child: child)),
  theme: darkTheme,
);

void main() {
  testWidgets(
    'the die-cut draws only the dotted line, with no notch on either side @VIS-04-S1 @VIS-04-S2',
    (tester) async {
      await _mount(tester, const SizedBox(width: 343, child: DieCut()));

      final painter = tester
          .widgetList<CustomPaint>(
            find.descendant(
              of: find.byType(DieCut),
              matching: find.byType(CustomPaint),
            ),
          )
          .map((c) => c.painter)
          .whereType<DieCutPainter>()
          .single;
      final canvas = _CountingCanvas();
      painter.paint(canvas, const Size(343, 16));

      expect(painter.line, _p.borderControl);
      expect(canvas.lines, greaterThan(20));
      expect(canvas.circles, 0);
      expect(canvas.arcs, 0);
    },
  );

  testWidgets(
    'the confirmed-booking celebration keeps its sparks, with no ring around them @VIS-04-S4',
    (tester) async {
      await _mount(
        tester,
        const Celebration(
          center: SizedBox.square(dimension: 92),
          cheer: Text('Game on!'),
          receipt: SizedBox(height: 40),
        ),
      );
      await tester.pump(const Duration(seconds: 3));

      for (final ring in [CustomPaint, RotationTransition]) {
        expect(
          find.descendant(
            of: find.byType(Celebration),
            matching: find.byType(ring),
          ),
          findsNothing,
          reason: '$ring',
        );
      }
      final sparks = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(Celebration),
              matching: find.byType(Container),
            ),
          )
          .where(
            (c) => (c.decoration as BoxDecoration?)?.shape == BoxShape.circle,
          );
      expect(sparks, hasLength(8));
    },
  );

  testWidgets(
    'the empty-state icon sits in a plain circle, with no dashed ring and no line across it @VIS-04-S3',
    (tester) async {
      await _mount(tester, const EmptyState(title: 'No results', text: 'x'));

      final circle = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(EmptyState),
              matching: find.byType(Container),
            ),
          )
          .single;
      final decoration = circle.decoration as BoxDecoration?;
      expect(decoration?.shape, BoxShape.circle);
      expect(decoration?.border, isNull);
      expect(
        find.descendant(
          of: find.byType(EmptyState),
          matching: find.byType(CustomPaint),
        ),
        findsNothing,
      );
    },
  );
}
