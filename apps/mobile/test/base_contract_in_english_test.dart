import 'package:clubnahuelmosse/common/field_errors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'los errores por campo que manda la API con la clave errores se siguen mostrando @assumption:ENG-08-ASM-06',
    () {
      expect(
        fieldErrors({
          'errors': {'dni': 'El DNI ya existe', 'edad': 3},
        }),
        {'dni': 'El DNI ya existe'},
      );
      expect(fieldErrors('texto'), isEmpty);
      expect(
        fieldErrors({
          'errores': {'dni': 'x'},
        }),
        isEmpty,
      );
    },
  );
}
