import 'package:clubnahuelmosse/api/cliente_api.dart';
import 'package:clubnahuelmosse/comun/reserva_pendiente.dart';
import 'package:clubnahuelmosse/sesion/fondo_de_inicio_sesion.dart';
import 'package:clubnahuelmosse/sesion/pantalla_inicio_sesion.dart';
import 'package:clubnahuelmosse/sesion/sesion.dart';
import 'package:clubnahuelmosse/tema/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'soporte/montar.dart';

const _pantalla = Size(393, 852);
const _alturaTeclado = 300.0;

void main() {
  setUpAll(cargarFuentes);

  Future<void> montarLogin(
    WidgetTester tester, {
    CredencialesFalsas? credenciales,
  }) async {
    final sesion = Sesion(
      credenciales: credenciales ?? CredencialesFalsas(),
      api: apiFalsa(codigo: 200, cuerpo: perfilJson()),
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
        GoRoute(
          path: '/recuperar-contrasena',
          builder: (_, _) => const Text('RECUPERAR'),
        ),
      ],
    );
    addTearDown(rutas.dispose);
    tester.view.physicalSize = _pantalla * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(
      MaterialApp.router(theme: temaOscuro, routerConfig: rutas),
    );
    await tester.pumpAndSettle();
  }

  Future<void> abrirTeclado(WidgetTester tester) async {
    tester.view.viewInsets = const FakeViewPadding(bottom: _alturaTeclado * 3);
    await tester.pumpAndSettle();
  }

  final arribaDelTeclado =_pantalla.height - _alturaTeclado;

  testWidgets(
    'con el teclado abierto la foto del inicio de sesión ocupa la misma área @SES-01-S1 @assumption:SES-01-ASM-01',
    (tester) async {
      await montarLogin(tester);
      final cerrado = tester.getRect(find.byType(FondoDeInicioSesion));

      await abrirTeclado(tester);

      expect(tester.getRect(find.byType(FondoDeInicioSesion)), cerrado);
    },
  );

  testWidgets(
    'con el teclado abierto el botón de ingresar se alcanza desplazando @SES-01-S2',
    (tester) async {
      await montarLogin(tester);
      await abrirTeclado(tester);

      await tester.ensureVisible(find.text('INICIAR SESIÓN'));
      await tester.pumpAndSettle();

      expect(
        tester.getRect(find.text('INICIAR SESIÓN')).bottom,
        lessThanOrEqualTo(arribaDelTeclado),
      );
    },
  );

  testWidgets(
    'con el teclado abierto el aviso de credenciales inválidas queda por encima del teclado @assumption:SES-01-ASM-02',
    (tester) async {
      await montarLogin(
        tester,
        credenciales: CredencialesFalsas(
          alIngresar: (_, _) async => throw const CredencialesInvalidas(),
        ),
      );
      await tester.enterText(find.bySemanticsLabel('Correo'), 'a@correo.com');
      await tester.enterText(find.bySemanticsLabel('Contraseña'), 'Mala1234');
      await abrirTeclado(tester);

      await tester.tap(find.text('INICIAR SESIÓN'));
      await tester.pumpAndSettle();

      expect(find.text(mensajeCredencialesInvalidas), findsOneWidget);
      expect(
        tester.getRect(find.byTooltip('Cerrar aviso')).bottom,
        lessThanOrEqualTo(arribaDelTeclado),
      );
    },
  );
}
