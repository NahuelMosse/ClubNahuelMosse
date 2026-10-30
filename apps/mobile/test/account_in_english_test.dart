import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _features = ['venues', 'spaces', 'session', 'users', 'notifications'];
const _oldFolders = [
  'sedes',
  'espacios',
  'sesion',
  'usuarios',
  'notificaciones',
];
final _spanishFile = RegExp(
  r'^(pantalla|tarjeta|cabecera|encabezado|boton|campo|formulario|aviso)_',
);

Iterable<File> _dartFiles(String dir) => Directory(dir).existsSync()
    ? Directory(dir)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
    : const [];

String _name(File f) => f.path.replaceAll('\\', '/').split('/').last;

void main() {
  test(
    'sedes, espacios, sesión, usuarios, notificaciones y el router viven en inglés y no quedan carpetas en castellano @ENG-11-S1 @assumption:ENG-11-ASM-02',
    () {
      for (final old in _oldFolders) {
        expect(Directory('lib/$old').existsSync(), isFalse, reason: 'lib/$old');
      }
      expect(File('lib/rutas.dart').existsSync(), isFalse);
      expect(File('lib/router.dart').existsSync(), isTrue);
      for (final f in _features) {
        expect(Directory('lib/features/$f').existsSync(), isTrue, reason: f);
        for (final file in _dartFiles('lib/features/$f')) {
          expect(
            _spanishFile.hasMatch(_name(file)),
            isFalse,
            reason: file.path,
          );
        }
      }
    },
  );

  test(
    'cada funcionalidad está partida en data, domain y presentation y cumple la regla de capas @ENG-11-S2',
    () {
      for (final f in _features) {
        for (final layer in ['data', 'domain', 'presentation']) {
          final dir = 'lib/features/$f/$layer';
          // users keeps its rules in domain/presentation and its API access in data.
          expect(_dartFiles(dir), isNotEmpty, reason: dir);
        }
      }
      // The import rule itself is enforced for every feature by capas_test.dart.
      expect(File('test/capas_test.dart').existsSync(), isTrue);
    },
  );
}
