import 'dart:ui' show SemanticsFlags;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/actions.dart';
import '../support/network.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const dias = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];
  final manana = todayAtClub().add(const Duration(days: 1));

  /// Una sede con un Fútbol 5 y una reserva de la cuenta nueva mañana a las 21.
  Future<(String, String, String)> reservaDeManana() async {
    final sede = 'Sede Haedo ${unique()}';
    await createVenue(sede, 'Av. Vergara 1850');
    final cancha = await createSpace(sede);
    final correo = 'socio.${unique()}@correo.com';
    await createAccount(correo: correo, contrasena: 'ClubNahuel1');
    await occupy(cancha, manana, 21, correo: correo);
    return (sede, cancha, correo);
  }

  Future<void> entrar(
    WidgetTester tester,
    String correo, {
    String? apiUrl,
  }) async {
    await openApp(tester, apiUrl: apiUrl);
    await typeInto(tester, 'Correo', correo);
    await typeInto(tester, 'Contraseña', 'ClubNahuel1');
    await tapText(tester, 'INICIAR SESIÓN');
    await waitUntil(tester, find.text('RESERVÁ TU CANCHA'));
  }

  Future<void> abrirMisReservas(WidgetTester tester, String cancha) async {
    await tapText(tester, 'RESERVAS');
    await waitUntil(tester, find.text(cancha));
  }

  Future<void> pedirCancelar(WidgetTester tester) async {
    await tapText(tester, 'CANCELAR');
    await waitUntil(tester, find.text('¿Cancelar la reserva?'));
  }

  SemanticsFlags banderas(WidgetTester tester, String etiqueta) =>
      tester.getSemantics(find.bySemanticsLabel(etiqueta)).flagsCollection;

  testWidgets(
    'cancela una reserva futura, ve el éxito y la reserva pasa al historial como cancelada @CU-10-H01-01',
    (tester) async {
      final (sede, cancha, correo) = await reservaDeManana();
      await entrar(tester, correo);
      await abrirMisReservas(tester, cancha);
      await pedirCancelar(tester);
      expect(find.textContaining(sede), findsWidgets);
      expect(find.textContaining('21:00 – 22:00'), findsWidgets);

      await tapText(tester, 'CANCELAR RESERVA');

      // Verifica: el éxito, la reserva sale de Próximas y está en el historial.
      await waitUntil(tester, find.text('Reserva cancelada con éxito'));
      await tapText(tester, 'ACEPTAR');
      await waitUntil(tester, find.text('No hay próximas reservas'));
      await tapText(tester, 'Historial');
      await waitUntil(tester, find.text('CANCELADA'));
      expect(find.text(cancha), findsOneWidget);
      expect(await bookingsOf(correo), isEmpty);
    },
  );

  testWidgets(
    'después de cancelar, otro usuario puede reservar ese mismo horario @CU-10-H01-02',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (sede, cancha, correo) = await reservaDeManana();
      await entrar(tester, correo);
      await abrirMisReservas(tester, cancha);
      await pedirCancelar(tester);
      await tapText(tester, 'CANCELAR RESERVA');
      await waitUntil(tester, find.text('Reserva cancelada con éxito'));

      // Otra persona mira los horarios de esa cancha.
      final otra = 'socio.${unique()}@correo.com';
      await createAccount(correo: otra, contrasena: 'ClubNahuel1');
      await entrar(tester, otra);
      await tapText(tester, 'SEDES');
      final tarjeta = find.bySemanticsLabel(RegExp('^${RegExp.escape(sede)},'));
      await waitUntil(tester, tarjeta);
      await tester.ensureVisible(tarjeta);
      await tester.pumpAndSettle();
      await tester.tap(tarjeta);
      await tester.pumpAndSettle();
      await tapText(tester, 'VER HORARIOS / RESERVAR');
      await waitUntil(tester, find.text('HORARIO DISPONIBLE'));
      final chip = find.bySemanticsLabel(
        '${dias[manana.weekday - 1]} ${manana.day}',
      );
      await tester.ensureVisible(chip);
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pumpAndSettle();

      // Verifica: las 21 volvieron a estar libres.
      expect(banderas(tester, '21:00 – 22:00').isEnabled, isTrue);
      semantica.dispose();
    },
  );

  testWidgets(
    'desiste en la confirmación y la reserva sigue activa y el horario ocupado @CU-10-H02-01',
    (tester) async {
      final (_, cancha, correo) = await reservaDeManana();
      await entrar(tester, correo);
      await abrirMisReservas(tester, cancha);
      await pedirCancelar(tester);

      await tapText(tester, 'NO CANCELAR');

      // Verifica: sigue en Próximas, activa, y la API la tiene.
      expect(find.text('¿Cancelar la reserva?'), findsNothing);
      expect(find.text('ACTIVA'), findsOneWidget);
      expect(await bookingsOf(correo), [(cancha, '21:00')]);
    },
  );

  testWidgets(
    'sin conexión al confirmar, ve el error con reintento y la reserva sigue activa @CU-10-H03-01',
    (tester) async {
      final (_, cancha, correo) = await reservaDeManana();
      final api = await ApiIntermedia.abrir();
      await entrar(tester, correo, apiUrl: api.url);
      await abrirMisReservas(tester, cancha);
      await pedirCancelar(tester);

      api.estado = ApiState.offline;
      await tapText(tester, 'CANCELAR RESERVA');

      // Verifica: el aviso con reintento y la reserva intacta.
      await waitUntil(tester, find.text('Error de conexión'));
      expect(find.text('REINTENTAR'), findsOneWidget);
      await tapText(tester, 'Volver');
      expect(await bookingsOf(correo), [(cancha, '21:00')]);
    },
  );

  testWidgets(
    'el servidor falla al cancelar y la reserva sigue activa @CU-10-H04-01',
    (tester) async {
      final (_, cancha, correo) = await reservaDeManana();
      final api = await ApiIntermedia.abrir();
      await entrar(tester, correo, apiUrl: api.url);
      await abrirMisReservas(tester, cancha);
      await pedirCancelar(tester);

      api.estado = ApiState.failing;
      await tapText(tester, 'CANCELAR RESERVA');

      // Verifica: el aviso del servidor y la reserva intacta.
      await waitUntil(tester, find.text('Error del servidor'));
      await tapText(tester, 'ACEPTAR');
      expect(find.text(cancha), findsOneWidget);
      expect(await bookingsOf(correo), [(cancha, '21:00')]);
    },
  );

  testWidgets(
    'intenta cancelar una reserva que ya empezó y se le informa que no se puede @CU-10-H05-01',
    (tester) async {
      final (_, cancha, correo) = await reservaDeManana();
      await entrar(tester, correo);
      await abrirMisReservas(tester, cancha);
      await pedirCancelar(tester);

      // Mientras mira la confirmación, el turno empieza.
      await startBookingsOf(cancha);
      await tapText(tester, 'CANCELAR RESERVA');

      // Verifica: el aviso de que cambió y, al actualizar, ya no se puede cancelar.
      await waitUntil(tester, find.text('Esto cambió mientras tanto'));
      await tapText(tester, 'VER LO ACTUALIZADO');
      await waitUntil(tester, find.text(cancha));
      expect(find.text('CANCELAR'), findsNothing);
      expect(await bookingsOf(correo), hasLength(1));
    },
  );
}
