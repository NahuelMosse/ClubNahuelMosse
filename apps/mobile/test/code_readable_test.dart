import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, String> _lib() => {
  for (final f in Directory('lib').listSync(recursive: true).whereType<File>())
    if (f.path.endsWith('.dart'))
      f.path.replaceAll('\\', '/').substring('lib/'.length): f
          .readAsStringSync(),
};

/// The code without comments or string contents, with line breaks intact.
String _clean(String s) {
  final out = StringBuffer();
  var i = 0;
  while (i < s.length) {
    final c = s[i];
    if (s.startsWith('//', i)) {
      while (i < s.length && s[i] != '\n') {
        i++;
      }
    } else if (s.startsWith('/*', i)) {
      final end = s.indexOf('*/', i + 2);
      final upTo = end < 0 ? s.length : end + 2;
      out.write('\n' * '\n'.allMatches(s.substring(i, upTo)).length);
      i = upTo;
    } else if (c == "'" || c == '"') {
      final raw = i > 0 && s[i - 1] == 'r';
      final end = _stringEnd(s, i, raw);
      out.write("''");
      out.write('\n' * '\n'.allMatches(s.substring(i, end)).length);
      i = end;
    } else {
      out.write(c);
      i++;
    }
  }
  return out.toString();
}

int _stringEnd(String s, int start, bool raw) {
  final q = s[start];
  final triple = s.startsWith(q * 3, start);
  final closing = triple ? q * 3 : q;
  var i = start + closing.length;
  while (i < s.length) {
    if (s.startsWith(closing, i)) return i + closing.length;
    if (!raw && s[i] == r'\') {
      i += 2;
    } else if (!raw && s.startsWith(r'${', i)) {
      i = _interpolationEnd(s, i + 2);
    } else {
      i++;
    }
  }
  return s.length;
}

int _interpolationEnd(String s, int from) {
  var depth = 1;
  var i = from;
  while (i < s.length && depth > 0) {
    final c = s[i];
    if (c == "'" || c == '"') {
      i = _stringEnd(s, i, false);
      continue;
    }
    if (c == '{') depth++;
    if (c == '}') depth--;
    i++;
  }
  return i;
}

enum _Body { type, function, inner }

/// Length in lines of each function, method or constructor with a body in `lib`,
/// `build` included: the key is `file:line`.
Map<String, int> _lengths(String file, String text) {
  final s = _clean(text);
  final lengths = <String, int>{};
  final stack = <(_Body, int)>[];
  var parens = 0;
  var segment = -1;
  var line = 1;
  bool accepts() => stack.isEmpty || stack.last.$1 == _Body.type;
  var i = 0;
  while (i < s.length) {
    final c = s[i];
    if (c == '\n') {
      line++;
    } else if (segment < 0 && accepts() && c.trim().isNotEmpty) {
      segment = i;
    }
    if ('([<'.contains(c) && c != '<') parens++;
    if (')]'.contains(c)) parens--;
    if (c == '=' &&
        s.startsWith('=>', i) &&
        parens == 0 &&
        accepts() &&
        segment >= 0) {
      final end = _arrowEnd(s, i + 2);
      final lines = '\n'.allMatches(s.substring(segment, end)).length + 1;
      final start = line - '\n'.allMatches(s.substring(segment, i)).length;
      lengths['$file:$start'] = lines;
      line += '\n'.allMatches(s.substring(i, end)).length;
      i = end;
      segment = -1;
      continue;
    }
    if (c == '{') {
      if (accepts() && parens == 0 && segment >= 0) {
        final previous = s.substring(segment, i).trimRight();
        final isFunction = RegExp(
          r'(\)|\basync\*?|\bsync\*)$',
        ).hasMatch(previous);
        final start = line - '\n'.allMatches(s.substring(segment, i)).length;
        stack.add((isFunction ? _Body.function : _Body.type, start));
      } else {
        stack.add((_Body.inner, line));
      }
      if (stack.last.$1 != _Body.inner) segment = -1;
    } else if (c == '}' && stack.isNotEmpty) {
      final (kind, start) = stack.removeLast();
      if (kind == _Body.function) lengths['$file:$start'] = line - start + 1;
      if (accepts()) segment = -1;
    } else if (c == ';' && parens == 0 && accepts()) {
      segment = -1;
    }
    i++;
  }
  return lengths;
}

/// The index of the `;` that closes the expression starting at [from].
int _arrowEnd(String s, int from) {
  var level = 0;
  for (var i = from; i < s.length; i++) {
    final c = s[i];
    if ('([{'.contains(c)) level++;
    if (')]}'.contains(c)) level--;
    if (c == ';' && level <= 0) return i + 1;
  }
  return s.length;
}

void main() {
  test(
    'the app analysis requires ordered imports and no positional booleans, and does not exclude fixed tests @SIM-03-S2 @SIM-03-S3',
    () {
      final options = File('analysis_options.yaml').readAsStringSync();
      expect(options, contains('- directives_ordering'));
      expect(options, contains('- avoid_positional_boolean_parameters'));
      expect(options, isNot(contains('anular_desde_el_detalle_test')));
    },
  );

  test(
    'no lib function goes over 80 lines, build included @SIM-03-S2 @assumption:SIM-03-ASM-03',
    () {
      final long = <String, int>{};
      for (final MapEntry(key: path, value: text) in _lib().entries) {
        _lengths(path, text).forEach((where, length) {
          if (length > 80) long[where] = length;
        });
      }
      expect(long, isEmpty);
    },
  );

  test('no leftover paginaQueSube or other unused code in lib @SIM-03-S3', () {
    final users = [
      for (final MapEntry(key: path, value: text) in _lib().entries)
        if (text.contains('paginaQueSube')) path,
    ];
    expect(users, isEmpty);
  });

  test(
    'motion.dart re-exports its widgets from common/motion without changing the imports @assumption:SIM-03-ASM-02',
    () {
      final index = File('lib/common/motion.dart').readAsStringSync();
      final exports = RegExp(
        r'^export .*$',
        multiLine: true,
      ).allMatches(index).map((m) => m.group(0)!).toList();
      expect(exports, isNotEmpty);
      for (final e in exports) {
        expect(e, contains("'motion/"));
        expect(e, contains(' show '), reason: e);
      }
      expect(index, isNot(contains('Widget')));
      for (final widget in [
        'FadeIn',
        'StaggeredEntrance',
        'Shake',
        'SuccessPulse',
        'Heartbeat',
        'Pressable',
        'Celebration',
        'AppMotion',
      ]) {
        expect(index, contains(widget), reason: widget);
      }
      final pieces = Directory(
        'lib/common/motion',
      ).listSync().whereType<File>().where((f) => f.path.endsWith('.dart'));
      expect(pieces.length, greaterThanOrEqualTo(6));
    },
  );

  test('the app router lives outside app.dart @SIM-03-S2', () {
    final lib = _lib();
    expect(lib['app.dart'], isNot(contains('GoRoute(')));
    expect(lib['app.dart'], isNot(contains('GoRouter(')));
    expect(lib['router.dart'], contains('GoRouter('));
  });

  test(
    'the pieces of a long build live in files of their own in the module @assumption:SIM-03-ASM-01',
    () {
      final lib = _lib();
      for (final path in [
        'features/bookings/presentation/booking_card.dart',
        'features/admin/presentation/booking_filters_screen.dart',
        'features/admin/presentation/admin_panel_screen.dart',
        'features/bookings/presentation/booking_confirmed_screen.dart',
        'features/session/presentation/account_card.dart',
        'features/admin/presentation/new_space_screen.dart',
      ]) {
        final text = lib[path]!;
        final classes = RegExp(
          r'^class (\w+)',
          multiLine: true,
        ).allMatches(text).map((m) => m.group(1)!).toList();
        expect(classes.length, lessThanOrEqualTo(2), reason: '$path $classes');
        expect(
          '\n'.allMatches(text).length,
          lessThan(250),
          reason: '$path is long',
        );
      }
    },
  );

  test(
    'the app shows the same: the screenshots are compared without regenerating them @SIM-03-S1',
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
}
