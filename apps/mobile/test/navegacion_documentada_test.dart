import 'dart:io';

import 'package:clubnahuelmosse/features/admin/presentation/admin_panel_screen.dart';
import 'package:clubnahuelmosse/app.dart';
import 'package:clubnahuelmosse/common/appearance.dart';
import 'package:clubnahuelmosse/features/session/presentation/access_denied_screen.dart';
import 'package:clubnahuelmosse/features/session/presentation/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/montar.dart';

const _acceso = '/admin/acceso-denegado';

/// Cada fila de la tabla de rutas de la página: la ruta con valores de ejemplo y quién entra.
List<(String, String)> _filas() {
  final texto = File(
    '../../docs/technical/navegacion-de-la-app.md',
  ).readAsStringSync();
  final tabla = texto.split('## Rutas').last.split('\n## ').first;
  final fila = RegExp(
    r'^\| `([^`]+)` \|.*\| ([^|]+) \| [^|]+ \|$',
    multiLine: true,
  );
  return [
    for (final m in fila.allMatches(tabla))
      (
        m
            .group(1)!
            .replaceAllMapped(RegExp(r':\w+'), (_) => '1')
            .replaceAll(RegExp(r'=(?=&|$)'), '=1'),
        m.group(2)!.trim(),
      ),
  ];
}

void main() {
  testWidgets(
    'quién puede entrar a cada ruta es lo que dice la página de navegación @DOC-01-S2',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final filas = _filas();
      expect(filas.length, greaterThanOrEqualTo(30));

      for (final (ruta, quien) in filas) {
        for (final sesion in ['ninguna', 'usuario', 'admin']) {
          await tester.pumpWidget(
            App(
              key: UniqueKey(),
              api: apiRutas({}),
              session: SesionFalsa(switch (sesion) {
                'usuario' => perfilUsuario,
                'admin' => perfilAdmin,
                _ => null,
              }),
              appearance: Appearance.inMemory(),
              initialLocation: ruta,
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));
          await tester.pump(const Duration(milliseconds: 300));

          final entra = switch (quien) {
            'Sin sesión' => true,
            'Cualquiera con sesión' => sesion != 'ninguna',
            'Usuario' => sesion == 'usuario',
            'Admin' => sesion == 'admin',
            _ => throw StateError('rol sin documentar: $quien'),
          };
          final alLogin =
              ruta != '/' &&
              find.byType(LoginScreen).hitTestable().evaluate().isNotEmpty;
          final denegado =
              ruta != _acceso &&
              find
                  .byType(AccessDeniedScreen)
                  .hitTestable()
                  .evaluate()
                  .isNotEmpty;
          final alPanel =
              quien != 'Admin' &&
              ruta != _acceso &&
              sesion == 'admin' &&
              quien == 'Usuario' &&
              find.byType(AdminPanelScreen).evaluate().isNotEmpty;

          expect(
            !(alLogin || denegado || alPanel),
            entra,
            reason: '$ruta con sesión «$sesion»: la página dice «$quien»',
          );
        }
      }
    },
  );
}
