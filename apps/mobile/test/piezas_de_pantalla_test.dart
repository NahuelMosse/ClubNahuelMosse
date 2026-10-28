import 'dart:io';

import 'package:clubnahuelmosse/common/booking_card.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/montar.dart';

/// El código de un archivo de `lib/`, sin comentarios.
String _codigo(String ruta) => File(
  'lib/$ruta',
).readAsLinesSync().where((l) => !l.trimLeft().startsWith('//')).join('\n');

/// Una pantalla y las piezas de su carpeta que importa, directa o indirectamente.
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
    final codigo = _codigo(ruta);
    vistos[ruta] = codigo;
    for (final m in importDeLaCarpeta.allMatches(codigo)) {
      pendientes.add('$carpeta/${m.group(1)}');
    }
  }
  return vistos;
}

String _todo(String pantalla) => _conPiezas(pantalla).values.join('\n');

/// Lo que va sobre una foto no lee la paleta de un modo fijo ni grises escritos a mano.
void _sinTonosFijos(String pantalla) {
  _conPiezas(pantalla).forEach((ruta, codigo) {
    expect(codigo, isNot(contains('Paleta.oscura')), reason: ruta);
    expect(codigo, isNot(contains('Paleta.clara')), reason: ruta);
    expect(codigo, isNot(contains('0xFFD4D4D8')), reason: ruta);
  });
}

void _acentoSobreFoto(String pantalla) {
  _sinTonosFijos(pantalla);
  expect(_todo(pantalla), contains('accentOnMedia'), reason: pantalla);
}

void main() {
  setUpAll(cargarFuentes);

  test(
    'el sobretítulo del inicio usa accentOnMedia en la pantalla o sus piezas @RED-01-S2 @ARQ-03-S3',
    () => _acentoSobreFoto('features/home/presentation/home_screen.dart'),
  );

  test(
    'el sobretítulo de la sede usa accentOnMedia en la pantalla o sus piezas @RED-01-S2 @ARQ-03-S3',
    () => _acentoSobreFoto('features/venues/presentation/venue_screen.dart'),
  );

  test(
    'el sobretítulo de confirmar reserva usa accentOnMedia en la pantalla o sus piezas @RED-01-S2 @ARQ-03-S3',
    () => _acentoSobreFoto(
      'features/bookings/presentation/confirm_booking_screen.dart',
    ),
  );

  test(
    'el sobretítulo de horarios usa accentOnMedia en la pantalla o sus piezas @RED-01-S2 @ARQ-03-S3',
    () => _acentoSobreFoto(
      'features/bookings/presentation/availability_screen.dart',
    ),
  );

  test(
    'el acento del login usa accentOnMedia en la pantalla o sus piezas @RED-01-S2 @ARQ-03-S3',
    () => _acentoSobreFoto('features/session/presentation/login_screen.dart'),
  );

  test(
    'el texto sobre foto de cada pantalla y sus piezas sale de los tokens on-media @RED-01-S3 @ARQ-03-S3',
    () {
      for (final pantalla in [
        'features/home/presentation/home_screen.dart',
        'features/venues/presentation/venue_screen.dart',
        'features/venues/presentation/venues_screen.dart',
        'features/bookings/presentation/confirm_booking_screen.dart',
        'features/bookings/presentation/availability_screen.dart',
        'features/session/presentation/login_screen.dart',
      ]) {
        _sinTonosFijos(pantalla);
        expect(_todo(pantalla), contains('textOnMedia'), reason: pantalla);
      }
    },
  );

  test(
    'la cabecera del perfil va de bgHeroFrom a bgHeroTo @RED-01-S5 @ARQ-03-S3',
    () {
      expect(
        _todo('features/users/presentation/my_profile_screen.dart'),
        contains('[p.bgHeroFrom, p.bgHeroTo]'),
      );
    },
  );

  testWidgets(
    'el panel admin y Mis reservas muestran la reserva con la misma tarjeta @REV-06-S5 @assumption:REV-06-ASM-04 @ARQ-03-S3',
    (tester) async {
      await montar(
        tester,
        const BookingDateAndTime(
          date: 'sábado 7 de junio',
          time: '18:00 – 19:00',
        ),
        tema: darkTheme,
      );
      expect(find.text('sábado 7 de junio'), findsOneWidget);
      expect(find.text('18:00 – 19:00'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
      expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);

      for (final pantalla in [
        'features/admin/presentation/admin_panel_screen.dart',
        'features/bookings/presentation/my_bookings_screen.dart',
      ]) {
        final codigo = _todo(pantalla);
        expect(codigo, contains('common/booking_card.dart'), reason: pantalla);
        expect(codigo, contains('BookingDateAndTime('), reason: pantalla);
        expect(
          codigo,
          isNot(contains('Icons.schedule_rounded')),
          reason: pantalla,
        );
      }
    },
  );

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
