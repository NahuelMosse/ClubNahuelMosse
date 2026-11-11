import 'package:clubnahuelmosse/features/bookings/data/booking_json.dart';
import 'dart:async';
import 'dart:convert';

import 'package:clubnahuelmosse/features/admin/presentation/booking_detail_screen.dart';
import 'package:clubnahuelmosse/features/admin/presentation/new_space_screen.dart';
import 'package:clubnahuelmosse/features/admin/presentation/edit_space_screen.dart';
import 'package:clubnahuelmosse/features/admin/presentation/space_created_screen.dart';
import 'package:clubnahuelmosse/features/admin/presentation/admin_spaces_screen.dart';
import 'package:clubnahuelmosse/features/admin/presentation/venue_form_screen.dart';
import 'package:clubnahuelmosse/features/admin/presentation/admin_panel_screen.dart';
import 'package:clubnahuelmosse/features/admin/presentation/venue_created_screen.dart';
import 'package:clubnahuelmosse/features/admin/presentation/admin_venues_screen.dart';
import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:clubnahuelmosse/common/bottom_bar.dart';
import 'package:clubnahuelmosse/features/home/presentation/home_screen.dart';
import 'package:clubnahuelmosse/features/bookings/presentation/space_search_screen.dart';
import 'package:clubnahuelmosse/features/bookings/presentation/confirm_change_screen.dart';
import 'package:clubnahuelmosse/features/bookings/presentation/confirm_booking_screen.dart';
import 'package:clubnahuelmosse/features/bookings/presentation/availability_screen.dart';
import 'package:clubnahuelmosse/features/bookings/presentation/my_bookings_screen.dart';
import 'package:clubnahuelmosse/features/bookings/presentation/booking_confirmed_screen.dart';
import 'package:clubnahuelmosse/features/bookings/domain/booking.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../my_bookings_test.dart' show bookingJson;
import '../notifications_test.dart' show FakeApi, centerOf;
import '../support/admin.dart';
import '../support/mount.dart';
import '../support/user.dart';
import 'package:clubnahuelmosse/features/notifications/presentation/notifications_screen.dart';
import 'package:clubnahuelmosse/features/session/presentation/account_card.dart';
import 'package:clubnahuelmosse/features/session/presentation/forgot_password_screen.dart';
import 'package:clubnahuelmosse/features/session/presentation/login_screen.dart';
import 'package:clubnahuelmosse/features/spaces/domain/space.dart';
import 'package:clubnahuelmosse/features/users/presentation/change_password_screen.dart';
import 'package:clubnahuelmosse/features/users/presentation/my_profile_screen.dart';
import 'package:clubnahuelmosse/features/users/presentation/registration_done_screen.dart';
import 'package:clubnahuelmosse/features/users/presentation/registration_screen.dart';
import 'package:clubnahuelmosse/features/venues/domain/venue.dart';
import 'package:clubnahuelmosse/features/venues/presentation/venue_screen.dart';
import 'package:clubnahuelmosse/features/venues/presentation/venues_screen.dart';

const _width = 393.0;
const _height = 852.0;

Duration _ms(int n) => Duration(milliseconds: n);

typedef _Step = Future<void> Function(WidgetTester tester);

GoRouter _routes(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Scaffold).first));

Future<void> _go(WidgetTester tester, String route, {Object? extra}) async =>
    _routes(tester).go(route, extra: extra);

Future<void> _push(WidgetTester tester, String route) async =>
    unawaited(_routes(tester).push<void>(route));

/// Taps [f] without waiting for the transition it triggers to finish.
Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
}

Future<void> _tapAndWait(WidgetTester tester, Finder f) async {
  await _tap(tester, f);
  await tester.pumpAndSettle();
}

/// Lets the navigation set up, without running the transition clock.
Future<void> _start(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

/// Discards the previous app: a new `App` over the old one would keep its router.
Future<void> _restart(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
}

void _reduceMotion(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

double _left(WidgetTester tester, Type screen) =>
    tester.getTopLeft(find.byType(screen)).dx;

double _top(WidgetTester tester, Finder screen) => tester.getTopLeft(screen).dy;

/// The screen is already in place and no page transition slides it.
void _noTransition(WidgetTester tester, Type screen, {String? reason}) {
  expect(find.byType(screen), findsOneWidget, reason: reason);
  expect(_left(tester, screen), 0, reason: reason);
  expect(
    find.ancestor(
      of: find.byType(screen),
      matching: find.byType(SlideTransition),
    ),
    findsNothing,
    reason: reason,
  );
  // Not a transition of the current route, whichever it is.
  expect(
    ModalRoute.of(tester.element(find.byType(screen)))?.animation?.status,
    AnimationStatus.completed,
    reason: reason,
  );
  // Nor a half-way fade or zoom.
  expect(_opacitiesOf(tester, screen), everyElement(1), reason: reason);
  expect(
    [
      for (final z in tester.widgetList<ScaleTransition>(
        find.ancestor(
          of: find.byType(screen),
          matching: find.byType(ScaleTransition),
        ),
      ))
        z.scale.value,
    ],
    everyElement(1),
    reason: reason,
  );
}

/// The screen is in place from the first frame and stays so: there is no transition in progress.
Future<void> _still(WidgetTester tester, Type screen, {String? reason}) async {
  _noTransition(tester, screen, reason: reason);
  await tester.pump(_ms(100));
  _noTransition(tester, screen, reason: reason);
}

/// The screen enters from the right: at 160 ms it is half-way and at 320 it has arrived.
Future<void> _entersFromRight(
  WidgetTester tester,
  Type screen, {
  String? reason,
}) async {
  await _start(tester);
  expect(find.byType(screen), findsOneWidget, reason: reason);
  await tester.pump(_ms(160));
  final halfway = _left(tester, screen);
  expect(halfway, greaterThan(0), reason: reason);
  expect(halfway, lessThan(_width), reason: reason);
  await tester.pump(_ms(160));
  expect(_left(tester, screen), 0, reason: reason);
}

/// The screen leaves to the right: at 140 ms it is half-way and at 280 it is gone.
Future<void> _leavesToRight(
  WidgetTester tester,
  Type screen, {
  String? reason,
}) async {
  await _start(tester);
  expect(find.byType(screen), findsOneWidget, reason: reason);
  await tester.pump(_ms(140));
  final halfway = _left(tester, screen);
  expect(halfway, greaterThan(0), reason: reason);
  expect(halfway, lessThan(_width), reason: reason);
  await tester.pump(_ms(140));
  await tester.pump();
  expect(find.byType(screen), findsNothing, reason: reason);
}

List<double> _opacitiesOf(WidgetTester tester, Type screen) => [
  for (final f in tester.widgetList<FadeTransition>(
    find.ancestor(
      of: find.byType(screen),
      matching: find.byType(FadeTransition),
    ),
  ))
    f.opacity.value,
];

// ---- the apps ----

ApiClient _userApi() => apiRoutes({
  ...venueRoutes(grid: gridJson(taken: {9, 12})),
  'GET /bookings': (200, '{"bookings": [${bookingJson()}]}'),
});

const _adminBooking =
    '{"id": "00000000-0000-7000-8000-000000000001", "space_id": "00000000-0000-7000-8000-000000000009", "venue_id": "00000000-0000-7000-8000-000000000001", "space":'
    ' "Moron_Rivadavia_19850_Futbol_F5_1", "sport": "Futbol", "kind": "F5", "venue":'
    ' "Sede Morón", "address": "Av. Rivadavia 19850", "starts_at":'
    ' "2026-11-12T21:00:00-03:00", "ends_at": "2026-11-12T22:00:00-03:00", "total": 38000,'
    ' "status": "active", "reason": null, "user_id": "00000000-0000-7000-8000-000000000001", "user": "Nahuel Mosse",'
    ' "created_at": "2026-11-02T18:42:00-03:00", "canceled_at": null,'
    ' "canceled_by_name": null, "space_deactivated": false}';

ApiClient _adminApi() => apiRoutes({
  ...spaceRoutes(),
  'GET /bookings/all': (
    200,
    '{"bookings": [$_adminBooking], "total": 1, "page": 1, "per_page": 20,'
        ' "counters": {"all": 1, "active": 1, "completed": 0,'
        ' "voided": 0}}',
  ),
});

/// Tall so that home builds all its blocks, the lower ones too.
const _tallPhone = Size(393, 1600);

Future<void> _userAt(WidgetTester tester, String startRoute) =>
    mountUser(tester, api: _userApi(), start: startRoute, size: _tallPhone);

Future<void> _adminAt(WidgetTester tester, String startRoute) =>
    mountAdmin(tester, api: _adminApi(), start: startRoute);

Future<void> _userWithCenter(WidgetTester tester, String startRoute) {
  final api = FakeApi();
  return mountUser(
    tester,
    api: api.client,
    start: startRoute,
    size: _tallPhone,
    center: (session) => centerOf(api, session),
  );
}

// ---- the child screens (S2 and S3) ----

class _Child {
  const _Child(
    this.name,
    this.mountScreen,
    this.open,
    this.screen, {
    this.withBar = false,
  });

  final String name;

  /// Leaves the app on the screen it is reached from.
  final _Step mountScreen;

  /// Does what the person does to get there, without waiting for the transition to finish.
  final _Step open;
  final Type screen;

  /// The screen has the «Volver» arrow of the top bar.
  final bool withBar;
}

final _children = <_Child>[
  _Child(
    'sede',
    (t) => _userAt(t, '/venues'),
    (t) => _go(t, '/venues/00000000-0000-7000-8000-000000000001'),
    VenueScreen,
  ),
  _Child(
    'horarios',
    (t) => _userAt(t, '/venues/00000000-0000-7000-8000-000000000001'),
    (t) => _go(
      t,
      '/venues/00000000-0000-7000-8000-000000000001/spaces/00000000-0000-7000-8000-000000000009',
    ),
    AvailabilityScreen,
  ),
  _Child(
    'confirmar reserva',
    (t) async {
      await _userAt(
        t,
        '/venues/00000000-0000-7000-8000-000000000001/spaces/00000000-0000-7000-8000-000000000009',
      );
      await _tapAndWait(t, find.text('18:00 – 19:00'));
    },
    (t) => _tap(t, find.text('CONTINUAR')),
    ConfirmBookingScreen,
  ),
  _Child(
    'modificar',
    (t) => _userAt(t, '/bookings'),
    (t) => _tap(t, find.text('MODIFICAR').first),
    AvailabilityScreen,
  ),
  _Child(
    'confirmar cambio',
    (t) async {
      await _userAt(t, '/bookings');
      await _tapAndWait(t, find.text('MODIFICAR').first);
      await _tapAndWait(t, find.text('19:00 – 20:00'));
    },
    (t) => _tap(t, find.text('CONTINUAR CON EL CAMBIO')),
    ConfirmChangeScreen,
  ),
  _Child(
    'contraseña',
    (t) => _userAt(t, '/profile'),
    (t) => _tap(t, find.text('Cambiar contraseña')),
    ChangePasswordScreen,
    withBar: true,
  ),
  _Child(
    'registro',
    (t) => _userAt(t, '/'),
    (t) => _tap(t, find.text('COMENZAR')),
    RegistrationScreen,
    withBar: true,
  ),
  _Child(
    'recuperar contraseña',
    (t) => _userAt(t, '/'),
    (t) => _tap(t, find.text('¿Olvidaste tu contraseña?')),
    ForgotPasswordScreen,
    withBar: true,
  ),
  _Child(
    'notificaciones',
    (t) => _userWithCenter(t, '/home'),
    (t) => _tap(t, find.byIcon(Icons.notifications_none_rounded)),
    NotificationsScreen,
    withBar: true,
  ),
  _Child(
    'buscar cancha',
    (t) => _userAt(t, '/home'),
    (t) => _tap(t, find.text('Buscar cancha')),
    SpaceSearchScreen,
    withBar: true,
  ),
  _Child(
    'detalle de reserva del admin',
    (t) => _adminAt(t, '/admin'),
    (t) => _tap(t, find.text('Nahuel Mosse')),
    BookingDetailScreen,
  ),
  _Child(
    'alta de sede',
    (t) => _adminAt(t, '/admin/venues'),
    (t) => _tap(t, find.text('AGREGAR SEDE')),
    VenueFormScreen,
  ),
  _Child(
    'edición de sede',
    (t) => _adminAt(t, '/admin/venues'),
    (t) => _tap(t, find.text('Editar sede').first),
    VenueFormScreen,
  ),
  _Child(
    'alta de espacio',
    (t) => _adminAt(t, '/admin/spaces'),
    (t) => _tap(t, find.text('ALTA ESPACIO')),
    NewSpaceScreen,
  ),
  _Child(
    'edición de espacio',
    (t) => _adminAt(t, '/admin/spaces'),
    (t) => _tap(t, find.text('Editar').first),
    EditSpaceScreen,
  ),
];

// ---- the roots (S1) ----

class _Root {
  const _Root(this.name, this.mountScreen, this.route, this.screen);

  final String name;
  final _Step mountScreen;
  final String route;
  final Type screen;
}

final _roots = <_Root>[
  _Root(
    'inicio',
    (t) => _userAt(t, '/venues/00000000-0000-7000-8000-000000000001'),
    '/home',
    HomeScreen,
  ),
  _Root('sedes', (t) => _userAt(t, '/home'), '/venues', VenuesScreen),
  _Root('reservas', (t) => _userAt(t, '/home'), '/bookings', MyBookingsScreen),
  _Root('perfil', (t) => _userAt(t, '/home'), '/profile', MyProfileScreen),
  _Root(
    'panel del admin',
    (t) => _adminAt(t, '/admin/venues'),
    '/admin',
    AdminPanelScreen,
  ),
  _Root(
    'sedes del admin',
    (t) => _adminAt(t, '/admin'),
    '/admin/venues',
    AdminVenuesScreen,
  ),
  _Root(
    'espacios del admin',
    (t) => _adminAt(t, '/admin'),
    '/admin/spaces',
    AdminSpacesScreen,
  ),
  _Root(
    'login',
    (t) => _userAt(t, '/venues/00000000-0000-7000-8000-000000000001'),
    '/',
    LoginScreen,
  ),
];

// ---- the results (S4) ----

class _Result {
  const _Result(this.name, this.mountScreen, this.open, this.screen);

  final String name;
  final _Step mountScreen;
  final _Step open;
  final Type screen;
}

Booking _confirmedBooking() {
  final booking = bookingFromJson(jsonDecode(bookingJson()));
  if (booking == null) fail('the test booking cannot be read');
  return booking;
}

final _results = <_Result>[
  _Result(
    'registro exitoso',
    (t) => _userAt(t, '/register'),
    (t) => _go(t, '/register/success'),
    RegistrationDoneScreen,
  ),
  _Result(
    'reserva confirmada',
    (t) => _userAt(t, '/bookings'),
    (t) => _go(t, '/bookings/confirmed', extra: _confirmedBooking()),
    BookingConfirmedScreen,
  ),
  _Result(
    'sede creada',
    (t) => _adminAt(t, '/admin/venues'),
    (t) => _go(
      t,
      '/admin/venues/created',
      extra: Venue.fromJson(jsonDecode(venueMoronJson)),
    ),
    VenueCreatedScreen,
  ),
  _Result(
    'espacio creado',
    (t) => _adminAt(t, '/admin/spaces'),
    (t) => _go(
      t,
      '/admin/spaces/created',
      extra: Space.fromJson(jsonDecode(spaceF5Json)),
    ),
    SpaceCreatedScreen,
  ),
];

Finder get _filterPanel =>
    find.byWidgetPredicate((w) => w.runtimeType.toString() == '_FiltersPanel');

void main() {
  setUpAll(loadFonts);

  testWidgets('every tab root appears on the first frame @RED-04-S1', (
    tester,
  ) async {
    for (final root in _roots) {
      for (final pushing in [false, true]) {
        final how = pushing ? 'push' : 'go';
        await root.mountScreen(tester);
        if (pushing) {
          await _push(tester, root.route);
        } else {
          await _go(tester, root.route);
        }
        await _start(tester);
        await _still(tester, root.screen, reason: '${root.name} ($how)');
        await _restart(tester);
      }
    }
  });

  testWidgets('every child screen enters from the right in 320 ms @RED-04-S2', (
    tester,
  ) async {
    for (final child in _children) {
      await child.mountScreen(tester);
      await child.open(tester);
      await _entersFromRight(tester, child.screen, reason: child.name);
      await _restart(tester);
    }
  });

  testWidgets(
    'going back with the back of the bar or of the system leaves to the right in 280 ms @RED-04-S3',
    (tester) async {
      for (final child in _children) {
        await child.mountScreen(tester);
        await child.open(tester);
        await tester.pumpAndSettle();
        await tester.binding.handlePopRoute();
        await _leavesToRight(
          tester,
          child.screen,
          reason: '${child.name} (atrás del sistema)',
        );
        await _restart(tester);

        if (!child.withBar) continue;
        await child.mountScreen(tester);
        await child.open(tester);
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Volver'));
        await _leavesToRight(
          tester,
          child.screen,
          reason: '${child.name} (atrás de la barra)',
        );
        await _restart(tester);
      }
    },
  );

  testWidgets('every result screen appears with a 250 ms fade @RED-04-S4', (
    tester,
  ) async {
    for (final result in _results) {
      await result.mountScreen(tester);
      await result.open(tester);
      await _start(tester);
      expect(find.byType(result.screen), findsOneWidget, reason: result.name);
      expect(
        find.ancestor(
          of: find.byType(result.screen),
          matching: find.byType(SlideTransition),
        ),
        findsNothing,
        reason: result.name,
      );
      await tester.pump(_ms(125));
      final halfway = _opacitiesOf(tester, result.screen);
      expect(
        halfway.any((o) => o > 0 && o < 1),
        isTrue,
        reason: '${result.name} at 125 ms: $halfway',
      );
      await tester.pump(_ms(125));
      expect(
        _opacitiesOf(tester, result.screen),
        everyElement(1),
        reason: '${result.name} at 250 ms',
      );
      await _restart(tester);
    }
  });

  testWidgets(
    'with reduce motion the transitions end on the first frame @RED-04-S14',
    (tester) async {
      _reduceMotion(tester);

      // Forward: the child is already in place.
      await _userAt(tester, '/venues');
      await _go(tester, '/venues/00000000-0000-7000-8000-000000000001');
      await _start(tester);
      _noPushTransition(tester, VenueScreen);

      // Back: the child is gone.
      await tester.binding.handlePopRoute();
      await _start(tester);
      await tester.pump();
      expect(find.byType(VenueScreen), findsNothing);
      await _restart(tester);

      // Result: the fade has finished.
      await _userAt(tester, '/bookings');
      await _go(tester, '/bookings/confirmed', extra: _confirmedBooking());
      await _start(tester);
      expect(find.byType(BookingConfirmedScreen), findsOneWidget);
      expect(_opacitiesOf(tester, BookingConfirmedScreen), everyElement(1));
      await _restart(tester);

      // Tab root.
      await _userAt(tester, '/venues/00000000-0000-7000-8000-000000000001');
      await _go(tester, '/home');
      await _start(tester);
      await _still(tester, HomeScreen);
      await _restart(tester);

      // The admin filter panel.
      await _adminAt(tester, '/admin');
      await tester.tap(find.text('Filtros'));
      await _until(tester, () => _filterPanel.evaluate().isNotEmpty);
      expect(_top(tester, _filterPanel), 0);
    },
  );

  testWidgets(
    'tapping the active tab inside a venue or «VER TODAS» and «Ver sedes» on home arrive without animation @RED-04-ASM-05',
    (tester) async {
      // The active tab, from inside a venue, leads to the listing.
      await _userAt(tester, '/venues/00000000-0000-7000-8000-000000000001');
      await _tap(
        tester,
        find.descendant(
          of: find.byType(BottomBar),
          matching: find.text('SEDES'),
        ),
      );
      await _start(tester);
      await _still(tester, VenuesScreen, reason: 'la pestaña activa');
      // The venue that is left leaves with its reverse push.
      await tester.pump(_ms(280));
      expect(find.byType(VenueScreen), findsNothing);
      await _restart(tester);

      await _userAt(tester, '/home');
      await _tap(tester, find.text('VER TODAS →'));
      await _start(tester);
      await _still(tester, MyBookingsScreen, reason: 'VER TODAS');
      expect(find.byType(HomeScreen), findsNothing);
      await _restart(tester);

      await _userAt(tester, '/home');
      await _tap(tester, find.text('Ver sedes'));
      await _start(tester);
      await _still(tester, VenuesScreen, reason: 'Ver sedes');
      expect(find.byType(HomeScreen), findsNothing);
    },
  );

  testWidgets('signing out shows the login without animation @RED-04-ASM-06', (
    tester,
  ) async {
    await _userAt(tester, '/home');
    await _tapAndWait(tester, find.byType(AccountButton));
    await _tap(tester, find.text('Cerrar sesión'));
    for (var i = 0; i < 5 && find.byType(LoginScreen).evaluate().isEmpty; i++) {
      await tester.pump();
    }
    await _still(tester, LoginScreen, reason: 'cerrar sesión');
    await _restart(tester);

    // Going back from password recovery to the login.
    await _userAt(tester, '/password-recovery');
    await _go(tester, '/');
    await _start(tester);
    await _still(tester, LoginScreen, reason: 'recuperar → login');
  });

  testWidgets(
    'the admin filter panel rises from the bottom in 450 ms @RED-04-ASM-09',
    (tester) async {
      await _adminAt(tester, '/admin');
      await tester.tap(find.text('Filtros'));
      await _until(tester, () => _filterPanel.evaluate().isNotEmpty);

      // Enters from the very bottom.
      expect(_top(tester, _filterPanel), closeTo(_height, 1));
      await tester.pump(_ms(225));
      final halfway = _top(tester, _filterPanel);
      expect(halfway, greaterThan(0));
      expect(halfway, lessThan(_height));
      await tester.pump(_ms(225));
      expect(_top(tester, _filterPanel), 0);
      await tester.pumpAndSettle();

      // And leaves downward.
      await tester.tap(find.byTooltip('Cerrar'));
      await _start(tester);
      await tester.pump(_ms(100));
      final leaving = _top(tester, _filterPanel);
      expect(leaving, greaterThan(0));
      expect(leaving, lessThan(_height));
      await tester.pump(_ms(450));
      await tester.pump();
      expect(_filterPanel, findsNothing);
    },
  );
}

/// With reduce motion the child is already in place, without sliding.
void _noPushTransition(WidgetTester tester, Type screen) {
  expect(find.byType(screen), findsOneWidget);
  expect(_left(tester, screen), 0);
}

/// Pumps frames without advancing the clock until [condition] holds.
Future<void> _until(WidgetTester tester, bool Function() condition) async {
  for (var i = 0; i < 20 && !condition(); i++) {
    await tester.pump();
  }
  expect(condition(), isTrue);
}
