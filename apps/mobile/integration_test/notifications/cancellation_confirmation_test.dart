import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/actions.dart';
import '../support/network.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  final manana = todayAtClub().add(const Duration(days: 1));
  const titulo = 'Reserva cancelada';

  String cuerpo(String sede, {String hora = '21:00'}) =>
      'Fútbol 5 · $sede · ${dias[manana.weekday - 1]} ${manana.day}, $hora. '
      'El horario quedó liberado.';

  /// Una sede nueva con un Fútbol 5 y una reserva de [correo] mañana a las [hora].
  Future<(String, String)> otraReserva(String correo, {int hora = 21}) async {
    final sede = 'Sede Morón ${unique()}';
    await createVenue(sede, 'Av. Rivadavia 19850');
    final cancha = await createSpace(sede);
    await occupy(cancha, manana, hora, email: correo);
    return (sede, cancha);
  }

  /// Una cuenta nueva con una reserva mañana a las 21.
  Future<(String, String, String)> reservaDeManana() async {
    final correo = 'socio.${unique()}@correo.com';
    await createAccount(email: correo, password: 'ClubNahuel1');
    final (sede, cancha) = await otraReserva(correo);
    return (correo, sede, cancha);
  }

  Future<void> entrar(
    WidgetTester tester,
    String correo, {
    bool permiso = true,
  }) async {
    await openApp(tester);
    await setNotificationPermission(granted: permiso);
    await typeInto(tester, 'Correo', correo);
    await typeInto(tester, 'Contraseña', 'ClubNahuel1');
    await tapText(tester, 'INICIAR SESIÓN');
    await waitUntil(tester, find.text('RESERVÁ TU CANCHA'));
  }

  Finder campana(int sinLeer) => find.bySemanticsLabel(
    sinLeer == 0 ? 'Notificaciones' : 'Notificaciones, $sinLeer sin leer',
  );

  Future<void> abrirCentro(WidgetTester tester, {int sinLeer = 0}) async {
    await waitUntil(tester, campana(sinLeer));
    await tester.tap(campana(sinLeer));
    await tester.pumpAndSettle();
    await waitUntil(tester, find.text('Notificaciones'));
  }

  Future<void> cerrarPanel(WidgetTester tester) async {
    await tester.tap(find.bySemanticsLabel('Cerrar las notificaciones'));
    await tester.pumpAndSettle();
  }

  /// Cancela la reserva de [cancha] de mañana a las [hora] desde Mis reservas, con el botón de
  /// su tarjeta, y acepta el mensaje de éxito; la app queda en Mis reservas, ya sin esa tarjeta.
  Future<void> cancelarEnLaApp(
    WidgetTester tester,
    String cancha, {
    int hora = 21,
  }) async {
    await tapText(tester, 'RESERVAS');
    await waitUntil(tester, find.text(cancha));
    final boton = find.bySemanticsLabel(
      'Cancelar la reserva de Fútbol 5, '
      '${dias[manana.weekday - 1]} ${manana.day}, $hora:00 – ${hora + 1}:00',
    );
    await tester.ensureVisible(boton);
    await tester.pumpAndSettle();
    await tester.tap(boton);
    await tester.pumpAndSettle();
    await waitUntil(tester, find.text('¿Cancelar la reserva?'));
    await tapText(tester, 'CANCELAR RESERVA');
    await waitUntil(tester, find.text('Reserva cancelada con éxito'));
    await tapText(tester, 'ACEPTAR');
    final fin = DateTime.now().add(const Duration(seconds: 20));
    while (find.text(cancha).evaluate().isNotEmpty &&
        DateTime.now().isBefore(fin)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text(cancha), findsNothing);
  }

  bool resaltada(WidgetTester tester, String sede) => tester
      .getSemantics(
        find.bySemanticsLabel(RegExp('^Fútbol 5, ${RegExp.escape(sede)},')),
      )
      .flagsCollection
      .isSelected;

  testWidgets(
    'cancela una reserva y recibe la confirmación con la reserva y el horario liberado @CU-24.3-H01-01 @supuesto:CU-24.3-SUP-05',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (correo, sede, _) = await reservaDeManana();
      await entrar(tester, correo);

      // La cancelación llega desde otro teléfono: acá la persona está en el Home.
      await cancelFromAnotherPhone(correo);
      await waitUntil(tester, find.text(titulo));

      // Verifica: la tarjeta superior trae qué reserva se canceló y que el horario quedó
      // libre, sobre la pantalla en la que estaba.
      expect(find.text(cuerpo(sede)), findsOneWidget);
      expect(find.text('MARCAR TODAS'), findsOneWidget);
      expect(find.text('RESERVÁ TU CANCHA'), findsOneWidget);
      semantica.dispose();
    },
  );

  testWidgets(
    'al tocar la confirmación la app abre el historial con la reserva cancelada @CU-24.3-H01-02 @supuesto:CU-24.3-SUP-06',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (correo, sede, cancha) = await reservaDeManana();
      await entrar(tester, correo);
      await cancelFromAnotherPhone(correo);
      await waitUntil(tester, find.text(titulo));

      await tester.tap(find.text(titulo));
      await tester.pumpAndSettle();

      // Verifica: Mis reservas en el historial, con la reserva como cancelada y resaltada.
      await waitUntil(tester, find.text('CANCELADA'));
      expect(find.text('Mis reservas'), findsOneWidget);
      expect(find.text(cancha), findsOneWidget);
      expect(resaltada(tester, sede), isTrue);
      expect(find.text('MARCAR TODAS'), findsNothing);
      semantica.dispose();
    },
  );

  testWidgets(
    'la confirmación queda en el centro de notificaciones @CU-24.3-H01-03',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (correo, sede, _) = await reservaDeManana();
      await entrar(tester, correo);
      await cancelFromAnotherPhone(correo);
      await waitUntil(tester, find.text(titulo));
      await cerrarPanel(tester);

      await abrirCentro(tester, sinLeer: 1);

      // Verifica: la confirmación figura en el centro, del día de hoy y sin leer.
      expect(find.text('HOY'), findsOneWidget);
      expect(find.text(titulo), findsOneWidget);
      expect(find.text(cuerpo(sede)), findsOneWidget);
      semantica.dispose();
    },
  );

  testWidgets(
    'si sigue en Mis reservas ve sólo el mensaje de éxito de la cancelación, sin la tarjeta @CU-24.3-H02-01 @supuesto:CU-24.3-SUP-03 @supuesto:CU-24.3-SUP-07',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (correo, sede, cancha) = await reservaDeManana();
      await otraReserva(correo, hora: 22);
      await entrar(tester, correo);

      await cancelarEnLaApp(tester, cancha);

      // Un recordatorio que llega después hace que la app lea el centro, que ya trae la
      // confirmación: el panel muestra el recordatorio y no la confirmación.
      await dispatchReminders(email: correo, day: manana, hour: 21);
      await waitUntil(tester, find.text('Tu reserva es en 1 hora'));

      // Verifica: la tarjeta de la confirmación no aparece y la pantalla sigue siendo Mis
      // reservas.
      expect(find.text(titulo), findsNothing);
      expect(find.text(cuerpo(sede)), findsNothing);
      expect(find.text('Mis reservas'), findsOneWidget);

      // Verifica: la confirmación sigue sin leer en la campana y en el centro.
      await cerrarPanel(tester);
      await tapText(tester, 'INICIO');
      await abrirCentro(tester, sinLeer: 2);
      expect(find.text(titulo), findsOneWidget);
      expect(find.text(cuerpo(sede)), findsOneWidget);
      semantica.dispose();
    },
  );

  testWidgets(
    'sin permiso de notificaciones no llega el push pero la confirmación está en el centro @CU-24.3-H03-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (correo, sede, cancha) = await reservaDeManana();
      await entrar(tester, correo, permiso: false);

      await cancelarEnLaApp(tester, cancha);
      await tapText(tester, 'INICIO');
      await abrirCentro(tester, sinLeer: 1);

      // Verifica: el centro avisa que están desactivadas y trae la confirmación igual.
      expect(find.text('Notificaciones desactivadas'), findsOneWidget);
      expect(find.text(cuerpo(sede)), findsOneWidget);
      expect(find.text('MARCAR TODAS'), findsNothing);
      semantica.dispose();
    },
  );

  testWidgets(
    'si la cancelación falló no recibe ninguna confirmación @CU-24.3-H04-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (correo, _, cancha) = await reservaDeManana();
      await entrar(tester, correo);
      await tapText(tester, 'RESERVAS');
      await waitUntil(tester, find.text(cancha));
      await tapText(tester, 'CANCELAR');
      await waitUntil(tester, find.text('¿Cancelar la reserva?'));

      // Mientras mira la confirmación, el turno empieza.
      await startBookingsOf(cancha);
      await tapText(tester, 'CANCELAR RESERVA');
      await waitUntil(tester, find.text('Esto cambió mientras tanto'));
      await tapText(tester, 'VER LO ACTUALIZADO');
      await tapText(tester, 'INICIO');

      // Verifica: el centro sigue vacío y la campana no cuenta nada.
      await abrirCentro(tester);
      await waitUntil(tester, find.text('Todavía no tenés notificaciones'));
      expect(find.text(titulo), findsNothing);
      semantica.dispose();
    },
  );
}
