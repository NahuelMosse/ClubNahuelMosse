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

  String chip(DateTime dia) => '${dias[dia.weekday - 1]} ${dia.day}';

  String franja(int hora, [int horas = 1]) {
    String dos(int h) => '${(h % 24).toString().padLeft(2, '0')}:00';
    return '${dos(hora)} – ${dos(hora + horas)}';
  }

  /// Una sede de 08:00 a 23:00 con un Fútbol 5 techado de $ 43.000 la hora.
  Future<(String, String)> sedeConCancha() async {
    final sede = 'Sede Haedo ${unique()}';
    await createVenue(sede, 'Av. Vergara 1850');
    return (sede, await createSpace(sede));
  }

  Future<String> cuenta() async {
    final correo = 'socio.${unique()}@correo.com';
    await createAccount(correo: correo, contrasena: 'ClubNahuel1');
    return correo;
  }

  Future<void> entrar(
    WidgetTester tester,
    String correo, {
    String contrasena = 'ClubNahuel1',
    String? apiUrl,
  }) async {
    await openApp(tester, apiUrl: apiUrl);
    await typeInto(tester, 'Correo', correo);
    await typeInto(tester, 'Contraseña', contrasena);
    await tapText(tester, 'INICIAR SESIÓN');
    await waitUntil(tester, find.text('RESERVÁ TU CANCHA'));
  }

  Future<void> tocarEtiqueta(WidgetTester tester, String etiqueta) async {
    final control = find.bySemanticsLabel(etiqueta);
    await waitUntil(tester, control);
    await tester.ensureVisible(control);
    await tester.pumpAndSettle();
    await tester.tap(control);
    await tester.pumpAndSettle();
  }

  SemanticsFlags banderas(WidgetTester tester, String etiqueta) =>
      tester.getSemantics(find.bySemanticsLabel(etiqueta)).flagsCollection;

  /// De la sede a los horarios de su cancha, mañana, con [horas] horas.
  Future<void> abrirHorarios(
    WidgetTester tester,
    String sede, {
    int horas = 1,
  }) async {
    await tapText(tester, 'SEDES');
    final tarjeta = find.bySemanticsLabel(RegExp('^${RegExp.escape(sede)},'));
    await waitUntil(tester, tarjeta);
    await tester.ensureVisible(tarjeta);
    await tester.pumpAndSettle();
    await tester.tap(tarjeta);
    await tester.pumpAndSettle();
    await tapText(tester, 'VER HORARIOS / RESERVAR');
    await waitUntil(tester, find.text('HORARIO DISPONIBLE'));
    await tocarEtiqueta(tester, chip(manana));
    for (var i = 1; i < horas; i++) {
      await tocarEtiqueta(tester, 'Una hora más');
    }
  }

  /// Elige la franja que empieza a la [hora] y llega a «Confirmá tu reserva».
  Future<void> irAConfirmar(
    WidgetTester tester,
    String sede, {
    int hora = 18,
    int horas = 1,
  }) async {
    await abrirHorarios(tester, sede, horas: horas);
    await tocarEtiqueta(tester, franja(hora, horas));
    await tapText(tester, 'CONTINUAR');
    await waitUntil(tester, find.text('Confirmá tu reserva'));
  }

  testWidgets(
    'confirma la reserva y aparece activa en Mis reservas con sede, espacio, fecha, horario y total @CU-09-H01-01',
    (tester) async {
      final (sede, cancha) = await sedeConCancha();
      final correo = await cuenta();
      await entrar(tester, correo);
      await irAConfirmar(tester, sede);

      await tapText(tester, 'CONFIRMAR RESERVA');

      // Verifica: el comprobante con el espacio y el horario.
      await waitUntil(tester, find.text('¡Reserva confirmada!'));
      expect(find.text(cancha), findsOneWidget);
      expect(find.textContaining(franja(18)), findsOneWidget);

      await tapText(tester, 'VER MIS RESERVAS');

      // Verifica: en Mis reservas, activa y con todos sus datos.
      await waitUntil(tester, find.text(cancha));
      expect(find.text('$sede · Av. Vergara 1850'), findsOneWidget);
      expect(find.text(franja(18)), findsOneWidget);
      expect(find.textContaining('43.000'), findsOneWidget);
      expect(find.text('ACTIVA'), findsOneWidget);
    },
  );

  testWidgets(
    'después de reservar, ese horario aparece no disponible para otro usuario @CU-09-H01-02',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (sede, _) = await sedeConCancha();
      await entrar(tester, await cuenta());
      await irAConfirmar(tester, sede, hora: 11);
      await tapText(tester, 'CONFIRMAR RESERVA');
      await waitUntil(tester, find.text('¡Reserva confirmada!'));

      // Otra persona entra a los horarios de la misma cancha.
      await entrar(tester, await cuenta());
      await abrirHorarios(tester, sede);

      // Verifica: las 11 ya no se pueden elegir.
      expect(banderas(tester, franja(11)).isEnabled, isFalse);
      expect(banderas(tester, franja(12)).isEnabled, isTrue);
      semantica.dispose();
    },
  );

  testWidgets(
    'reserva varias horas seguidas y el total es el precio por hora por la duración @CU-09-H01-03',
    (tester) async {
      final (sede, _) = await sedeConCancha();
      final correo = await cuenta();
      await entrar(tester, correo);
      await irAConfirmar(tester, sede, hora: 15, horas: 3);
      expect(find.text('${franja(15, 3)} · 3 horas'), findsOneWidget);

      await tapText(tester, 'CONFIRMAR RESERVA');

      // Verifica: tres horas a $ 43.000.
      await waitUntil(tester, find.text('¡Reserva confirmada!'));
      expect(find.textContaining('129.000'), findsOneWidget);
      expect(await bookingsOf(correo), hasLength(1));
    },
  );

  testWidgets(
    'toca Cancelar en la confirmación y no se crea ninguna reserva @CU-09-H01-07',
    (tester) async {
      final (sede, _) = await sedeConCancha();
      final correo = await cuenta();
      await entrar(tester, correo);
      await irAConfirmar(tester, sede);

      await tapText(tester, 'CANCELAR');

      // Verifica: vuelve a los horarios y no hay reserva.
      await waitUntil(tester, find.text('HORARIO DISPONIBLE'));
      expect(await bookingsOf(correo), isEmpty);
    },
  );

  testWidgets(
    'desde el comprobante va a Mis reservas o vuelve al inicio @CU-09-H01-09',
    (tester) async {
      final (sede, _) = await sedeConCancha();
      await entrar(tester, await cuenta());
      await irAConfirmar(tester, sede);
      await tapText(tester, 'CONFIRMAR RESERVA');
      await waitUntil(tester, find.text('¡Reserva confirmada!'));

      // Verifica: las dos salidas están.
      expect(find.text('VER MIS RESERVAS'), findsOneWidget);
      await tapText(tester, 'Volver al inicio');
      await waitUntil(tester, find.text('RESERVÁ TU CANCHA'));
    },
  );

  testWidgets(
    'otra persona reservó ese horario mientras confirmaba: ve el aviso y no se crea la reserva @CU-09-H02-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (sede, cancha) = await sedeConCancha();
      final correo = await cuenta();
      await entrar(tester, correo);
      await irAConfirmar(tester, sede, hora: 20);

      // Mientras confirma, otra persona toma ese horario.
      await occupy(cancha, manana, 20);
      await tapText(tester, 'CONFIRMAR RESERVA');

      // Verifica: el aviso, y al volver a la grilla el horario está ocupado.
      await waitUntil(tester, find.text('Ese horario se ocupó'));
      await tapText(tester, 'ELEGIR OTRO HORARIO');
      await waitUntil(tester, find.text('HORARIO DISPONIBLE'));
      expect(banderas(tester, franja(20)).isEnabled, isFalse);
      expect(await bookingsOf(correo), isEmpty);
      semantica.dispose();
    },
  );

  testWidgets(
    'sin horario elegido, el botón de confirmar está deshabilitado @CU-09-H03-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final (sede, _) = await sedeConCancha();
      await entrar(tester, await cuenta());

      await abrirHorarios(tester, sede);

      // Verifica: no se puede seguir hasta elegir, y el resumen dice qué falta.
      expect(find.text('Sin horario elegido'), findsOneWidget);
      expect(banderas(tester, 'CONTINUAR').isEnabled, isFalse);
      semantica.dispose();
    },
  );

  testWidgets(
    'con la sesión vencida va al login y, al volver a entrar, retoma la reserva que tenía en curso @CU-09-H04-01',
    (tester) async {
      final (sede, cancha) = await sedeConCancha();
      final correo = await cuenta();
      await entrar(tester, correo);
      await irAConfirmar(tester, sede, hora: 16);

      // La contraseña cambia desde otro teléfono y la sesión vence.
      await changeFromAnotherDevice(correo, 'ClubNahuel1', 'ClubNahuel2');
      await tapText(tester, 'CONFIRMAR RESERVA');

      // Verifica: avisa y lleva al inicio de sesión.
      await waitUntil(tester, find.text('Tu sesión expiró'));
      await tapText(tester, 'IR AL INICIO DE SESIÓN');
      await waitUntil(tester, find.text('INICIAR SESIÓN'));
      await typeInto(tester, 'Correo', correo);
      await typeInto(tester, 'Contraseña', 'ClubNahuel2');
      await tapText(tester, 'INICIAR SESIÓN');

      // Verifica: vuelve a la confirmación con la misma cancha y el mismo horario.
      await waitUntil(tester, find.text('Confirmá tu reserva'));
      expect(find.text('${franja(16)} · 1 hora'), findsOneWidget);
      await tapText(tester, 'CONFIRMAR RESERVA');
      await waitUntil(tester, find.text('¡Reserva confirmada!'));
      expect(await bookingsOf(correo, contrasena: 'ClubNahuel2'), [
        (cancha, '16:00'),
      ]);
    },
  );

  testWidgets(
    'sin conexión al confirmar, ve el error y la reserva no se crea @CU-09-H05-01',
    (tester) async {
      final (sede, _) = await sedeConCancha();
      final correo = await cuenta();
      final api = await ApiIntermedia.abrir();
      await entrar(tester, correo, apiUrl: api.url);
      await irAConfirmar(tester, sede);

      api.estado = ApiState.offline;
      await tapText(tester, 'CONFIRMAR RESERVA');

      // Verifica: el aviso de conexión, sigue en la confirmación y no hay reserva.
      await waitUntil(tester, find.text('Error de conexión'));
      await tapText(tester, 'Volver');
      expect(find.text('Confirmá tu reserva'), findsOneWidget);
      expect(await bookingsOf(correo), isEmpty);
    },
  );

  testWidgets(
    'el servidor falla al confirmar y la reserva no se crea @CU-09-H05-02',
    (tester) async {
      final (sede, _) = await sedeConCancha();
      final correo = await cuenta();
      final api = await ApiIntermedia.abrir();
      await entrar(tester, correo, apiUrl: api.url);
      await irAConfirmar(tester, sede);

      api.estado = ApiState.failing;
      await tapText(tester, 'CONFIRMAR RESERVA');

      // Verifica: el error del servidor, sigue en la confirmación y no hay reserva.
      await waitUntil(tester, find.text('Error del servidor'));
      await tapText(tester, 'ACEPTAR');
      expect(find.text('Confirmá tu reserva'), findsOneWidget);
      expect(await bookingsOf(correo), isEmpty);
    },
  );
}
