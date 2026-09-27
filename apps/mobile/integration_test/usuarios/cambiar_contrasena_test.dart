import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../soporte/acciones.dart';
import '../soporte/red.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const actual = 'ClubNahuel1';
  const nueva = 'ClubNahuel2';

  Future<void> irACambiar(
    WidgetTester tester,
    String correo, {
    String? apiUrl,
  }) async {
    await entrarComoUsuario(tester, correo: correo, apiUrl: apiUrl);
    await tester.tap(find.bySemanticsLabel('Tu cuenta'));
    await tester.pumpAndSettle();
    await tocar(tester, 'Perfil completo');
    await tocar(tester, 'Cambiar contraseña');
    expect(find.text('Cambiá tu contraseña'), findsOneWidget);
  }

  Future<void> completar(
    WidgetTester tester, {
    String contrasenaActual = actual,
    String contrasenaNueva = nueva,
    String? repetida,
  }) async {
    await escribir(tester, 'Contraseña actual', contrasenaActual);
    await escribir(tester, 'Contraseña nueva', contrasenaNueva);
    await escribir(tester, 'Repetir contraseña', repetida ?? contrasenaNueva);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
  }

  String? escrito(WidgetTester tester, String campo) => tester
      .widget<TextField>(
        find.descendant(
          of: find.bySemanticsLabel(campo),
          matching: find.byType(TextField),
        ),
      )
      .controller
      ?.text;

  bool guardarHabilitado(WidgetTester tester) =>
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'GUARDAR CONTRASEÑA'),
          )
          .onPressed !=
      null;

  testWidgets(
    'cambia la contraseña, vuelve al perfil con la sesión abierta y la nueva sirve para entrar @CU-04-H01-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final correo = 'socio.${unico()}@correo.com';
      await irACambiar(tester, correo);

      await completar(tester);
      expect(guardarHabilitado(tester), isTrue);
      await tocar(tester, 'GUARDAR CONTRASEÑA');

      // Verifica: confirma el cambio y vuelve al perfil, no al login.
      await esperarA(tester, find.text('Contraseña actualizada'));
      await tocar(tester, 'VOLVER AL PERFIL');
      expect(find.text('MIEMBRO ACTIVO'), findsOneWidget);
      expect(find.text('INICIAR SESIÓN'), findsNothing);

      // Verifica: la nueva contraseña es la que vale en Firebase.
      expect(await puedeEntrar(correo, nueva), isTrue);

      // Verifica: la sesión de este teléfono sigue viva al reabrir la app.
      await reabrirApp(tester);
      expect(find.text('RESERVÁ TU CANCHA'), findsOneWidget);
      semantica.dispose();
    },
  );

  testWidgets(
    'después del cambio, la contraseña anterior ya no sirve para iniciar sesión @CU-04-H01-02',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final correo = 'socio.${unico()}@correo.com';
      await irACambiar(tester, correo);
      await completar(tester);
      await tocar(tester, 'GUARDAR CONTRASEÑA');
      await esperarA(tester, find.text('Contraseña actualizada'));

      // Verifica: la contraseña expuesta deja de abrir la cuenta.
      expect(await puedeEntrar(correo, actual), isFalse);
      semantica.dispose();
    },
  );

  testWidgets(
    'escribe mal la contraseña actual y ve el error sin que cambie nada @CU-04-H02-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final correo = 'socio.${unico()}@correo.com';
      await irACambiar(tester, correo);

      await completar(tester, contrasenaActual: 'OtraClave9');
      await tocar(tester, 'GUARDAR CONTRASEÑA');

      // Verifica: marca la contraseña actual y conserva lo demás.
      await esperarA(tester, find.text('La contraseña actual no coincide'));
      expect(escrito(tester, 'Contraseña nueva'), nueva);
      expect(escrito(tester, 'Repetir contraseña'), nueva);
      expect(find.text('Contraseña actualizada'), findsNothing);

      // Verifica: la contraseña no cambió.
      expect(await puedeEntrar(correo, actual), isTrue);
      expect(await puedeEntrar(correo, nueva), isFalse);
      semantica.dispose();
    },
  );

  testWidgets(
    'la contraseña nueva no cumple una regla y el botón sigue deshabilitado @CU-04-H03-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      await irACambiar(tester, 'socio.${unico()}@correo.com');

      await completar(tester, contrasenaNueva: 'ClubNahuel');

      // Verifica: la regla que falta se ve y no se puede guardar.
      expect(find.text('Al menos un número'), findsOneWidget);
      expect(guardarHabilitado(tester), isFalse);
      semantica.dispose();
    },
  );

  testWidgets(
    'la repetición no coincide y el botón sigue deshabilitado @CU-04-H04-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      await irACambiar(tester, 'socio.${unico()}@correo.com');

      await completar(tester, repetida: 'ClubNahuel3');

      // Verifica: marca la repetición y no deja guardar.
      expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
      expect(guardarHabilitado(tester), isFalse);
      semantica.dispose();
    },
  );

  testWidgets(
    'sin conexión al guardar, ve el error de conexión y conserva lo escrito @CU-04-H05-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final correo = 'socio.${unico()}@correo.com';
      final api = await ApiIntermedia.abrir();
      await irACambiar(tester, correo, apiUrl: api.url);
      await completar(tester);

      api.estado = EstadoApi.sinRed;
      await tocar(tester, 'GUARDAR CONTRASEÑA');

      // Verifica: avisa que no hay conexión y no pierde lo escrito.
      await esperarA(tester, find.text('Error de conexión'));
      await tocar(tester, 'Volver');
      expect(escrito(tester, 'Contraseña actual'), actual);
      expect(escrito(tester, 'Contraseña nueva'), nueva);
      expect(await puedeEntrar(correo, actual), isTrue);
      semantica.dispose();
    },
  );

  testWidgets(
    'el servidor falla al guardar y la contraseña no cambia @CU-04-H06-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final correo = 'socio.${unico()}@correo.com';
      final api = await ApiIntermedia.abrir();
      await irACambiar(tester, correo, apiUrl: api.url);
      await completar(tester);

      api.estado = EstadoApi.falla;
      await tocar(tester, 'GUARDAR CONTRASEÑA');

      // Verifica: avisa del servidor y la contraseña sigue siendo la de antes.
      await esperarA(tester, find.text('Error del servidor'));
      expect(await puedeEntrar(correo, actual), isTrue);
      expect(await puedeEntrar(correo, nueva), isFalse);
      semantica.dispose();
    },
  );

  testWidgets('con la sesión vencida, la app lo lleva al login @CU-04-H07-01', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    final correo = 'socio.${unico()}@correo.com';
    await irACambiar(tester, correo);
    // Otro dispositivo cambia la contraseña: la sesión de este teléfono queda vencida.
    await cambiarDesdeOtroDispositivo(correo, actual, 'ClubNahuel3');

    await completar(tester, contrasenaActual: 'ClubNahuel3');
    await tocar(tester, 'GUARDAR CONTRASEÑA');

    // Verifica: avisa que la sesión venció y lo lleva a iniciar sesión.
    await esperarA(tester, find.text('Tu sesión expiró'));
    await tocar(tester, 'IR AL INICIO DE SESIÓN');
    expect(find.text('INICIAR SESIÓN'), findsOneWidget);
    semantica.dispose();
  });
}
