import 'dart:ui' show SemanticsFlags;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../soporte/acciones.dart';
import '../soporte/red.dart';

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
  final manana = hoyEnElClub().add(const Duration(days: 1));

  /// Una sede con un Fútbol 5 y una reserva de la cuenta nueva mañana a las 21.
  Future<(String, String, String)> reservaDeManana() async {
    final sede = 'Sede Haedo ${unico()}';
    await crearSede(sede, 'Av. Vergara 1850');
    final cancha = await crearEspacio(sede);
    final correo = 'socio.${unico()}@correo.com';
    await crearCuenta(correo: correo, contrasena: 'ClubNahuel1');
    await ocupar(cancha, manana, 21, correo: correo);
    return (sede, cancha, correo);
  }

  Future<void> entrar(
    WidgetTester tester,
    String correo, {
    String? apiUrl,
  }) async {
    await abrirApp(tester, apiUrl: apiUrl);
    await escribir(tester, 'Correo', correo);
    await escribir(tester, 'Contraseña', 'ClubNahuel1');
    await tocar(tester, 'INICIAR SESIÓN');
    await esperarA(tester, find.text('RESERVÁ TU CANCHA'));
  }

  Future<void> abrirMisReservas(WidgetTester tester, String cancha) async {
    await tocar(tester, 'RESERVAS');
    await esperarA(tester, find.text(cancha));
  }

  Future<void> pedirCancelar(WidgetTester tester) async {
    await tocar(tester, 'CANCELAR');
    await esperarA(tester, find.text('¿Cancelar la reserva?'));
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

      await tocar(tester, 'CANCELAR RESERVA');

      // Verifica: el éxito, la reserva sale de Próximas y está en el historial.
      await esperarA(tester, find.text('Reserva cancelada con éxito'));
      await tocar(tester, 'ACEPTAR');
      await esperarA(tester, find.text('No hay próximas reservas'));
      await tocar(tester, 'Historial');
      await esperarA(tester, find.text('CANCELADA'));
      expect(find.text(cancha), findsOneWidget);
      expect(await reservasDe(correo), isEmpty);
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
      await tocar(tester, 'CANCELAR RESERVA');
      await esperarA(tester, find.text('Reserva cancelada con éxito'));

      // Otra persona mira los horarios de esa cancha.
      final otra = 'socio.${unico()}@correo.com';
      await crearCuenta(correo: otra, contrasena: 'ClubNahuel1');
      await entrar(tester, otra);
      await tocar(tester, 'SEDES');
      final tarjeta = find.bySemanticsLabel(RegExp('^${RegExp.escape(sede)},'));
      await esperarA(tester, tarjeta);
      await tester.ensureVisible(tarjeta);
      await tester.pumpAndSettle();
      await tester.tap(tarjeta);
      await tester.pumpAndSettle();
      await tocar(tester, 'VER HORARIOS / RESERVAR');
      await esperarA(tester, find.text('HORARIO DISPONIBLE'));
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

      await tocar(tester, 'NO CANCELAR');

      // Verifica: sigue en Próximas, activa, y la API la tiene.
      expect(find.text('¿Cancelar la reserva?'), findsNothing);
      expect(find.text('ACTIVA'), findsOneWidget);
      expect(await reservasDe(correo), [(cancha, '21:00')]);
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

      api.estado = EstadoApi.sinRed;
      await tocar(tester, 'CANCELAR RESERVA');

      // Verifica: el aviso con reintento y la reserva intacta.
      await esperarA(tester, find.text('Error de conexión'));
      expect(find.text('REINTENTAR'), findsOneWidget);
      await tocar(tester, 'Volver');
      expect(await reservasDe(correo), [(cancha, '21:00')]);
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

      api.estado = EstadoApi.falla;
      await tocar(tester, 'CANCELAR RESERVA');

      // Verifica: el aviso del servidor y la reserva intacta.
      await esperarA(tester, find.text('Error del servidor'));
      await tocar(tester, 'ACEPTAR');
      expect(find.text(cancha), findsOneWidget);
      expect(await reservasDe(correo), [(cancha, '21:00')]);
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
      await empezarReservasDe(cancha);
      await tocar(tester, 'CANCELAR RESERVA');

      // Verifica: el aviso de que cambió y, al actualizar, ya no se puede cancelar.
      await esperarA(tester, find.text('Esto cambió mientras tanto'));
      await tocar(tester, 'VER LO ACTUALIZADO');
      await esperarA(tester, find.text(cancha));
      expect(find.text('CANCELAR'), findsNothing);
      expect(await reservasDe(correo), hasLength(1));
    },
  );
}
