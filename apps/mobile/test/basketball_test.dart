import 'package:clubnahuelmosse/features/spaces/presentation/sport_icons.dart';
import 'package:clubnahuelmosse/features/venues/presentation/photos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the app shows «Básquet» with its icon @REV-05-S4', () {
    expect(sportIcon('Basquet'), Icons.sports_basketball_rounded);
  });

  test(
    'the «Básquet» photo is not that of a football court @REV-05-S4 @assumption:REV-05-ASM-02',
    () {
      expect(
        sportPhoto('Basquet'),
        const AssetImage('assets/imagenes/sedes/portada_1.jpg'),
      );
      for (final other in [
        'Futbol',
        'Tenis',
        'Padel',
        'Voley',
        'Hockey',
        'Golf',
      ]) {
        expect(sportPhoto(other), isNot(sportPhoto('Basquet')), reason: other);
      }
    },
  );
}
