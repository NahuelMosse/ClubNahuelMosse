import 'package:clubnahuelmosse/reservas/reserva_pendiente.dart';
import 'package:clubnahuelmosse/comun/apariencia.dart';
import 'package:clubnahuelmosse/admin/historial_reservas.dart';
import 'package:clubnahuelmosse/admin/pantalla_panel_admin.dart';
import 'package:clubnahuelmosse/espacios/espacios.dart';
import 'package:clubnahuelmosse/inicio/pantalla_inicio.dart';
import 'package:clubnahuelmosse/sedes/sedes.dart';
import 'package:clubnahuelmosse/sesion/pantalla_inicio_sesion.dart';
import 'package:clubnahuelmosse/sesion/pantalla_nueva_contrasena.dart';
import 'package:clubnahuelmosse/sesion/pantalla_recuperar_contrasena.dart';
import 'package:clubnahuelmosse/sesion/recuperacion.dart';
import 'package:clubnahuelmosse/sesion/sesion.dart';
import 'package:clubnahuelmosse/tema/tema.dart';
import 'package:clubnahuelmosse/usuarios/pantalla_cambiar_contrasena.dart';
import 'package:clubnahuelmosse/usuarios/pantalla_mi_perfil.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/montar.dart';

void main() {
  setUpAll(cargarFuentes);

  Widget login({bool rechaza = false}) => PantallaInicioSesion(
    pendiente: ReservaPendiente(),
    sesion: Sesion(
      credenciales: CredencialesFalsas(
        alIngresar: rechaza
            ? (_, _) async => throw const CredencialesInvalidas()
            : null,
      ),
      api: apiFalsa(codigo: 200, cuerpo: perfilJson()),
    ),
  );

  Future<void> cumpleLasGuias(WidgetTester tester) async {
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  }

  final temas = {'oscuro': temaOscuro, 'claro': temaClaro};
  final pantallas = <String, Widget Function()>{
    'el login': login,
    'el Home': () => PantallaInicio(sesion: SesionFalsa(perfilUsuario)),
    'el panel de administración': () {
      final sesion = SesionFalsa(perfilAdmin);
      final api = apiRutas({
        'GET /reservas/todas': (
          200,
          '{"reservas": [], "total": 0, "pagina": 1, "por_pagina": 20,'
              ' "contadores": {"todas": 0, "activas": 0, "completadas": 0,'
              ' "anuladas": 0}}',
        ),
      });
      return PantallaPanelAdmin(
        historial: HistorialDeReservas(api: api, sesion: sesion),
        sedes: Sedes(api: api, sesion: sesion),
        espacios: Espacios(api: api, sesion: sesion),
        sesion: sesion,
        pendientes: FiltrosDePanelPendientes(),
      );
    },
    'recuperar contraseña': () => PantallaRecuperarContrasena(
      recuperacion: Recuperacion(apiFalsa(codigo: 202, cuerpo: '')),
    ),
    'Mi perfil': () => PantallaMiPerfil(
      sesion: SesionFalsa(perfilUsuario),
      apariencia: Apariencia.enMemoria(),
    ),
    'la contraseña nueva': () => PantallaNuevaContrasena(
      recuperacion: Recuperacion(apiFalsa(codigo: 204, cuerpo: '')),
      sesion: SesionFalsa(null),
      codigo: 'abc',
    ),
    'el enlace inválido': () => PantallaNuevaContrasena(
      recuperacion: Recuperacion(apiFalsa(codigo: 410, cuerpo: '')),
      sesion: SesionFalsa(null),
      codigo: 'abc',
    ),
    'cambiar contraseña': () =>
        PantallaCambiarContrasena(sesion: SesionFalsa(perfilUsuario)),
  };

  for (final MapEntry(key: modo, value: tema) in temas.entries) {
    for (final MapEntry(key: nombre, value: pantalla) in pantallas.entries) {
      testWidgets('$nombre cumple las guías de accesibilidad en modo $modo', (
        tester,
      ) async {
        final semantica = tester.ensureSemantics();
        await montar(tester, pantalla(), tema: tema);
        await cumpleLasGuias(tester);
        semantica.dispose();
      });
    }

    testWidgets('el login con errores y aviso cumple las guías en modo $modo', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await montar(tester, login(rechaza: true), tema: tema);
      await tester.tap(find.text('INICIAR SESIÓN'));
      await tester.pumpAndSettle();
      await cumpleLasGuias(tester);
      await tester.enterText(find.bySemanticsLabel('Correo'), 'n@correo.com');
      await tester.enterText(find.bySemanticsLabel('Contraseña'), 'Mala1234');
      await tester.tap(find.text('INICIAR SESIÓN'));
      await tester.pumpAndSettle();
      expect(find.text(mensajeCredencialesInvalidas), findsOneWidget);
      await cumpleLasGuias(tester);
      semantica.dispose();
    });
  }

  for (final MapEntry(key: modo, value: tema) in temas.entries) {
    testWidgets('el perfil en edición cumple las guías en modo $modo', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await montar(
        tester,
        PantallaMiPerfil(
          sesion: SesionFalsa(perfilUsuario),
          apariencia: Apariencia.enMemoria(),
        ),
        tema: tema,
      );
      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();
      await cumpleLasGuias(tester);
      semantica.dispose();
    });
  }

  for (final MapEntry(key: modo, value: tema) in temas.entries) {
    testWidgets('la confirmación de la baja cumple las guías en modo $modo', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await montar(
        tester,
        PantallaMiPerfil(
          sesion: SesionFalsa(perfilUsuario),
          apariencia: Apariencia.enMemoria(),
        ),
        tema: tema,
      );
      await tester.ensureVisible(find.text('ELIMINAR CUENTA'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ELIMINAR CUENTA'));
      await tester.pumpAndSettle();
      await cumpleLasGuias(tester);
      semantica.dispose();
    });
  }

  testWidgets('los campos del login anuncian su nombre', (tester) async {
    final semantica = tester.ensureSemantics();
    await montar(tester, login(), tema: temaOscuro);
    expect(find.bySemanticsLabel('Correo'), findsOneWidget);
    expect(find.bySemanticsLabel('Contraseña'), findsOneWidget);
    expect(find.bySemanticsLabel('Club Nahuel Mosse'), findsOneWidget);
    semantica.dispose();
  });

  testWidgets('con el texto al 200 % nada se desborda', (tester) async {
    for (final pantalla in pantallas.values) {
      await montar(
        tester,
        pantalla(),
        tema: temaOscuro,
        tamano: const Size(360, 800),
        escalaTexto: 2,
      );
      expect(tester.takeException(), isNull);
    }
  });
}
