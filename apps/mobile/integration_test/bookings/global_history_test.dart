import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

import '../support/actions.dart';
import '../support/network.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final today = todayAtClub();
  final yesterday = today.subtract(const Duration(days: 1));
  final tomorrow = today.add(const Duration(days: 1));

  String dateText(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}${two(d.month)}${d.year}';
  }

  // First, because it needs no booking to exist yet in the run's database.
  testWidgets(
    'with no booking in the system sees «No hay reservas», without «Limpiar filtros» @CU-14-H07-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await clearBookings();
      await signInAsAdmin(tester);
      await waitUntil(tester, find.text('No hay reservas'));
      expect(
        find.text('Todavía no se registró ninguna reserva en el sistema.'),
        findsOneWidget,
      );
      expect(find.text('LIMPIAR FILTROS'), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets(
    'sees the bookings of all users with user, venue, space, time, price and status, and the total @CU-14-H01-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final venueName = 'Sede Haedo ${unique()}';
      await createVenue(venueName, 'Av. Vergara 1850');
      final court = await createSpace(venueName);
      final email = 'socio.${unique()}@correo.com';
      await createAccount(
        email: email,
        password: 'ClubNahuel1',
        name: 'Nahuel',
      );
      await occupy(court, tomorrow, 21, email: email);
      await signInAsAdmin(tester);
      await typeInto(tester, 'Buscar reserva', venueName);
      await waitUntil(tester, find.text(court));

      // Verifies: the booking data and the total already filtered by the search.
      expect(find.textContaining('1 RESULTADO'), findsOneWidget);
      expect(find.text('Nahuel Mosse'), findsOneWidget);
      expect(find.text('ACTIVA'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets(
    'a booking just made by a user shows up in the panel @CU-14-H01-02',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final venueName = 'Sede Ramos Mejia ${unique()}';
      await createVenue(venueName, 'Calle Belgrano 1240');
      final court = await createSpace(venueName);
      await signInAsAdmin(tester);
      await typeInto(tester, 'Buscar reserva', venueName);
      await waitUntil(tester, find.text('Sin resultados'));

      await occupy(court, tomorrow, 20);
      await tapText(tester, 'Filtros');
      await waitUntil(tester, find.text('APLICAR'));
      await tapText(tester, 'APLICAR');

      await waitUntil(tester, find.text(court));
      semantics.dispose();
    },
  );

  testWidgets(
    'the status tabs filter the listing and update the counter @CU-14-H01-03',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final venueName = 'Sede Castelar ${unique()}';
      await createVenue(venueName, 'Av. Rivadavia 23500');
      final active = await createSpace(venueName);
      final completed = await createSpace(venueName);
      final voided = await createSpace(venueName);
      await occupy(active, tomorrow, 9);
      await occupy(completed, yesterday, 9);
      await occupy(
        voided,
        tomorrow,
        15,
        status: 'voided',
        reason: 'mantenimiento',
      );
      await signInAsAdmin(tester);
      await typeInto(tester, 'Buscar reserva', venueName);
      await waitUntil(tester, find.textContaining('3 RESULTADOS'));

      await waitUntil(tester, find.text('Activas (1)'));
      await tapText(tester, 'Activas (1)');
      await waitUntil(tester, find.text(active));
      expect(find.text(completed), findsNothing);
      expect(find.text(voided), findsNothing);

      await tapText(tester, 'Anuladas (1)');
      await waitUntil(tester, find.text(voided));
      expect(find.text(active), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets(
    'applies venue, sport and date filters and sees only the bookings that meet all of them @CU-14-H01-04',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final venueName = 'Sede San Justo ${unique()}';
      await createVenue(venueName, 'Av. Rivadavia 5000');
      final football = await createSpace(venueName);
      final tennis = await createSpace(venueName, sport: 'Tenis', kind: 'PDL');
      final oldFootball = await createSpace(venueName);
      await occupy(football, tomorrow, 10);
      await occupy(tennis, tomorrow, 10);
      await occupy(oldFootball, today.subtract(const Duration(days: 10)), 10);
      await signInAsAdmin(tester);
      await typeInto(tester, 'Buscar reserva', venueName);
      await waitUntil(tester, find.textContaining('3 RESULTADOS'));

      await tapText(tester, 'Filtros');
      await waitUntil(tester, find.text('APLICAR'));
      await tapText(tester, venueName);
      await tapText(tester, 'Fútbol');
      await typeInto(tester, 'Desde', dateText(today));
      await typeInto(tester, 'Hasta', dateText(tomorrow));
      await tapText(tester, 'APLICAR');

      await waitUntil(tester, find.textContaining('1 RESULTADO'));
      expect(find.text(football), findsOneWidget);
      expect(find.text(tennis), findsNothing);
      expect(find.text(oldFootball), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets(
    'searches by user name and the search combines with the filters @CU-14-H01-05',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final venueName = 'Sede Moron ${unique()}';
      await createVenue(venueName, 'Av. Rivadavia 19850');
      final courtOne = await createSpace(venueName);
      final courtTwo = await createSpace(venueName);
      final emailOne = 'valentina.${unique()}@correo.com';
      final emailTwo = 'bruno.${unique()}@correo.com';
      await createAccount(
        email: emailOne,
        password: 'ClubNahuel1',
        name: 'Valentina',
      );
      await createAccount(
        email: emailTwo,
        password: 'ClubNahuel1',
        name: 'Bruno',
      );
      await occupy(courtOne, tomorrow, 9, email: emailOne);
      await occupy(courtTwo, tomorrow, 9, email: emailTwo);
      await signInAsAdmin(tester);

      await tapText(tester, 'Filtros');
      await waitUntil(tester, find.text('APLICAR'));
      await tapText(tester, venueName);
      await tapText(tester, 'APLICAR');
      await waitUntil(tester, find.textContaining('2 RESULTADOS'));

      await typeInto(tester, 'Buscar reserva', 'Valentina');
      await waitUntil(tester, find.textContaining('1 RESULTADO'));
      expect(find.text('Valentina Mosse'), findsOneWidget);
      expect(find.text('Bruno Mosse'), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets(
    'opens the detail and sees when and who created the booking @CU-14-H01-06',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final venueName = 'Sede Haedo ${unique()}';
      await createVenue(venueName, 'Av. Vergara 1850');
      final court = await createSpace(venueName);
      final email = 'camila.${unique()}@correo.com';
      await createAccount(
        email: email,
        password: 'ClubNahuel1',
        name: 'Camila',
      );
      await occupy(court, tomorrow, 11, email: email);
      await signInAsAdmin(tester);
      await typeInto(tester, 'Buscar reserva', venueName);
      await waitUntil(tester, find.text(court));

      await tapText(tester, court);

      await waitUntil(tester, find.text('Detalle de reserva'));
      expect(find.text('Reserva creada'), findsOneWidget);
      expect(find.textContaining('Por Camila Mosse'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets(
    'goes back from the detail to the listing with the same filters @CU-14-H01-08',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final venueName = 'Sede Ramos Mejia ${unique()}';
      await createVenue(venueName, 'Calle Belgrano 1240');
      final court = await createSpace(venueName);
      await occupy(court, tomorrow, 12);
      await signInAsAdmin(tester);
      await typeInto(tester, 'Buscar reserva', venueName);
      await waitUntil(tester, find.text(court));

      await tapText(tester, court);
      await waitUntil(tester, find.text('Detalle de reserva'));
      await tapText(tester, 'VOLVER AL LISTADO');

      // Verifies: the search is still applied, without asking for it again by hand.
      await waitUntil(tester, find.text(court));
      expect(find.bySemanticsLabel('Buscar reserva'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets(
    'while the history loads sees «Cargando reservas…» and not a blank screen @CU-14-H01-09',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final api = await ProxyApi.open();
      api.state = ApiState.slow;
      await signInAsAdmin(tester, apiUrl: api.url);

      // Verifies: while the slow request has not returned, the notice shows and not an empty screen.
      expect(find.text('Cargando reservas…'), findsOneWidget);
      expect(find.text('PANEL ADMIN'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets(
    'the filters find nothing and sees «Sin resultados» with «Limpiar filtros» @CU-14-H02-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final venueName = 'Sede San Justo ${unique()}';
      await createVenue(venueName, 'Av. Rivadavia 5000');
      final court = await createSpace(venueName);
      await occupy(court, tomorrow, 13);
      await signInAsAdmin(tester);

      await typeInto(tester, 'Buscar reserva', '$venueName-sin-coincidencia');
      await waitUntil(tester, find.text('Sin resultados'));
      expect(
        find.text('Ninguna reserva coincide con los filtros aplicados.'),
        findsOneWidget,
      );

      await tapText(tester, 'LIMPIAR FILTROS');
      // The lazy list leaves the booking off screen among the run's others.
      await waitUntil(tester, find.textContaining('RESERVAS EN TOTAL'));
      await tester.scrollUntilVisible(
        find.text(court),
        400,
        maxScrolls: 300,
        scrollable: find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      semantics.dispose();
    },
  );

  testWidgets(
    'the server fails and sees the error with «Reintentar», without partial data @CU-14-H03-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final api = await ProxyApi.open();
      await signInAsAdmin(tester, apiUrl: api.url);
      await waitUntil(tester, find.textContaining('RESERVA'));

      api.state = ApiState.failing;
      await tapText(tester, 'Filtros');
      await waitUntil(tester, find.text('APLICAR'));
      await tapText(tester, 'APLICAR');

      await waitUntil(tester, find.text('Error del servidor'));
      expect(find.textContaining('RESERVAS EN TOTAL'), findsNothing);
      expect(find.textContaining('RESULTADO'), findsNothing);

      api.state = ApiState.normal;
      await tapText(tester, 'REINTENTAR');
      await waitUntil(tester, find.textContaining('RESERVA'));
      semantics.dispose();
    },
  );

  testWidgets('sets «Desde» after «Hasta» and cannot apply @CU-14-H04-01', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await signInAsAdmin(tester);
    await tapText(tester, 'Filtros');
    await waitUntil(tester, find.text('APLICAR'));
    // With the run's venues the date range ends up below what the listing builds.
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
      dateText(tomorrow.add(const Duration(days: 10))),
    );
    await typeInto(tester, 'Hasta', dateText(tomorrow));

    expect(find.text('Desde no puede ser posterior a Hasta'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('APLICAR'))
          .flagsCollection
          .isEnabled,
      isFalse,
    );
    semantics.dispose();
  });

  testWidgets(
    'a user without the admin role does not see the panel and, entering by link, sees «Acceso denegado» @CU-14-H05-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final email = 'socio.${unique()}@correo.com';
      await signInAsUser(tester, email: email);
      expect(find.text('PANEL ADMIN'), findsNothing);

      final context = tester.element(find.byType(Scaffold).first);
      GoRouter.of(context).go('/admin');
      await tester.pumpAndSettle();

      await waitUntil(tester, find.text('Acceso denegado'));
      await tapText(tester, 'IR A MIS RESERVAS');
      await waitUntil(tester, find.text('Mis reservas'));
      semantics.dispose();
    },
  );

  testWidgets(
    'with an expired session goes to login and returns to the history with its filters @CU-14-H06-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final venueName = 'Sede Haedo ${unique()}';
      await createVenue(venueName, 'Av. Vergara 1850');
      final api = await ProxyApi.open();
      await signInAsAdmin(tester, apiUrl: api.url);
      await typeInto(tester, 'Buscar reserva', venueName);
      await waitUntil(tester, find.text('Sin resultados'));

      api.state = ApiState.sessionExpired;
      await tapText(tester, 'Filtros');
      await waitUntil(tester, find.text('APLICAR'));
      await tapText(tester, 'APLICAR');

      await waitUntil(tester, find.text('Tu sesión expiró'));
      await tapText(tester, 'IR AL INICIO DE SESIÓN');
      await waitUntil(tester, find.text('INICIAR SESIÓN'));

      api.state = ApiState.normal;
      await typeInto(tester, 'Correo', adminEmail);
      await typeInto(tester, 'Contraseña', adminPassword);
      await tapText(tester, 'INICIAR SESIÓN');

      // Verifies: back on the history with the search it had.
      await waitUntil(tester, find.text('PANEL ADMIN'));
      expect(find.bySemanticsLabel('Buscar reserva'), findsOneWidget);
      await waitUntil(tester, find.text('Sin resultados'));
      semantics.dispose();
    },
  );

  testWidgets(
    'the bookings of a deactivated space stay in the history marked «Baja del espacio deportivo» @CU-14-H09-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final venueName = 'Sede Castelar ${unique()}';
      await createVenue(venueName, 'Av. Rivadavia 23500');
      final court = await createSpace(venueName);
      // No future bookings: deactivating the space is not blocked (decision 5, CU-14-AMB-07).
      await occupy(court, yesterday, 9);
      await deactivateSpaceFromAnotherSession(court);
      await signInAsAdmin(tester);
      await typeInto(tester, 'Buscar reserva', venueName);

      await waitUntil(tester, find.text('Baja del espacio deportivo'));
      await tapText(tester, court);
      await waitUntil(tester, find.text('Detalle de reserva'));
      expect(find.text('Baja del espacio deportivo'), findsOneWidget);
      semantics.dispose();
    },
  );
}
