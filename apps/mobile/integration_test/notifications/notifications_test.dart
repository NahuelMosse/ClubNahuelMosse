import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/actions.dart';
import '../support/network.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final manana = todayAtClub().add(const Duration(days: 1));
  const titulo = 'Tu reserva es en 1 hora';

  Future<String> nuevaCuenta() async {
    final correo = 'socio.${unique()}@correo.com';
    await createAccount(correo: correo, contrasena: 'ClubNahuel1');
    return correo;
  }

  /// Una sede nueva con un Fútbol 5 y una reserva de [correo] mañana a la [hora].
  Future<(String, String)> reservaDeManana(
    String correo, {
    int hora = 21,
  }) async {
    final sede = 'Sede Morón ${unique()}';
    await createVenue(sede, 'Av. Rivadavia 19850');
    final cancha = await createSpace(sede);
    await occupy(cancha, manana, hora, correo: correo);
    return (sede, cancha);
  }

  /// Inicia sesión; [permiso] es lo que el sistema del teléfono contesta sobre las
  /// notificaciones.
  Future<void> entrar(
    WidgetTester tester,
    String correo, {
    bool permiso = true,
    String? apiUrl,
  }) async {
    await openApp(tester, apiUrl: apiUrl);
    await setNotificationPermission(concedido: permiso);
    await typeInto(tester, 'Correo', correo);
    await typeInto(tester, 'Contraseña', 'ClubNahuel1');
    await tapText(tester, 'INICIAR SESIÓN');
    await waitUntil(tester, find.text('RESERVÁ TU CANCHA'));
  }

  /// El barrido de recordatorios de la API corriendo a las [hora] de mañana.
  Future<int> barrido(String correo, int hora, {int minuto = 0}) =>
      dispatchReminders(
        correo: correo,
        dia: manana,
        hora: hora,
        minuto: minuto,
      );

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

  /// La reserva de [sede] en Mis reservas, con si está resaltada.
  Finder tarjetaDe(String sede) =>
      find.bySemanticsLabel(RegExp('^Fútbol 5, ${RegExp.escape(sede)},'));

  bool resaltada(WidgetTester tester, String sede) =>
      tester.getSemantics(tarjetaDe(sede)).flagsCollection.isSelected;

  testWidgets(
    'al tocar el recordatorio la app abre Mis reservas con esa reserva a la vista @CU-24.1-H01-02 @supuesto:CU-24.1-SUP-03 @supuesto:CU-24.1-SUP-11',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final correo = await nuevaCuenta();
      final (sede, cancha) = await reservaDeManana(correo);
      final (otraSede, otraCancha) = await reservaDeManana(correo, hora: 22);
      await entrar(tester, correo);
      await barrido(correo, 20, minuto: 30);
      await waitUntil(tester, find.text(titulo));

      await tester.tap(find.text(titulo));
      await tester.pumpAndSettle();

      // Verifica: abre Mis reservas, con las dos reservas y sólo la avisada resaltada.
      await waitUntil(tester, find.text(cancha));
      expect(find.text('Mis reservas'), findsOneWidget);
      expect(find.text(otraCancha), findsOneWidget);
      expect(resaltada(tester, sede), isTrue);
      expect(resaltada(tester, otraSede), isFalse);
      // Verifica: el panel se cerró y el aviso tocado quedó leído.
      expect(find.text('MARCAR TODAS'), findsNothing);
      await tapText(tester, 'INICIO');
      await waitUntil(tester, campana(0));
      semantica.dispose();
    },
  );

  testWidgets(
    'el recordatorio queda en el centro de notificaciones con deporte, sede y horario @CU-24.1-H01-03',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final correo = await nuevaCuenta();
      final (sede, _) = await reservaDeManana(correo);
      await entrar(tester, correo);
      await barrido(correo, 20);
      await waitUntil(tester, find.text(titulo));
      await cerrarPanel(tester);

      await abrirCentro(tester, sinLeer: 1);

      // Verifica: el aviso está en el centro, agrupado en HOY, con lo que dice el CU.
      expect(find.text('HOY'), findsOneWidget);
      expect(find.text(titulo), findsOneWidget);
      expect(find.text('Fútbol 5 · $sede · 21:00 – 22:00'), findsOneWidget);
      semantica.dispose();
    },
  );

  testWidgets(
    'con la app abierta el recordatorio aparece como tarjeta superior sin cambiar de pantalla @CU-24.1-H02-01 @supuesto:CU-24.1-SUP-09',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final correo = await nuevaCuenta();
      final (sede, cancha) = await reservaDeManana(correo);
      await entrar(tester, correo);
      await tapText(tester, 'RESERVAS');
      await waitUntil(tester, find.text(cancha));

      await barrido(correo, 20);
      await waitUntil(tester, find.text(titulo));

      // Verifica: la tarjeta trae el aviso completo y la pantalla de abajo sigue siendo
      // Mis reservas.
      expect(find.text('Fútbol 5 · $sede · 21:00 – 22:00'), findsOneWidget);
      expect(find.text('MARCAR TODAS'), findsOneWidget);
      expect(find.text('Mis reservas'), findsOneWidget);
      await cerrarPanel(tester);
      expect(find.text(titulo), findsNothing);
      expect(find.text('Mis reservas'), findsOneWidget);
      expect(find.text(cancha), findsOneWidget);
      semantica.dispose();
    },
  );

  testWidgets(
    'sin permiso de notificaciones el centro muestra «Notificaciones desactivadas» y el aviso queda registrado @CU-24.1-H03-01 @supuesto:CU-24.1-SUP-08',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final correo = await nuevaCuenta();
      final (sede, _) = await reservaDeManana(correo);
      await entrar(tester, correo, permiso: false);

      await barrido(correo, 20);
      await abrirCentro(tester, sinLeer: 1);

      // Verifica: el centro avisa que están desactivadas y ofrece activarlas, la app no
      // abrió el panel encima, y la API sabe que este dispositivo no tiene permiso.
      expect(find.text('Notificaciones desactivadas'), findsOneWidget);
      expect(
        find.text(
          'Activá los avisos para que te recordemos tus reservas una hora antes.',
        ),
        findsOneWidget,
      );
      expect(find.text('ACTIVAR NOTIFICACIONES'), findsOneWidget);
      expect(find.text('MARCAR TODAS'), findsNothing);
      expect(await devicesOf(correo), [false]);
      // Verifica: el recordatorio quedó en el centro igual.
      expect(find.text('Fútbol 5 · $sede · 21:00 – 22:00'), findsOneWidget);
      semantica.dispose();
    },
  );

  testWidgets(
    'desde «Notificaciones desactivadas» activa los avisos y empieza a recibirlos @CU-24.1-H03-02',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final correo = await nuevaCuenta();
      final (sede, _) = await reservaDeManana(correo);
      await entrar(tester, correo, permiso: false);
      await abrirCentro(tester);
      expect(find.text('Notificaciones desactivadas'), findsOneWidget);
      expect(await devicesOf(correo), [false]);

      await tapText(tester, 'ACTIVAR NOTIFICACIONES');

      // Verifica: el centro deja de decir que están desactivadas y la API registra el
      // dispositivo con permiso.
      await waitUntil(tester, find.text('Todavía no tenés notificaciones'));
      expect(find.text('Notificaciones desactivadas'), findsNothing);
      expect(await devicesOf(correo), [true]);
      // Verifica: el recordatorio siguiente llega a la app abierta.
      await barrido(correo, 20);
      await waitUntil(tester, find.text('Fútbol 5 · $sede · 21:00 – 22:00'));
      semantica.dispose();
    },
  );

  testWidgets(
    'un recordatorio que no se tocó queda como no leído, también después de abrir el centro @CU-24.1-H04-01 @supuesto:CU-24.1-SUP-03',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final correo = await nuevaCuenta();
      final (sede, _) = await reservaDeManana(correo);
      await entrar(tester, correo);
      await barrido(correo, 20);
      await waitUntil(tester, find.text(titulo));
      await cerrarPanel(tester);

      await abrirCentro(tester, sinLeer: 1);

      // Verifica: el aviso figura sin leer; mirar el centro no lo marca.
      expect(
        find.bySemanticsLabel(
          RegExp('^$titulo.*Fútbol 5 · ${RegExp.escape(sede)}.*sin leer'),
        ),
        findsOneWidget,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await waitUntil(tester, campana(1));
      semantica.dispose();
    },
  );

  testWidgets(
    '«Marcar todas» deja todas las notificaciones como leídas y sigue así al reabrir la app @CU-24.1-H04-02',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final correo = await nuevaCuenta();
      final (sede, _) = await reservaDeManana(correo);
      final (otraSede, _) = await reservaDeManana(correo);
      await entrar(tester, correo);
      expect(await barrido(correo, 20), 2);
      await waitUntil(tester, find.text('MARCAR TODAS'));

      await tester.tap(find.text('MARCAR TODAS'));
      await tester.pumpAndSettle();

      // Verifica: el panel se cierra y la campana ya no cuenta ninguna sin leer.
      expect(find.text('MARCAR TODAS'), findsNothing);
      await waitUntil(tester, campana(0));
      // Verifica: en el centro las dos están leídas.
      await abrirCentro(tester);
      expect(find.bySemanticsLabel(RegExp('sin leer')), findsNothing);
      expect(find.textContaining(sede), findsOneWidget);
      expect(find.textContaining(otraSede), findsOneWidget);
      // Verifica: persistió; al reabrir la app siguen leídas.
      await reopenApp(tester);
      await waitUntil(tester, campana(0));
      semantica.dispose();
    },
  );

  testWidgets(
    'sin notificaciones el centro dice que todavía no hay ninguna @sin-centinela:estado vacío @supuesto:CU-24.1-SUP-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final correo = await nuevaCuenta();
      await entrar(tester, correo);

      await abrirCentro(tester);

      // Verifica: el estado vacío con su leyenda, no una pantalla en blanco.
      expect(find.text('Todavía no tenés notificaciones'), findsOneWidget);
      expect(
        find.text('Acá vas a ver los recordatorios de tus reservas.'),
        findsOneWidget,
      );
      expect(find.text('Notificaciones desactivadas'), findsNothing);
      semantica.dispose();
    },
  );

  testWidgets(
    'el centro ordena de la más nueva a la más vieja @supuesto:CU-24.1-SUP-04',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final correo = await nuevaCuenta();
      final (primera, _) = await reservaDeManana(correo);
      final (segunda, _) = await reservaDeManana(correo, hora: 22);
      await entrar(tester, correo);
      await barrido(correo, 20, minuto: 30);
      await waitUntil(tester, find.text(titulo));
      await cerrarPanel(tester);
      await barrido(correo, 21, minuto: 30);
      await waitUntil(tester, campana(2));

      await abrirCentro(tester, sinLeer: 2);

      // Verifica: el aviso de las 22 (el último en llegar) está arriba del de las 21.
      final de21 = find.text('Fútbol 5 · $primera · 21:00 – 22:00');
      final de22 = find.text('Fútbol 5 · $segunda · 22:00 – 23:00');
      expect(de21, findsOneWidget);
      expect(de22, findsOneWidget);
      expect(tester.getTopLeft(de22).dy < tester.getTopLeft(de21).dy, isTrue);
      semantica.dispose();
    },
  );

  testWidgets(
    'al cerrar la sesión el dispositivo deja de recibir avisos @supuesto:CU-24.1-SUP-08',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final correo = await nuevaCuenta();
      await entrar(tester, correo);
      expect(await devicesOf(correo), [true]);

      await tester.tap(find.bySemanticsLabel('Tu cuenta'));
      await tester.pumpAndSettle();
      await tapText(tester, 'Cerrar sesión');

      // Verifica: la API ya no tiene ningún dispositivo activo de esa cuenta (decisión 14).
      expect(find.text('INICIAR SESIÓN'), findsOneWidget);
      expect(await devicesOf(correo), isEmpty);
      semantica.dispose();
    },
  );

  testWidgets(
    'sin conexión al abrir el centro avisa del error y ofrece reintentar @sin-centinela:error de red',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final correo = await nuevaCuenta();
      final api = await ApiIntermedia.abrir();
      await entrar(tester, correo, apiUrl: api.url);
      await waitUntil(tester, campana(0));

      api.estado = ApiState.offline;
      await tester.tap(campana(0));
      await tester.pumpAndSettle();

      // Verifica: el aviso de red con reintento, no un centro vacío que engaña.
      await waitUntil(tester, find.text('Error de conexión'));
      expect(find.text('REINTENTAR'), findsOneWidget);
      expect(find.text('Todavía no tenés notificaciones'), findsNothing);
      semantica.dispose();
    },
  );
}
