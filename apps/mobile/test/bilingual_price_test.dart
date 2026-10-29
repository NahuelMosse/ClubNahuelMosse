import 'dart:ui';

import 'package:clubnahuelmosse/common/app_language.dart';
import 'package:clubnahuelmosse/common/price_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => useLanguage(const Locale('es')));

  test('the price keeps the pesos format in both languages @ENG-19-ASM-03', () {
    // The space after the sign does not break: it is a no-break space.
    for (final language in const [Locale('en'), Locale('es')]) {
      useLanguage(language);
      expect(formatPesos(38000), '\$ 38.000');
      expect(formatPesos(1500000), '\$ 1.500.000');
    }
  });
}
