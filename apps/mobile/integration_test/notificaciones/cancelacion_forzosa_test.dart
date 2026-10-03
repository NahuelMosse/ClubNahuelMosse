import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../soporte/acciones.dart';
import '../soporte/red.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  final manana = hoyEnElClub().add(const Duration(days: 1));
  const titulo = 'El club anuló tu reserva';
  const motivo = 'mantenimiento de la cancha';

  String cuerpo(String sede, {String hora = '21:00'}) =>
      'Fútbol 5 · $sede · ${dias[manana.weekday - 1]} ${manana.day}, $hora. '
      'Motivo: $motivo.';

  /// Una sede nueva con un Fútbol 5 y una reserva de [correo] mañana a las [hora].
  Future<(String, String)> otraReserva(String correo, {int hora = 21}) async {
    final sede = 'Sede Morón ${unico()}';
    await crearSede(sede, 'Av. Rivadavia 19850');
    final cancha = await crearEspacio(sede);
    await ocupar(cancha, manana, hora, correo: correo);
    return (sede, cancha);
  }

  /// Una cuenta nueva con una reserva mañana a las 21.
  Future<(String, String, String)> reservaDeManana() async {
    final correo = 'socio.${unico()}@correo.com';
    await crearCuenta(correo: correo, contrasena: 'ClubNahuel1');
    final (sede, cancha) = await otraReserva(correo);
    return (correo, sede, cancha);
  }

  Future<void> entrar(
    WidgetTester tester,
    String correo, {
    bool permiso = true,
  }) async {
    await abrirApp(tester);
    await fijarPermisoDeNotificaciones(concedido: permiso);
    await escribir(tester, 'Correo', correo);
    await escribir(tester, 'Contraseña', 'ClubNahuel1');
    await tocar(tester, 'INICIAR SESIÓN');
    await esperarA(tester, find.text('RESERVÁ TU CANCHA'));
  }

  Finder campana(int sinLeer) => find.bySemanticsLabel(
    sinLeer == 0 ? 'Notificaciones' : 'Notificaciones, $sinLeer sin leer',
  );

  Future<void> abrirCentro(WidgetTester tester, {int sinLeer = 0}) async {
    await esperarA(tester, campana(sinLeer));
    await tester.tap(campana(sinLeer));
    await tester.pumpAndSettle();
    await esperarA(tester, find.text('Notificaciones'));
  }

  bool resaltada(WidgetTester tester, String sede) => tester
      .getSemantics(
        find.bySemanticsLabel(RegExp('^Fútbol 5, ${RegExp.escape(sede)},')),
      )
      .flagsCollection
      .isSelected;

  testWidgets(
    'el administrador anula la reserva y el usuario ve el aviso con deporte, sede, fecha y motivo @CU-24.2-H01-01 @supuesto:CU-24.2-SUP-06',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (correo, sede, _) = await reservaDeManana();
      await entrar(tester, correo);

      // La anulación llega desde el club: acá la persona está en el Home.
      final [reserva] = await proximasDe(correo);
      expect(await anularDesdeElAdmin(reserva), 200);
      await esperarA(tester, find.text(titulo));

      // Verifica: la tarjeta superior trae la reserva y el motivo, sobre la pantalla en la
      // que estaba.
      expect(find.text(cuerpo(sede)), findsOneWidget);
      expect(find.text('MARCAR TODAS'), findsOneWidget);
      expect(find.text('RESERVÁ TU CANCHA'), findsOneWidget);
      semantica.dispose();
    },
  );

  testWidgets(
    'al tocar el aviso la app abre el historial con la reserva anulada y su motivo @CU-24.2-H01-02 @supuesto:CU-24.2-SUP-04',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (correo, sede, cancha) = await reservaDeManana();
      await entrar(tester, correo);
      final [reserva] = await proximasDe(correo);
      expect(await anularDesdeElAdmin(reserva), 200);
      await esperarA(tester, find.text(titulo));

      await tester.tap(find.text(titulo));
      await tester.pumpAndSettle();

      // Verifica: Mis reservas en el historial, con la reserva anulada, su motivo y resaltada.
      await esperarA(tester, find.text('ANULADA'));
      expect(find.text('Mis reservas'), findsOneWidget);
      expect(find.text(cancha), findsOneWidget);
      expect(
        find.text('Anulada por el administrador · $motivo'),
        findsOneWidget,
      );
      expect(resaltada(tester, sede), isTrue);
      expect(find.text('MARCAR TODAS'), findsNothing);
      semantica.dispose();
    },
  );

  testWidgets(
    'el envío del aviso consta en la trazabilidad de la reserva que ve el administrador @CU-24.2-H01-03 @supuesto:CU-24.2-SUP-07',
    (tester) async {
      final (correo, sede, cancha) = await reservaDeManana();
      final [reserva] = await proximasDe(correo);
      expect(await anularDesdeElAdmin(reserva), 200);
      // La corrida no tiene servicio de notificaciones: el aviso queda en el centro.
      expect(await esperarElEnvioDelAviso(cancha), 'sin_canal');

      await entrarComoAdmin(tester);
      await escribir(tester, 'Buscar reserva', sede);
      await esperarA(tester, find.text(cancha));
      await tocar(tester, cancha);

      // Verifica: el detalle deja el aviso en la trazabilidad, junto con la anulación.
      await esperarA(tester, find.text('Detalle de reserva'));
      expect(find.text('Anulada por el administrador'), findsOneWidget);
      expect(find.text('Aviso en el centro del usuario'), findsOneWidget);
      expect(find.text('El push no salió'), findsOneWidget);
    },
  );

  testWidgets(
    'varias reservas anuladas a la misma persona llegan en un solo aviso con la cantidad @CU-24.2-H03-01 @supuesto:CU-24.2-SUP-02 @supuesto:CU-24.2-SUP-06',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (correo, _, _) = await reservaDeManana();
      await otraReserva(correo, hora: 22);
      await entrar(tester, correo, permiso: false);

      for (final reserva in await proximasDe(correo)) {
        expect(await anularDesdeElAdmin(reserva), 200);
      }
      await abrirCentro(tester, sinLeer: 1);

      // Verifica: un solo aviso, que dice cuántas son; tocarlo lleva al historial.
      expect(find.text('El club anuló 2 de tus reservas'), findsOneWidget);
      expect(
        find.text(
          'Tenés 2 reservas anuladas por el club. Mirá el detalle en tu historial.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('El club anuló 2 de tus reservas'));
      await tester.pumpAndSettle();
      await esperarA(tester, find.text('Mis reservas'));
      expect(find.text('ANULADA'), findsNWidgets(2));
      semantica.dispose();
    },
  );

  testWidgets(
    'sin permiso de notificaciones no llega el push pero el aviso está en el centro @CU-24.2-H04-01 @supuesto:CU-24.2-SUP-07',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (correo, sede, cancha) = await reservaDeManana();
      await entrar(tester, correo, permiso: false);

      final [reserva] = await proximasDe(correo);
      expect(await anularDesdeElAdmin(reserva), 200);
      await abrirCentro(tester, sinLeer: 1);

      // Verifica: el centro avisa que están desactivadas y trae la anulación igual; la API
      // sabe que el push no salió.
      expect(find.text('Notificaciones desactivadas'), findsOneWidget);
      expect(find.text(titulo), findsOneWidget);
      expect(find.text(cuerpo(sede)), findsOneWidget);
      expect(find.text('MARCAR TODAS'), findsNothing);
      expect(await esperarElEnvioDelAviso(cancha), 'sin_permiso');
      semantica.dispose();
    },
  );

  testWidgets(
    'si el usuario ya había cancelado la reserva no recibe el aviso del club @CU-24.2-H05-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (correo, sede, cancha) = await reservaDeManana();
      final [reserva] = await proximasDe(correo);
      // Sin permiso el panel no se abre solo en el Home y la campana abre el centro.
      await entrar(tester, correo, permiso: false);
      await tocar(tester, 'RESERVAS');
      await esperarA(tester, find.text(cancha));
      await tocar(tester, 'CANCELAR');
      await esperarA(tester, find.text('¿Cancelar la reserva?'));
      await tocar(tester, 'CANCELAR RESERVA');
      await esperarA(tester, find.text('Reserva cancelada con éxito'));
      await tocar(tester, 'ACEPTAR');
      await tocar(tester, 'INICIO');

      // El club intenta anularla después: la reserva ya no está activa.
      expect(await anularDesdeElAdmin(reserva), 409);
      await abrirCentro(tester, sinLeer: 1);

      // Verifica: el centro sólo trae la confirmación de su propia cancelación.
      expect(find.text('Reserva cancelada'), findsOneWidget);
      expect(find.text(titulo), findsNothing);
      expect(find.text(cuerpo(sede)), findsNothing);
      semantica.dispose();
    },
  );
}
