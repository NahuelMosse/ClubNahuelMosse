import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The files of `lib/`, by relative path, with their text.
Map<String, String> _lib() => {
  for (final file in Directory(
    'lib',
  ).listSync(recursive: true).whereType<File>())
    if (file.path.endsWith('.dart'))
      file.path.replaceAll(r'\', '/').substring(4): file.readAsStringSync(),
};

Set<String> _filesContaining(Pattern pattern) => {
  for (final MapEntry(key: path, value: text) in _lib().entries)
    if (text.contains(pattern)) path,
};

void main() {
  test(
    'dates, times and the DNI come from intl and no file uses padLeft @ARQ-03-S1',
    () {
      expect(_filesContaining('padLeft('), isEmpty);
      expect(_lib()['common/dates.dart'], contains('DateFormat'));
      expect(
        _filesContaining('package:intl/intl.dart'),
        contains('common/dates.dart'),
      );
    },
  );

  test(
    'only load_failure.dart reports the expired session and the network error @ARQ-03-S2 @ARQ-03-ASM-02',
    () {
      final calls = RegExp(r'show(SessionExpired|NetworkError)\(context');
      expect(_filesContaining(calls), {
        'features/session/presentation/load_failure.dart',
      });
    },
  );

  test(
    'the selectable chips and tabs are a single SelectableChip @ARQ-03-S2 @ARQ-03-ASM-03',
    () {
      final copies = RegExp(r'class _(Chip|ChipCondicion|Pestanas|Elegible) ');
      expect(_filesContaining(copies), isEmpty);
      expect(
        _lib()['common/selectable_chip.dart'],
        contains('class SelectableChip '),
      );
      expect(
        _filesContaining('SelectableChip(').length,
        greaterThanOrEqualTo(5),
      );
    },
  );

  test(
    'the successful registration is a ResultScreen and the in-progress deactivations use InProgress @ARQ-03-S2',
    () {
      expect(
        _lib()['features/users/presentation/registration_done_screen.dart'],
        contains('ResultScreen('),
      );
      expect(_lib()['common/in_progress.dart'], contains('class InProgress '));
      expect(_filesContaining('InProgress(').length, greaterThanOrEqualTo(4));
    },
  );

  test(
    'the per-field errors sent by the server are read only in field_errors.dart @ARQ-03-S2',
    () {
      expect(_filesContaining("['errors']"), {'common/field_errors.dart'});
    },
  );

  test('no screen goes over 500 lines @ARQ-03-S3', () {
    final long = {
      for (final MapEntry(key: path, value: text) in _lib().entries)
        if (path.split('/').last.startsWith('pantalla_') &&
            '\n'.allMatches(text).length > 500)
          path,
    };
    expect(long, isEmpty);
  });

  test(
    'the screenshots are compared without regenerating them @ARQ-03-S3 @ARQ-03-ASM-01',
    () {
      final screenshots = Directory('test/screenshots')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('_screenshots.dart'))
          .toList();
      expect(screenshots, isNotEmpty);
      for (final file in screenshots) {
        final text = file.readAsStringSync();
        expect(text, contains('matchesGoldenFile'), reason: file.path);
        expect(
          text,
          isNot(contains('autoUpdateGoldenFiles')),
          reason: file.path,
        );
      }
    },
  );

  test(
    'my profile validates the birth date with the club clock and nobody uses DateTime.now @ARQ-03-ASM-04',
    () {
      expect(
        _lib()['features/users/presentation/my_profile_screen.dart'],
        contains('clubNow'),
      );
      expect(_filesContaining('DateTime.now()'), isEmpty);
    },
  );
}
