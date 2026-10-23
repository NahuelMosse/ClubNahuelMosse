import 'dart:async';

import 'package:clubnahuelmosse/comun/reserva_pendiente.dart';
import 'package:clubnahuelmosse/api/cliente_api.dart';
import 'package:clubnahuelmosse/sesion/pantalla_inicio_sesion.dart';
import 'package:clubnahuelmosse/sesion/sesion.dart';
import 'package:clubnahuelmosse/tema/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'soporte/montar.dart';

void main() {
  setUpAll(cargarFuentes);

  Future<void> montarLogin(
    WidgetTester tester,
    CredencialesFalsas credenciales, {
    ClienteApi? api,
  }) async {
    final sesion = Sesion(
      credenciales: credenciales,
      api: api ?? apiFalsa(codigo: 200, cuerpo: perfilJson()),
    );
    final rutas = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => PantallaInicioSesion(
            sesion: sesion,
            pendiente: ReservaPendiente(),
          ),
        ),
        GoRoute(path: '/inicio', builder: (_, _) => const Text('HOME')),
        GoRoute(path: '/admin', builder: (_, _) => const Text('PANEL')),
        GoRoute(
          path: '/recuperar-contrasena',
          builder: (_, _) => const Text('RECUPERAR'),
        ),
      ],
    );
    addTearDown(rutas.dispose);
    tester.view.physicalSize = const Size(393, 852) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp.router(theme: temaOscuro, routerConfig: rutas),
    );
    await tester.pumpAndSettle();
  }

  Future<void> ingresar(
    WidgetTester tester,
    String correo,
    String clave,
  ) async {
    await tester.enterText(find.bySemanticsLabel('Correo'), correo);
    await tester.enterText(find.bySemanticsLabel('Contraseña'), clave);
    await tester.tap(find.text('INICIAR SESIÓN'));
    await tester.pumpAndSettle();
  }

  testWidgets('con los dos campos vacíos marca ambos y no intenta ingresar', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    final credenciales = CredencialesFalsas();
    await montarLogin(tester, credenciales);

    await ingresar(tester, '   ', '');

    expect(find.text('Completá tu correo electrónico'), findsOneWidget);
    expect(find.text('Completá tu contraseña'), findsOneWidget);
    expect(credenciales.intentos, isEmpty);

    // Al escribir, el error del campo se va.
    await tester.enterText(find.bySemanticsLabel('Correo'), 'a');
    await tester.pump();
    expect(find.text('Completá tu correo electrónico'), findsNothing);
    expect(find.text('Completá tu contraseña'), findsOneWidget);
    semantica.dispose();
  });

  testWidgets('manda el correo sin espacios y en minúsculas', (tester) async {
    final semantica = tester.ensureSemantics();
    final credenciales = CredencialesFalsas();
    await montarLogin(tester, credenciales);

    await ingresar(tester, '  Nahuel@Correo.COM ', ' Clave 1 ');

    // La contraseña va tal cual: los espacios pueden ser parte de ella.
    expect(credenciales.intentos, [('nahuel@correo.com', ' Clave 1 ')]);
    expect(find.text('HOME'), findsOneWidget);
    semantica.dispose();
  });

  testWidgets('el administrador entra al panel', (tester) async {
    final semantica = tester.ensureSemantics();
    await montarLogin(
      tester,
      CredencialesFalsas(),
      api: apiFalsa(codigo: 200, cuerpo: perfilJson(rol: 'admin')),
    );

    await ingresar(tester, 'admin@club.com', 'Clave1234');

    expect(find.text('PANEL'), findsOneWidget);
    semantica.dispose();
  });

  testWidgets('credenciales inválidas: aviso genérico que se cierra con la X', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    await montarLogin(
      tester,
      CredencialesFalsas(
        alIngresar: (_, _) async => throw const CredencialesInvalidas(),
      ),
    );

    await ingresar(tester, 'nahuel@correo.com', 'Mala1234');
    expect(find.text(mensajeCredencialesInvalidas), findsOneWidget);

    await tester.tap(find.byTooltip('Cerrar aviso'));
    await tester.pumpAndSettle();
    expect(find.text(mensajeCredencialesInvalidas), findsNothing);
    semantica.dispose();
  });

  testWidgets('una cuenta sin perfil activo no entra y no queda con sesión', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    final credenciales = CredencialesFalsas();
    await montarLogin(
      tester,
      credenciales,
      api: apiFalsa(codigo: 401, cuerpo: '{"detail": "Sesión inválida"}'),
    );

    await ingresar(tester, 'baja@correo.com', 'Clave1234');

    expect(find.text(mensajeCredencialesInvalidas), findsOneWidget);
    expect(credenciales.salidas, 1);
    expect(credenciales.hayCuenta, isFalse);
    semantica.dispose();
  });

  testWidgets(
    'si la API falla, avisa del servidor y cierra la sesión de Firebase',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final credenciales = CredencialesFalsas();
      await montarLogin(
        tester,
        credenciales,
        api: apiFalsa(codigo: 500, cuerpo: 'Internal Server Error'),
      );

      await ingresar(tester, 'nahuel@correo.com', 'Clave1234');

      expect(find.text('Error del servidor'), findsOneWidget);
      expect(find.text('REINTENTAR'), findsNothing);
      expect(credenciales.hayCuenta, isFalse);
      await tester.tap(find.text('ACEPTAR'));
      await tester.pumpAndSettle();
      expect(find.text('INICIAR SESIÓN'), findsOneWidget);
      semantica.dispose();
    },
  );

  testWidgets(
    'sin conexión, REINTENTAR vuelve a intentar con los mismos datos',
    (tester) async {
      final semantica = tester.ensureSemantics();
      var fallar = true;
      final credenciales = CredencialesFalsas(
        alIngresar: (_, _) async {
          if (fallar) throw const SinConexion();
        },
      );
      await montarLogin(tester, credenciales);

      await ingresar(tester, 'nahuel@correo.com', 'Clave1234');
      expect(find.text('Error de conexión'), findsOneWidget);

      fallar = false;
      await tester.tap(find.text('REINTENTAR'));
      await tester.pumpAndSettle();
      expect(credenciales.intentos, hasLength(2));
      expect(find.text('HOME'), findsOneWidget);
      semantica.dispose();
    },
  );

  testWidgets('un segundo toque mientras ingresa no manda otro intento', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    final espera = Completer<void>();
    final credenciales = CredencialesFalsas(
      alIngresar: (_, _) => espera.future,
    );
    await montarLogin(tester, credenciales);

    await tester.enterText(find.bySemanticsLabel('Correo'), 'n@correo.com');
    await tester.enterText(find.bySemanticsLabel('Contraseña'), 'Clave1234');
    await tester.tap(find.text('INICIAR SESIÓN'));
    await tester.pump();
    await tester.tap(find.byType(FilledButton), warnIfMissed: false);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(credenciales.intentos, hasLength(1));

    espera.complete();
    await tester.pumpAndSettle();
    expect(find.text('HOME'), findsOneWidget);
    semantica.dispose();
  });

  testWidgets('«¿Olvidaste tu contraseña?» lleva a recuperarla', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    await montarLogin(tester, CredencialesFalsas());

    await tester.tap(find.text('¿Olvidaste tu contraseña?'));
    await tester.pumpAndSettle();

    expect(find.text('RECUPERAR'), findsOneWidget);
    semantica.dispose();
  });

  testWidgets('el ojo muestra y oculta la contraseña', (tester) async {
    final semantica = tester.ensureSemantics();
    await montarLogin(tester, CredencialesFalsas());
    bool oculta() => tester
        .widget<TextField>(
          find.descendant(
            of: find.bySemanticsLabel('Contraseña'),
            matching: find.byType(TextField),
          ),
        )
        .obscureText;

    expect(oculta(), isTrue);
    await tester.tap(find.byTooltip('Mostrar contraseña'));
    await tester.pump();
    expect(oculta(), isFalse);
    semantica.dispose();
  });
}
