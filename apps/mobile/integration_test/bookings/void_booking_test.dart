import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/actions.dart';
import '../support/network.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final manana = todayAtClub().add(const Duration(days: 1));
  const motivo = 'Mantenimiento urgente del césped sintético.';

  /// Una sede con un Fútbol 5 y una reserva de una cuenta nueva mañana a las 21.
  Future<(String, String, String)> reservaDeManana() async {
    final sede = 'Sede Haedo ${unique()}';
    await createVenue(sede, 'Av. Vergara 1850');
    final cancha = await createSpace(sede);
    final correo = 'socio.${unique()}@correo.com';
    await createAccount(correo: correo, contrasena: 'ClubNahuel1');
    await occupy(cancha, manana, 21, correo: correo);
    return (sede, cancha, correo);
  }

  /// El administrador entra al panel y deja a la vista sólo la reserva de [sede].
  Future<void> abrirPanel(
    WidgetTester tester,
    String sede,
    String cancha, {
    String? apiUrl,
  }) async {
    await signInAsAdmin(tester, apiUrl: apiUrl);
    await typeInto(tester, 'Buscar reserva', sede);
    await waitUntil(tester, find.text(cancha));
  }

  Future<void> pedirAnular(WidgetTester tester) async {
    await tapText(tester, 'ANULAR RESERVA');
    await waitUntil(tester, find.text('¿Anular esta reserva?'));
  }

  Future<void> confirmarConMotivo(WidgetTester tester) async {
    await typeInto(tester, 'Motivo de la anulación', motivo);
    await tapText(tester, 'CONFIRMAR ANULACIÓN');
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
      await waitUntil(tester, find.text('Reserva anulada correctamente'));
      await tapText(tester, 'ACEPTAR');
      await waitUntil(tester, find.text('ANULADA'));
      expect(find.text('ANULAR RESERVA'), findsNothing);
      final reserva = await bookingAdminSees(cancha);
      expect(reserva?['status'], 'voided');
      expect(reserva?['reason'], motivo);
      expect(reserva?['canceled_at'], isNotNull);
      expect(reserva?['canceled_by_name'], isNotNull);
    },
  );

  testWidgets(
    'después de anular, otro usuario puede reservar ese mismo horario @CU-15-H01-02',
    (tester) async {
      final (sede, cancha, _) = await reservaDeManana();
      await abrirPanel(tester, sede, cancha);
      await pedirAnular(tester);
      await confirmarConMotivo(tester);
      await waitUntil(tester, find.text('Reserva anulada correctamente'));

      // Verifica: las 21 vuelven a estar libres y otra cuenta las reserva.
      expect(await freeStarts(cancha, manana), contains('21:00'));
      final otra = 'socio.${unique()}@correo.com';
      await createAccount(correo: otra, contrasena: 'ClubNahuel1');
      expect(await bookThroughApi(otra, cancha, manana, 21), greaterThan(0));
    },
  );

  testWidgets(
    'el usuario afectado ve la reserva anulada en su historial con el motivo @CU-15-H01-03',
    (tester) async {
      final (sede, cancha, correo) = await reservaDeManana();
      await abrirPanel(tester, sede, cancha);
      await pedirAnular(tester);
      await confirmarConMotivo(tester);
      await waitUntil(tester, find.text('Reserva anulada correctamente'));

      await openApp(tester);
      await typeInto(tester, 'Correo', correo);
      await typeInto(tester, 'Contraseña', 'ClubNahuel1');
      await tapText(tester, 'INICIAR SESIÓN');
      await waitUntil(tester, find.text('RESERVÁ TU CANCHA'));
      // La anulación ya generó su aviso (CU-24.2): el panel se abre solo al entrar y tapa la
      // pantalla hasta que se cierra.
      await waitUntil(tester, find.text('El club anuló tu reserva'));
      await tester.tap(find.bySemanticsLabel('Cerrar las notificaciones'));
      await tester.pumpAndSettle();
      await tapText(tester, 'RESERVAS');
      await tapText(tester, 'Historial');

      // Verifica: figura anulada, con el motivo que escribió el administrador.
      await waitUntil(tester, find.text('ANULADA'));
      expect(find.text(cancha), findsOneWidget);
      expect(find.textContaining(motivo), findsOneWidget);
      expect(await historyOf(correo), [(cancha, 'voided', motivo)]);
    },
  );

  testWidgets(
    'vuelve atrás desde la confirmación y la reserva sigue activa @CU-15-H02-01',
    (tester) async {
      final (sede, cancha, _) = await reservaDeManana();
      await abrirPanel(tester, sede, cancha);
      await pedirAnular(tester);

      await tapText(tester, 'VOLVER');

      // Verifica: vuelve al listado, la reserva no cambió y se puede anular de nuevo.
      expect(find.text('¿Anular esta reserva?'), findsNothing);
      expect(find.text('ACTIVA'), findsOneWidget);
      expect(find.text('ANULAR RESERVA'), findsOneWidget);
      expect((await bookingAdminSees(cancha))?['status'], 'active');
    },
  );

  testWidgets(
    'confirma sin motivo, ve que es obligatorio y no se anula @CU-15-H03-01',
    (tester) async {
      final (sede, cancha, _) = await reservaDeManana();
      await abrirPanel(tester, sede, cancha);
      await pedirAnular(tester);

      await tapText(tester, 'CONFIRMAR ANULACIÓN');

      // Verifica: el aviso del campo, la confirmación sigue abierta y la API no vio nada.
      await waitUntil(tester, find.text('El motivo es obligatorio para anular'));
      expect(find.text('¿Anular esta reserva?'), findsOneWidget);
      expect((await bookingAdminSees(cancha))?['status'], 'active');
    },
  );

  testWidgets(
    'el usuario canceló la reserva mientras tanto y la anulación se rechaza @CU-15-H04-01',
    (tester) async {
      final (sede, cancha, correo) = await reservaDeManana();
      await abrirPanel(tester, sede, cancha);
      await pedirAnular(tester);

      await cancelUpcomingOf(correo);
      await confirmarConMotivo(tester);

      // Verifica: el aviso de que cambió, el listado actualizado y la cancelación intacta.
      await waitUntil(tester, find.text('Esto cambió mientras tanto'));
      await tapText(tester, 'VER LO ACTUALIZADO');
      await waitUntil(tester, find.text('CANCELADA'));
      expect(find.text('ANULAR RESERVA'), findsNothing);
      final reserva = await bookingAdminSees(cancha);
      expect(reserva?['status'], 'canceled');
      expect(reserva?['reason'], isNull);
    },
  );

  testWidgets('la reserva ya empezó y la anulación se rechaza @CU-15-H04-02', (
    tester,
  ) async {
    final (sede, cancha, _) = await reservaDeManana();
    await abrirPanel(tester, sede, cancha);
    await pedirAnular(tester);

    await startBookingsOf(cancha);
    await confirmarConMotivo(tester);

    // Verifica: el aviso, el listado ya no ofrece anular y la reserva sigue activa.
    await waitUntil(tester, find.text('Esto cambió mientras tanto'));
    await tapText(tester, 'VER LO ACTUALIZADO');
    await waitUntil(tester, find.text('ACTIVA'));
    expect(find.text('ANULAR RESERVA'), findsNothing);
    expect((await bookingAdminSees(cancha))?['status'], 'active');
  });

  testWidgets(
    'sin conexión al confirmar, ve el error con reintento y la reserva sigue activa @CU-15-H05-01',
    (tester) async {
      final (sede, cancha, _) = await reservaDeManana();
      final api = await ApiIntermedia.abrir();
      await abrirPanel(tester, sede, cancha, apiUrl: api.url);
      await pedirAnular(tester);

      api.estado = ApiState.offline;
      await confirmarConMotivo(tester);

      // Verifica: el aviso con reintento, y al volver la reserva conserva su estado.
      await waitUntil(tester, find.text('Error de conexión'));
      expect(find.text('REINTENTAR'), findsOneWidget);
      await tapText(tester, 'Volver');
      expect(find.text('ACTIVA'), findsOneWidget);
      expect((await bookingAdminSees(cancha))?['status'], 'active');
    },
  );

  testWidgets(
    'el servidor falla al anular y la reserva sigue activa @CU-15-H05-01',
    (tester) async {
      final (sede, cancha, _) = await reservaDeManana();
      final api = await ApiIntermedia.abrir();
      await abrirPanel(tester, sede, cancha, apiUrl: api.url);
      await pedirAnular(tester);

      api.estado = ApiState.failing;
      await confirmarConMotivo(tester);

      // Verifica: el aviso del servidor y la reserva intacta.
      await waitUntil(tester, find.text('Error del servidor'));
      await tapText(tester, 'ACEPTAR');
      expect(find.text('ACTIVA'), findsOneWidget);
      expect((await bookingAdminSees(cancha))?['status'], 'active');
    },
  );

  testWidgets(
    'reintenta después del corte y la reserva queda anulada una sola vez @CU-15-H05-01',
    (tester) async {
      final (sede, cancha, _) = await reservaDeManana();
      final api = await ApiIntermedia.abrir();
      await abrirPanel(tester, sede, cancha, apiUrl: api.url);
      await pedirAnular(tester);

      api.estado = ApiState.offline;
      await confirmarConMotivo(tester);
      await waitUntil(tester, find.text('Error de conexión'));
      api.estado = ApiState.normal;
      await tapText(tester, 'REINTENTAR');

      // Verifica: el aviso de éxito y el rastro con el motivo escrito.
      await waitUntil(tester, find.text('Reserva anulada correctamente'));
      await tapText(tester, 'ACEPTAR');
      await waitUntil(tester, find.text('ANULADA'));
      final reserva = await bookingAdminSees(cancha);
      expect(reserva?['status'], 'voided');
      expect(reserva?['reason'], motivo);
    },
  );
}
