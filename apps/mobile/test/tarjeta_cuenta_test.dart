import 'package:clubnahuelmosse/app.dart';
import 'package:clubnahuelmosse/common/appearance.dart';
import 'package:clubnahuelmosse/common/avatar.dart';
import 'package:clubnahuelmosse/features/users/presentation/my_profile_screen.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'soporte/montar.dart';

void main() {
  setUpAll(cargarFuentes);

  /// Lo que necesita el panel admin (CU-14) para no fallar con un pedido real.
  final apiConPanelAdmin = apiRutas({
    'GET /reservas/todas': (
      200,
      '{"reservas": [], "total": 0, "pagina": 1, "por_pagina": 20,'
          ' "contadores": {"todas": 0, "activas": 0, "completadas": 0,'
          ' "anuladas": 0}}',
    ),
  });

  /// La app real con una sesión ya iniciada, arrancando en [inicio].
  Future<GoRouter> montarApp(
    WidgetTester tester,
    SesionFalsa sesion, {
    String inicio = '/inicio',
  }) async {
    tester.view.physicalSize = const Size(393, 852) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      App(
        api: inicio.startsWith('/admin') ? apiConPanelAdmin : apiInicio(),
        session: sesion,
        appearance: Appearance.inMemory(),
        initialLocation: inicio,
      ),
    );
    await tester.pumpAndSettle();
    return GoRouter.of(tester.element(find.byType(Scaffold).first));
  }

  Future<void> abrirTarjeta(WidgetTester tester) async {
    await tester.tap(find.bySemanticsLabel('Tu cuenta'));
    await tester.pumpAndSettle();
  }

  testWidgets('la tarjeta del usuario muestra sus datos y sus tres opciones', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    await montarApp(tester, SesionFalsa(perfilUsuario));
    await abrirTarjeta(tester);

    expect(find.text('Nahuel Mosse'), findsOneWidget);
    expect(find.text('nmosse@unimoron.edu.ar'), findsOneWidget);
    expect(find.text('MIEMBRO ACTIVO'), findsOneWidget);
    for (final opcion in ['Perfil completo', 'Mis reservas', 'Cerrar sesión']) {
      expect(find.text(opcion), findsOneWidget, reason: opcion);
    }
    semantica.dispose();
  });

  testWidgets(
    '«Perfil completo» y «Mis reservas» cierran la tarjeta y llevan a su pantalla',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final rutas = await montarApp(tester, SesionFalsa(perfilUsuario));

      await abrirTarjeta(tester);
      await tester.tap(find.text('Perfil completo'));
      await tester.pumpAndSettle();
      expect(find.text('CERRAR SESIÓN'), findsOneWidget);
      expect(find.text('Cerrar sesión'), findsNothing);

      rutas.go('/inicio');
      await tester.pumpAndSettle();
      await abrirTarjeta(tester);
      await tester.tap(find.text('Mis reservas'));
      await tester.pumpAndSettle();
      expect(find.text('Mis reservas'), findsOneWidget);
      expect(find.text('Próximas'), findsOneWidget);
      semantica.dispose();
    },
  );

  testWidgets('cerrar sesión desde la tarjeta vuelve al login', (tester) async {
    final semantica = tester.ensureSemantics();
    final sesion = SesionFalsa(perfilUsuario);
    await montarApp(tester, sesion);

    await abrirTarjeta(tester);
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(sesion.cierres, 1);
    expect(find.text('INICIAR SESIÓN'), findsOneWidget);
    semantica.dispose();
  });

  testWidgets('el administrador sólo tiene «Cerrar sesión» en su tarjeta', (
    tester,
  ) async {
    // Verifica CU-02-SUP-02.
    final semantica = tester.ensureSemantics();
    await montarApp(tester, SesionFalsa(perfilAdmin), inicio: '/admin');
    await abrirTarjeta(tester);

    expect(find.text('Ana Díaz'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsOneWidget);
    expect(find.text('Perfil completo'), findsNothing);
    expect(find.text('Mis reservas'), findsNothing);
    expect(find.text('MIEMBRO ACTIVO'), findsNothing);
    semantica.dispose();
  });

  testWidgets('tocar afuera cierra la tarjeta sin cerrar la sesión', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    final sesion = SesionFalsa(perfilUsuario);
    await montarApp(tester, sesion);
    await abrirTarjeta(tester);

    await tester.tapAt(const Offset(40, 700));
    await tester.pumpAndSettle();

    expect(find.text('Cerrar sesión'), findsNothing);
    expect(sesion.cierres, 0);
    semantica.dispose();
  });

  testWidgets('«CERRAR SESIÓN» de Mi perfil cierra la sesión', (tester) async {
    final semantica = tester.ensureSemantics();
    final sesion = SesionFalsa(perfilUsuario);
    await montar(
      tester,
      MyProfileScreen(session: sesion, appearance: Appearance.inMemory()),
      tema: darkTheme,
    );

    await tester.ensureVisible(find.text('CERRAR SESIÓN'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CERRAR SESIÓN'));
    await tester.pump();

    expect(sesion.cierres, 1);
    semantica.dispose();
  });

  test('las iniciales salen de la primera letra del nombre y del apellido', () {
    expect(AvatarInitials.initials('Nahuel Agustín', 'Mosse'), 'NM');
    expect(AvatarInitials.initials(' ángel ', 'ñandú'), 'ÁÑ');
    expect(AvatarInitials.initials('Ana', ''), 'A');
  });

  testWidgets('el avatar se abre también con el lector de pantalla', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    await montarApp(tester, SesionFalsa(perfilUsuario));
    expect(
      tester.getSemantics(find.bySemanticsLabel('Tu cuenta')),
      matchesSemantics(label: 'Tu cuenta', isButton: true, hasTapAction: true),
    );
    semantica.dispose();
  });

  testWidgets('desde Perfil completo, atrás vuelve al inicio', (tester) async {
    final semantica = tester.ensureSemantics();
    await montarApp(tester, SesionFalsa(perfilUsuario));
    await abrirTarjeta(tester);
    await tester.tap(find.text('Perfil completo'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('RESERVÁ TU CANCHA'), findsOneWidget);
    semantica.dispose();
  });

  testWidgets('cerrar sesión desde Mi perfil apilado vuelve al login', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    await montarApp(tester, SesionFalsa(perfilUsuario));
    await abrirTarjeta(tester);
    await tester.tap(find.text('Perfil completo'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('CERRAR SESIÓN'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CERRAR SESIÓN'));
    await tester.pumpAndSettle();
    expect(find.text('INICIAR SESIÓN'), findsOneWidget);
    semantica.dispose();
  });

  testWidgets('cada rol entra sólo a sus pantallas', (tester) async {
    final usuario = await montarApp(tester, SesionFalsa(perfilUsuario));
    usuario.go('/admin');
    await tester.pumpAndSettle();
    // Por enlace profundo, sin rol de administrador ve «Acceso denegado» (CU-14 FA4).
    expect(find.text('Acceso denegado'), findsOneWidget);
    await tester.tap(find.text('IR A MIS RESERVAS'));
    await tester.pumpAndSettle();
    expect(find.text('PANEL ADMIN'), findsNothing);

    final admin = await montarApp(
      tester,
      SesionFalsa(perfilAdmin),
      inicio: '/admin',
    );
    admin.go('/perfil');
    await tester.pumpAndSettle();
    expect(find.text('PANEL ADMIN'), findsOneWidget);
  });
}
