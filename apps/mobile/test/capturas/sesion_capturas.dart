import 'package:clubnahuelmosse/features/session/data/session_repository.dart';
import 'package:clubnahuelmosse/features/spaces/data/spaces_repository.dart';
import 'package:clubnahuelmosse/features/venues/data/venues_repository.dart';
import 'package:clubnahuelmosse/common/pending_booking.dart';
import 'package:clubnahuelmosse/common/appearance.dart';
import 'package:clubnahuelmosse/features/admin/data/booking_history_api.dart';
import 'package:clubnahuelmosse/features/admin/domain/pending_panel_filters.dart';
import 'package:clubnahuelmosse/features/admin/presentation/admin_panel_screen.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide testWidgets;

import '../soporte/montar.dart';
import '../soporte/reloj_fijo.dart';
import 'package:clubnahuelmosse/features/session/data/password_recovery.dart';
import 'package:clubnahuelmosse/features/session/domain/session_exceptions.dart';
import 'package:clubnahuelmosse/features/session/presentation/forgot_password_screen.dart';
import 'package:clubnahuelmosse/features/session/presentation/login_screen.dart';
import 'package:clubnahuelmosse/features/session/presentation/new_password_screen.dart';
import 'package:clubnahuelmosse/features/session/presentation/session.dart';
import 'package:clubnahuelmosse/features/spaces/presentation/spaces.dart';
import 'package:clubnahuelmosse/features/users/presentation/my_profile_screen.dart';
import 'package:clubnahuelmosse/features/venues/presentation/venues.dart';

/// No afirma nada: produce la tira del paso 9 para mirarla contra el prototipo.
void main() {
  setUpAll(cargarFuentes);

  const telefonos = {'360': Size(360, 800), '430': Size(430, 932)};
  final temas = {'oscuro': darkTheme, 'claro': lightTheme};

  Widget login() => LoginScreen(
    pending: PendingBooking(),
    session: Session(
      repository: SessionRepository(
        credentials: CredencialesFalsas(
          alIngresar: (_, _) async => throw const InvalidCredentials(),
        ),
        api: apiFalsa(codigo: 200, cuerpo: perfilJson()),
      ),
    ),
  );

  Future<void> capturar(WidgetTester tester, String archivo) async {
    // La foto del fondo se decodifica fuera del reloj falso del test.
    await tester.runAsync(() async {
      for (final elemento in find.byType(Image).evaluate()) {
        final imagen = elemento.widget;
        if (imagen is Image) await precacheImage(imagen.image, elemento);
      }
    });
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile(archivo));
  }

  for (final MapEntry(key: ancho, value: tamano) in telefonos.entries) {
    for (final MapEntry(key: modo, value: tema) in temas.entries) {
      testWidgets('login vacío $ancho $modo', (tester) async {
        await montar(tester, login(), tema: tema, tamano: tamano);
        await capturar(tester, 'sesion/login_vacio_${ancho}_$modo.png');
      });

      testWidgets('login campos incompletos $ancho $modo', (tester) async {
        final semantica = tester.ensureSemantics();
        await montar(tester, login(), tema: tema, tamano: tamano);
        await tester.tap(find.text('INICIAR SESIÓN'));
        await tester.pumpAndSettle();
        await capturar(tester, 'sesion/login_incompleto_${ancho}_$modo.png');
        semantica.dispose();
      });

      testWidgets('login credenciales inválidas $ancho $modo', (tester) async {
        final semantica = tester.ensureSemantics();
        await montar(tester, login(), tema: tema, tamano: tamano);
        await tester.enterText(
          find.bySemanticsLabel('Correo'),
          'nmosse@unimoron.edu.ar',
        );
        await tester.enterText(
          find.bySemanticsLabel('Contraseña'),
          'Clave1234',
        );
        await tester.tap(find.text('INICIAR SESIÓN'));
        await tester.pumpAndSettle();
        await capturar(tester, 'sesion/login_invalido_${ancho}_$modo.png');
        semantica.dispose();
      });

      testWidgets('home $ancho $modo', (tester) async {
        await montar(
          tester,
          inicioFalso(SesionFalsa(perfilUsuario)),
          tema: tema,
          tamano: tamano,
        );
        await capturar(tester, 'sesion/home_${ancho}_$modo.png');
      });

      testWidgets('tarjeta de la cuenta $ancho $modo', (tester) async {
        final semantica = tester.ensureSemantics();
        await montar(
          tester,
          inicioFalso(SesionFalsa(perfilUsuario)),
          tema: tema,
          tamano: tamano,
        );
        await tester.tap(find.bySemanticsLabel('Tu cuenta'));
        await tester.pumpAndSettle();
        await capturar(tester, 'sesion/tarjeta_cuenta_${ancho}_$modo.png');
        semantica.dispose();
      });

      testWidgets('mi perfil $ancho $modo', (tester) async {
        await montar(
          tester,
          MyProfileScreen(
            session: SesionFalsa(perfilUsuario),
            appearance: Appearance.inMemory(dark: modo == 'oscuro'),
          ),
          tema: tema,
          tamano: tamano,
        );
        await capturar(tester, 'sesion/mi_perfil_${ancho}_$modo.png');
      });

      testWidgets('recuperar correo inválido $ancho $modo', (tester) async {
        final semantica = tester.ensureSemantics();
        await montar(
          tester,
          ForgotPasswordScreen(
            recovery: PasswordRecovery(apiFalsa(codigo: 202, cuerpo: '')),
          ),
          tema: tema,
          tamano: tamano,
        );
        await tester.enterText(
          find.bySemanticsLabel('Correo electrónico'),
          'nmosse@unimoron',
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await capturar(tester, 'sesion/recuperar_invalido_${ancho}_$modo.png');
        semantica.dispose();
      });

      testWidgets('recuperar enviado $ancho $modo', (tester) async {
        final semantica = tester.ensureSemantics();
        await montar(
          tester,
          ForgotPasswordScreen(
            recovery: PasswordRecovery(apiFalsa(codigo: 202, cuerpo: '')),
          ),
          tema: tema,
          tamano: tamano,
        );
        await tester.enterText(
          find.bySemanticsLabel('Correo electrónico'),
          'nmosse@unimoron.edu.ar',
        );
        await tester.pump();
        await tester.tap(find.text('ENVIAR ENLACE'));
        await tester.pumpAndSettle();
        await capturar(tester, 'sesion/recuperar_enviado_${ancho}_$modo.png');
        semantica.dispose();
      });

      for (final (nombre, codigo) in [
        ('nueva', 204),
        ('enlace_invalido', 410),
      ]) {
        testWidgets('recuperar $nombre $ancho $modo', (tester) async {
          await montar(
            tester,
            NewPasswordScreen(
              recovery: PasswordRecovery(apiFalsa(codigo: codigo, cuerpo: '')),
              session: SesionFalsa(null),
              code: 'abc',
            ),
            tema: tema,
            tamano: tamano,
          );
          await capturar(
            tester,
            'sesion/recuperar_${nombre}_${ancho}_$modo.png',
          );
        });
      }

      for (final (nombre, invalido) in [
        ('edicion', false),
        ('edicion_invalida', true),
      ]) {
        testWidgets('mi perfil $nombre $ancho $modo', (tester) async {
          final semantica = tester.ensureSemantics();
          await montar(
            tester,
            MyProfileScreen(
              session: SesionFalsa(perfilUsuario),
              appearance: Appearance.inMemory(dark: modo == 'oscuro'),
            ),
            tema: tema,
            tamano: tamano,
          );
          await tester.tap(find.text('Editar'));
          await tester.pumpAndSettle();
          if (invalido) {
            await tester.enterText(find.bySemanticsLabel('DNI'), '42118');
            await tester.enterText(
              find.bySemanticsLabel('Fecha de nacimiento'),
              '32132000',
            );
            await tester.ensureVisible(find.text('GUARDAR'));
            await tester.pumpAndSettle();
            await tester.tap(find.text('GUARDAR'));
            await tester.pumpAndSettle();
            await tester.ensureVisible(find.text('DATOS PERSONALES'));
            await tester.pumpAndSettle();
          }
          await capturar(
            tester,
            'sesion/mi_perfil_${nombre}_${ancho}_$modo.png',
          );
          semantica.dispose();
        });
      }

      testWidgets('mi perfil confirmar baja $ancho $modo', (tester) async {
        await montar(
          tester,
          MyProfileScreen(
            session: SesionFalsa(perfilUsuario),
            appearance: Appearance.inMemory(dark: modo == 'oscuro'),
          ),
          tema: tema,
          tamano: tamano,
        );
        await tester.ensureVisible(find.text('ELIMINAR CUENTA'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('ELIMINAR CUENTA'));
        await tester.pumpAndSettle();
        await capturar(tester, 'sesion/confirmar_baja_${ancho}_$modo.png');
      });

      testWidgets('panel admin $ancho $modo', (tester) async {
        final sesionAdmin = SesionFalsa(perfilAdmin);
        final apiPanel = apiRutas({
          'GET /reservas/todas': (
            200,
            '{"reservas": [], "total": 0, "pagina": 1, "por_pagina": 20,'
                ' "contadores": {"todas": 0, "activas": 0, "completadas": 0,'
                ' "anuladas": 0}}',
          ),
        });
        await montar(
          tester,
          AdminPanelScreen(
            history: BookingHistory(api: apiPanel, sesion: sesionAdmin),
            venues: Venues(
              repository: VenuesRepository(api: apiPanel, session: sesionAdmin),
            ),
            spaces: Spaces(
              repository: SpacesRepository(api: apiPanel, session: sesionAdmin),
            ),
            session: sesionAdmin,
            pending: PendingPanelFilters(),
          ),
          tema: tema,
          tamano: tamano,
        );
        await capturar(tester, 'sesion/panel_admin_${ancho}_$modo.png');
      });

      testWidgets('recuperar contraseña $ancho $modo', (tester) async {
        await montar(
          tester,
          ForgotPasswordScreen(
            recovery: PasswordRecovery(apiFalsa(codigo: 202, cuerpo: '')),
          ),
          tema: tema,
          tamano: tamano,
        );
        await capturar(tester, 'sesion/recuperar_${ancho}_$modo.png');
      });
    }
  }
}
