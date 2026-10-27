// kit_a11y.dart — the four accessibility guidelines of flutter_test, one message.
// Runs text contrast, Android and iOS tap targets and labeled tap targets on the current screen and
// fails once with every failure, so a screen is fixed in one pass.
import 'package:flutter_test/flutter_test.dart';

Future<void> kitA11y(WidgetTester tester) async {
  final handle = tester.ensureSemantics();
  final failures = <String>[];
  try {
    final guidelines = <String, AccessibilityGuideline>{
      'textContrastGuideline': textContrastGuideline,
      'androidTapTargetGuideline': androidTapTargetGuideline,
      'iOSTapTargetGuideline': iOSTapTargetGuideline,
      'labeledTapTargetGuideline': labeledTapTargetGuideline,
    };
    for (final entry in guidelines.entries) {
      final result = await entry.value.evaluate(tester);
      if (!result.passed) failures.add('${entry.key}: ${result.reason}');
    }
  } finally {
    handle.dispose();
  }
  if (failures.isNotEmpty) {
    fail('kitA11y: ${failures.length} of 4 guidelines failed\n${failures.join('\n')}');
  }
}
