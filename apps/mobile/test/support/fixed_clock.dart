import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart' as flutter_test;

/// Screenshots do not depend on the day they are generated: the club is on Thursday,
/// November 12, 2026 at 15:00 (18:00 UTC), the week of the test data.
final screenshotClock = Clock.fixed(DateTime.utc(2026, 11, 12, 18));

/// `testWidgets` with the fixed clock; the screenshots use it instead of `flutter_test`'s.
void testWidgets(
  String description,
  Future<void> Function(flutter_test.WidgetTester tester) body,
) {
  flutter_test.testWidgets(
    description,
    (tester) => withClock(screenshotClock, () => body(tester)),
  );
}
