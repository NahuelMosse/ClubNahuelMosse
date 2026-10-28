// Regenera las imágenes del ícono del launcher con PintorIsotipo:
//   flutter test tool/generar_isotipo_test.dart
// y después: dart run flutter_launcher_icons
import 'dart:io';
import 'dart:ui' as ui;

import 'package:clubnahuelmosse/common/logo_mark.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

const _lado = 1024.0;
const _proporcionDelLogo = 0.62;
const _verde = Color(0xFFD4FF3D);
const _oscuro = Color(0xFF0A0A0B);

Future<void> _guardar(String ruta, {Color? fondo}) async {
  final grabador = ui.PictureRecorder();
  final lienzo = Canvas(grabador);
  if (fondo != null) {
    lienzo.drawRect(
      const Rect.fromLTWH(0, 0, _lado, _lado),
      Paint()..color = fondo,
    );
  }
  const logo = _lado * _proporcionDelLogo;
  lienzo.translate((_lado - logo) / 2, (_lado - logo) / 2);
  const LogoMarkPainter(color: _oscuro).paint(lienzo, const Size(logo, logo));
  final imagen = await grabador.endRecording().toImage(
    _lado.toInt(),
    _lado.toInt(),
  );
  final png = await imagen.toByteData(format: ui.ImageByteFormat.png);
  File(ruta).writeAsBytesSync(png!.buffer.asUint8List());
}

void main() {
  testWidgets('genera icono.png e icono_primer_plano.png', (tester) async {
    await tester.runAsync(() async {
      await _guardar('assets/icono/icono.png', fondo: _verde);
      await _guardar('assets/icono/icono_primer_plano.png');
    });
  });
}
