import 'package:clubnahuelmosse/espacios/iconos.dart';
import 'package:clubnahuelmosse/sedes/fotos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('la app muestra Básquet con su ícono @REV-05-H19-04', () {
    expect(iconoDeDeporte('Basquet'), Icons.sports_basketball_rounded);
  });

  test(
    'la foto de Básquet no es la de una cancha de fútbol @REV-05-H19-04 @assumption:REV-05-ASM-02',
    () {
      expect(
        fotoDeDeporte('Basquet'),
        const AssetImage('assets/imagenes/sedes/portada_1.jpg'),
      );
      for (final otro in [
        'Futbol',
        'Tenis',
        'Padel',
        'Voley',
        'Hockey',
        'Golf',
      ]) {
        expect(
          fotoDeDeporte(otro),
          isNot(fotoDeDeporte('Basquet')),
          reason: otro,
        );
      }
    },
  );
}
