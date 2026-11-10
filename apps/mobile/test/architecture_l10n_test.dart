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
  final imports = <String, Set<String>>{};
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
    imports[path] = targets;
  }
  return imports;
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

void main() {
  test(
    'the app has an imports test and common imports only api, theme and l10n, which import no other lib folders @REV-06-S2 @assumption:REV-06-ASM-02 @assumption:REV-06-ASM-13',
    () {
      final graph = _graph();
      expect(
        graph['common']!.difference({'api', 'theme', 'l10n'}),
        isEmpty,
        reason: 'common can only import api, theme and l10n',
      );
      expect(graph['api'] ?? <String>{}, isEmpty);
      expect(graph['theme'] ?? <String>{}, isEmpty);
      expect(graph['l10n'] ?? <String>{}, isEmpty);
    },
  );
}
