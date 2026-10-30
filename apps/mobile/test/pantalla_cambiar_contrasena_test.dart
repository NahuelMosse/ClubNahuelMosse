import 'package:clubnahuelmosse/features/session/data/session_repository.dart';
import 'package:clubnahuelmosse/features/session/presentation/session.dart';
import 'package:clubnahuelmosse/features/users/presentation/change_password_screen.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'soporte/montar.dart';

void main() {
  setUpAll(cargarFuentes);

  late CredencialesFalsas credenciales;
  late List<http.Request> pedidos;

  Future<Session> sesionCon((int, String) cambio) async {
    credenciales = CredencialesFalsas();
    pedidos = [];
    final sesion = Session(
      repository: SessionRepository(
        credentials: credenciales,
        api: apiRutas({
          'GET /me': (200, perfilJson()),
          'PUT /me/password': cambio,
        }, pedidos: pedidos),
      ),
    );
    await sesion.signIn('nahuel@correo.com', 'ClubNahuel1');
    return sesion;
  }

  Future<void> montarPantalla(WidgetTester tester, Session sesion) =>
      montar(tester, ChangePasswordScreen(session: sesion), tema: darkTheme);

  Future<void> completar(
    WidgetTester tester, {
    String actual = 'ClubNahuel1',
    String nueva = 'ClubNahuel2',
    String? repetida,
  }) async {
    await tester.enterText(find.bySemanticsLabel('Contraseña actual'), actual);
    await tester.enterText(find.bySemanticsLabel('Contraseña nueva'), nueva);
    await tester.enterText(
      find.bySemanticsLabel('Repetir contraseña'),
      repetida ?? nueva,
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
  }

  bool habilitado(WidgetTester tester) =>
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'GUARDAR CONTRASEÑA'),
          )
          .onPressed !=
      null;

  testWidgets('arranca vacío y con el botón deshabilitado', (tester) async {
    final semantica = tester.ensureSemantics();
    await montarPantalla(tester, await sesionCon((204, '')));
    expect(habilitado(tester), isFalse);
    expect(find.text('Al menos 8 caracteres'), findsNothing);
    semantica.dispose();
  });

  testWidgets('muestra las reglas mientras falta alguna', (tester) async {
    final semantica = tester.ensureSemantics();
    await montarPantalla(tester, await sesionCon((204, '')));
    await tester.enterText(find.bySemanticsLabel('Contraseña nueva'), 'club');
    await tester.pump();
    expect(
      find.bySemanticsLabel('Al menos 8 caracteres: falta'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Una letra mayúscula: falta'), findsOneWidget);
    expect(find.bySemanticsLabel('Al menos un número: falta'), findsOneWidget);

    await tester.enterText(
      find.bySemanticsLabel('Contraseña nueva'),
      'ClubNahuel',
    );
    await tester.pump();
    expect(
      find.bySemanticsLabel('Una letra mayúscula: cumplida'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Al menos un número: falta'), findsOneWidget);

    await tester.enterText(
      find.bySemanticsLabel('Contraseña nueva'),
      'ClubNahuel2',
    );
    await tester.pump();
    expect(find.text('Al menos un número'), findsNothing);
    semantica.dispose();
  });

  testWidgets('la repetición distinta no deja guardar ni manda nada', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    await montarPantalla(tester, await sesionCon((204, '')));
    await completar(tester, repetida: 'ClubNahuel3');
    expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
    expect(habilitado(tester), isFalse);
    expect(pedidos.where((p) => p.method == 'PUT'), isEmpty);
    semantica.dispose();
  });

  testWidgets('guarda, vuelve a entrar con la nueva y muestra el éxito', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    await montarPantalla(tester, await sesionCon((204, '')));
    await completar(tester);

    await tester.tap(find.text('GUARDAR CONTRASEÑA'));
    await tester.pumpAndSettle();

    expect(find.text('Contraseña actualizada'), findsOneWidget);
    expect(credenciales.intentos.last, ('nahuel@correo.com', 'ClubNahuel2'));
    final put = pedidos.singleWhere((p) => p.method == 'PUT');
    expect(put.headers['authorization'], 'Bearer token-falso');
    expect(put.body, '{"current_password":"ClubNahuel1","new_password":"ClubNahuel2"}');
    semantica.dispose();
  });

  testWidgets('la actual equivocada marca el campo hasta que se corrige', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    await montarPantalla(
      tester,
      await sesionCon((
        422,
        '{"errors": {"current_password": "La contraseña actual no coincide"}}',
      )),
    );
    await completar(tester, actual: 'OtraClave9');
    await tester.tap(find.text('GUARDAR CONTRASEÑA'));
    await tester.pumpAndSettle();

    expect(find.text('La contraseña actual no coincide'), findsOneWidget);
    expect(habilitado(tester), isFalse);

    await tester.enterText(find.bySemanticsLabel('Contraseña actual'), 'Otra');
    await tester.pump();
    expect(find.text('La contraseña actual no coincide'), findsNothing);
    expect(habilitado(tester), isTrue);
    semantica.dispose();
  });

  testWidgets('con la sesión vencida avisa y cierra la sesión', (tester) async {
    final semantica = tester.ensureSemantics();
    await montarPantalla(tester, await sesionCon((401, '{}')));
    await completar(tester);
    await tester.tap(find.text('GUARDAR CONTRASEÑA'));
    await tester.pumpAndSettle();

    expect(find.text('Tu sesión expiró'), findsOneWidget);
    await tester.tap(find.text('IR AL INICIO DE SESIÓN'));
    await tester.pumpAndSettle();
    expect(credenciales.salidas, 1);
    semantica.dispose();
  });

  testWidgets('demasiados intentos se ven como error del servidor', (
    tester,
  ) async {
    // Verifica CU-04-SUP-03.
    final semantica = tester.ensureSemantics();
    await montarPantalla(tester, await sesionCon((429, '')));
    await completar(tester);
    await tester.tap(find.text('GUARDAR CONTRASEÑA'));
    await tester.pumpAndSettle();
    expect(find.text('Error del servidor'), findsOneWidget);
    semantica.dispose();
  });

  testWidgets('si Firebase ya no refresca la sesión, avisa que venció', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    final sesion = await sesionCon((204, ''));
    credenciales.tokenFalla = true;
    await montarPantalla(tester, sesion);
    await completar(tester);
    await tester.tap(find.text('GUARDAR CONTRASEÑA'));
    await tester.pumpAndSettle();

    expect(find.text('Tu sesión expiró'), findsOneWidget);
    semantica.dispose();
  });

  testWidgets('tocar el campo sin escribir no borra el error del servidor', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    await montarPantalla(
      tester,
      await sesionCon((
        422,
        '{"errors": {"current_password": "La contraseña actual no coincide"}}',
      )),
    );
    await completar(tester, actual: 'OtraClave9');
    await tester.tap(find.text('GUARDAR CONTRASEÑA'));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Contraseña actual'));
    await tester.pumpAndSettle();
    expect(find.text('La contraseña actual no coincide'), findsOneWidget);
    expect(habilitado(tester), isFalse);
    semantica.dispose();
  });
}
