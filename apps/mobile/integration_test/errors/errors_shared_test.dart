import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/actions.dart';
import '../support/network.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Finder tarjeta(String nombre) =>
      find.bySemanticsLabel(RegExp('^${RegExp.escape(nombre)},'));

  Future<void> entrarA(WidgetTester tester, String nombre) async {
    await waitUntil(tester, tarjeta(nombre));
    await tester.ensureVisible(tarjeta(nombre));
    await tester.pumpAndSettle();
    await tester.tap(tarjeta(nombre));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'sin conexión, una operación muestra el error de conexión con reintentar y lo cargado sigue a la vista @TP-07-H01-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final nombre = 'Sede Haedo ${unique()}';
      await createVenue(nombre, 'Av. Vergara 1850');
      await createSpace(nombre);
      final api = await ApiIntermedia.abrir();
      await signInAsUser(
        tester,
        correo: 'socio.${unique()}@correo.com',
        apiUrl: api.url,
      );
      await tapText(tester, 'SEDES');
      await waitUntil(tester, tarjeta(nombre));

      api.estado = ApiState.offline;
      await entrarA(tester, nombre);

      // Verifica: el aviso compartido con sus dos salidas. Si falla, la persona queda
      // frente a una pantalla vacía sin saber qué pasó ni cómo seguir.
      await waitUntil(tester, find.text('Error de conexión'));
      expect(
        find.text(
          'No pudimos conectarnos. Revisá tu conexión a internet y volvé a intentar.',
        ),
        findsOneWidget,
      );
      expect(find.text('REINTENTAR'), findsOneWidget);
      expect(find.text('Volver'), findsOneWidget);

      // Verifica: al volver, el listado que ya estaba cargado sigue ahí.
      await tapText(tester, 'Volver');
      await waitUntil(tester, tarjeta(nombre));
      semantica.dispose();
    },
  );

  testWidgets(
    'al volver la conexión, reintentar completa la operación @TP-07-H01-02 @supuesto:TP-07-SUP-02',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final nombre = 'Sede Haedo ${unique()}';
      await createVenue(nombre, 'Av. Vergara 1850');
      final cancha = await createSpace(nombre);
      final api = await ApiIntermedia.abrir();
      await signInAsUser(
        tester,
        correo: 'socio.${unique()}@correo.com',
        apiUrl: api.url,
      );
      await tapText(tester, 'SEDES');
      await waitUntil(tester, tarjeta(nombre));
      api.estado = ApiState.offline;
      await entrarA(tester, nombre);
      await waitUntil(tester, find.text('Error de conexión'));

      api.estado = ApiState.normal;

      // Verifica: con la red de vuelta la operación no se completa sola; espera al
      // reintento de la persona.
      expect(find.text(cancha), findsNothing);
      await tapText(tester, 'REINTENTAR');

      // Verifica: reintentar completa lo que había quedado a medias.
      await waitUntil(tester, find.text('1 CANCHA · TODOS LOS DEPORTES'));
      expect(find.text(cancha), findsOneWidget);
      expect(find.text('Error de conexión'), findsNothing);
      semantica.dispose();
    },
  );

  testWidgets(
    'con el servidor caído se muestra el error del servidor y ningún dato a medias @TP-07-H02-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final nombre = 'Sede Haedo ${unique()}';
      await createVenue(nombre, 'Av. Vergara 1850');
      final api = await ApiIntermedia.abrir();
      await signInAsUser(
        tester,
        correo: 'socio.${unique()}@correo.com',
        apiUrl: api.url,
      );

      api.estado = ApiState.failing;
      await tapText(tester, 'SEDES');

      // Verifica: el aviso del servidor con su única salida y nada del listado.
      await waitUntil(tester, find.text('Error del servidor'));
      expect(
        find.text(
          'No pudimos procesar la operación en este momento. Intentá más tarde.',
        ),
        findsOneWidget,
      );
      await tapText(tester, 'ACEPTAR');
      expect(tarjeta(nombre), findsNothing);
      semantica.dispose();
    },
  );

  testWidgets('un login incorrecto muestra el mensaje genérico @TP-07-H03-01', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    final correo = 'socio.${unique()}@correo.com';
    await createAccount(correo: correo, contrasena: 'ClubNahuel1');
    await openApp(tester);

    await typeInto(tester, 'Correo', correo);
    await typeInto(tester, 'Contraseña', 'OtraClave9');
    await tapText(tester, 'INICIAR SESIÓN');

    // Verifica: el mensaje no dice qué dato está mal y la persona sigue en el login.
    await waitUntil(
      tester,
      find.text(
        'No se pudo iniciar sesión. Revisá tus datos e intentá de nuevo.',
      ),
    );
    expect(find.text('RESERVÁ TU CANCHA'), findsNothing);
    semantica.dispose();
  });

  testWidgets(
    'registrarse con un correo ya usado muestra que el usuario ya está registrado @TP-07-H04-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final correo = 'repetido.${unique()}@correo.com';
      await createAccount(correo: correo, contrasena: 'ClubNahuel1');
      await openApp(tester);
      await tapText(tester, 'COMENZAR');
      await typeInto(tester, 'Nombre', 'Nahuel Agustín');
      await typeInto(tester, 'Apellido', 'Mosse');
      await typeInto(tester, 'DNI', dniOf(unique()));
      await typeInto(tester, 'Fecha de nacimiento', '14032000');
      await typeInto(tester, 'Correo electrónico', correo);
      await typeInto(tester, 'Contraseña', 'ClubNahuel1');

      await tapText(tester, 'CREAR CUENTA');

      // Verifica: el aviso del prototipo y la persona sigue en el formulario.
      await waitUntil(
        tester,
        find.text(
          'El usuario ya está registrado. Modificá el correo o el DNI.',
        ),
      );
      expect(find.text('¡Cuenta creada!'), findsNothing);
      semantica.dispose();
    },
  );

  testWidgets(
    'con la sesión vencida, una pantalla con datos lleva al aviso y al inicio de sesión @TP-07-H05-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final nombre = 'Sede Haedo ${unique()}';
      await createVenue(nombre, 'Av. Vergara 1850');
      final correo = 'socio.${unique()}@correo.com';
      await signInAsUser(tester, correo: correo);
      await changeFromAnotherDevice(correo, 'ClubNahuel1', 'ClubNahuel3');

      await tapText(tester, 'SEDES');

      // Verifica: avisa que la sesión expiró, sin datos, y lleva al inicio de sesión.
      await waitUntil(tester, find.text('Tu sesión expiró'));
      expect(tarjeta(nombre), findsNothing);
      await tapText(tester, 'IR AL INICIO DE SESIÓN');
      expect(find.text('INICIAR SESIÓN'), findsOneWidget);
      semantica.dispose();
    },
  );

  testWidgets(
    'un usuario sin rol de administrador que entra al panel ve «Acceso denegado» y llega a Mis reservas @TP-07-H06-01 @supuesto:TP-07-SUP-03',
    (tester) async {
      final semantica = tester.ensureSemantics();
      await signInAsUser(tester, correo: 'socio.${unique()}@correo.com');

      // La ruta directa es el vector deliberado: la app no ofrece el panel a un usuario,
      // y el enlace copiado o la sesión reabierta es la forma de llegar.
      await tester.binding.handlePushRoute('/admin');
      await tester.pumpAndSettle();

      // Verifica: el aviso del prototipo y nada del panel.
      await waitUntil(tester, find.text('Acceso denegado'));
      expect(
        find.text(
          'Tu cuenta no tiene permisos de administrador. Te llevamos a Mis reservas.',
        ),
        findsOneWidget,
      );
      expect(find.text('PANEL ADMIN'), findsNothing);

      // Verifica: la única salida lleva a Mis reservas.
      await tapText(tester, 'IR A MIS RESERVAS');
      await waitUntil(tester, find.text('Mis reservas'));
      expect(find.text('Acceso denegado'), findsNothing);
      semantica.dispose();
    },
  );

  testWidgets(
    'si la cancha se dio de baja mientras se miraba, ve «Esto cambió mientras tanto» y el estado real @TP-07-H07-01 @supuesto:TP-07-SUP-05',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final sede = 'Sede Haedo ${unique()}';
      await createVenue(sede, 'Av. Vergara 1850');
      final cancha1 = await createSpace(sede);
      final cancha2 = await createSpace(sede);
      await signInAsUser(tester, correo: 'socio.${unique()}@correo.com');
      await tapText(tester, 'SEDES');
      await entrarA(tester, sede);
      // La sede tiene dos canchas: se abren los horarios de la primera, que es cancha1.
      final reservar = find.text('VER HORARIOS / RESERVAR').first;
      await tester.ensureVisible(reservar);
      await tester.pumpAndSettle();
      await tester.tap(reservar);
      await waitUntil(tester, find.text('HORARIO DISPONIBLE'));

      await deactivateSpaceFromAnotherSession(cancha1);
      await tester.tap(find.bySemanticsLabel('Una hora más'));
      await tester.pumpAndSettle();

      // Verifica: el aviso compartido, y al aceptarlo la sede sin la cancha dada de baja.
      await waitUntil(tester, find.text('Esto cambió mientras tanto'));
      await tapText(tester, 'VER LO ACTUALIZADO');
      await waitUntil(tester, find.text(cancha2));
      expect(find.text(cancha1), findsNothing);
      semantica.dispose();
    },
  );
}
