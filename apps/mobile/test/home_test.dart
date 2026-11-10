import 'package:clubnahuelmosse/features/spaces/data/spaces_repository.dart';
import 'package:clubnahuelmosse/features/venues/data/venues_repository.dart';
import 'package:clubnahuelmosse/common/club_timezone.dart';
import 'package:clubnahuelmosse/features/home/presentation/home_greeting.dart';
import 'package:clubnahuelmosse/common/marker.dart';
import 'package:clubnahuelmosse/features/home/presentation/home_screen.dart';
import 'package:clubnahuelmosse/features/bookings/presentation/bookings.dart';
import 'package:clubnahuelmosse/features/bookings/data/bookings_api.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/mount.dart';
import 'package:clubnahuelmosse/features/spaces/presentation/spaces.dart';
import 'package:clubnahuelmosse/features/venues/presentation/venues.dart';

Finder _inMarker(String text) =>
    find.descendant(of: find.byType(AppMarker), matching: find.text(text));

void main() {
  setUpAll(loadFonts);

  testWidgets('the Home shows the greeting, the count and the next booking', (
    tester,
  ) async {
    await mountScreen(
      tester,
      fakeHome(FakeSession(userProfile)),
      theme: darkTheme,
    );

    expect(find.text(HomeGreeting.forHour(clubNow())), findsOneWidget);
    expect(find.text('Nahuel'), findsOneWidget);
    expect(_inMarker('04'), findsOneWidget);
    expect(_inMarker('SEDES'), findsOneWidget);
    expect(_inMarker('17'), findsOneWidget);
    expect(_inMarker('CANCHAS'), findsOneWidget);
    expect(_inMarker('PRÓXIMAS'), findsOneWidget);
    expect(find.text('TU PRÓXIMA RESERVA'), findsOneWidget);
    expect(find.text('Moron_Rivadavia_19850_Futbol_F5_1'), findsOneWidget);
    expect(find.text('MODIFICAR'), findsOneWidget);
    expect(find.text('CANCELAR'), findsOneWidget);
    expect(find.text('Fútbol'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Buscar cancha'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Buscar cancha'), findsOneWidget);
  });

  testWidgets(
    'with no upcoming bookings the next-booking block does not appear',
    (tester) async {
      await mountScreen(
        tester,
        fakeHome(FakeSession(userProfile), withBooking: false),
        theme: darkTheme,
      );

      expect(find.text('RESERVÁ TU CANCHA'), findsOneWidget);
      expect(find.text('TU PRÓXIMA RESERVA'), findsNothing);
      expect(find.text('VER TODAS →'), findsNothing);
    },
  );

  testWidgets('with a single venue and one court the marker counts 01 and 01', (
    tester,
  ) async {
    await mountScreen(
      tester,
      fakeHome(FakeSession(userProfile), oneVenue: true),
      theme: darkTheme,
    );

    expect(_inMarker('01'), findsNWidgets(3));
    expect(_inMarker('SEDES'), findsOneWidget);
    expect(_inMarker('CANCHAS'), findsOneWidget);
  });

  testWidgets(
    'with text at 200 % at 360 px nothing overflows when scrolling through it',
    (tester) async {
      for (final theme in [darkTheme, lightTheme]) {
        await mountScreen(
          tester,
          fakeHome(FakeSession(userProfile)),
          theme: theme,
          size: const Size(360, 800),
          textScale: 2,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('TU PRÓXIMA RESERVA'), findsOneWidget);

        final list = find.byType(Scrollable).first;
        await tester.scrollUntilVisible(
          find.text('Ver sedes'),
          300,
          scrollable: list,
        );
        await tester.drag(list, const Offset(0, -2000));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Horarios y canchas de cada una'), findsOneWidget);
      }
    },
  );

  testWidgets('if the read fails it warns and lets the user retry', (
    tester,
  ) async {
    final session = FakeSession(userProfile);
    final api = apiRoutes({});
    await mountScreen(
      tester,
      HomeScreen(
        sesion: session,
        reservas: Bookings(BookingsApi(api: api, sesion: session)),
        espacios: Spaces(
          repository: SpacesRepository(api: api, session: session),
        ),
        venues: Venues(
          repository: VenuesRepository(api: api, session: session),
        ),
      ),
      theme: darkTheme,
    );

    expect(find.text('Error del servidor'), findsOneWidget);
    await tester.tap(find.text('ACEPTAR'));
    await tester.pumpAndSettle();

    expect(find.text('REINTENTAR'), findsOneWidget);
    expect(find.text('TU PRÓXIMA RESERVA'), findsNothing);
    expect(find.textContaining('disponibilidad en tiempo real'), findsNothing);
  });
}
