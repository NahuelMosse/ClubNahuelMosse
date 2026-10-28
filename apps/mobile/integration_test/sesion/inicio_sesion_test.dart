import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../soporte/acciones.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const contrasena = 'ClubNahuel1';
  const generico =
      'No se pudo iniciar sesión. Revisá tus datos e intentá de nuevo.';

  Future<void> ingresar(
    WidgetTester tester,
    String correo,
    String clave,
  ) async {
    if (correo.isNotEmpty) await escribir(tester, 'Correo', correo);
    if (clave.isNotEmpty) await escribir(tester, 'Contraseña', clave);
    await tocar(tester, 'INICIAR SESIÓN');
  }

  testWidgets(
    'inicia sesión con correo y contraseña correctos y llega al Home @CU-01-H01-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final correo = 'socio.${unico()}@correo.com';
      await crearCuenta(correo: correo, contrasena: contrasena);
      await abrirApp(tester);

      // Verifica CU-01-SUP-03: el correo con mayúsculas y espacios alrededor entra igual.
      await ingresar(tester, '  ${correo.toUpperCase()} ', contrasena);

      // Verifica: llega al Home con su nombre. Si falla, queda en el login sin poder reservar.
      await esperarA(tester, find.text('RESERVÁ TU CANCHA'));
      expect(find.text('Nahuel'), findsOneWidget);
      expect(find.text('INICIAR SESIÓN'), findsNothing);
      semantica.dispose();
    },
  );

  testWidgets(
    'inicia sesión con una cuenta de administrador y llega al panel de administración @CU-01-H01-02',
    (tester) async {
      final semantica = tester.ensureSemantics();
      await abrirApp(tester);

      await ingresar(tester, correoAdmin, contrasenaAdmin);

      // Verifica: el rol sale de la cuenta, sin elegirlo en el login. Si falla, el admin
      // cae en el Home de usuario y no llega a las herramientas de administración.
      await esperarA(tester, find.text('PANEL ADMIN'));
      expect(find.text('RESERVÁ TU CANCHA'), findsNothing);
      semantica.dispose();
    },
  );

  testWidgets(
    'intenta ingresar con el correo vacío y no se envía nada al backend @CU-01-H02-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      // Sin red: si la app mandara las credenciales, al asentarse la pantalla ya estaría el
      // error de conexión.
      await abrirApp(tester, apiUrl: apiSinRed, authEmulador: sinRed);

      await ingresar(tester, '', contrasena);

      // Verifica: marca el correo que falta y no manda nada. Si falla, la persona no sabe qué
      // le falta, o la app consulta al backend con datos incompletos.
      expect(find.text('Completá tu correo electrónico'), findsOneWidget);
      expect(find.text('Completá tu contraseña'), findsNothing);
      expect(find.text('Error de conexión'), findsNothing);
      expect(find.text('INICIAR SESIÓN'), findsOneWidget);
      semantica.dispose();
    },
  );

  testWidgets(
    'intenta ingresar con la contraseña vacía y no se envía nada al backend @CU-01-H02-02',
    (tester) async {
      final semantica = tester.ensureSemantics();
      await abrirApp(tester, apiUrl: apiSinRed, authEmulador: sinRed);

      await ingresar(tester, 'socio@correo.com', '');

      // Verifica: marca la contraseña que falta y no manda nada.
      expect(find.text('Completá tu contraseña'), findsOneWidget);
      expect(find.text('Completá tu correo electrónico'), findsNothing);
      expect(find.text('Error de conexión'), findsNothing);
      expect(find.text('INICIAR SESIÓN'), findsOneWidget);
      semantica.dispose();
    },
  );

  testWidgets(
    'ingresa un correo que no está registrado y ve el mensaje genérico @CU-01-H03-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      await abrirApp(tester);

      await ingresar(tester, 'nadie.${unico()}@correo.com', contrasena);

      // Verifica: el mensaje no dice qué dato está mal. Si falla, la app revela qué correos
      // tienen cuenta.
      await esperarA(tester, find.text(generico));
      expect(find.text('INICIAR SESIÓN'), findsOneWidget);
      expect(find.text('RESERVÁ TU CANCHA'), findsNothing);
      semantica.dispose();
    },
  );

  testWidgets(
    'ingresa una contraseña incorrecta y ve el mismo mensaje genérico @CU-01-H03-02',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final correo = 'socio.${unico()}@correo.com';
      await crearCuenta(correo: correo, contrasena: contrasena);
      await abrirApp(tester);

      await ingresar(tester, correo, 'OtraClave9');

      // Verifica: el mismo texto que con un correo sin cuenta, y no entra.
      await esperarA(tester, find.text(generico));
      expect(find.text('INICIAR SESIÓN'), findsOneWidget);
      expect(find.text('RESERVÁ TU CANCHA'), findsNothing);
      semantica.dispose();
    },
  );

  testWidgets(
    'toca «¿Olvidaste tu contraseña?» y llega a Recuperar contraseña @CU-01-H04-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      await abrirApp(tester);

      await tocar(tester, '¿Olvidaste tu contraseña?');

      // Verifica: el enlace lleva a recuperar la contraseña. Si falla, quien la olvidó no
      // tiene cómo volver a entrar.
      expect(find.text('Recuperar contraseña'), findsOneWidget);
      expect(find.text('INICIAR SESIÓN'), findsNothing);
      semantica.dispose();
    },
  );

  testWidgets(
    'el servidor falla al iniciar sesión y se le pide reintentar más tarde @CU-01-H05-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final correo = 'socio.${unico()}@correo.com';
      await crearCuenta(correo: correo, contrasena: contrasena);
      await abrirApp(tester, apiUrl: await apiQueFalla());

      await ingresar(tester, correo, contrasena);

      // Verifica: avisa que el servidor falló y pide intentar más tarde.
      await esperarA(tester, find.text('Error del servidor'));
      expect(
        find.text(
          'No pudimos procesar la operación en este momento. Intentá más tarde.',
        ),
        findsOneWidget,
      );

      // Verifica: al cerrar el aviso sigue en el login, sin una sesión a medias.
      await tocar(tester, 'ACEPTAR');
      expect(find.text('INICIAR SESIÓN'), findsOneWidget);
      expect(find.text('RESERVÁ TU CANCHA'), findsNothing);
      semantica.dispose();
    },
  );

  testWidgets(
    'sin conexión a internet, se le pide restablecer la conexión @CU-01-H06-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      await abrirApp(tester, apiUrl: apiSinRed, authEmulador: sinRed);

      await ingresar(tester, 'socio@correo.com', contrasena);

      // Verifica: dice que no hay conexión y ofrece reintentar, en vez del mensaje de
      // credenciales inválidas.
      await esperarA(tester, find.text('Error de conexión'));
      expect(
        find.text(
          'No pudimos conectarnos. Revisá tu conexión a internet y volvé a intentar.',
        ),
        findsOneWidget,
      );
      expect(find.text('REINTENTAR'), findsOneWidget);
      expect(find.text(generico), findsNothing);
      semantica.dispose();
    },
  );
}
