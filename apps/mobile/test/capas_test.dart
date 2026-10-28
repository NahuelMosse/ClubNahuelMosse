import 'dart:io';

import 'package:clubnahuelmosse/features/users/domain/registration_rules.dart';
import 'package:flutter_test/flutter_test.dart';

final _import = RegExp(
  r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

/// Imports of [file] resolved to paths relative to `lib/`, or `package:`/`dart:` URIs as they are.
List<String> _imports(File file) {
  final here = file.path
      .replaceAll('\\', '/')
      .split('lib/')
      .skip(1)
      .join('lib/');
  return [
    for (final m in _import.allMatches(file.readAsStringSync()))
      if (m[1]!.startsWith('package:clubnahuelmosse/'))
        m[1]!.substring('package:clubnahuelmosse/'.length)
      else if (m[1]!.contains(':'))
        m[1]!
      else
        Uri.parse(here).resolve(m[1]!).path,
  ];
}

Iterable<File> _dartFiles(String dir) => Directory(dir).existsSync()
    ? Directory(dir)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
    : const [];

void main() {
  test(
    'cada capa de una funcionalidad importa sólo lo que le toca @ENG-08-S3 @assumption:ENG-08-ASM-01',
    () {
      final features = Directory('lib/features');
      expect(features.existsSync(), isTrue);
      final problems = <String>[];
      for (final f in _dartFiles('lib/features')) {
        final path = f.path.replaceAll('\\', '/');
        final layer = RegExp(
          r'features/[^/]+/(data|domain|presentation)/',
        ).firstMatch(path)?[1];
        if (layer == null) {
          problems.add('$path: outside data/domain/presentation');
          continue;
        }
        for (final i in _imports(f)) {
          final flutter = i.startsWith('package:flutter/');
          final http = i.startsWith('package:http/');
          final api = i.startsWith('api/');
          final data = i.contains('/data/');
          final presentation = i.contains('/presentation/');
          final bad = switch (layer) {
            'domain' => flutter || http || api || data || presentation,
            'data' => flutter || presentation,
            _ => api,
          };
          if (bad) problems.add('$path imports $i');
        }
      }
      for (final dir in ['common', 'theme', 'api']) {
        for (final f in _dartFiles('lib/$dir')) {
          for (final i in _imports(f)) {
            if (i.startsWith('features/')) problems.add('${f.path} imports $i');
          }
        }
      }
      expect(problems, isEmpty);
    },
  );

  test(
    'las reglas del alta de usuario viven en el dominio de users y validan lo mismo @ENG-08-S4 @assumption:ENG-08-ASM-02',
    () {
      expect(
        File(
          'lib/features/users/presentation/password_rules.dart',
        ).existsSync(),
        isTrue,
      );
      expect(File('lib/comun/reglas_registro.dart').existsSync(), isFalse);
      expect(validateName('  ', requiredMessage: 'Falta'), 'Falta');
      expect(
        validateName('a' * 61, requiredMessage: 'x'),
        'Máximo 60 caracteres',
      );
      expect(validateName('Ana', requiredMessage: 'x'), isNull);
      expect(validateDni('12.345.678'), isNull);
      expect(validateDni(''), 'El DNI es obligatorio');
      expect(validateDni('123'), 'El DNI tiene 7 u 8 números');
      final today = DateTime(2026, 10, 27);
      expect(
        validateBirthDate('', today),
        'La fecha de nacimiento es obligatoria',
      );
      expect(
        validateBirthDate('27 / 10 / 2026', today),
        'La fecha tiene que ser anterior a hoy',
      );
      expect(validateEmail('a@b'), 'Revisá el formato del correo');
      expect(validateEmail('a@b.com'), isNull);
      expect(passwordProblems('abc'), [
        'Al menos 8 caracteres',
        'Una letra mayúscula',
        'Al menos un número',
      ]);
      expect(validatePassword(''), 'La contraseña es obligatoria');
      expect(validatePassword('Abcdefg1'), isNull);
    },
  );
}
