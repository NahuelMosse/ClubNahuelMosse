import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart' as flutter_test;

/// Las capturas no dependen del día en que se generan: el club está en el jueves
/// 12 de noviembre de 2026 a las 15:00 (18:00 UTC), la semana de los datos de prueba.
final relojDeLasCapturas = Clock.fixed(DateTime.utc(2026, 11, 12, 18));

/// `testWidgets` con el reloj fijo; las capturas lo usan en lugar del de `flutter_test`.
void testWidgets(
  String descripcion,
  Future<void> Function(flutter_test.WidgetTester tester) cuerpo,
) {
  flutter_test.testWidgets(
    descripcion,
    (tester) => withClock(relojDeLasCapturas, () => cuerpo(tester)),
  );
}
