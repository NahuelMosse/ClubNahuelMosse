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

  String franja(int hora) {
    String dos(int h) => '${(h % 24).toString().padLeft(2, '0')}:00';
    return '${dos(hora)} – ${dos(hora + 1)}';
  }

  /// Una sede con dos Fútbol 5 y una reserva de la cuenta nueva en la Cancha 1, mañana a
  /// las 21.
  Future<(String, String, String)> reservaDeManana() async {
    final sede = 'Sede Haedo ${unico()}';
    await crearSede(sede, 'Av. Vergara 1850');
    final cancha = await crearEspacio(sede);
    await crearEspacio(sede);
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

  Future<void> tocarEtiqueta(WidgetTester tester, String etiqueta) async {
    final control = find.bySemanticsLabel(etiqueta);
    await esperarA(tester, control);
    await tester.ensureVisible(control);
    await tester.pumpAndSettle();
    await tester.tap(control);
    await tester.pumpAndSettle();
  }

  SemanticsFlags banderas(WidgetTester tester, String etiqueta) =>
      tester.getSemantics(find.bySemanticsLabel(etiqueta)).flagsCollection;

  /// De Mis reservas a la grilla para modificar la reserva de [cancha].
  Future<void> abrirModificar(WidgetTester tester, String cancha) async {
    await tocar(tester, 'RESERVAS');
    await esperarA(tester, find.text(cancha));
    await tocar(tester, 'MODIFICAR');
    await esperarA(tester, find.textContaining('Estás modificando tu reserva'));
  }

  /// Elige las 19 y llega a «Confirmá el cambio».
  Future<void> hastaConfirmar(WidgetTester tester) async {
    await tocarEtiqueta(tester, franja(19));
    await tocar(tester, 'CONTINUAR CON EL CAMBIO');
    await esperarA(tester, find.text('Confirmá el cambio'));
  }

  testWidgets(
    'cambia el horario y la reserva, con el mismo identificador, muestra el horario nuevo @CU-11-H01-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (_, cancha, correo) = await reservaDeManana();
      final antes = await numerosDeReservas(correo);
      await entrar(tester, correo);
      await abrirModificar(tester, cancha);
      await hastaConfirmar(tester);
      expect(find.text('ANTES'), findsOneWidget);
      expect(find.textContaining(franja(21)), findsWidgets);
      expect(find.textContaining(franja(19)), findsWidgets);

      await tocar(tester, 'GUARDAR EL CAMBIO');

      // Verifica: Mis reservas muestra el horario nuevo en la misma reserva.
      await esperarA(tester, find.text('Reserva modificada'));
      await esperarA(tester, find.text(franja(19)));
      expect(find.text(franja(21)), findsNothing);
      expect(await numerosDeReservas(correo), antes);
      expect(await reservasDe(correo), [(cancha, '19:00')]);
      semantica.dispose();
    },
  );

  testWidgets(
    'después del cambio, el horario anterior queda libre para otros y el nuevo ocupado @CU-11-H01-02',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (sede, cancha, correo) = await reservaDeManana();
      await entrar(tester, correo);
      await abrirModificar(tester, cancha);
      await hastaConfirmar(tester);
      await tocar(tester, 'GUARDAR EL CAMBIO');
      await esperarA(tester, find.text('Reserva modificada'));

      // Otra persona mira los horarios de la Cancha 1.
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
      await tester.ensureVisible(find.text('VER HORARIOS / RESERVAR').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('VER HORARIOS / RESERVAR').first);
      await tester.pumpAndSettle();
      await tocarEtiqueta(tester, '${dias[manana.weekday - 1]} ${manana.day}');

      // Verifica: las 21 están libres y las 19 ocupadas.
      expect(banderas(tester, franja(21)).isEnabled, isTrue);
      expect(banderas(tester, franja(19)).isEnabled, isFalse);
      semantica.dispose();
    },
  );

  testWidgets(
    'desiste con «Dejar la reserva como está» y nada cambia @CU-11-H02-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (_, cancha, correo) = await reservaDeManana();
      await entrar(tester, correo);
      await abrirModificar(tester, cancha);
      await hastaConfirmar(tester);

      await tocar(tester, 'DEJAR LA RESERVA COMO ESTÁ');

      // Verifica: vuelve a Mis reservas con la reserva en su horario.
      await esperarA(tester, find.text(franja(21)));
      expect(await reservasDe(correo), [(cancha, '21:00')]);
      semantica.dispose();
    },
  );

  testWidgets(
    'el horario nuevo se ocupó mientras elegía: se rechaza y la reserva original sigue intacta @CU-11-H03-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (_, cancha, correo) = await reservaDeManana();
      await entrar(tester, correo);
      await abrirModificar(tester, cancha);
      await hastaConfirmar(tester);

      // Mientras confirma, otra persona toma las 19.
      await ocupar(cancha, manana, 19);
      await tocar(tester, 'GUARDAR EL CAMBIO');

      // Verifica: el aviso, la grilla actualizada y la reserva donde estaba.
      await esperarA(tester, find.text('Esto cambió mientras tanto'));
      await tocar(tester, 'VER LO ACTUALIZADO');
      await esperarA(
        tester,
        find.textContaining('Estás modificando tu reserva'),
      );
      expect(banderas(tester, franja(19)).isEnabled, isFalse);
      expect(await reservasDe(correo), [(cancha, '21:00')]);
      semantica.dispose();
    },
  );

  testWidgets(
    'sin elegir un horario distinto, el botón sigue deshabilitado @CU-11-H04-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (_, cancha, correo) = await reservaDeManana();
      await entrar(tester, correo);

      await abrirModificar(tester, cancha);

      // Verifica: con el horario actual elegido no se puede seguir.
      expect(banderas(tester, 'CONTINUAR CON EL CAMBIO').isEnabled, isFalse);
      await tocarEtiqueta(tester, franja(19));
      expect(banderas(tester, 'CONTINUAR CON EL CAMBIO').isEnabled, isTrue);
      semantica.dispose();
    },
  );

  testWidgets(
    'la reserva ya empezó y se le informa que no se puede modificar @CU-11-H05-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (_, cancha, correo) = await reservaDeManana();
      await entrar(tester, correo);
      await abrirModificar(tester, cancha);
      await hastaConfirmar(tester);

      // Mientras confirma, el turno empieza.
      await empezarReservasDe(cancha);
      await tocar(tester, 'GUARDAR EL CAMBIO');

      // Verifica: el aviso y, en Mis reservas, ya no se ofrece modificarla.
      await esperarA(tester, find.text('Esto cambió mientras tanto'));
      await tocar(tester, 'VER LO ACTUALIZADO');
      await esperarA(tester, find.text(cancha));
      expect(find.text('MODIFICAR'), findsNothing);
      semantica.dispose();
    },
  );

  testWidgets(
    'la reserva fue anulada por un administrador y se le informa que no se puede modificar @CU-11-H05-02',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (_, cancha, correo) = await reservaDeManana();
      await entrar(tester, correo);
      await abrirModificar(tester, cancha);
      await hastaConfirmar(tester);

      // Mientras confirma, el club la anula.
      await anularReservasDe(cancha);
      await tocar(tester, 'GUARDAR EL CAMBIO');

      // Verifica: el aviso y la reserva fuera de las próximas.
      await esperarA(tester, find.text('Esto cambió mientras tanto'));
      await tocar(tester, 'VER LO ACTUALIZADO');
      await esperarA(tester, find.text('No hay próximas reservas'));
      expect(await reservasDe(correo), isEmpty);
      semantica.dispose();
    },
  );

  testWidgets(
    'sin conexión o con el servidor caído al guardar, la reserva queda como estaba @CU-11-H06-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (_, cancha, correo) = await reservaDeManana();
      final api = await ApiIntermedia.abrir();
      await entrar(tester, correo, apiUrl: api.url);
      await abrirModificar(tester, cancha);
      await hastaConfirmar(tester);

      api.estado = EstadoApi.sinRed;
      await tocar(tester, 'GUARDAR EL CAMBIO');

      // Verifica: sin conexión, el aviso y la reserva intacta.
      await esperarA(tester, find.text('Error de conexión'));
      await tocar(tester, 'Volver');
      expect(find.text('Confirmá el cambio'), findsOneWidget);
      expect(await reservasDe(correo), [(cancha, '21:00')]);

      api.estado = EstadoApi.falla;
      await tocar(tester, 'GUARDAR EL CAMBIO');

      // Verifica: con el servidor caído, lo mismo.
      await esperarA(tester, find.text('Error del servidor'));
      await tocar(tester, 'ACEPTAR');
      expect(await reservasDe(correo), [(cancha, '21:00')]);
      semantica.dispose();
    },
  );
}
