import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

import '../support/actions.dart';
import '../support/network.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final hoy = todayAtClub();
  final ayer = hoy.subtract(const Duration(days: 1));
  final manana = hoy.add(const Duration(days: 1));

  String fechaTexto(DateTime d) {
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(d.day)}${dos(d.month)}${d.year}';
  }

  // Primero, porque necesita que todavía no exista ninguna reserva en la base de la corrida.
  testWidgets(
    'sin ninguna reserva en el sistema ve «No hay reservas», sin «Limpiar filtros» @CU-14-H07-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      await clearBookings();
      await signInAsAdmin(tester);
      await waitUntil(tester, find.text('No hay reservas'));
      expect(
        find.text('Todavía no se registró ninguna reserva en el sistema.'),
        findsOneWidget,
      );
      expect(find.text('LIMPIAR FILTROS'), findsNothing);
      semantica.dispose();
    },
  );

  testWidgets(
    've las reservas de todos los usuarios con usuario, sede, espacio, horario, precio y estado, y el total @CU-14-H01-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final nombreSede = 'Sede Haedo ${unique()}';
      await createVenue(nombreSede, 'Av. Vergara 1850');
      final cancha = await createSpace(nombreSede);
      final correo = 'socio.${unique()}@correo.com';
      await createAccount(
        correo: correo,
        contrasena: 'ClubNahuel1',
        nombre: 'Nahuel',
      );
      await occupy(cancha, manana, 21, correo: correo);
      await signInAsAdmin(tester);
      await typeInto(tester, 'Buscar reserva', nombreSede);
      await waitUntil(tester, find.text(cancha));

      // Verifica: los datos de la reserva y el total ya filtrado por la búsqueda.
      expect(find.textContaining('1 RESULTADO'), findsOneWidget);
      expect(find.text('Nahuel Mosse'), findsOneWidget);
      expect(find.text('ACTIVA'), findsOneWidget);
      semantica.dispose();
    },
  );

  testWidgets(
    'una reserva recién hecha por un usuario aparece en el panel @CU-14-H01-02',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final nombreSede = 'Sede Ramos Mejia ${unique()}';
      await createVenue(nombreSede, 'Calle Belgrano 1240');
      final cancha = await createSpace(nombreSede);
      await signInAsAdmin(tester);
      await typeInto(tester, 'Buscar reserva', nombreSede);
      await waitUntil(tester, find.text('Sin resultados'));

      await occupy(cancha, manana, 20);
      await tapText(tester, 'Filtros');
      await waitUntil(tester, find.text('APLICAR'));
      await tapText(tester, 'APLICAR');

      await waitUntil(tester, find.text(cancha));
      semantica.dispose();
    },
  );

  testWidgets(
    'las pestañas de estado filtran el listado y actualizan el contador @CU-14-H01-03',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final nombreSede = 'Sede Castelar ${unique()}';
      await createVenue(nombreSede, 'Av. Rivadavia 23500');
      final activo = await createSpace(nombreSede);
      final completo = await createSpace(nombreSede);
      final anulado = await createSpace(nombreSede);
      await occupy(activo, manana, 9);
      await occupy(completo, ayer, 9);
      await occupy(
        anulado,
        manana,
        15,
        estado: 'voided',
        motivo: 'mantenimiento',
      );
      await signInAsAdmin(tester);
      await typeInto(tester, 'Buscar reserva', nombreSede);
      await waitUntil(tester, find.textContaining('3 RESULTADOS'));

      await waitUntil(tester, find.text('Activas (1)'));
      await tapText(tester, 'Activas (1)');
      await waitUntil(tester, find.text(activo));
      expect(find.text(completo), findsNothing);
      expect(find.text(anulado), findsNothing);

      await tapText(tester, 'Anuladas (1)');
      await waitUntil(tester, find.text(anulado));
      expect(find.text(activo), findsNothing);
      semantica.dispose();
    },
  );

  testWidgets(
    'aplica filtros de sede, deporte y fechas y ve sólo las reservas que cumplen todos @CU-14-H01-04',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final nombreSede = 'Sede San Justo ${unique()}';
      await createVenue(nombreSede, 'Av. Rivadavia 5000');
      final futbol = await createSpace(nombreSede);
      final tenis = await createSpace(
        nombreSede,
        deporte: 'Tenis',
        tipo: 'PDL',
      );
      final futbolViejo = await createSpace(nombreSede);
      await occupy(futbol, manana, 10);
      await occupy(tenis, manana, 10);
      await occupy(futbolViejo, hoy.subtract(const Duration(days: 10)), 10);
      await signInAsAdmin(tester);
      await typeInto(tester, 'Buscar reserva', nombreSede);
      await waitUntil(tester, find.textContaining('3 RESULTADOS'));

      await tapText(tester, 'Filtros');
      await waitUntil(tester, find.text('APLICAR'));
      await tapText(tester, nombreSede);
      await tapText(tester, 'Fútbol');
      await typeInto(tester, 'Desde', fechaTexto(hoy));
      await typeInto(tester, 'Hasta', fechaTexto(manana));
      await tapText(tester, 'APLICAR');

      await waitUntil(tester, find.textContaining('1 RESULTADO'));
      expect(find.text(futbol), findsOneWidget);
      expect(find.text(tenis), findsNothing);
      expect(find.text(futbolViejo), findsNothing);
      semantica.dispose();
    },
  );

  testWidgets(
    'busca por nombre de usuario y la búsqueda se combina con los filtros @CU-14-H01-05',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final nombreSede = 'Sede Moron ${unique()}';
      await createVenue(nombreSede, 'Av. Rivadavia 19850');
      final canchaUno = await createSpace(nombreSede);
      final canchaDos = await createSpace(nombreSede);
      final correoUno = 'valentina.${unique()}@correo.com';
      final correoDos = 'bruno.${unique()}@correo.com';
      await createAccount(
        correo: correoUno,
        contrasena: 'ClubNahuel1',
        nombre: 'Valentina',
      );
      await createAccount(
        correo: correoDos,
        contrasena: 'ClubNahuel1',
        nombre: 'Bruno',
      );
      await occupy(canchaUno, manana, 9, correo: correoUno);
      await occupy(canchaDos, manana, 9, correo: correoDos);
      await signInAsAdmin(tester);

      await tapText(tester, 'Filtros');
      await waitUntil(tester, find.text('APLICAR'));
      await tapText(tester, nombreSede);
      await tapText(tester, 'APLICAR');
      await waitUntil(tester, find.textContaining('2 RESULTADOS'));

      await typeInto(tester, 'Buscar reserva', 'Valentina');
      await waitUntil(tester, find.textContaining('1 RESULTADO'));
      expect(find.text('Valentina Mosse'), findsOneWidget);
      expect(find.text('Bruno Mosse'), findsNothing);
      semantica.dispose();
    },
  );

  testWidgets(
    'abre el detalle y ve cuándo y quién creó la reserva @CU-14-H01-06',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final nombreSede = 'Sede Haedo ${unique()}';
      await createVenue(nombreSede, 'Av. Vergara 1850');
      final cancha = await createSpace(nombreSede);
      final correo = 'camila.${unique()}@correo.com';
      await createAccount(
        correo: correo,
        contrasena: 'ClubNahuel1',
        nombre: 'Camila',
      );
      await occupy(cancha, manana, 11, correo: correo);
      await signInAsAdmin(tester);
      await typeInto(tester, 'Buscar reserva', nombreSede);
      await waitUntil(tester, find.text(cancha));

      await tapText(tester, cancha);

      await waitUntil(tester, find.text('Detalle de reserva'));
      expect(find.text('Reserva creada'), findsOneWidget);
      expect(find.textContaining('Por Camila Mosse'), findsOneWidget);
      semantica.dispose();
    },
  );

  testWidgets(
    'vuelve del detalle al listado con los mismos filtros @CU-14-H01-08',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final nombreSede = 'Sede Ramos Mejia ${unique()}';
      await createVenue(nombreSede, 'Calle Belgrano 1240');
      final cancha = await createSpace(nombreSede);
      await occupy(cancha, manana, 12);
      await signInAsAdmin(tester);
      await typeInto(tester, 'Buscar reserva', nombreSede);
      await waitUntil(tester, find.text(cancha));

      await tapText(tester, cancha);
      await waitUntil(tester, find.text('Detalle de reserva'));
      await tapText(tester, 'VOLVER AL LISTADO');

      // Verifica: sigue con la búsqueda aplicada, sin volver a pedirla a mano.
      await waitUntil(tester, find.text(cancha));
      expect(find.bySemanticsLabel('Buscar reserva'), findsOneWidget);
      semantica.dispose();
    },
  );

  testWidgets(
    'mientras carga el historial ve «Cargando reservas…» y no una pantalla en blanco @CU-14-H01-09',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final api = await ApiIntermedia.abrir();
      api.estado = ApiState.slow;
      await signInAsAdmin(tester, apiUrl: api.url);

      // Verifica: mientras el pedido lento no volvió, se ve el aviso y no una pantalla vacía.
      expect(find.text('Cargando reservas…'), findsOneWidget);
      expect(find.text('PANEL ADMIN'), findsOneWidget);
      semantica.dispose();
    },
  );

  testWidgets(
    'los filtros no encuentran nada y ve «Sin resultados» con «Limpiar filtros» @CU-14-H02-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final nombreSede = 'Sede San Justo ${unique()}';
      await createVenue(nombreSede, 'Av. Rivadavia 5000');
      final cancha = await createSpace(nombreSede);
      await occupy(cancha, manana, 13);
      await signInAsAdmin(tester);

      await typeInto(tester, 'Buscar reserva', '$nombreSede-sin-coincidencia');
      await waitUntil(tester, find.text('Sin resultados'));
      expect(
        find.text('Ninguna reserva coincide con los filtros aplicados.'),
        findsOneWidget,
      );

      await tapText(tester, 'LIMPIAR FILTROS');
      // La lista perezosa deja la reserva fuera de pantalla entre las demás de la corrida.
      await waitUntil(tester, find.textContaining('RESERVAS EN TOTAL'));
      await tester.scrollUntilVisible(
        find.text(cancha),
        400,
        maxScrolls: 300,
        scrollable: find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      semantica.dispose();
    },
  );

  testWidgets(
    'falla el servidor y ve el error con «Reintentar», sin datos parciales @CU-14-H03-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final api = await ApiIntermedia.abrir();
      await signInAsAdmin(tester, apiUrl: api.url);
      await waitUntil(tester, find.textContaining('RESERVA'));

      api.estado = ApiState.failing;
      await tapText(tester, 'Filtros');
      await waitUntil(tester, find.text('APLICAR'));
      await tapText(tester, 'APLICAR');

      await waitUntil(tester, find.text('Error del servidor'));
      expect(find.textContaining('RESERVAS EN TOTAL'), findsNothing);
      expect(find.textContaining('RESULTADO'), findsNothing);

      api.estado = ApiState.normal;
      await tapText(tester, 'REINTENTAR');
      await waitUntil(tester, find.textContaining('RESERVA'));
      semantica.dispose();
    },
  );

  testWidgets(
    'pone «desde» después de «hasta» y no puede aplicar @CU-14-H04-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      await signInAsAdmin(tester);
      await tapText(tester, 'Filtros');
      await waitUntil(tester, find.text('APLICAR'));
      // Con las sedes de la corrida el rango de fechas queda debajo de lo que arma el listado.
      await tester.scrollUntilVisible(
        find.text('RANGO DE FECHAS'),
        300,
        maxScrolls: 100,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );

      await typeInto(
        tester,
        'Desde',
        fechaTexto(manana.add(const Duration(days: 10))),
      );
      await typeInto(tester, 'Hasta', fechaTexto(manana));

      expect(find.text('Desde no puede ser posterior a Hasta'), findsOneWidget);
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('APLICAR'))
            .flagsCollection
            .isEnabled,
        isFalse,
      );
      semantica.dispose();
    },
  );

  testWidgets(
    'un usuario sin rol de administrador no ve el panel y, si entra por enlace, ve «Acceso denegado» @CU-14-H05-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final correo = 'socio.${unique()}@correo.com';
      await signInAsUser(tester, correo: correo);
      expect(find.text('PANEL ADMIN'), findsNothing);

      final contexto = tester.element(find.byType(Scaffold).first);
      GoRouter.of(contexto).go('/admin');
      await tester.pumpAndSettle();

      await waitUntil(tester, find.text('Acceso denegado'));
      await tapText(tester, 'IR A MIS RESERVAS');
      await waitUntil(tester, find.text('Mis reservas'));
      semantica.dispose();
    },
  );

  testWidgets(
    'con la sesión vencida va al login y vuelve al historial con sus filtros @CU-14-H06-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final nombreSede = 'Sede Haedo ${unique()}';
      await createVenue(nombreSede, 'Av. Vergara 1850');
      final api = await ApiIntermedia.abrir();
      await signInAsAdmin(tester, apiUrl: api.url);
      await typeInto(tester, 'Buscar reserva', nombreSede);
      await waitUntil(tester, find.text('Sin resultados'));

      api.estado = ApiState.sessionExpired;
      await tapText(tester, 'Filtros');
      await waitUntil(tester, find.text('APLICAR'));
      await tapText(tester, 'APLICAR');

      await waitUntil(tester, find.text('Tu sesión expiró'));
      await tapText(tester, 'IR AL INICIO DE SESIÓN');
      await waitUntil(tester, find.text('INICIAR SESIÓN'));

      api.estado = ApiState.normal;
      await typeInto(tester, 'Correo', adminEmail);
      await typeInto(tester, 'Contraseña', adminPassword);
      await tapText(tester, 'INICIAR SESIÓN');

      // Verifica: vuelve al historial con la búsqueda que tenía.
      await waitUntil(tester, find.text('PANEL ADMIN'));
      expect(find.bySemanticsLabel('Buscar reserva'), findsOneWidget);
      await waitUntil(tester, find.text('Sin resultados'));
      semantica.dispose();
    },
  );

  testWidgets(
    'las reservas de un espacio dado de baja siguen en el historial marcadas «Baja del espacio deportivo» @CU-14-H09-01',
    (tester) async {
      final semantica = tester.ensureSemantics();
      final nombreSede = 'Sede Castelar ${unique()}';
      await createVenue(nombreSede, 'Av. Rivadavia 23500');
      final cancha = await createSpace(nombreSede);
      // Sin reservas futuras: la baja del espacio no está bloqueada (decisión 5, CU-14-AMB-07).
      await occupy(cancha, ayer, 9);
      await deactivateSpaceFromAnotherSession(cancha);
      await signInAsAdmin(tester);
      await typeInto(tester, 'Buscar reserva', nombreSede);

      await waitUntil(tester, find.text('Baja del espacio deportivo'));
      await tapText(tester, cancha);
      await waitUntil(tester, find.text('Detalle de reserva'));
      expect(find.text('Baja del espacio deportivo'), findsOneWidget);
      semantica.dispose();
    },
  );
}
