import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Names of the folders of `lib` that carry the Spanish words the app used before the rename.
const _spanishFolders = {
  'comun',
  'tema',
  'inicio',
  'reservas',
  'sedes',
  'espacios',
  'usuarios',
  'sesion',
  'notificaciones',
  'redireccion',
  'rutas',
};

const _layers = ['data', 'domain', 'presentation'];

/// A feature that shows data owned by other features has nothing of its own to fetch.
const _featuresWithoutData = {'home'};

Iterable<Directory> _dirs(String root) =>
    Directory(root).listSync(recursive: true).whereType<Directory>();

String _segment(Directory d) => d.path.replaceAll('\\', '/').split('/').last;

void main() {
  test(
    'ningún archivo de lib queda en una carpeta en castellano @ENG-16-S1 @assumption:ENG-16-ASM-01',
    () {
      final spanish = [
        for (final d in _dirs('lib'))
          if (_spanishFolders.contains(_segment(d))) d.path,
      ];
      expect(spanish, isEmpty);
    },
  );

  test(
    'cada funcionalidad de lib/features tiene sus capas data, domain y presentation @ENG-16-S2',
    () {
      final features = Directory(
        'lib/features',
      ).listSync().whereType<Directory>();
      expect(features, isNotEmpty);
      for (final feature in features) {
        final name = _segment(feature);
        final expected = [
          for (final layer in _layers)
            if (!(layer == 'data' && _featuresWithoutData.contains(name)))
              layer,
        ];
        final present = [
          for (final d in feature.listSync().whereType<Directory>())
            _segment(d),
        ]..sort();
        expect(present, containsAll(expected), reason: name);
        expect(
          present.where((layer) => !_layers.contains(layer)),
          isEmpty,
          reason: '$name has files outside the layers',
        );
        final loose = feature.listSync().whereType<File>();
        expect(loose, isEmpty, reason: '$name has loose files');
      }
    },
  );
}
