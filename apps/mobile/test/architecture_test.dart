import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _root = '(root)';

/// The folder of `lib/` that [path] (relative to `lib/`) belongs to; loose files
/// in the root count as one more folder.
String _folder(String path) {
  final parts = path.split('/');
  return parts.length == 1 ? _root : parts.first;
}

final _import = RegExp(
  r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

/// Each file of `lib/` with the files of `lib/` it imports or re-exports (paths
/// relative to `lib/`).
Map<String, Set<String>> _files() {
  final lib = Directory('lib');
  final output = <String, Set<String>>{};
  for (final f in lib.listSync(recursive: true).whereType<File>()) {
    if (!f.path.endsWith('.dart')) continue;
    final path = f.path
        .replaceAll('\\', '/')
        .split('lib/')
        .skip(1)
        .join('lib/');
    final targets = <String>{};
    for (final m in _import.allMatches(f.readAsStringSync())) {
      final usage = m.group(1)!;
      if (usage.startsWith('package:clubnahuelmosse/')) {
        targets.add(usage.substring('package:clubnahuelmosse/'.length));
      } else if (!usage.contains(':')) {
        targets.add(Uri.parse(path).resolve(usage).path);
      }
    }
    output[path] = targets;
  }
  return output;
}

/// The dependencies between folders of `lib/`, without those of a folder on itself.
Map<String, Set<String>> _graph() {
  final graph = <String, Set<String>>{};
  for (final MapEntry(:key, :value) in _files().entries) {
    final from = _folder(key);
    graph.putIfAbsent(from, () => {});
    for (final a in value) {
      final to = _folder(a);
      if (to != from) graph[from]!.add(to);
    }
  }
  return graph;
}

/// A cycle of the [graph] (the first folder repeats at the end), or `null` if there is none.
List<String>? _cycle(Map<String, Set<String>> graph) {
  final state = <String, int>{};
  final trail = <String>[];
  List<String>? found;

  void visit(String node) {
    if (found != null) return;
    state[node] = 1;
    trail.add(node);
    for (final v in graph[node] ?? const <String>{}) {
      if (state[v] == 1) {
        found ??= [...trail.sublist(trail.indexOf(v)), v];
        return;
      }
      if (state[v] == null) visit(v);
    }
    trail.removeLast();
    state[node] = 2;
  }

  for (final n in graph.keys) {
    if (state[n] == null) visit(n);
  }
  return found;
}

/// The text of [path] (relative to `lib/`) without the line comments.
String _code(String path) => File(
  'lib/$path',
).readAsLinesSync().map((l) => l.replaceFirst(RegExp(r'//.*'), '')).join('\n');

void main() {
  test(
    'no lib folder forms an import cycle @REV-06-S4 @assumption:REV-06-ASM-02',
    () {
      expect(_cycle(_graph()), isNull);
    },
  );

  test(
    'the files in the lib root count as one folder in the cycles test @REV-06-S4 @assumption:REV-06-ASM-12',
    () {
      expect(
        _cycle({
          _root: {'a'},
          'a': {_root},
        }),
        [_root, 'a', _root],
      );
      expect(
        _cycle({
          _root: {'a'},
          'a': <String>{},
        }),
        isNull,
      );
      final graph = _graph();
      expect(graph.containsKey(_root), isTrue);
      expect(graph.entries.where((e) => e.value.contains(_root)), isEmpty);
    },
  );

  test(
    'the app has an imports test and common imports only api and theme, which import no other lib folders @REV-06-S2 @assumption:REV-06-ASM-02 @assumption:REV-06-ASM-13',
    () {
      final graph = _graph();
      expect(
        graph['common']!.difference({'api', 'theme'}),
        isEmpty,
        reason: 'common can only import api and theme',
      );
      expect(graph['api'] ?? <String>{}, isEmpty);
      expect(graph['theme'] ?? <String>{}, isEmpty);
    },
  );

  test(
    'the booking history entry does not force nulls with the ! operator @REV-06-S7 @assumption:REV-06-ASM-06',
    () {
      final forced = RegExp(r'[\w)\]]!(?!=)');
      expect(
        forced.hasMatch(
          _code('features/admin/domain/booking_history_entry.dart'),
        ),
        isFalse,
      );
    },
  );

  test(
    'the club timezone is defined only once in the app @REV-06-S10 @assumption:REV-06-ASM-07',
    () {
      final offset = RegExp(r'hours:\s*3\b');
      final where = [
        for (final path in _files().keys)
          if (offset.hasMatch(_code(path))) path,
      ];
      expect(where, ['common/club_timezone.dart']);
    },
  );
}
