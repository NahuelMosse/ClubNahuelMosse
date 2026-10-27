import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

const _res = 'android/app/src/main/res';

String _leer(String ruta) => File(ruta).readAsStringSync();

String _colorDe(String archivo, String nombre) {
  final m = RegExp(
    '<color name="$nombre">(#[0-9A-Fa-f]{6})</color>',
  ).firstMatch(_leer(archivo));
  expect(m, isNotNull, reason: '$nombre en $archivo');
  return m!.group(1)!;
}

double _luminancia(String hex) {
  double canal(int desde) {
    final c = int.parse(hex.substring(desde, desde + 2), radix: 16) / 255;
    return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * canal(1) + 0.7152 * canal(3) + 0.0722 * canal(5);
}

void main() {
  test(
    'los avisos push usan el isotipo blanco y un color propio, sin otra librería @VIS-01-S4 @assumption:VIS-01-ASM-04',
    () {
      final manifiesto = _leer('android/app/src/main/AndroidManifest.xml');
      expect(
        manifiesto,
        contains('com.google.firebase.messaging.default_notification_icon'),
      );
      expect(manifiesto, contains('@drawable/ic_notificacion'));
      expect(
        manifiesto,
        contains('com.google.firebase.messaging.default_notification_color'),
      );
      expect(manifiesto, contains('@color/color_notificacion'));
      expect(
        _leer('$_res/drawable/ic_notificacion.xml'),
        contains('#FFFFFFFF'),
      );
      expect(
        _leer('pubspec.yaml'),
        isNot(contains('flutter_local_notifications')),
      );
    },
  );

  test(
    'el color de los avisos contrasta en modo claro y en oscuro @VIS-01-S4 @assumption:VIS-01-ASM-05',
    () {
      final claro = _colorDe('$_res/values/colors.xml', 'color_notificacion');
      expect(
        _colorDe('$_res/values-night/colors.xml', 'color_notificacion'),
        '#D4FF3D',
      );
      final razon = 1.05 / (_luminancia(claro) + 0.05);
      expect(razon, greaterThanOrEqualTo(4.5));
    },
  );
}
