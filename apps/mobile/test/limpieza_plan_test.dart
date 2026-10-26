import 'dart:io';

import 'package:clubnahuelmosse/comun/fechas.dart';
import 'package:clubnahuelmosse/sesion/tarjeta_cuenta.dart';
import 'package:clubnahuelmosse/tema/tema.dart';
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
  Future<void> cerrar() async => throw Exception('Firebase no respondió');
}

void main() {
  test(
    'sólo fallo_de_carga.dart, el cierre de sesión y las pantallas sin sesión avisan la sesión vencida y el error de red @ARQ-03-S2 @ARQ-03-ASM-02',
    () {
      final llamadas = RegExp(r'mostrar(SesionVencida|ErrorDeRed)\(context');
      expect(_queContienen(llamadas), {
        'sesion/fallo_de_carga.dart',
        'sesion/tarjeta_cuenta.dart',
        'usuarios/pantalla_registro.dart',
        'sesion/pantalla_recuperar_contrasena.dart',
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
              onPressed: () => cerrarSesion(context, sesion),
              child: const Text('Cerrar sesión'),
            ),
          ),
        ),
        tema: temaOscuro,
      );

      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Error del servidor'), findsOneWidget);
      expect(sesion.perfil, isNotNull);
    },
  );

  test(
    'mi perfil cierra la sesión vencida aunque ya no esté en pantalla @ARQ-03-ASM-05',
    () {
      final perfil = _lib()['usuarios/pantalla_mi_perfil.dart']!;
      expect(
        perfil,
        matches(RegExp(r'if \(!mounted\) \{[\s\S]{0,400}?sesion\.cerrar\(\)')),
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
      expect(diaCorto(jueves), 'Jue 12');
      expect(fechaLarga(jueves), 'Jue 12 de noviembre');
      expect(diaDeLaSemana(DateTime(2026, 11, 11)), 'Miércoles');
      expect(diaAbreviado(DateTime(2026, 11, 14)), 'SÁB');
      expect(horaCorta(DateTime(2026, 11, 12, 9, 5)), '09:05');
      expect(fechaIso(jueves), '2026-11-12');
    },
  );

  test(
    'el DNI se agrupa con intl y uno que no es número se muestra como llega @ARQ-03-ASM-07',
    () {
      expect(dniLegible('30111222'), '30.111.222');
      expect(dniLegible('X12'), 'X12');
      expect(dniLegible(''), '');
    },
  );

  test(
    'sólo el token simulado de notificaciones usa DateTime.now @ARQ-03-ASM-04',
    () {
      expect(_queContienen('DateTime.now()'), {'notificaciones/sistema.dart'});
      expect(
        _lib()['usuarios/pantalla_mi_perfil.dart'],
        contains('ahoraEnElClub'),
      );
    },
  );

  test(
    'los cinco chips usan ChipElegible, cada indicador en curso usa EnCurso y los errores por campo se leen en un solo lugar @ARQ-03-S2 @ARQ-03-ASM-03',
    () {
      expect(_queContienen('ChipElegible(').length, greaterThanOrEqualTo(6));
      expect(_queContienen('EnCurso(').length, greaterThanOrEqualTo(6));
      expect(_queContienen("'errores'"), {'comun/errores_de_campo.dart'});
      expect(_queContienen('class _Elegible '), isEmpty);
    },
  );

  test(
    'el registro exitoso conserva su pulso y sus separaciones @ARQ-03-ASM-08',
    () {
      final registro = _lib()['usuarios/pantalla_registro_exitoso.dart']!;
      expect(registro, contains('PantallaResultado('));
      for (final medida in ['100', '44', '20', '36']) {
        expect(registro, contains(medida), reason: medida);
      }
    },
  );
}
