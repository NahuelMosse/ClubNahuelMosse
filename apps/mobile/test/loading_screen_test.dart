import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:clubnahuelmosse/common/loading_screen.dart';
import 'package:clubnahuelmosse/common/logo_mark.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _res = 'android/app/src/main/res';

String _read(String path) => File(path).readAsStringSync();

/// Decodes a PNG into RGBA pixels.
Future<({int width, int height, ByteData data})> _decode(String path) async {
  final codec = await ui.instantiateImageCodec(File(path).readAsBytesSync());
  final image = (await codec.getNextFrame()).image;
  final data = (await image.toByteData())!;
  return (width: image.width, height: image.height, data: data);
}

int _pixel(({int width, int height, ByteData data}) i, int x, int y) {
  final o = (y * i.width + x) * 4;
  return (i.data.getUint8(o) << 24) |
      (i.data.getUint8(o + 1) << 16) |
      (i.data.getUint8(o + 2) << 8) |
      i.data.getUint8(o + 3);
}

const _green = 0xD4FF3DFF;

bool _hasDark(({int width, int height, ByteData data}) i) {
  for (var y = i.height ~/ 4; y < i.height * 3 ~/ 4; y++) {
    for (var x = i.width ~/ 4; x < i.width * 3 ~/ 4; x++) {
      final p = _pixel(i, x, y);
      if (((p >> 24) & 0xFF) < 60 && ((p >> 8) & 0xFF) < 60) return true;
    }
  }
  return false;
}

void main() {
  test(
    'the native loading screen is electric green with the isotype in the center @VIS-01-S1 @assumption:VIS-01-ASM-01',
    () {
      for (final folder in ['drawable', 'drawable-v21']) {
        final background = _read('$_res/$folder/launch_background.xml');
        expect(background, contains('#D4FF3D'));
        expect(background, contains('@drawable/isotipo'));
        expect(background, contains('center'));
      }
      expect(_read('$_res/drawable/isotipo.xml'), contains('#0A0A0B'));
      expect(_read('$_res/values/colors.xml'), contains('verde_electrico'));
      for (final folder in ['values-v31', 'values-night-v31']) {
        final styles = _read('$_res/$folder/styles.xml');
        expect(styles, contains('windowSplashScreenBackground'));
        expect(styles, contains('@color/verde_electrico'));
        expect(styles, contains('windowSplashScreenAnimatedIcon'));
        expect(styles, contains('NormalTheme'));
      }
    },
  );

  testWidgets(
    'the launcher icon, its generated mipmaps and the adaptive background are the dark isotype on electric green @VIS-01-S3 @assumption:VIS-01-ASM-02',
    (tester) async {
      await tester.runAsync(() async {
        for (final path in [
          'assets/icono/icono.png',
          '$_res/mipmap-xxxhdpi/ic_launcher.png',
        ]) {
          final i = await _decode(path);
          expect(_pixel(i, 2, 2), _green, reason: path);
          expect(_hasDark(i), isTrue, reason: path);
        }
        final foreground = await _decode('assets/icono/icono_primer_plano.png');
        expect(_pixel(foreground, 2, 2) & 0xFF, 0);
        expect(_hasDark(foreground), isTrue);
      });
      expect(_read('$_res/values/colors.xml'), contains('#D4FF3D'));
      expect(
        _read('pubspec.yaml'),
        contains('adaptive_icon_background: "#D4FF3D"'),
      );
    },
  );

  test(
    'push notices use the white isotype and electric green, with no other library @VIS-01-S4 @assumption:VIS-01-ASM-04',
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

  testWidgets(
    'the startup wait shows the isotype on electric green and a progress indicator @VIS-01-S2 @assumption:VIS-01-ASM-03',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: lightTheme, home: const LoadingScreen()),
      );
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFFD4FF3D));
      expect(find.byType(LogoMark), findsOneWidget);
      final painter =
          tester
                  .widget<CustomPaint>(
                    find.descendant(
                      of: find.byType(LogoMark),
                      matching: find.byType(CustomPaint),
                    ),
                  )
                  .painter!
              as LogoMarkPainter;
      expect(painter.color, const Color(0xFF0A0A0B));
      final progress = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(progress.color, const Color(0xFF0A0A0B));
      expect(
        tester.getCenter(find.byType(CircularProgressIndicator)).dy,
        greaterThan(tester.getCenter(find.byType(LogoMark)).dy),
      );
    },
  );
}
