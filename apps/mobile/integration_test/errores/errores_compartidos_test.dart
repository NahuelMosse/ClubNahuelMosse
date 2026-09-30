import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../soporte/acciones.dart';
import '../soporte/red.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Finder tarjeta(String nombre) =>
      find.bySemanticsLabel(RegExp('^${RegExp.escape(nombre)},'));

  Future<void> entrarA(WidgetTester tester, String nombre) async {
    await esperarA(tester, tarjeta(nombre));
    await tester.ensureVisible(tarjeta(nombre));
    await tester.pumpAndSettle();
    await tester.tap(tarjeta(nombre));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'sin conexión, una operación muestra el error de conexión con reintentar y lo cargado sigue a la vista @TP-07-H01-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final nombre = 'Sede Haedo ${unico()}';
      await crearSede(nombre, 'Av. Vergara 1850');
      await crearEspacio(nombre);
      final api = await ApiIntermedia.abrir();
      await entrarComoUsuario(
        tester,
        correo: 'socio.${unico()}@correo.com',
        apiUrl: api.url,
      );
      await tocar(tester, 'SEDES');
      await esperarA(tester, tarjeta(nombre));

      api.estado = EstadoApi.sinRed;
      await entrarA(tester, nombre);

      // Verifica: el aviso compartido con sus dos salidas. Si falla, la persona queda
      // frente a una pantalla vacía sin saber qué pasó ni cómo seguir.
      await esperarA(tester, find.text('Error de conexión'));
      expect(
        find.text(
          'No pudimos conectarnos. Revisá tu conexión a internet y volvé a intentar.',
        ),
        findsOneWidget,
      );
      expect(find.text('REINTENTAR'), findsOneWidget);
      expect(find.text('Volver'), findsOneWidget);

      // Verifica: al volver, el listado que ya estaba cargado sigue ahí.
      await tocar(tester, 'Volver');
      await esperarA(tester, tarjeta(nombre));
      semantica.dispose();
    },
  );

  testWidgets(
    'al volver la conexión, reintentar completa la operación @TP-07-H01-02 @supuesto:TP-07-SUP-02',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final nombre = 'Sede Haedo ${unico()}';
      await crearSede(nombre, 'Av. Vergara 1850');
      final cancha = await crearEspacio(nombre);
      final api = await ApiIntermedia.abrir();
      await entrarComoUsuario(
        tester,
        correo: 'socio.${unico()}@correo.com',
        apiUrl: api.url,
      );
      await tocar(tester, 'SEDES');
      await esperarA(tester, tarjeta(nombre));
      api.estado = EstadoApi.sinRed;
      await entrarA(tester, nombre);
      await esperarA(tester, find.text('Error de conexión'));

      api.estado = EstadoApi.normal;

      // Verifica: con la red de vuelta la operación no se completa sola; espera al
      // reintento de la persona.
      expect(find.text(cancha), findsNothing);
      await tocar(tester, 'REINTENTAR');

      // Verifica: reintentar completa lo que había quedado a medias.
      await esperarA(tester, find.text('1 CANCHA · TODOS LOS DEPORTES'));
      expect(find.text(cancha), findsOneWidget);
      expect(find.text('Error de conexión'), findsNothing);
      semantica.dispose();
    },
  );

  testWidgets(
    'con el servidor caído se muestra el error del servidor y ningún dato a medias @TP-07-H02-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final nombre = 'Sede Haedo ${unico()}';
      await crearSede(nombre, 'Av. Vergara 1850');
      final api = await ApiIntermedia.abrir();
      await entrarComoUsuario(
        tester,
        correo: 'socio.${unico()}@correo.com',
        apiUrl: api.url,
      );

      api.estado = EstadoApi.falla;
      await tocar(tester, 'SEDES');

      // Verifica: el aviso del servidor con su única salida y nada del listado.
      await esperarA(tester, find.text('Error del servidor'));
      expect(
        find.text(
          'No pudimos procesar la operación en este momento. Intentá más tarde.',
        ),
        findsOneWidget,
      );
      await tocar(tester, 'ACEPTAR');
      expect(tarjeta(nombre), findsNothing);
      semantica.dispose();
    },
  );

  testWidgets('un login incorrecto muestra el mensaje genérico @TP-07-H03-01', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    final correo = 'socio.${unico()}@correo.com';
    await crearCuenta(correo: correo, contrasena: 'ClubNahuel1');
    await abrirApp(tester);

    await escribir(tester, 'Correo', correo);
    await escribir(tester, 'Contraseña', 'OtraClave9');
    await tocar(tester, 'INICIAR SESIÓN');

    // Verifica: el mensaje no dice qué dato está mal y la persona sigue en el login.
    await esperarA(
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
      final correo = 'repetido.${unico()}@correo.com';
      await crearCuenta(correo: correo, contrasena: 'ClubNahuel1');
      await abrirApp(tester);
      await tocar(tester, 'COMENZAR');
      await escribir(tester, 'Nombre', 'Nahuel Agustín');
      await escribir(tester, 'Apellido', 'Mosse');
      await escribir(tester, 'DNI', dniDe(unico()));
      await escribir(tester, 'Fecha de nacimiento', '14032000');
      await escribir(tester, 'Correo electrónico', correo);
      await escribir(tester, 'Contraseña', 'ClubNahuel1');

      await tocar(tester, 'CREAR CUENTA');

      // Verifica: el aviso del prototipo y la persona sigue en el formulario.
      await esperarA(
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
      final nombre = 'Sede Haedo ${unico()}';
      await crearSede(nombre, 'Av. Vergara 1850');
      final correo = 'socio.${unico()}@correo.com';
      await entrarComoUsuario(tester, correo: correo);
      await cambiarDesdeOtroDispositivo(correo, 'ClubNahuel1', 'ClubNahuel3');

      await tocar(tester, 'SEDES');

      // Verifica: avisa que la sesión expiró, sin datos, y lleva al inicio de sesión.
      await esperarA(tester, find.text('Tu sesión expiró'));
      expect(tarjeta(nombre), findsNothing);
      await tocar(tester, 'IR AL INICIO DE SESIÓN');
      expect(find.text('INICIAR SESIÓN'), findsOneWidget);
      semantica.dispose();
    },
  );

  testWidgets(
    'un usuario sin rol de administrador que entra al panel ve «Acceso denegado» y llega a Mis reservas @TP-07-H06-01 @supuesto:TP-07-SUP-03',
    (tester) async {
      final semantica = tester.ensureSemantics();
      await entrarComoUsuario(tester, correo: 'socio.${unico()}@correo.com');

      // La ruta directa es el vector deliberado: la app no ofrece el panel a un usuario,
      // y el enlace copiado o la sesión reabierta es la forma de llegar.
      await tester.binding.handlePushRoute('/admin');
      await tester.pumpAndSettle();

      // Verifica: el aviso del prototipo y nada del panel.
      await esperarA(tester, find.text('Acceso denegado'));
      expect(
        find.text(
          'Tu cuenta no tiene permisos de administrador. Te llevamos a Mis reservas.',
        ),
        findsOneWidget,
      );
      expect(find.text('PANEL ADMIN'), findsNothing);

      // Verifica: la única salida lleva a Mis reservas.
      await tocar(tester, 'IR A MIS RESERVAS');
      await esperarA(tester, find.text('Mis reservas'));
      expect(find.text('Acceso denegado'), findsNothing);
      semantica.dispose();
    },
  );

  testWidgets(
    'si la cancha se dio de baja mientras se miraba, ve «Esto cambió mientras tanto» y el estado real @TP-07-H07-01 @supuesto:TP-07-SUP-05',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final sede = 'Sede Haedo ${unico()}';
      await crearSede(sede, 'Av. Vergara 1850');
      final cancha1 = await crearEspacio(sede);
      final cancha2 = await crearEspacio(sede);
      await entrarComoUsuario(tester, correo: 'socio.${unico()}@correo.com');
      await tocar(tester, 'SEDES');
      await entrarA(tester, sede);
      await tocar(tester, 'VER HORARIOS / RESERVAR');
      await esperarA(tester, find.text('HORARIO DISPONIBLE'));

      await darDeBajaEspacioDesdeOtraSesion(cancha1);
      await tester.tap(find.bySemanticsLabel('Una hora más'));
      await tester.pumpAndSettle();

      // Verifica: el aviso compartido, y al aceptarlo la sede sin la cancha dada de baja.
      await esperarA(tester, find.text('Esto cambió mientras tanto'));
      await tocar(tester, 'VER LO ACTUALIZADO');
      await esperarA(tester, find.text(cancha2));
      expect(find.text(cancha1), findsNothing);
      semantica.dispose();
    },
  );
}
