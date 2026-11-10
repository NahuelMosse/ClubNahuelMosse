import 'package:clubnahuelmosse/features/spaces/presentation/sport_icons.dart';
import 'package:clubnahuelmosse/features/venues/presentation/photos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('la app muestra Básquet con su ícono @REV-05-S4', () {
    expect(sportIcon('Basquet'), Icons.sports_basketball_rounded);
  });

  test(
    'la foto de Básquet no es la de una cancha de fútbol @REV-05-S4 @assumption:REV-05-ASM-02',
    () {
      expect(
        sportPhoto('Basquet'),
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
        expect(sportPhoto(otro), isNot(sportPhoto('Basquet')), reason: otro);
      }
    },
  );
}
