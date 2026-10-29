import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> _catalog(String name) =>
    jsonDecode(File('lib/l10n/$name').readAsStringSync())
        as Map<String, Object?>;

/// The arguments of an ICU message, leaving out the text of the plural branches.
Set<String?> _arguments(String message) => RegExp(
  r'(?<!=\d|zero|one|two|few|many|other)\{(\w+)[,}]',
).allMatches(message).map((m) => m.group(1)).toSet();

void main() {
  group('catalogs', () {
    test(
      'every key of app_en.arb has its Spanish translation in app_es.arb @ENG-19-S2',
      () {
        final en = _catalog('app_en.arb');
        final es = _catalog('app_es.arb');
        final keys = en.keys.where((k) => !k.startsWith('@'));
        expect(keys, isNotEmpty);
        for (final key in keys) {
          expect(es.containsKey(key), isTrue, reason: 'missing in es: $key');
          expect(es[key], isNot('""'), reason: 'empty in es: $key');
          expect(
            _arguments(es[key]! as String),
            _arguments(en[key]! as String),
            reason: 'placeholders differ in $key',
          );
        }
        final extra = es.keys.where(
          (k) => !k.startsWith('@') && !en.containsKey(k),
        );
        expect(extra, isEmpty);
      },
    );
  });
}
