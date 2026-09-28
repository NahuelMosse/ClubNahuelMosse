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

  /// La etiqueta del chip de [dia] en FECHA: «Viernes 13».
  String chip(DateTime dia) => '${dias[dia.weekday - 1]} ${dia.day}';

  /// La franja que empieza a la [hora] en punto y dura [horas]: «18:00 – 19:00».
  String franja(int hora, [int horas = 1]) {
    String dos(int h) => '${(h % 24).toString().padLeft(2, '0')}:00';
    return '${dos(hora)} – ${dos(hora + horas)}';
  }

  final manana = hoyEnElClub().add(const Duration(days: 1));
  final pasado = hoyEnElClub().add(const Duration(days: 2));

  /// Una sede de 08:00 a 23:00 con dos Fútbol 5 techados de $ 43.000 la hora.
  Future<(String, String, String)> sedeConDosCanchas({
    List<int> dias = const [1, 2, 3, 4, 5, 6, 7],
  }) async {
    final sede = 'Sede Haedo ${unico()}';
    await crearSede(sede, 'Av. Vergara 1850', dias: dias);
    return (sede, await crearEspacio(sede), await crearEspacio(sede));
  }

  /// Entra como usuario a los horarios de la Cancha 1 de [sede].
  Future<void> abrirHorarios(
    WidgetTester tester,
    String sede, {
    String? apiUrl,
    void Function()? antesDeEntrar,
  }) async {
    await entrarComoUsuario(
      tester,
      correo: 'socio.${unico()}@correo.com',
      apiUrl: apiUrl,
    );
    await tocar(tester, 'SEDES');
    final tarjeta = find.bySemanticsLabel(RegExp('^${RegExp.escape(sede)},'));
    await esperarA(tester, tarjeta);
    await tester.ensureVisible(tarjeta);
    await tester.pumpAndSettle();
    await tester.tap(tarjeta);
    await tester.pumpAndSettle();
    final reservar = find.text('VER HORARIOS / RESERVAR');
    await esperarA(tester, reservar);
    antesDeEntrar?.call();
    await tester.ensureVisible(reservar.first);
    await tester.pumpAndSettle();
    await tester.tap(reservar.first);
    await tester.pumpAndSettle();
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

  bool habilitada(WidgetTester tester, String etiqueta) =>
      banderas(tester, etiqueta).isEnabled;

  bool elegida(WidgetTester tester, String etiqueta) =>
      banderas(tester, etiqueta).isSelected;

  Future<void> verDia(WidgetTester tester, DateTime dia) async {
    await tocarEtiqueta(tester, chip(dia));
    await esperarA(tester, find.text('HORARIO DISPONIBLE'));
  }

  testWidgets(
    'abre los horarios con cancha, fecha de hoy y 1 hora por defecto, y sólo puede elegir franjas libres y futuras @CU-12-H01-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (sede, _, _) = await sedeConDosCanchas();
      await abrirHorarios(tester, sede);

      // Verifica: la Cancha 1, hoy y 1 hora vienen elegidas.
      await esperarA(tester, find.text('HORARIO DISPONIBLE'));
      expect(elegida(tester, 'Cancha 1, Techada'), isTrue);
      expect(elegida(tester, chip(hoyEnElClub())), isTrue);
      expect(find.text('1 hora'), findsOneWidget);

      // Verifica: las horas que ya empezaron no se ofrecen y la próxima sí.
      final ahora = horaEnElClub();
      for (var h = 8; h <= ahora && h <= 22; h++) {
        expect(find.bySemanticsLabel(franja(h)), findsNothing);
      }
      final proxima = ahora < 8 ? 8 : ahora + 1;
      if (proxima <= 22) {
        expect(habilitada(tester, franja(proxima)), isTrue);
      } else {
        expect(find.text('No hay horarios disponibles'), findsOneWidget);
      }
      semantica.dispose();
    },
  );

  testWidgets(
    'una franja que otra persona ya reservó aparece no disponible @CU-12-H01-02',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (sede, cancha1, _) = await sedeConDosCanchas();
      await ocupar(cancha1, manana, 10);
      await abrirHorarios(tester, sede);

      await verDia(tester, manana);

      // Verifica: la de las 10 se ve pero no se puede elegir; la siguiente sí.
      expect(habilitada(tester, franja(10)), isFalse);
      expect(habilitada(tester, franja(11)), isTrue);
      semantica.dispose();
    },
  );

  testWidgets(
    'elige una franja y el resumen muestra el horario y el total; continuar lleva a reservar @CU-12-H01-03',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (sede, _, _) = await sedeConDosCanchas();
      await abrirHorarios(tester, sede);
      await verDia(tester, manana);

      await tocarEtiqueta(tester, franja(18));

      // Verifica: la franja queda elegida y el resumen dice horario, fecha y total.
      expect(elegida(tester, franja(18)), isTrue);
      expect(find.text(franja(18)), findsNWidgets(2));
      expect(find.textContaining('43.000 × 1'), findsOneWidget);
      expect(find.textContaining(_mes(manana)), findsOneWidget);

      await tocar(tester, 'CONTINUAR');

      // Verifica: la confirmación recibe la sede, la cancha, la fecha y el horario.
      await esperarA(tester, find.text('Confirmá tu reserva'));
      expect(find.text(sede.toUpperCase()), findsOneWidget);
      expect(find.text('Cancha 1 · Techada'), findsOneWidget);
      expect(find.text('${franja(18)} · 1 hora'), findsOneWidget);
      expect(find.textContaining('43.000'), findsOneWidget);
      semantica.dispose();
    },
  );

  testWidgets(
    'el botón para continuar está deshabilitado mientras no eligió franja @CU-12-H01-04',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (sede, _, _) = await sedeConDosCanchas();
      await abrirHorarios(tester, sede);

      await verDia(tester, manana);

      // Verifica: sin franja no hay horario en el resumen y no se puede seguir.
      expect(find.text('Sin horario elegido'), findsOneWidget);
      expect(habilitada(tester, 'CONTINUAR'), isFalse);
      await tester.tap(find.text('CONTINUAR'));
      await tester.pumpAndSettle();
      expect(find.text('Confirmá tu reserva'), findsNothing);
      semantica.dispose();
    },
  );

  testWidgets(
    'la nota de la grilla dice cuántos horarios no están disponibles @CU-12-H01-05',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (sede, cancha1, _) = await sedeConDosCanchas();
      await ocupar(cancha1, manana, 9);
      await ocupar(cancha1, manana, 12);
      await abrirHorarios(tester, sede);

      await verDia(tester, manana);

      // Verifica: dos ocupadas, dos no disponibles.
      await esperarA(
        tester,
        find.text('Algunos horarios ya están ocupados · 2 no disponibles'),
      );
      semantica.dispose();
    },
  );

  testWidgets(
    'cambia la fecha y la grilla se recalcula para ese día @CU-12-H02-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (sede, cancha1, _) = await sedeConDosCanchas();
      await ocupar(cancha1, manana, 10);
      await abrirHorarios(tester, sede);
      await verDia(tester, manana);
      expect(habilitada(tester, franja(10)), isFalse);

      await verDia(tester, pasado);

      // Verifica: el otro día la de las 10 está libre.
      expect(elegida(tester, chip(pasado)), isTrue);
      expect(habilitada(tester, franja(10)), isTrue);
      semantica.dispose();
    },
  );

  testWidgets(
    'cambia de cancha y la grilla se recalcula para esa cancha @CU-12-H03-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (sede, _, cancha2) = await sedeConDosCanchas();
      await ocupar(cancha2, manana, 10);
      await abrirHorarios(tester, sede);
      await verDia(tester, manana);
      expect(habilitada(tester, franja(10)), isTrue);

      await tocarEtiqueta(tester, 'Cancha 2, Techada');

      // Verifica: en la Cancha 2 la de las 10 está ocupada.
      await esperarA(tester, find.text('HORARIO DISPONIBLE'));
      expect(elegida(tester, 'Cancha 2, Techada'), isTrue);
      expect(habilitada(tester, franja(10)), isFalse);
      semantica.dispose();
    },
  );

  testWidgets(
    'con 2 horas sólo se ofrecen inicios con las dos horas libres y fin antes del cierre @CU-12-H04-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (sede, cancha1, _) = await sedeConDosCanchas();
      await ocupar(cancha1, manana, 11);
      await abrirHorarios(tester, sede);
      await verDia(tester, manana);

      await tocarEtiqueta(tester, 'Una hora más');

      // Verifica: las que pisan las 11 no se pueden elegir, las demás sí.
      await esperarA(tester, find.text('2 horas'));
      expect(habilitada(tester, franja(9, 2)), isTrue);
      expect(habilitada(tester, franja(10, 2)), isFalse);
      expect(habilitada(tester, franja(11, 2)), isFalse);
      expect(habilitada(tester, franja(12, 2)), isTrue);

      // Verifica: la última termina al cierre.
      expect(habilitada(tester, franja(21, 2)), isTrue);
      expect(find.bySemanticsLabel(franja(22, 2)), findsNothing);
      expect(
        find.text('Con 2 horas hay menos inicios posibles · 2 no disponibles'),
        findsOneWidget,
      );
      semantica.dispose();
    },
  );

  testWidgets(
    'con más horas vale la misma regla y el total es precio por hora por duración @CU-12-H04-02',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (sede, cancha1, _) = await sedeConDosCanchas();
      await ocupar(cancha1, manana, 15);
      await abrirHorarios(tester, sede);
      await verDia(tester, manana);
      await tocarEtiqueta(tester, 'Una hora más');
      await tocarEtiqueta(tester, 'Una hora más');
      await esperarA(tester, find.text('3 horas'));

      await tocarEtiqueta(tester, franja(18, 3));

      // Verifica: con 3 horas la que pisa las 15 no se ofrece, y el total es por tres.
      expect(habilitada(tester, franja(13, 3)), isFalse);
      expect(habilitada(tester, franja(20, 3)), isTrue);
      expect(find.bySemanticsLabel(franja(21, 3)), findsNothing);
      expect(find.textContaining('43.000 × 3'), findsOneWidget);
      expect(find.textContaining('129.000'), findsOneWidget);
      semantica.dispose();
    },
  );

  testWidgets(
    'la duración va de 1 a 4 horas: en 1 hora no se puede bajar y en 4 no se puede subir @CU-12-H04-03',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (sede, _, _) = await sedeConDosCanchas();
      await abrirHorarios(tester, sede);
      await verDia(tester, manana);

      // Verifica: arranca en 1 hora sin poder bajar, con la regla a la vista.
      expect(habilitada(tester, 'Una hora menos'), isFalse);
      expect(
        find.text('Horas completas, de 1 a 4 h. La sede cierra a las 23:00.'),
        findsOneWidget,
      );

      for (var i = 0; i < 3; i++) {
        await tocarEtiqueta(tester, 'Una hora más');
      }

      // Verifica: en 4 horas no sube más.
      await esperarA(tester, find.text('4 horas'));
      expect(habilitada(tester, 'Una hora más'), isFalse);
      expect(habilitada(tester, 'Una hora menos'), isTrue);
      semantica.dispose();
    },
  );

  testWidgets(
    'no queda ninguna franja libre y ve el estado vacío con la sugerencia @CU-12-H05-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (sede, cancha1, _) = await sedeConDosCanchas();
      await ocupar(cancha1, manana, 8, horas: 4);
      await ocupar(cancha1, manana, 12, horas: 4);
      await ocupar(cancha1, manana, 16, horas: 4);
      await ocupar(cancha1, manana, 20, horas: 3);
      await abrirHorarios(tester, sede);

      await verDia(tester, manana);

      // Verifica: el estado vacío reemplaza la grilla y sugiere otra fecha.
      await esperarA(tester, find.text('No hay horarios disponibles'));
      expect(
        find.text(
          'Ya no quedan turnos libres ese día. Probá con otra fecha u otra cancha.',
        ),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(franja(8)), findsNothing);
      expect(habilitada(tester, 'CONTINUAR'), isFalse);
      semantica.dispose();
    },
  );

  testWidgets(
    'elige un día en que la sede no abre y ve el estado vacío @CU-12-H05-02',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (sede, _, _) = await sedeConDosCanchas(
        dias: [
          for (var d = 1; d <= 7; d++)
            if (d != manana.weekday) d,
        ],
      );
      await abrirHorarios(tester, sede);

      await verDia(tester, manana);

      // Verifica: la sede no abre ese día y no hay franjas.
      await esperarA(tester, find.text('No hay horarios disponibles'));
      expect(
        find.text('La sede no abre ese día. Probá con otra fecha.'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(franja(10)), findsNothing);
      semantica.dispose();
    },
  );

  testWidgets('sin conexión, ve la alerta y ningún horario @CU-12-H06-01', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    final (sede, _, _) = await sedeConDosCanchas();
    final api = await ApiIntermedia.abrir();

    await abrirHorarios(
      tester,
      sede,
      apiUrl: api.url,
      antesDeEntrar: () => api.estado = EstadoApi.sinRed,
    );

    // Verifica: la alerta de conexión y, al cerrarla, ningún horario.
    await esperarA(tester, find.text('Error de conexión'));
    await tocar(tester, 'Volver');
    expect(find.text('HORARIO DISPONIBLE'), findsNothing);
    expect(find.bySemanticsLabel(RegExp(r'^\d\d:00 – ')), findsNothing);
    expect(find.text('REINTENTAR'), findsOneWidget);
    semantica.dispose();
  });

  testWidgets('el servidor falla y no se muestran horarios @CU-12-H07-01', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    final (sede, _, _) = await sedeConDosCanchas();
    final api = await ApiIntermedia.abrir();

    await abrirHorarios(
      tester,
      sede,
      apiUrl: api.url,
      antesDeEntrar: () => api.estado = EstadoApi.falla,
    );

    // Verifica: el error del servidor y, al cerrarlo, ningún horario.
    await esperarA(tester, find.text('Error del servidor'));
    await tocar(tester, 'ACEPTAR');
    expect(find.text('HORARIO DISPONIBLE'), findsNothing);
    expect(find.bySemanticsLabel(RegExp(r'^\d\d:00 – ')), findsNothing);
    expect(find.text('REINTENTAR'), findsOneWidget);
    semantica.dispose();
  });
}

const _meses = [
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

String _mes(DateTime dia) => '${dia.day} de ${_meses[dia.month - 1]}';
