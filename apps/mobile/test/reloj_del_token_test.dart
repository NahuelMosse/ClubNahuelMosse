import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Los archivos de `lib/` que importan por nombre (de su carpeta) desde [pantalla], en cadena.
Map<String, String> _conPiezas(String pantalla) {
  final carpeta = pantalla.substring(0, pantalla.lastIndexOf('/'));
  final importDeLaCarpeta = RegExp(
    r"^import '([a-z_]+\.dart)'",
    multiLine: true,
  );
  final vistos = <String, String>{};
  final pendientes = [pantalla];
  while (pendientes.isNotEmpty) {
    final ruta = pendientes.removeLast();
    if (vistos.containsKey(ruta)) continue;
    final codigo = File('lib/$ruta').readAsStringSync();
    vistos[ruta] = codigo;
    for (final m in importDeLaCarpeta.allMatches(codigo)) {
      pendientes.add('$carpeta/${m.group(1)}');
    }
  }
  return vistos;
}

void main() {
  test(
    'sólo el token simulado de notificaciones usa DateTime.now y mi perfil valida el nacimiento con el reloj del club @ARQ-03-ASM-04 @ARQ-03-S3',
    () {
      final conReloj = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => f.readAsStringSync().contains('DateTime.now()'))
          .map((f) => f.path.replaceAll('\\', '/').substring('lib/'.length))
          .toSet();
      expect(conReloj, {
        'features/notifications/data/simulated_notification_system.dart',
      });

      final perfil = _conPiezas(
        'features/users/presentation/my_profile_screen.dart',
      );
      expect(perfil.values.join('\n'), contains('clubNow'));
      for (final MapEntry(:key, :value) in perfil.entries) {
        expect(value, isNot(contains('DateTime.now()')), reason: key);
      }
    },
  );
}
