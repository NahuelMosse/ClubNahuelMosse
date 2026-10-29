import 'dart:async';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

/// The scenarios assert Spanish text: the device runs in Spanish (es-AR) whatever the
/// language of the machine that runs them.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setUp(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.localesTestValue =
        const [Locale('es', 'AR')];
  });
  await testMain();
}
