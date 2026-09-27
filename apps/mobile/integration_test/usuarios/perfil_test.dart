import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../soporte/acciones.dart';
import '../soporte/red.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Brightness brillo(WidgetTester tester, String texto) =>
      Theme.of(tester.element(find.text(texto).first)).brightness;

  testWidgets(
    'abre Perfil desde la barra inferior y ve sus datos personales y el correo como no editable @CU-05-H01-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final correo = 'socio.${unico()}@correo.com';
      await entrarComoUsuario(tester, correo: correo);

      await tocar(tester, 'PERFIL');

      // Verifica: se ven los datos que la API tiene de la cuenta.
      await esperarA(tester, find.text('DATOS PERSONALES'));
      expect(find.text('Nahuel Mosse'), findsOneWidget);
      expect(find.text('MIEMBRO ACTIVO'), findsOneWidget);
      for (final dato in ['Nombre', 'Apellido', 'DNI', 'Nacimiento']) {
        expect(find.text(dato), findsOneWidget, reason: dato);
      }
      expect(find.text('Mosse'), findsOneWidget);
      expect(find.text('14/03/2000'), findsOneWidget);

      // Verifica: el correo se muestra y se anuncia como un dato que no se puede cambiar.
      expect(
        find.bySemanticsLabel('Correo: $correo. No se puede cambiar'),
        findsOneWidget,
      );
      expect(find.text('Cambiar contraseña'), findsOneWidget);
      semantica.dispose();
    },
  );

  testWidgets(
    'cambia a modo claro y la app entera cambia de tema sin salir del perfil @CU-05-H01-02',
    (tester) async {
      final semantica = tester.ensureSemantics();
      await entrarComoUsuario(tester, correo: 'socio.${unico()}@correo.com');
      await tocar(tester, 'PERFIL');
      await esperarA(tester, find.text('DATOS PERSONALES'));
      expect(brillo(tester, 'DATOS PERSONALES'), Brightness.dark);

      await tester.tap(find.bySemanticsLabel('Modo oscuro'));
      await tester.pumpAndSettle();

      // Verifica: el perfil queda en claro y sigue a la vista.
      expect(brillo(tester, 'DATOS PERSONALES'), Brightness.light);

      // Verifica: el cambio vale para toda la app, no sólo para esta pantalla.
      await tocar(tester, 'INICIO');
      expect(brillo(tester, 'RESERVÁ TU CANCHA'), Brightness.light);
      semantica.dispose();
    },
  );

  testWidgets(
    'desde el perfil llega a Editar perfil, Cambiar contraseña, Cerrar sesión y Eliminar cuenta @CU-05-H01-03',
    (tester) async {
      final semantica = tester.ensureSemantics();
      await entrarComoUsuario(tester, correo: 'socio.${unico()}@correo.com');
      Future<void> abrirPerfil() async {
        await tocar(tester, 'PERFIL');
        await esperarA(tester, find.text('DATOS PERSONALES'));
      }

      // Verifica: «Editar» pasa los datos personales a modo edición.
      await abrirPerfil();
      await tocar(tester, 'Editar');
      expect(find.text('GUARDAR'), findsOneWidget);

      // Verifica: la fila de Seguridad lleva a cambiar la contraseña.
      await tocar(tester, 'INICIO');
      await abrirPerfil();
      await tocar(tester, 'Cambiar contraseña');
      expect(find.text('Cambiá tu contraseña'), findsOneWidget);
      await tester.tap(find.byTooltip('Volver'));
      await tester.pumpAndSettle();

      // Verifica: «ELIMINAR CUENTA» pide confirmación, y cancelar no cambia nada.
      await tocar(tester, 'ELIMINAR CUENTA');
      expect(find.text('¿Eliminar tu cuenta?'), findsOneWidget);
      await tocar(tester, 'CANCELAR');
      expect(find.text('DATOS PERSONALES'), findsOneWidget);

      // Verifica: «CERRAR SESIÓN» sale al login.
      await tocar(tester, 'CERRAR SESIÓN');
      expect(find.text('INICIAR SESIÓN'), findsOneWidget);
      semantica.dispose();
    },
  );

  testWidgets(
    'abre el perfil desde «Perfil completo» en la tarjeta del avatar @CU-05-H02-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      await entrarComoUsuario(tester, correo: 'socio.${unico()}@correo.com');

      await tester.tap(find.bySemanticsLabel('Tu cuenta'));
      await tester.pumpAndSettle();
      await tocar(tester, 'Perfil completo');

      // Verifica: llega al mismo perfil que por la barra inferior.
      await esperarA(tester, find.text('DATOS PERSONALES'));
      expect(find.text('14/03/2000'), findsOneWidget);
      semantica.dispose();
    },
  );

  testWidgets(
    'sin conexión, ve la alerta de conexión y ningún dato del perfil @CU-05-H03-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final api = await ApiIntermedia.abrir();
      await entrarComoUsuario(
        tester,
        correo: 'socio.${unico()}@correo.com',
        apiUrl: api.url,
      );

      api.estado = EstadoApi.sinRed;
      await tocar(tester, 'PERFIL');

      // Verifica: avisa que no hay conexión y no muestra datos viejos.
      await esperarA(tester, find.text('Error de conexión'));
      expect(find.text('DATOS PERSONALES'), findsNothing);
      expect(find.text('14/03/2000'), findsNothing);
      semantica.dispose();
    },
  );

  testWidgets(
    'el servidor falla y la pantalla no muestra datos @CU-05-H04-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final api = await ApiIntermedia.abrir();
      await entrarComoUsuario(
        tester,
        correo: 'socio.${unico()}@correo.com',
        apiUrl: api.url,
      );

      api.estado = EstadoApi.falla;
      await tocar(tester, 'PERFIL');

      // Verifica: avisa del servidor y no muestra datos.
      await esperarA(tester, find.text('Error del servidor'));
      expect(find.text('DATOS PERSONALES'), findsNothing);
      semantica.dispose();
    },
  );

  testWidgets(
    'con la sesión vencida, no ve datos y la app lo lleva al login @CU-05-H05-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final correo = 'socio.${unico()}@correo.com';
      await entrarComoUsuario(tester, correo: correo);
      await cambiarDesdeOtroDispositivo(correo, 'ClubNahuel1', 'ClubNahuel3');

      await tocar(tester, 'PERFIL');

      // Verifica: no expone datos y manda a iniciar sesión.
      await esperarA(tester, find.text('Tu sesión expiró'));
      expect(find.text('DATOS PERSONALES'), findsNothing);
      await tocar(tester, 'IR AL INICIO DE SESIÓN');
      expect(find.text('INICIAR SESIÓN'), findsOneWidget);
      semantica.dispose();
    },
  );
}
