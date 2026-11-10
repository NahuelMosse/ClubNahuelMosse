import 'package:clubnahuelmosse/common/club_timezone.dart';
import 'package:clubnahuelmosse/features/home/presentation/home_greeting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/actions.dart';
import '../support/network.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final manana = todayAtClub().add(const Duration(days: 1));
  final enCincoDias = todayAtClub().add(const Duration(days: 5));

  /// Espera a que [texto] deje de estar en pantalla: el Home recién recargó.
  Future<void> esperarQueDesaparezca(WidgetTester tester, String texto) async {
    final fin = DateTime.now().add(const Duration(seconds: 20));
    while (DateTime.now().isBefore(fin) &&
        find.text(texto).evaluate().isNotEmpty) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text(texto), findsNothing);
  }

  testWidgets('al iniciar sesión ve el Home con el saludo y su nombre'
      ' @TP-01-H01-01', (tester) async {
    await signInAsUser(
      tester,
      email: 'socio.${unique()}@correo.com',
      name: 'Valentina',
    );

    // Verifica: el saludo de la hora del club y el nombre de quien inició sesión.
    expect(find.text(HomeGreeting.forHour(clubNow())), findsOneWidget);
    expect(find.text('Valentina'), findsOneWidget);
  });

  testWidgets(
    'el Home muestra su próxima reserva activa, la más cercana, con fecha,'
    ' horario y sede @TP-01-H01-02 @supuesto:TP-01-SUP-05',
    (tester) async {
      final sede = 'Sede Haedo ${unique()}';
      await createVenue(sede, 'Av. Vergara 1850');
      final cancha = await createSpace(sede);
      final otraCancha = await createSpace(sede, kind: 'F7');
      final correo = 'socio.${unique()}@correo.com';
      await createAccount(email: correo, password: 'ClubNahuel1');
      // Dos próximas reservas: la de mañana tiene que ganarle a la de en cinco días.
      await occupy(otraCancha, enCincoDias, 10, email: correo);
      await occupy(cancha, manana, 21, email: correo);

      await signInAsUser(tester, email: correo);

      // Verifica: se muestra la más cercana (mañana), con su sede y horario.
      await waitUntil(tester, find.text('TU PRÓXIMA RESERVA'));
      expect(find.text(cancha), findsOneWidget);
      expect(find.textContaining(sede), findsWidgets);
      expect(find.textContaining('21:00 – 22:00'), findsWidgets);
      expect(find.text(otraCancha), findsNothing);
    },
  );

  testWidgets(
    'desde la próxima reserva puede modificarla o cancelarla @TP-01-H01-03',
    (tester) async {
      final sede = 'Sede Haedo ${unique()}';
      await createVenue(sede, 'Av. Vergara 1850');
      final cancha = await createSpace(sede);
      final correo = 'socio.${unique()}@correo.com';
      await createAccount(email: correo, password: 'ClubNahuel1');
      await occupy(cancha, manana, 21, email: correo);

      await signInAsUser(tester, email: correo);
      await waitUntil(tester, find.text('MODIFICAR'));
      expect(find.text('CANCELAR'), findsOneWidget);

      await tapText(tester, 'CANCELAR');
      await waitUntil(tester, find.text('¿Cancelar la reserva?'));
      await tapText(tester, 'CANCELAR RESERVA');

      // Verifica: el éxito y que el bloque de la próxima reserva desaparece del Home.
      await waitUntil(tester, find.text('Reserva cancelada con éxito'));
      await tapText(tester, 'ACEPTAR');
      await esperarQueDesaparezca(tester, 'TU PRÓXIMA RESERVA');
      expect(await bookingsOf(correo), isEmpty);
    },
  );

  testWidgets('«Ver todas» lleva a Mis reservas @TP-01-H01-04', (tester) async {
    final sede = 'Sede Haedo ${unique()}';
    await createVenue(sede, 'Av. Vergara 1850');
    final cancha = await createSpace(sede);
    final correo = 'socio.${unique()}@correo.com';
    await createAccount(email: correo, password: 'ClubNahuel1');
    await occupy(cancha, manana, 21, email: correo);

    await signInAsUser(tester, email: correo);
    await waitUntil(tester, find.text('VER TODAS →'));
    await tapText(tester, 'VER TODAS →');

    await waitUntil(tester, find.text('Mis reservas'));
    expect(find.text(cancha), findsOneWidget);
  });

  testWidgets(
    'la cantidad de sedes y canchas del hero sale de los datos cargados @TP-01-H01-05',
    (tester) async {
      final correo = 'socio.${unique()}@correo.com';
      await signInAsUser(tester, email: correo);
      await waitUntil(
        tester,
        find.textContaining('disponibilidad en tiempo real'),
      );

      final sedes = await venuesAUserSees();
      final total = sedes.values.fold(0, (a, b) => a + b);

      // Verifica: el hero muestra exactamente lo que la API devuelve, no un valor fijo.
      final cuantasSedes = sedes.length == 1 ? 'sede' : 'sedes';
      final cuantasCanchas = total == 1 ? 'cancha' : 'canchas';
      expect(
        find.text(
          '${sedes.length} $cuantasSedes · $total $cuantasCanchas'
          ' · disponibilidad en tiempo real',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    '«Buscar cancha» lleva a Consultar canchas y «Ver sedes» al listado de sedes'
    ' @TP-01-H01-06',
    (tester) async {
      await signInAsUser(tester, email: 'socio.${unique()}@correo.com');

      await tapText(tester, 'Buscar cancha');
      await waitUntil(tester, find.text('Consultar canchas'));

      await tester.tap(find.byTooltip('Volver'));
      await tester.pumpAndSettle();
      await waitUntil(tester, find.text('RESERVÁ TU CANCHA'));
      await tapText(tester, 'Ver sedes');
      await waitUntil(tester, find.text('Sedes'));
    },
  );

  testWidgets(
    'la barra inferior lleva a Inicio, Sedes, Reservas y Perfil @TP-01-H01-07',
    (tester) async {
      await signInAsUser(tester, email: 'socio.${unique()}@correo.com');

      await tapText(tester, 'SEDES');
      await waitUntil(tester, find.text('Sedes'));
      await tapText(tester, 'RESERVAS');
      await waitUntil(tester, find.text('Mis reservas'));
      await tapText(tester, 'PERFIL');
      await waitUntil(tester, find.text('DATOS PERSONALES'));
      await tapText(tester, 'INICIO');
      await waitUntil(tester, find.text('RESERVÁ TU CANCHA'));
    },
  );

  testWidgets(
    'desde la tarjeta del avatar llega a su perfil y a Mis reservas @TP-01-H01-08',
    (tester) async {
      await signInAsUser(tester, email: 'socio.${unique()}@correo.com');

      await tester.tap(find.bySemanticsLabel('Tu cuenta'));
      await tester.pumpAndSettle();
      await tapText(tester, 'Perfil completo');
      await waitUntil(tester, find.text('DATOS PERSONALES'));
      await tapText(tester, 'INICIO');

      await tester.tap(find.bySemanticsLabel('Tu cuenta'));
      await tester.pumpAndSettle();
      await tapText(tester, 'Mis reservas');
      await waitUntil(tester, find.text('Mis reservas'));
    },
  );

  testWidgets(
    'sin reservas próximas, el Home no muestra la tarjeta de próxima reserva'
    ' @TP-01-H02-01 @supuesto:TP-01-SUP-01',
    (tester) async {
      await signInAsUser(tester, email: 'socio.${unique()}@correo.com');

      // Verifica: el Home terminó de cargar y el bloque de la próxima reserva no está.
      await waitUntil(
        tester,
        find.textContaining('disponibilidad en tiempo real'),
      );
      expect(find.text('REINTENTAR'), findsNothing);
      expect(find.text('TU PRÓXIMA RESERVA'), findsNothing);
    },
  );

  testWidgets(
    'un administrador, al iniciar sesión, llega al panel de administración'
    ' @TP-01-H03-01',
    (tester) async {
      await signInAsAdmin(tester);

      // Verifica: llega directo al panel, no al Home de usuario.
      expect(find.text('PANEL ADMIN'), findsOneWidget);
      expect(find.text('RESERVÁ TU CANCHA'), findsNothing);
    },
  );
}
