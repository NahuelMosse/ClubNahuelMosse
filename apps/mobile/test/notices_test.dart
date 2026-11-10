import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

const _res = 'android/app/src/main/res';

String _read(String path) => File(path).readAsStringSync();

String _colorOf(String file, String name) {
  final m = RegExp(
    '<color name="$name">(#[0-9A-Fa-f]{6})</color>',
  ).firstMatch(_read(file));
  expect(m, isNotNull, reason: '$name in $file');
  return m!.group(1)!;
}

double _luminance(String hex) {
  double channel(int from) {
    final c = int.parse(hex.substring(from, from + 2), radix: 16) / 255;
    return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * channel(1) + 0.7152 * channel(3) + 0.0722 * channel(5);
}

void main() {
  test(
    'push notices use the white isotype and their own color, with no other library @VIS-01-S4 @assumption:VIS-01-ASM-04',
    () {
      final manifest = _read('android/app/src/main/AndroidManifest.xml');
      expect(
        manifest,
        contains('com.google.firebase.messaging.default_notification_icon'),
      );
      expect(manifest, contains('@drawable/ic_notificacion'));
      expect(
        manifest,
        contains('com.google.firebase.messaging.default_notification_color'),
      );
      expect(manifest, contains('@color/color_notificacion'));
      expect(
        _read('$_res/drawable/ic_notificacion.xml'),
        contains('#FFFFFFFF'),
      );
      expect(
        _read('pubspec.yaml'),
        isNot(contains('flutter_local_notifications')),
      );
    },
  );

  test(
    'the notice color contrasts in light and dark mode @VIS-01-S4 @assumption:VIS-01-ASM-05',
    () {
      final light = _colorOf('$_res/values/colors.xml', 'color_notificacion');
      expect(
        _colorOf('$_res/values-night/colors.xml', 'color_notificacion'),
        '#D4FF3D',
      );
      final ratio = 1.05 / (_luminance(light) + 0.05);
      expect(ratio, greaterThanOrEqualTo(4.5));
    },
  );
}
