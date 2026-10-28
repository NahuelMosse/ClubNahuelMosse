// kit_states.dart — one golden per state and width.
// Pins the view size, pumps the widget, fails on any layout exception (a RenderFlex overflow
// included) naming the state and the width, and compares with `goldens/<state>_<width>.png`
// next to the test file. The view is restored at the end, also when a check fails.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const double _kitHeight = 800;

Future<void> kitGolden(
  WidgetTester tester,
  Widget widget, {
  required String state,
  List<double> widths = const [320, 390, 1280],
}) async {
  try {
    for (final w in widths) {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = Size(w, _kitHeight);
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      final problems = <String>[];
      Object? error;
      while ((error = tester.takeException()) != null) {
        final text = error.toString();
        final overflow = text.contains('overflowed');
        final firstLine = text.split('\n').first;
        problems.add(
          overflow
              ? 'RenderFlex overflow ($firstLine)'
              : 'exception ($firstLine)',
        );
      }
      if (problems.isNotEmpty) {
        fail('kitGolden "$state" at ${w.round()} px: ${problems.join('; ')}');
      }

      await expectLater(
        find.byWidget(widget),
        matchesGoldenFile('goldens/${state}_${w.round()}.png'),
      );
    }
  } finally {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }
}
