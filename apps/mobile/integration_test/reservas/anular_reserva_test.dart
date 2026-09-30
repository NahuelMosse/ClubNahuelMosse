import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../soporte/acciones.dart';
import '../soporte/red.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final manana = hoyEnElClub().add(const Duration(days: 1));
  const motivo = 'Mantenimiento urgente del césped sintético.';

  /// Una sede con un Fútbol 5 y una reserva de una cuenta nueva mañana a las 21.
  Future<(String, String, String)> reservaDeManana() async {
    final sede = 'Sede Haedo ${unico()}';
    await crearSede(sede, 'Av. Vergara 1850');
    final cancha = await crearEspacio(sede);
    final correo = 'socio.${unico()}@correo.com';
    await crearCuenta(correo: correo, contrasena: 'ClubNahuel1');
    await ocupar(cancha, manana, 21, correo: correo);
    return (sede, cancha, correo);
  }

  /// El administrador entra al panel y deja a la vista sólo la reserva de [sede].
  Future<void> abrirPanel(
    WidgetTester tester,
    String sede,
    String cancha, {
    String? apiUrl,
  }) async {
    await entrarComoAdmin(tester, apiUrl: apiUrl);
    await escribir(tester, 'Buscar reserva', sede);
    await esperarA(tester, find.text(cancha));
  }

  Future<void> pedirAnular(WidgetTester tester) async {
    await tocar(tester, 'ANULAR RESERVA');
    await esperarA(tester, find.text('¿Anular esta reserva?'));
  }

  Future<void> confirmarConMotivo(WidgetTester tester) async {
    await escribir(tester, 'Motivo de la anulación', motivo);
    await tocar(tester, 'CONFIRMAR ANULACIÓN');
  }

  testWidgets(
    'anula una reserva activa con motivo y queda anulada con motivo, fecha, hora y administrador @CU-15-H01-01',
    (tester) async {
      final (sede, cancha, _) = await reservaDeManana();
      await abrirPanel(tester, sede, cancha);
      await pedirAnular(tester);
      expect(find.text('Nahuel Mosse'), findsWidgets);
      expect(find.textContaining(sede), findsWidgets);
      expect(find.textContaining('21:00 – 22:00'), findsWidgets);

      await confirmarConMotivo(tester);

      // Verifica: el aviso, la tarjeta anulada y el rastro completo en la API.
      await esperarA(tester, find.text('Reserva anulada correctamente'));
      await tocar(tester, 'ACEPTAR');
      await esperarA(tester, find.text('ANULADA'));
      expect(find.text('ANULAR RESERVA'), findsNothing);
      final reserva = await reservaQueVeElAdmin(cancha);
      expect(reserva?['estado'], 'anulada');
      expect(reserva?['motivo'], motivo);
      expect(reserva?['cancelada_en'], isNotNull);
      expect(reserva?['cancelada_por_nombre'], isNotNull);
    },
  );

  testWidgets(
    'después de anular, otro usuario puede reservar ese mismo horario @CU-15-H01-02',
    (tester) async {
      final (sede, cancha, _) = await reservaDeManana();
      await abrirPanel(tester, sede, cancha);
      await pedirAnular(tester);
      await confirmarConMotivo(tester);
      await esperarA(tester, find.text('Reserva anulada correctamente'));

      // Verifica: las 21 vuelven a estar libres y otra cuenta las reserva.
      expect(await iniciosLibres(cancha, manana), contains('21:00'));
      final otra = 'socio.${unico()}@correo.com';
      await crearCuenta(correo: otra, contrasena: 'ClubNahuel1');
      expect(await reservarPorLaApi(otra, cancha, manana, 21), greaterThan(0));
    },
  );

  testWidgets(
    'el usuario afectado ve la reserva anulada en su historial con el motivo @CU-15-H01-03',
    (tester) async {
      final (sede, cancha, correo) = await reservaDeManana();
      await abrirPanel(tester, sede, cancha);
      await pedirAnular(tester);
      await confirmarConMotivo(tester);
      await esperarA(tester, find.text('Reserva anulada correctamente'));

      await abrirApp(tester);
      await escribir(tester, 'Correo', correo);
      await escribir(tester, 'Contraseña', 'ClubNahuel1');
      await tocar(tester, 'INICIAR SESIÓN');
      await esperarA(tester, find.text('RESERVÁ TU CANCHA'));
      await tocar(tester, 'RESERVAS');
      await tocar(tester, 'Historial');

      // Verifica: figura anulada, con el motivo que escribió el administrador.
      await esperarA(tester, find.text('ANULADA'));
      expect(find.text(cancha), findsOneWidget);
      expect(find.textContaining(motivo), findsOneWidget);
      expect(await historialDe(correo), [(cancha, 'anulada', motivo)]);
    },
  );

  testWidgets(
    'vuelve atrás desde la confirmación y la reserva sigue activa @CU-15-H02-01',
    (tester) async {
      final (sede, cancha, _) = await reservaDeManana();
      await abrirPanel(tester, sede, cancha);
      await pedirAnular(tester);

      await tocar(tester, 'VOLVER');

      // Verifica: vuelve al listado, la reserva no cambió y se puede anular de nuevo.
      expect(find.text('¿Anular esta reserva?'), findsNothing);
      expect(find.text('ACTIVA'), findsOneWidget);
      expect(find.text('ANULAR RESERVA'), findsOneWidget);
      expect((await reservaQueVeElAdmin(cancha))?['estado'], 'activa');
    },
  );

  testWidgets(
    'confirma sin motivo, ve que es obligatorio y no se anula @CU-15-H03-01',
    (tester) async {
      final (sede, cancha, _) = await reservaDeManana();
      await abrirPanel(tester, sede, cancha);
      await pedirAnular(tester);

      await tocar(tester, 'CONFIRMAR ANULACIÓN');

      // Verifica: el aviso del campo, la confirmación sigue abierta y la API no vio nada.
      await esperarA(tester, find.text('El motivo es obligatorio para anular'));
      expect(find.text('¿Anular esta reserva?'), findsOneWidget);
      expect((await reservaQueVeElAdmin(cancha))?['estado'], 'activa');
    },
  );

  testWidgets(
    'el usuario canceló la reserva mientras tanto y la anulación se rechaza @CU-15-H04-01',
    (tester) async {
      final (sede, cancha, correo) = await reservaDeManana();
      await abrirPanel(tester, sede, cancha);
      await pedirAnular(tester);

      await cancelarProximasDe(correo);
      await confirmarConMotivo(tester);

      // Verifica: el aviso de que cambió, el listado actualizado y la cancelación intacta.
      await esperarA(tester, find.text('Esto cambió mientras tanto'));
      await tocar(tester, 'VER LO ACTUALIZADO');
      await esperarA(tester, find.text('CANCELADA'));
      expect(find.text('ANULAR RESERVA'), findsNothing);
      final reserva = await reservaQueVeElAdmin(cancha);
      expect(reserva?['estado'], 'cancelada');
      expect(reserva?['motivo'], isNull);
    },
  );

  testWidgets('la reserva ya empezó y la anulación se rechaza @CU-15-H04-02', (
    tester,
  ) async {
    final (sede, cancha, _) = await reservaDeManana();
    await abrirPanel(tester, sede, cancha);
    await pedirAnular(tester);

    await empezarReservasDe(cancha);
    await confirmarConMotivo(tester);

    // Verifica: el aviso, el listado ya no ofrece anular y la reserva sigue activa.
    await esperarA(tester, find.text('Esto cambió mientras tanto'));
    await tocar(tester, 'VER LO ACTUALIZADO');
    await esperarA(tester, find.text('ACTIVA'));
    expect(find.text('ANULAR RESERVA'), findsNothing);
    expect((await reservaQueVeElAdmin(cancha))?['estado'], 'activa');
  });

  testWidgets(
    'sin conexión al confirmar, ve el error con reintento y la reserva sigue activa @CU-15-H05-01',
    (tester) async {
      final (sede, cancha, _) = await reservaDeManana();
      final api = await ApiIntermedia.abrir();
      await abrirPanel(tester, sede, cancha, apiUrl: api.url);
      await pedirAnular(tester);

      api.estado = EstadoApi.sinRed;
      await confirmarConMotivo(tester);

      // Verifica: el aviso con reintento, y al volver la reserva conserva su estado.
      await esperarA(tester, find.text('Error de conexión'));
      expect(find.text('REINTENTAR'), findsOneWidget);
      await tocar(tester, 'Volver');
      expect(find.text('ACTIVA'), findsOneWidget);
      expect((await reservaQueVeElAdmin(cancha))?['estado'], 'activa');
    },
  );

  testWidgets(
    'el servidor falla al anular y la reserva sigue activa @CU-15-H05-01',
    (tester) async {
      final (sede, cancha, _) = await reservaDeManana();
      final api = await ApiIntermedia.abrir();
      await abrirPanel(tester, sede, cancha, apiUrl: api.url);
      await pedirAnular(tester);

      api.estado = EstadoApi.falla;
      await confirmarConMotivo(tester);

      // Verifica: el aviso del servidor y la reserva intacta.
      await esperarA(tester, find.text('Error del servidor'));
      await tocar(tester, 'ACEPTAR');
      expect(find.text('ACTIVA'), findsOneWidget);
      expect((await reservaQueVeElAdmin(cancha))?['estado'], 'activa');
    },
  );

  testWidgets(
    'reintenta después del corte y la reserva queda anulada una sola vez @CU-15-H05-01',
    (tester) async {
      final (sede, cancha, _) = await reservaDeManana();
      final api = await ApiIntermedia.abrir();
      await abrirPanel(tester, sede, cancha, apiUrl: api.url);
      await pedirAnular(tester);

      api.estado = EstadoApi.sinRed;
      await confirmarConMotivo(tester);
      await esperarA(tester, find.text('Error de conexión'));
      api.estado = EstadoApi.normal;
      await tocar(tester, 'REINTENTAR');

      // Verifica: el aviso de éxito y el rastro con el motivo escrito.
      await esperarA(tester, find.text('Reserva anulada correctamente'));
      await tocar(tester, 'ACEPTAR');
      await esperarA(tester, find.text('ANULADA'));
      final reserva = await reservaQueVeElAdmin(cancha);
      expect(reserva?['estado'], 'anulada');
      expect(reserva?['motivo'], motivo);
    },
  );
}
