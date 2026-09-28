import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../soporte/acciones.dart';
import '../soporte/red.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const contrasena = 'ClubNahuel1';

  Future<void> pedirBaja(WidgetTester tester) async {
    await tocar(tester, 'PERFIL');
    await esperarA(tester, find.text('DATOS PERSONALES'));
    await tocar(tester, 'ELIMINAR CUENTA');
    expect(find.text('¿Eliminar tu cuenta?'), findsOneWidget);
  }

  /// El botón que confirma la baja, el del diálogo.
  Finder confirmar() => find.descendant(
    of: find.byType(Dialog),
    matching: find.text('ELIMINAR CUENTA'),
  );

  testWidgets(
    'elimina su cuenta, vuelve al login y ya no puede iniciar sesión con ella @CU-07-H01-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final correo = 'socio.${unico()}@correo.com';
      await entrarComoUsuario(tester, correo: correo);
      await pedirBaja(tester);

      await tester.tap(confirmar());
      await tester.pumpAndSettle();

      // Verifica: la sesión termina y la app vuelve al login.
      await esperarA(tester, find.text('INICIAR SESIÓN'));

      // Verifica: con esa cuenta ya no se entra.
      await escribir(tester, 'Correo', correo);
      await escribir(tester, 'Contraseña', contrasena);
      await tocar(tester, 'INICIAR SESIÓN');
      await esperarA(
        tester,
        find.text(
          'No se pudo iniciar sesión. Revisá tus datos e intentá de nuevo.',
        ),
      );
      expect(find.text('RESERVÁ TU CANCHA'), findsNothing);
      semantica.dispose();
    },
  );

  testWidgets(
    'mientras se elimina la cuenta, el botón muestra «Eliminando tu cuenta…» y no se puede volver a tocar @CU-07-H01-03',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final api = await ApiIntermedia.abrir();
      await entrarComoUsuario(
        tester,
        correo: 'socio.${unico()}@correo.com',
        apiUrl: api.url,
      );
      await pedirBaja(tester);

      api.estado = EstadoApi.lenta;
      await tester.tap(confirmar());
      await tester.pump(const Duration(milliseconds: 500));

      // Verifica: mientras espera, el botón lo dice y no acepta otro toque.
      expect(find.text('ELIMINANDO TU CUENTA…'), findsOneWidget);
      final boton = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'ELIMINANDO TU CUENTA…'),
      );
      expect(boton.onPressed, isNull);

      await esperarA(tester, find.text('INICIAR SESIÓN'));
      semantica.dispose();
    },
  );

  testWidgets(
    'cancela en la confirmación y la cuenta sigue intacta @CU-07-H02-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final correo = 'socio.${unico()}@correo.com';
      await entrarComoUsuario(tester, correo: correo);
      await pedirBaja(tester);

      await tocar(tester, 'CANCELAR');

      // Verifica: vuelve al perfil con la sesión abierta y la cuenta sigue sirviendo.
      expect(find.text('¿Eliminar tu cuenta?'), findsNothing);
      expect(find.text('DATOS PERSONALES'), findsOneWidget);
      expect(await puedeEntrar(correo, contrasena), isTrue);
      semantica.dispose();
    },
  );

  testWidgets(
    'sin conexión al confirmar, ve la alerta y la cuenta no se elimina @CU-07-H03-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final correo = 'socio.${unico()}@correo.com';
      final api = await ApiIntermedia.abrir();
      await entrarComoUsuario(tester, correo: correo, apiUrl: api.url);
      await pedirBaja(tester);

      api.estado = EstadoApi.sinRed;
      await tester.tap(confirmar());
      await tester.pumpAndSettle();

      // Verifica: avisa que no hay conexión y la cuenta queda como estaba.
      await esperarA(tester, find.text('Error de conexión'));
      await tocar(tester, 'Volver');
      expect(find.text('DATOS PERSONALES'), findsOneWidget);
      expect(await puedeEntrar(correo, contrasena), isTrue);
      semantica.dispose();
    },
  );

  testWidgets(
    'el servidor falla al confirmar y la cuenta no se elimina @CU-07-H04-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final correo = 'socio.${unico()}@correo.com';
      final api = await ApiIntermedia.abrir();
      await entrarComoUsuario(tester, correo: correo, apiUrl: api.url);
      await pedirBaja(tester);

      api.estado = EstadoApi.falla;
      await tester.tap(confirmar());
      await tester.pumpAndSettle();

      // Verifica: avisa del servidor y la cuenta sigue sirviendo.
      await esperarA(tester, find.text('Error del servidor'));
      await tocar(tester, 'ACEPTAR');
      api.estado = EstadoApi.normal;
      expect(find.text('DATOS PERSONALES'), findsOneWidget);
      expect(await puedeEntrar(correo, contrasena), isTrue);
      semantica.dispose();
    },
  );
}
