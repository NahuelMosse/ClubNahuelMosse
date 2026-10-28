import 'package:clubnahuelmosse/features/session/presentation/account_card.dart';
import 'dart:io';

import 'package:clubnahuelmosse/common/dates.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/montar.dart';

Map<String, String> _lib() => {
  for (final archivo in Directory(
    'lib',
  ).listSync(recursive: true).whereType<File>())
    if (archivo.path.endsWith('.dart'))
      archivo.path.replaceAll(r'\', '/').substring(4): archivo
          .readAsStringSync(),
};

Set<String> _queContienen(Pattern patron) => {
  for (final MapEntry(key: ruta, value: texto) in _lib().entries)
    if (texto.contains(patron)) ruta,
};

/// Una sesión que Firebase no puede cerrar.
class _SesionQueNoCierra extends SesionFalsa {
  _SesionQueNoCierra() : super(perfilUsuario);

  @override
  Future<void> close() async => throw Exception('Firebase no respondió');
}

void main() {
  test(
    'sólo fallo_de_carga.dart, el cierre de sesión y las pantallas sin sesión avisan la sesión vencida y el error de red @ARQ-03-S2 @ARQ-03-ASM-02',
    () {
      final llamadas = RegExp(r'show(SessionExpired|NetworkError)\(context');
      expect(_queContienen(llamadas), {
        'features/session/presentation/load_failure.dart',
        'features/session/presentation/account_card.dart',
        'features/users/presentation/registration_screen.dart',
        'features/session/presentation/forgot_password_screen.dart',
      });
    },
  );

  testWidgets(
    'si Firebase no puede cerrar la sesión, la persona queda adentro y ve el error del servidor @ARQ-03-ASM-05',
    (tester) async {
      final sesion = _SesionQueNoCierra();
      await montar(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => signOut(context, sesion),
              child: const Text('Cerrar sesión'),
            ),
          ),
        ),
        tema: darkTheme,
      );

      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Error del servidor'), findsOneWidget);
      expect(sesion.profile, isNotNull);
    },
  );

  test(
    'mi perfil cierra la sesión vencida aunque ya no esté en pantalla @ARQ-03-ASM-05',
    () {
      final perfil =
          _lib()['features/users/presentation/my_profile_screen.dart']!;
      expect(
        perfil,
        matches(RegExp(r'if \(!mounted\) \{[\s\S]{0,400}?session\.close\(\)')),
      );
    },
  );

  test(
    'cada pantalla_*.dart declara sólo su widget y su State; sus piezas van a archivos de la carpeta @ARQ-03-S3 @ARQ-03-ASM-06',
    () {
      final conPiezas = {
        for (final MapEntry(key: ruta, value: texto) in _lib().entries)
          if (ruta.split('/').last.startsWith('pantalla_') &&
              RegExp(r'^class ', multiLine: true).allMatches(texto).length > 2)
            ruta,
      };
      expect(conPiezas, isEmpty);
    },
  );

  test(
    'los días y meses salen de intl en español, con la mayúscula de hoy @ARQ-03-S1 @ARQ-03-ASM-07',
    () {
      expect(_queContienen(RegExp("'[Mm]iércoles'")), isEmpty);
      expect(_queContienen(RegExp("'[Nn]oviembre'")), isEmpty);
      final jueves = DateTime(2026, 11, 12);
      expect(shortDay(jueves), 'Jue 12');
      expect(longDate(jueves), 'Jue 12 de noviembre');
      expect(weekdayName(DateTime(2026, 11, 11)), 'Miércoles');
      expect(weekdayAbbreviation(DateTime(2026, 11, 14)), 'SÁB');
      expect(shortTime(DateTime(2026, 11, 12, 9, 5)), '09:05');
      expect(isoDate(jueves), '2026-11-12');
    },
  );

  test(
    'el DNI se agrupa con intl y uno que no es número se muestra como llega @ARQ-03-ASM-07',
    () {
      expect(readableDni('30111222'), '30.111.222');
      expect(readableDni('X12'), 'X12');
      expect(readableDni(''), '');
    },
  );

  test(
    'sólo el token simulado de notificaciones usa DateTime.now @ARQ-03-ASM-04',
    () {
      expect(_queContienen('DateTime.now()'), {
        'features/notifications/data/simulated_notification_system.dart',
      });
      expect(
        _lib()['features/users/presentation/my_profile_screen.dart'],
        contains('clubNow'),
      );
    },
  );

  test(
    'los cinco chips usan SelectableChip, cada indicador en curso usa InProgress y los errores por campo se leen en un solo lugar @ARQ-03-S2 @ARQ-03-ASM-03',
    () {
      expect(_queContienen('SelectableChip(').length, greaterThanOrEqualTo(6));
      expect(_queContienen('InProgress(').length, greaterThanOrEqualTo(6));
      expect(_queContienen("'errores'"), {'common/field_errors.dart'});
      expect(_queContienen('class _Elegible '), isEmpty);
    },
  );

  test(
    'el registro exitoso conserva su pulso y sus separaciones @ARQ-03-ASM-08',
    () {
      final registro =
          _lib()['features/users/presentation/registration_done_screen.dart']!;
      expect(registro, contains('ResultScreen('));
      for (final medida in ['100', '44', '20', '36']) {
        expect(registro, contains(medida), reason: medida);
      }
    },
  );
}
