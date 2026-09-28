import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../soporte/acciones.dart';
import '../soporte/red.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final hoy = hoyEnElClub();
  DateTime dia(int dias) => hoy.add(Duration(days: dias));

  const meses = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];
  const dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  /// «Jue 12 de noviembre».
  String fecha(DateTime d) =>
      '${dias[d.weekday - 1]} ${d.day} de ${meses[d.month - 1]}';

  /// Una sede con un Fútbol 5 y un Tenis de polvo de ladrillo.
  Future<(String, String, String)> sedeConCanchas() async {
    final sede = 'Sede Haedo ${unico()}';
    await crearSede(sede, 'Av. Vergara 1850');
    return (
      sede,
      await crearEspacio(sede),
      await crearEspacio(sede, deporte: 'Tenis', tipo: 'PDL'),
    );
  }

  Future<String> cuenta() async {
    final correo = 'socio.${unico()}@correo.com';
    await crearCuenta(correo: correo, contrasena: 'ClubNahuel1');
    return correo;
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

  Future<void> abrirMisReservas(WidgetTester tester) async {
    await tocar(tester, 'RESERVAS');
    await esperarA(tester, find.text('Mis reservas'));
  }

  Future<void> verHistorial(WidgetTester tester) async {
    await tocar(tester, 'Historial');
  }

  /// El orden en pantalla, de arriba abajo, de los textos que se encuentran.
  List<String> enOrden(WidgetTester tester, List<String> textos) {
    final y = {
      for (final t in textos) t: tester.getTopLeft(find.text(t).first).dy,
    };
    return [...textos]..sort((a, b) => y[a]!.compareTo(y[b]!));
  }

  testWidgets(
    'abre Mis reservas y ve sus próximas reservas con sede, espacio, fecha, horario y precio @CU-08-H01-01',
    (tester) async {
      final (sede, f5, tenis) = await sedeConCanchas();
      final correo = await cuenta();
      await ocupar(tenis, dia(3), 10, correo: correo);
      await ocupar(f5, dia(1), 18, horas: 2, correo: correo);
      await entrar(tester, correo);

      await abrirMisReservas(tester);

      // Verifica: cada próxima con sus datos, la más cercana primero.
      await esperarA(tester, find.text(f5));
      expect(find.text(tenis), findsOneWidget);
      expect(find.text('$sede · Av. Vergara 1850'), findsNWidgets(2));
      expect(find.text(fecha(dia(1))), findsOneWidget);
      expect(find.text('18:00 – 20:00'), findsOneWidget);
      expect(find.textContaining('86.000'), findsOneWidget);
      expect(find.text('ACTIVA'), findsNWidgets(2));
      expect(enOrden(tester, [f5, tenis]), [f5, tenis]);
    },
  );

  testWidgets('una reserva recién hecha aparece en Próximas @CU-08-H01-02', (
    tester,
  ) async {
    final (_, f5, _) = await sedeConCanchas();
    final correo = await cuenta();
    await entrar(tester, correo);
    await abrirMisReservas(tester);
    await esperarA(tester, find.text('No hay próximas reservas'));

    await ocupar(f5, dia(2), 9, correo: correo);
    await tocar(tester, 'INICIO');
    await abrirMisReservas(tester);

    // Verifica: al volver a la sección ya está.
    await esperarA(tester, find.text(f5));
    expect(find.text('09:00 – 10:00'), findsOneWidget);
  });

  testWidgets(
    'abre Historial y ve sus reservas ya finalizadas, ordenadas por fecha @CU-08-H01-03',
    (tester) async {
      final (_, f5, tenis) = await sedeConCanchas();
      final correo = await cuenta();
      await ocupar(f5, dia(-6), 10, correo: correo);
      await ocupar(tenis, dia(-2), 19, correo: correo);
      await entrar(tester, correo);
      await abrirMisReservas(tester);

      await verHistorial(tester);

      // Verifica: las dos completadas, la más reciente primero.
      await esperarA(tester, find.text(tenis));
      expect(find.text(f5), findsOneWidget);
      expect(find.text('COMPLETADA'), findsNWidgets(2));
      expect(enOrden(tester, [f5, tenis]), [tenis, f5]);
    },
  );

  testWidgets(
    'una reserva cancelada o anulada aparece en el historial con su estado @CU-08-H01-04',
    (tester) async {
      final (_, f5, tenis) = await sedeConCanchas();
      final correo = await cuenta();
      await ocupar(f5, dia(2), 20, correo: correo, estado: 'cancelada');
      await ocupar(
        tenis,
        dia(-1),
        19,
        correo: correo,
        estado: 'anulada',
        motivo: 'mantenimiento de la cancha',
      );
      await entrar(tester, correo);
      await abrirMisReservas(tester);
      await esperarA(tester, find.text('No hay próximas reservas'));

      await verHistorial(tester);

      // Verifica: las dos con su estado y el porqué.
      await esperarA(tester, find.text('CANCELADA'));
      expect(find.text('ANULADA'), findsOneWidget);
      expect(
        find.text('Cancelada por vos · el horario quedó liberado'),
        findsOneWidget,
      );
      expect(
        find.text('Anulada por el administrador · mantenimiento de la cancha'),
        findsOneWidget,
      );
    },
  );

  testWidgets('no ve reservas de otros usuarios @CU-08-H01-05', (tester) async {
    final (_, f5, tenis) = await sedeConCanchas();
    final correo = await cuenta();
    final otra = await cuenta();
    await ocupar(f5, dia(1), 10, correo: correo);
    await ocupar(tenis, dia(1), 10, correo: otra);
    await ocupar(tenis, dia(-1), 10, correo: otra);
    await entrar(tester, correo);

    await abrirMisReservas(tester);

    // Verifica: sólo la suya, en las dos pestañas.
    await esperarA(tester, find.text(f5));
    expect(find.text(tenis), findsNothing);
    await verHistorial(tester);
    await esperarA(tester, find.text('No hay reservas pasadas'));
    expect(find.text(tenis), findsNothing);
  });

  testWidgets(
    'sin reservas próximas, ve el aviso de que no tiene @CU-08-H02-01',
    (tester) async {
      final (_, f5, _) = await sedeConCanchas();
      final correo = await cuenta();
      await ocupar(f5, dia(-3), 10, correo: correo);
      await entrar(tester, correo);

      await abrirMisReservas(tester);

      // Verifica: el aviso de Próximas.
      await esperarA(tester, find.text('No hay próximas reservas'));
      expect(
        find.text('No se encontraron próximas reservas asociadas a tu cuenta.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'sin reservas pasadas, ve el aviso de que no tiene @CU-08-H02-02',
    (tester) async {
      final (_, f5, _) = await sedeConCanchas();
      final correo = await cuenta();
      await ocupar(f5, dia(3), 10, correo: correo);
      await entrar(tester, correo);
      await abrirMisReservas(tester);
      await esperarA(tester, find.text(f5));

      await verHistorial(tester);

      // Verifica: el aviso del Historial.
      await esperarA(tester, find.text('No hay reservas pasadas'));
      expect(
        find.text('No se encontraron reservas pasadas asociadas a tu cuenta.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('sin conexión, ve el error de conexión @CU-08-H03-01', (
    tester,
  ) async {
    final (_, f5, _) = await sedeConCanchas();
    final correo = await cuenta();
    await ocupar(f5, dia(1), 10, correo: correo);
    final api = await ApiIntermedia.abrir();
    await entrar(tester, correo, apiUrl: api.url);

    api.estado = EstadoApi.sinRed;
    await tocar(tester, 'RESERVAS');

    // Verifica: el aviso de conexión y, al cerrarlo, ninguna reserva.
    await esperarA(tester, find.text('Error de conexión'));
    await tocar(tester, 'Volver');
    expect(find.text(f5), findsNothing);
    expect(find.text('REINTENTAR'), findsOneWidget);
  });

  testWidgets(
    'el servidor falla y no se muestran datos parciales @CU-08-H03-02',
    (tester) async {
      final (_, f5, _) = await sedeConCanchas();
      final correo = await cuenta();
      await ocupar(f5, dia(1), 10, correo: correo);
      await ocupar(f5, dia(-1), 10, correo: correo);
      final api = await ApiIntermedia.abrir();
      await entrar(tester, correo, apiUrl: api.url);
      await abrirMisReservas(tester);
      await esperarA(tester, find.text(f5));

      api.estado = EstadoApi.falla;
      await verHistorial(tester);

      // Verifica: el error del servidor y ninguna tarjeta del historial.
      await esperarA(tester, find.text('Error del servidor'));
      await tocar(tester, 'ACEPTAR');
      expect(find.text('COMPLETADA'), findsNothing);
      expect(find.text(f5), findsNothing);
      expect(find.text('REINTENTAR'), findsOneWidget);
    },
  );
}
