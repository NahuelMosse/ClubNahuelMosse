import 'package:clubnahuelmosse/features/spaces/presentation/sport_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'a sport the app does not know is shown with the generic icon @REV-05-S4 @assumption:REV-05-ASM-04',
    () {
      expect(sportIcon('Rugby'), Icons.sports_rounded);
    },
  );
}
