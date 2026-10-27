import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:clubnahuelmosse/comun/isotipo.dart';
import 'package:clubnahuelmosse/comun/pantalla_de_carga.dart';
import 'package:clubnahuelmosse/tema/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _res = 'android/app/src/main/res';

String _leer(String ruta) => File(ruta).readAsStringSync();

/// Decodifica un PNG a pixeles RGBA.
Future<({int ancho, int alto, ByteData datos})> _decodificar(String ruta) async {
  final codec = await ui.instantiateImageCodec(File(ruta).readAsBytesSync());
  final imagen = (await codec.getNextFrame()).image;
  final datos = (await imagen.toByteData())!;
  return (ancho: imagen.width, alto: imagen.height, datos: datos);
}

int _pixel(({int ancho, int alto, ByteData datos}) i, int x, int y) {
  final o = (y * i.ancho + x) * 4;
  return (i.datos.getUint8(o) << 24) |
      (i.datos.getUint8(o + 1) << 16) |
      (i.datos.getUint8(o + 2) << 8) |
      i.datos.getUint8(o + 3);
}

const _verde = 0xD4FF3DFF;

bool _hayOscuros(({int ancho, int alto, ByteData datos}) i) {
  for (var y = i.alto ~/ 4; y < i.alto * 3 ~/ 4; y++) {
    for (var x = i.ancho ~/ 4; x < i.ancho * 3 ~/ 4; x++) {
      final p = _pixel(i, x, y);
      if (((p >> 24) & 0xFF) < 60 && ((p >> 8) & 0xFF) < 60) return true;
    }
  }
  return false;
}

void main() {
  test(
    'la pantalla nativa de carga es verde eléctrico con el isotipo al centro @VIS-01-S1 @assumption:VIS-01-ASM-01',
    () {
      for (final carpeta in ['drawable', 'drawable-v21']) {
        final fondo = _leer('$_res/$carpeta/launch_background.xml');
        expect(fondo, contains('#D4FF3D'));
        expect(fondo, contains('@drawable/isotipo'));
        expect(fondo, contains('center'));
      }
      expect(_leer('$_res/drawable/isotipo.xml'), contains('#0A0A0B'));
      expect(_leer('$_res/values/colors.xml'), contains('verde_electrico'));
      for (final carpeta in ['values-v31', 'values-night-v31']) {
        final estilos = _leer('$_res/$carpeta/styles.xml');
        expect(estilos, contains('windowSplashScreenBackground'));
        expect(estilos, contains('@color/verde_electrico'));
        expect(estilos, contains('windowSplashScreenAnimatedIcon'));
        expect(estilos, contains('NormalTheme'));
      }
    },
  );

  testWidgets(
    'el ícono del launcher, sus mipmap generados y el fondo adaptativo son el isotipo oscuro sobre verde eléctrico @VIS-01-S3 @assumption:VIS-01-ASM-02',
    (tester) async {
      await tester.runAsync(() async {
        for (final ruta in [
          'assets/icono/icono.png',
          '$_res/mipmap-xxxhdpi/ic_launcher.png',
        ]) {
          final i = await _decodificar(ruta);
          expect(_pixel(i, 2, 2), _verde, reason: ruta);
          expect(_hayOscuros(i), isTrue, reason: ruta);
        }
        final primerPlano = await _decodificar(
          'assets/icono/icono_primer_plano.png',
        );
        expect(_pixel(primerPlano, 2, 2) & 0xFF, 0);
        expect(_hayOscuros(primerPlano), isTrue);
      });
      expect(_leer('$_res/values/colors.xml'), contains('#D4FF3D'));
      expect(_leer('pubspec.yaml'), contains('adaptive_icon_background: "#D4FF3D"'));
    },
  );

  test(
    'los avisos push usan el isotipo blanco y el verde eléctrico, sin otra librería @VIS-01-S4 @assumption:VIS-01-ASM-04',
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
      expect(manifiesto, contains('@color/verde_electrico'));
      expect(_leer('$_res/drawable/ic_notificacion.xml'), contains('#FFFFFFFF'));
      expect(_leer('pubspec.yaml'), isNot(contains('flutter_local_notifications')));
    },
  );

  testWidgets(
    'la espera de arranque muestra el isotipo sobre verde eléctrico y un indicador de progreso @VIS-01-S2 @assumption:VIS-01-ASM-03',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: temaClaro, home: const PantallaDeCarga()),
      );
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFFD4FF3D));
      expect(find.byType(Isotipo), findsOneWidget);
      final pintor =
          tester
                  .widget<CustomPaint>(
                    find.descendant(
                      of: find.byType(Isotipo),
                      matching: find.byType(CustomPaint),
                    ),
                  )
                  .painter!
              as PintorIsotipo;
      expect(pintor.color, const Color(0xFF0A0A0B));
      final progreso = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(progreso.color, const Color(0xFF0A0A0B));
      expect(
        tester.getCenter(find.byType(CircularProgressIndicator)).dy,
        greaterThan(tester.getCenter(find.byType(Isotipo)).dy),
      );
    },
  );
}
