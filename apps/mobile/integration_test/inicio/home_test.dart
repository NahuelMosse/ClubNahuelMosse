import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../soporte/acciones.dart';
import '../soporte/red.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final manana = hoyEnElClub().add(const Duration(days: 1));
  final enCincoDias = hoyEnElClub().add(const Duration(days: 5));

  /// Espera a que [texto] deje de estar en pantalla: el Home recién recargó.
  Future<void> esperarQueDesaparezca(WidgetTester tester, String texto) async {
    final fin = DateTime.now().add(const Duration(seconds: 20));
    while (DateTime.now().isBefore(fin) &&
        find.text(texto).evaluate().isNotEmpty) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text(texto), findsNothing);
  }

  testWidgets(
    'al iniciar sesión ve el Home con el saludo y su nombre'
    ' @TP-01-H01-01 @supuesto:TP-01-SUP-07',
    (tester) async {
      await entrarComoUsuario(
        tester,
        correo: 'socio.${unico()}@correo.com',
        nombre: 'Valentina',
      );

      // Verifica: el saludo fijo y el nombre de quien inició sesión.
      expect(find.text('BUENOS DÍAS,'), findsOneWidget);
      expect(find.text('Valentina'), findsOneWidget);
    },
  );

  testWidgets(
    'el Home muestra su próxima reserva activa, la más cercana, con fecha,'
    ' horario y sede @TP-01-H01-02 @supuesto:TP-01-SUP-05',
    (tester) async {
      final sede = 'Sede Haedo ${unico()}';
      await crearSede(sede, 'Av. Vergara 1850');
      final cancha = await crearEspacio(sede);
      final otraCancha = await crearEspacio(sede, tipo: 'F7');
      final correo = 'socio.${unico()}@correo.com';
      await crearCuenta(correo: correo, contrasena: 'ClubNahuel1');
      // Dos próximas reservas: la de mañana tiene que ganarle a la de en cinco días.
      await ocupar(otraCancha, enCincoDias, 10, correo: correo);
      await ocupar(cancha, manana, 21, correo: correo);

      await entrarComoUsuario(tester, correo: correo);

      // Verifica: se muestra la más cercana (mañana), con su sede y horario.
      await esperarA(tester, find.text('TU PRÓXIMA RESERVA'));
      expect(find.text(cancha), findsOneWidget);
      expect(find.textContaining(sede), findsWidgets);
      expect(find.textContaining('21:00 – 22:00'), findsWidgets);
      expect(find.text(otraCancha), findsNothing);
    },
  );

  testWidgets('desde la próxima reserva puede modificarla o cancelarla @TP-01-H01-03', (
    tester,
  ) async {
    final sede = 'Sede Haedo ${unico()}';
    await crearSede(sede, 'Av. Vergara 1850');
    final cancha = await crearEspacio(sede);
    final correo = 'socio.${unico()}@correo.com';
    await crearCuenta(correo: correo, contrasena: 'ClubNahuel1');
    await ocupar(cancha, manana, 21, correo: correo);

    await entrarComoUsuario(tester, correo: correo);
    await esperarA(tester, find.text('MODIFICAR'));
    expect(find.text('CANCELAR'), findsOneWidget);

    await tocar(tester, 'CANCELAR');
    await esperarA(tester, find.text('¿Cancelar la reserva?'));
    await tocar(tester, 'CANCELAR RESERVA');

    // Verifica: el éxito y que el bloque de la próxima reserva desaparece del Home.
    await esperarA(tester, find.text('Reserva cancelada con éxito'));
    await tocar(tester, 'ACEPTAR');
    await esperarQueDesaparezca(tester, 'TU PRÓXIMA RESERVA');
    expect(await reservasDe(correo), isEmpty);
  });

  testWidgets('«Ver todas» lleva a Mis reservas @TP-01-H01-04', (tester) async {
    final sede = 'Sede Haedo ${unico()}';
    await crearSede(sede, 'Av. Vergara 1850');
    final cancha = await crearEspacio(sede);
    final correo = 'socio.${unico()}@correo.com';
    await crearCuenta(correo: correo, contrasena: 'ClubNahuel1');
    await ocupar(cancha, manana, 21, correo: correo);

    await entrarComoUsuario(tester, correo: correo);
    await esperarA(tester, find.text('VER TODAS →'));
    await tocar(tester, 'VER TODAS →');

    await esperarA(tester, find.text('Mis reservas'));
    expect(find.text(cancha), findsOneWidget);
  });

  testWidgets(
    'la cantidad de sedes y canchas del hero sale de los datos cargados @TP-01-H01-05',
    (tester) async {
      final correo = 'socio.${unico()}@correo.com';
      await entrarComoUsuario(tester, correo: correo);
      await esperarA(tester, find.textContaining('disponibilidad en tiempo real'));

      final sedes = await sedesQueVeUnUsuario();
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
      await entrarComoUsuario(tester, correo: 'socio.${unico()}@correo.com');

      await tocar(tester, 'Buscar cancha');
      await esperarA(tester, find.text('Consultar canchas'));

      await tester.tap(find.byTooltip('Volver'));
      await tester.pumpAndSettle();
      await esperarA(tester, find.text('RESERVÁ TU CANCHA'));
      await tocar(tester, 'Ver sedes');
      await esperarA(tester, find.text('Sedes'));
    },
  );

  testWidgets(
    'la barra inferior lleva a Inicio, Sedes, Reservas y Perfil @TP-01-H01-07',
    (tester) async {
      await entrarComoUsuario(tester, correo: 'socio.${unico()}@correo.com');

      await tocar(tester, 'SEDES');
      await esperarA(tester, find.text('Sedes'));
      await tocar(tester, 'RESERVAS');
      await esperarA(tester, find.text('Mis reservas'));
      await tocar(tester, 'PERFIL');
      await esperarA(tester, find.text('DATOS PERSONALES'));
      await tocar(tester, 'INICIO');
      await esperarA(tester, find.text('RESERVÁ TU CANCHA'));
    },
  );

  testWidgets(
    'desde la tarjeta del avatar llega a su perfil y a Mis reservas @TP-01-H01-08',
    (tester) async {
      await entrarComoUsuario(tester, correo: 'socio.${unico()}@correo.com');

      await tester.tap(find.bySemanticsLabel('Tu cuenta'));
      await tester.pumpAndSettle();
      await tocar(tester, 'Perfil completo');
      await esperarA(tester, find.text('DATOS PERSONALES'));
      await tocar(tester, 'INICIO');

      await tester.tap(find.bySemanticsLabel('Tu cuenta'));
      await tester.pumpAndSettle();
      await tocar(tester, 'Mis reservas');
      await esperarA(tester, find.text('Mis reservas'));
    },
  );

  testWidgets(
    'sin reservas próximas, el Home no muestra la tarjeta de próxima reserva'
    ' @TP-01-H02-01 @supuesto:TP-01-SUP-01',
    (tester) async {
      await entrarComoUsuario(tester, correo: 'socio.${unico()}@correo.com');

      // Verifica: el Home terminó de cargar y el bloque de la próxima reserva no está.
      await esperarA(
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
      await entrarComoAdmin(tester);

      // Verifica: llega directo al panel, no al Home de usuario.
      expect(find.text('PANEL ADMIN'), findsOneWidget);
      expect(find.text('RESERVÁ TU CANCHA'), findsNothing);
    },
  );
}
