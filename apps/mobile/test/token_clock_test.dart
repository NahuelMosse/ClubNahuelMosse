import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The `lib/` files that, in a chain, are imported by name (from its folder) from [screen].
Map<String, String> _withPieces(String screen) {
  final folder = screen.substring(0, screen.lastIndexOf('/'));
  final folderImport = RegExp(r"^import '([a-z_]+/.dart)'", multiLine: true);
  final seen = <String, String>{};
  final pending = [screen];
  while (pending.isNotEmpty) {
    final path = pending.removeLast();
    if (seen.containsKey(path)) continue;
    final code = File('lib/$path').readAsStringSync();
    seen[path] = code;
    for (final m in folderImport.allMatches(code)) {
      pending.add('$folder/${m.group(1)}');
    }
  }
  return seen;
}

void main() {
  test(
    'only the simulated notifications token uses DateTime.now and my profile validates the birth date with the club clock @ARQ-03-ASM-04 @ARQ-03-S3',
    () {
      final withClock = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => f.readAsStringSync().contains('DateTime.now()'))
          .map((f) => f.path.replaceAll('\\', '/').substring('lib/'.length))
          .toSet();
      expect(withClock, {
        'features/notifications/data/simulated_notification_system.dart',
      });

      final profile = _withPieces(
        'features/users/presentation/my_profile_screen.dart',
      );
      expect(profile.values.join('\n'), contains('clubNow'));
      for (final MapEntry(:key, :value) in profile.entries) {
        expect(value, isNot(contains('DateTime.now()')), reason: key);
      }
    },
  );
}
