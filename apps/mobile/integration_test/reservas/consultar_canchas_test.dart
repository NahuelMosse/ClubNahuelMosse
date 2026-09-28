import 'dart:ui' show SemanticsFlags;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../soporte/acciones.dart';
import '../soporte/red.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final manana = hoyEnElClub().add(const Duration(days: 1));
  final ayer = hoyEnElClub().subtract(const Duration(days: 1));

  /// «29/09/2026».
  String fecha(DateTime dia) =>
      '${dia.day.toString().padLeft(2, '0')}/'
      '${dia.month.toString().padLeft(2, '0')}/${dia.year}';

  const dias = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  /// Una sede de 08:00 a 23:00 con dos Fútbol 5 y un Fútbol 7.
  Future<(String, String, String, String)> sedeConCanchas() async {
    final sede = 'Sede Haedo ${unico()}';
    await crearSede(sede, 'Av. Vergara 1850');
    return (
      sede,
      await crearEspacio(sede),
      await crearEspacio(sede),
      await crearEspacio(sede, tipo: 'F7'),
    );
  }

  Future<void> abrirBusqueda(WidgetTester tester, {String? apiUrl}) async {
    await entrarComoUsuario(
      tester,
      correo: 'socio.${unico()}@correo.com',
      apiUrl: apiUrl,
    );
    await tocar(tester, 'Buscar cancha');
    await esperarA(tester, find.text('Consultar canchas'));
  }

  Future<void> completar(
    WidgetTester tester,
    String sede, {
    String tipo = 'Fútbol 5',
    DateTime? dia,
    String desde = '10:00',
    String hasta = '12:00',
  }) async {
    await elegir(tester, 'Sede', sede);
    await elegir(tester, 'Deporte', 'Fútbol');
    await elegir(tester, 'Tipo de cancha', tipo);
    await escribir(tester, 'Fecha', fecha(dia ?? manana));
    await elegir(tester, 'Desde', desde);
    await elegir(tester, 'Hasta', hasta);
  }

  SemanticsFlags banderas(WidgetTester tester, String etiqueta) =>
      tester.getSemantics(find.bySemanticsLabel(etiqueta)).flagsCollection;

  testWidgets(
    'consulta sede, tipo, fecha y rango y ve sólo las canchas libres en todo ese rango @CU-13-H01-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (sede, f5a, f5b, f7) = await sedeConCanchas();
      await ocupar(f5b, manana, 11);
      await abrirBusqueda(tester);
      await completar(tester, sede);

      await tocar(tester, 'CONSULTAR');

      // Verifica: sólo la Fútbol 5 libre de 10 a 12, con el rango consultado.
      await esperarA(
        tester,
        find.text('1 CANCHA DISPONIBLE · FÚTBOL 5 · 10:00 – 12:00'),
      );
      expect(find.text(f5a), findsOneWidget);
      expect(find.text(f5b), findsNothing);
      expect(find.text(f7), findsNothing);
      semantica.dispose();
    },
  );

  testWidgets(
    'una cancha con una reserva que se superpone con el rango no aparece como disponible @CU-13-H01-02',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (sede, f5a, f5b, _) = await sedeConCanchas();
      // La de la Cancha 1 termina cuando empieza el rango; la de la Cancha 2 lo pisa.
      await ocupar(f5a, manana, 9);
      await ocupar(f5b, manana, 11, horas: 2);
      await abrirBusqueda(tester);
      await completar(tester, sede);

      await tocar(tester, 'CONSULTAR');

      // Verifica: la que termina a las 10 queda libre; la que pisa el rango, no.
      await esperarA(tester, find.text(f5a));
      expect(find.text(f5b), findsNothing);
      semantica.dispose();
    },
  );

  testWidgets(
    'elige una cancha del resultado y pasa a reservarla con el horario consultado @CU-13-H01-03',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (sede, f5a, _, _) = await sedeConCanchas();
      await abrirBusqueda(tester);
      await completar(tester, sede);
      await tocar(tester, 'CONSULTAR');
      await esperarA(tester, find.text(f5a));

      await tocar(tester, 'VER HORARIOS / RESERVAR');

      // Verifica: la grilla de esa cancha llega con el día, la duración y el horario.
      await esperarA(tester, find.text('HORARIO DISPONIBLE'));
      expect(banderas(tester, 'Cancha 1, Techada').isSelected, isTrue);
      expect(
        banderas(
          tester,
          '${dias[manana.weekday - 1]} ${manana.day}',
        ).isSelected,
        isTrue,
      );
      expect(find.text('2 horas'), findsOneWidget);
      expect(banderas(tester, '10:00 – 12:00').isSelected, isTrue);
      expect(banderas(tester, 'CONTINUAR').isEnabled, isTrue);
      semantica.dispose();
    },
  );

  testWidgets(
    'después de consultar, los filtros siguen visibles y se pueden cambiar @CU-13-H01-04',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (sede, f5a, _, _) = await sedeConCanchas();
      await abrirBusqueda(tester);
      await completar(tester, sede);
      await tocar(tester, 'CONSULTAR');
      await esperarA(tester, find.text(f5a));

      // Verifica: lo elegido sigue en los filtros.
      expect(find.text(sede), findsWidgets);
      expect(find.text(fecha(manana)), findsOneWidget);

      await elegir(tester, 'Hasta', '11:00');
      await tocar(tester, 'CONSULTAR');

      // Verifica: la nueva consulta usa el rango cambiado.
      await esperarA(
        tester,
        find.text('2 CANCHAS DISPONIBLES · FÚTBOL 5 · 10:00 – 11:00'),
      );
      semantica.dispose();
    },
  );

  testWidgets(
    'ninguna cancha está libre en el rango y ve el aviso sin perder los filtros @CU-13-H02-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (sede, f5a, f5b, _) = await sedeConCanchas();
      await ocupar(f5a, manana, 10, horas: 2);
      await ocupar(f5b, manana, 10);
      await abrirBusqueda(tester);
      await completar(tester, sede);

      await tocar(tester, 'CONSULTAR');

      // Verifica: el aviso, y los filtros siguen cargados.
      await esperarA(tester, find.text('No hay canchas disponibles'));
      expect(find.text(f5a), findsNothing);
      expect(find.text(sede), findsWidgets);
      expect(find.text(fecha(manana)), findsOneWidget);
      semantica.dispose();
    },
  );

  testWidgets('elige una fecha pasada y no se consulta @CU-13-H03-01', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    final (sede, _, _, _) = await sedeConCanchas();
    await abrirBusqueda(tester);

    await completar(tester, sede, dia: ayer);

    // Verifica: el error en la fecha y la consulta bloqueada.
    await esperarA(tester, find.text('La fecha tiene que ser futura'));
    expect(banderas(tester, 'CONSULTAR').isEnabled, isFalse);
    expect(find.textContaining('DISPONIBLE'), findsNothing);
    semantica.dispose();
  });

  testWidgets(
    'elige un rango de menos de una hora y no se consulta @CU-13-H03-02',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (sede, _, _, _) = await sedeConCanchas();
      await abrirBusqueda(tester);

      await completar(tester, sede, desde: '18:00', hasta: '18:00');

      // Verifica: el error en el rango y la consulta bloqueada.
      await esperarA(tester, find.text('La duración mínima es de una hora'));
      expect(banderas(tester, 'CONSULTAR').isEnabled, isFalse);
      semantica.dispose();
    },
  );

  testWidgets(
    'elige un rango que termina después del cierre de la sede y no se consulta @CU-13-H03-03',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (sede, _, _, _) = await sedeConCanchas();
      await abrirBusqueda(tester);

      await completar(tester, sede, desde: '22:00', hasta: '00:00');

      // Verifica: el error con la hora de cierre y la consulta bloqueada.
      await esperarA(tester, find.text('La sede cierra a las 23:00'));
      expect(banderas(tester, 'CONSULTAR').isEnabled, isFalse);
      semantica.dispose();
    },
  );

  testWidgets(
    'sin conexión al consultar, ve el error y conserva los filtros @CU-13-H04-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (sede, _, _, _) = await sedeConCanchas();
      final api = await ApiIntermedia.abrir();
      await abrirBusqueda(tester, apiUrl: api.url);
      await completar(tester, sede);

      api.estado = EstadoApi.sinRed;
      await tocar(tester, 'CONSULTAR');

      // Verifica: el error con reintento, y los filtros siguen cargados.
      await esperarA(
        tester,
        find.text('No se pudo consultar la disponibilidad'),
      );
      expect(find.textContaining('Revisá tu conexión'), findsOneWidget);
      expect(find.text('REINTENTAR'), findsOneWidget);
      expect(find.text(sede), findsWidgets);
      expect(find.text(fecha(manana)), findsOneWidget);
      semantica.dispose();
    },
  );

  testWidgets(
    'el servidor falla al consultar y no se muestran resultados viejos @CU-13-H05-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (sede, f5a, _, _) = await sedeConCanchas();
      final api = await ApiIntermedia.abrir();
      await abrirBusqueda(tester, apiUrl: api.url);
      await completar(tester, sede);
      await tocar(tester, 'CONSULTAR');
      await esperarA(tester, find.text(f5a));

      api.estado = EstadoApi.falla;
      await tocar(tester, 'CONSULTAR');

      // Verifica: el error, y el resultado anterior ya no está.
      await esperarA(
        tester,
        find.text('No se pudo consultar la disponibilidad'),
      );
      expect(find.text(f5a), findsNothing);
      expect(find.textContaining('CANCHAS DISPONIBLES'), findsNothing);
      semantica.dispose();
    },
  );
}
