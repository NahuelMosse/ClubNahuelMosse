import 'dart:async';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// The suite runs with the device in Spanish (es-AR): the tests that assert Spanish text
/// stay valid. The tests of the bilingual app set their own device.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  await initializeDateFormatting('en');
  Intl.defaultLocale = 'es';
  setUp(() {
    Intl.defaultLocale = 'es';
    binding.platformDispatcher.localesTestValue = const [Locale('es', 'AR')];
  });
  await testMain();
}
