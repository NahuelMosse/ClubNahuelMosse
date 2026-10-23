import 'package:clubnahuelmosse/espacios/iconos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'un deporte que la app no conoce se muestra con el ícono genérico @REV-05-S4 @assumption:REV-05-ASM-04',
    () {
      expect(iconoDeDeporte('Rugby'), Icons.sports_rounded);
    },
  );
}
