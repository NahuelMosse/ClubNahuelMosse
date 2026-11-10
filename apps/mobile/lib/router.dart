import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'api/api_client.dart';
import 'common/appearance.dart';
import 'common/pending_booking.dart';
import 'common/transitions.dart';
import 'features/admin/data/booking_history_api.dart';
import 'features/admin/domain/booking_history_entry.dart';
import 'features/admin/domain/history_filters.dart';
import 'features/admin/domain/pending_panel_filters.dart';
import 'features/admin/presentation/admin_panel_screen.dart';
import 'features/admin/presentation/admin_spaces_screen.dart';
import 'features/admin/presentation/admin_venues_screen.dart';
import 'features/admin/presentation/booking_detail_screen.dart';
import 'features/admin/presentation/edit_space_screen.dart';
import 'features/admin/presentation/new_space_screen.dart';
import 'features/admin/presentation/space_created_screen.dart';
import 'features/admin/presentation/venue_created_screen.dart';
import 'features/admin/presentation/venue_form_screen.dart';
import 'features/bookings/data/availability_api.dart';
import 'features/bookings/domain/booking.dart';
import 'features/bookings/domain/booking_choice.dart';
import 'features/bookings/presentation/availability_screen.dart';
import 'features/bookings/presentation/booking_confirmed_screen.dart';
import 'features/bookings/presentation/bookings.dart';
import 'features/bookings/presentation/confirm_booking_screen.dart';
import 'features/bookings/presentation/confirm_change_screen.dart';
import 'features/bookings/presentation/my_bookings_screen.dart';
import 'features/bookings/presentation/space_search_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/notifications/domain/app_notification.dart';
import 'features/notifications/presentation/notification_center.dart';
import 'features/notifications/presentation/notifications_screen.dart';
import 'features/session/data/password_recovery.dart';
import 'features/session/presentation/access_denied_screen.dart';
import 'features/session/presentation/forgot_password_screen.dart';
import 'features/session/presentation/login_screen.dart';
import 'features/session/presentation/new_password_screen.dart';
import 'features/session/presentation/session.dart';
import 'features/spaces/domain/space.dart';
import 'features/spaces/presentation/spaces.dart';
import 'features/users/data/registration_service.dart';
import 'features/users/presentation/change_password_screen.dart';
import 'features/users/presentation/my_profile_screen.dart';
import 'features/users/presentation/registration_done_screen.dart';
import 'features/users/presentation/registration_screen.dart';
import 'features/venues/domain/venue.dart';
import 'features/venues/presentation/venue_screen.dart';
import 'features/venues/presentation/venues.dart';
import 'features/venues/presentation/venues_screen.dart';
import 'l10n/app_localizations.dart';
import 'redirect.dart';

/// Las rutas de la app, con lo que cada pantalla recibe.
class AppRouter {
  const AppRouter({
    required ValueGetter<ApiClient> api,
    required ValueGetter<Session> session,
    required ValueGetter<Appearance> appearance,
    required ValueGetter<NotificationCenter?> center,
    required this.recovery,
    required this.venues,
    required this.spaces,
    required this.availability,
    required this.bookings,
    required this.adminHistory,
    required this.pending,
    required this.pendingFilters,
  }) : _api = api,
       _session = session,
       _appearance = appearance,
       _center = center;

  // Se leen de la app en cada uso: si el widget se reemplaza con la misma `State`,
  // las rutas siguen con lo que trae el widget nuevo.
  final ValueGetter<ApiClient> _api;
  final ValueGetter<Session> _session;
  final ValueGetter<Appearance> _appearance;
  final ValueGetter<NotificationCenter?> _center;
  final PasswordRecovery recovery;
  final Venues venues;
  final Spaces spaces;
  final AvailabilityApi availability;
  final Bookings bookings;
  final BookingHistory adminHistory;
  final PendingBooking<BookingChoice> pending;
  final PendingPanelFilters pendingFilters;

  ApiClient get api => _api();
  Session get session => _session();
  Appearance get appearance => _appearance();
  NotificationCenter? get center => _center();

  /// El router de la app: arranca en [initialLocation] y, al iniciar o cerrar la sesión, vuelve
  /// a evaluar a quién deja pasar adónde.
  GoRouter router({
    required GlobalKey<NavigatorState> navigatorKey,
    required String initialLocation,
  }) => GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: initialLocation,
    refreshListenable: session,
    redirect: (context, state) =>
        redirectByRole(state.matchedLocation, session.profile),
    routes: [
      ..._sessionRoutes(),
      ..._homeRoutes(),
      ..._venueRoutes(),
      ..._bookingRoutes(),
      ..._adminRoutes(),
    ],
  );

  /// `AAAA-MM-DD` de un enlace como día del club; `null` si no viene o no es una fecha.
  static DateTime? _day(String? iso) => switch (DateTime.tryParse(iso ?? '')) {
    final d? => DateTime.utc(d.year, d.month, d.day),
    null => null,
  };

  List<RouteBase> _sessionRoutes() => [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => rootPage(
        context,
        state,
        LoginScreen(session: session, pending: pending),
      ),
      routes: [
        GoRoute(
          path: 'register',
          pageBuilder: (context, state) => forwardPage(
            context,
            state,
            RegistrationScreen(registration: RegistrationService(api)),
          ),
        ),
        GoRoute(
          path: 'register/success',
          pageBuilder: (context, state) =>
              resultPage(context, state, const RegistrationDoneScreen()),
        ),
        GoRoute(
          path: 'password-recovery',
          pageBuilder: (context, state) => forwardPage(
            context,
            state,
            ForgotPasswordScreen(recovery: recovery),
          ),
        ),
      ],
    ),
    // Adonde abre el enlace del correo: clubnahuelmosse://app/recover?code=…
    GoRoute(
      path: '/recover',
      pageBuilder: (context, state) {
        final code = state.uri.queryParameters['code'] ?? '';
        // Un enlace nuevo con la pantalla ya abierta es otra pantalla, no la misma.
        return forwardPage(
          context,
          state,
          NewPasswordScreen(
            key: ValueKey(code),
            recovery: recovery,
            session: session,
            code: code,
          ),
        );
      },
    ),
  ];

  List<RouteBase> _homeRoutes() => [
    GoRoute(
      path: '/home',
      pageBuilder: (context, state) => rootPage(
        context,
        state,
        HomeScreen(
          session: session,
          bookings: bookings,
          spaces: spaces,
          venues: venues,
          center: center,
        ),
      ),
      routes: [
        GoRoute(
          path: 'search',
          pageBuilder: (context, state) => forwardPage(
            context,
            state,
            SpaceSearchScreen(
              venues: venues,
              spaces: spaces,
              availability: availability,
              session: session,
              sport: state.uri.queryParameters['sport'],
            ),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/notifications',
      pageBuilder: (context, state) =>
          forwardPage(context, state, switch (center) {
            final NotificationCenter center => NotificationsScreen(
              center: center,
              session: session,
              onOpen: (context, n) =>
                  context.go(noticeRoute(n.kind, n.bookingId)),
            ),
            null => const SizedBox.shrink(),
          }),
    ),
    GoRoute(
      path: '/profile',
      pageBuilder: (context, state) => rootPage(
        context,
        state,
        MyProfileScreen(session: session, appearance: appearance),
      ),
      routes: [
        GoRoute(
          path: 'password',
          pageBuilder: (context, state) => forwardPage(
            context,
            state,
            ChangePasswordScreen(session: session),
          ),
        ),
      ],
    ),
  ];

  List<RouteBase> _venueRoutes() => [
    GoRoute(
      path: '/venues',
      pageBuilder: (context, state) => rootPage(
        context,
        state,
        VenuesScreen(venues: venues, spaces: spaces, session: session),
      ),
      routes: [
        GoRoute(
          path: ':venue',
          pageBuilder: (context, state) => forwardPage(
            context,
            state,
            VenueScreen(
              key: ValueKey(state.pathParameters['venue']),
              venueId: state.pathParameters['venue'] ?? '',
              venues: venues,
              spaces: spaces,
              session: session,
            ),
          ),
          routes: [
            GoRoute(
              path: 'spaces/:space',
              pageBuilder: (context, state) => forwardPage(
                context,
                state,
                AvailabilityScreen(
                  key: ValueKey(state.pathParameters['space']),
                  venueId: state.pathParameters['venue'] ?? '',
                  spaceId: state.pathParameters['space'] ?? '',
                  venues: venues,
                  spaces: spaces,
                  availability: availability,
                  session: session,
                  date: _day(state.uri.queryParameters['date']),
                  hours: int.tryParse(state.uri.queryParameters['hours'] ?? ''),
                  start: state.uri.queryParameters['start'],
                ),
              ),
              routes: [
                GoRoute(
                  path: 'book',
                  redirect: (context, state) => state.extra is BookingChoice
                      ? null
                      : '/venues/${state.pathParameters['venue']}'
                            '/spaces/${state.pathParameters['space']}',
                  pageBuilder: (context, state) =>
                      forwardPage(context, state, _confirmBooking(state)),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ];

  /// La confirmación de una reserva nueva; sin la elección, nada que mostrar.
  Widget _confirmBooking(GoRouterState state) => switch (state.extra) {
    final BookingChoice choice => ConfirmBookingScreen(
      choice: choice,
      bookings: bookings,
      pending: pending,
      session: session,
    ),
    _ => const SizedBox.shrink(),
  };

  List<RouteBase> _bookingRoutes() => [
    GoRoute(
      path: '/bookings',
      pageBuilder: (context, state) => rootPage(
        context,
        state,
        MyBookingsScreen(
          bookings: bookings,
          spaces: spaces,
          session: session,
          bookingId: state.uri.queryParameters['booking'],
          inHistory: state.uri.queryParameters['history'] == '1',
        ),
      ),
      routes: [
        _changeBookingRoute(),
        GoRoute(
          path: 'confirmed',
          redirect: (context, state) =>
              state.extra is Booking ? null : '/bookings',
          pageBuilder: (context, state) => resultPage(
            context,
            state,
            switch (state.extra) {
              final Booking booking => BookingConfirmedScreen(booking: booking),
              _ => const SizedBox.shrink(),
            },
          ),
        ),
      ],
    ),
    // La reserva que quedó pendiente cuando venció la sesión, al volver a entrar.
    GoRoute(
      path: '/book',
      redirect: (context, state) =>
          state.extra is BookingChoice ? null : '/home',
      pageBuilder: (context, state) =>
          forwardPage(context, state, _confirmBooking(state)),
    ),
  ];

  GoRoute _changeBookingRoute() => GoRoute(
    path: ':booking/modify',
    // La confirmación está anidada acá y trae su propio extra.
    redirect: (context, state) => switch (state.extra) {
      Booking() || (Booking(), BookingChoice()) => null,
      _ => '/bookings',
    },
    pageBuilder: (context, state) =>
        forwardPage(context, state, switch (state.extra) {
          final Booking booking => AvailabilityScreen(
            venueId: booking.venueId,
            spaceId: booking.spaceId,
            venues: venues,
            spaces: spaces,
            availability: availability,
            session: session,
            modifying: booking,
            backLabel: state.uri.queryParameters['from'] == 'home'
                ? AppLocalizations.of(context).homeBackLabel
                : AppLocalizations.of(context).accountMyBookings,
          ),
          _ => const SizedBox.shrink(),
        }),
    routes: [
      GoRoute(
        path: 'confirm',
        redirect: (context, state) =>
            state.extra is (Booking, BookingChoice) ? null : '/bookings',
        pageBuilder: (context, state) =>
            forwardPage(context, state, switch (state.extra) {
              (final Booking booking, final BookingChoice choice) =>
                ConfirmChangeScreen(
                  booking: booking,
                  choice: choice,
                  bookings: bookings,
                  session: session,
                ),
              _ => const SizedBox.shrink(),
            }),
      ),
    ],
  );

  List<RouteBase> _adminRoutes() => [
    ..._adminBookingRoutes(),
    GoRoute(
      path: '/admin/access-denied',
      pageBuilder: (context, state) =>
          forwardPage(context, state, AccessDeniedScreen(session: session)),
    ),
    ..._adminVenueRoutes(),
    ..._adminSpaceRoutes(),
  ];

  List<RouteBase> _adminBookingRoutes() => [
    GoRoute(
      path: '/admin',
      pageBuilder: (context, state) => rootPage(
        context,
        state,
        AdminPanelScreen(
          history: adminHistory,
          venues: venues,
          spaces: spaces,
          session: session,
          pending: pendingFilters,
        ),
      ),
      routes: [
        GoRoute(
          path: 'booking/:id',
          // Sin la reserva y los filtros del listado de donde se vino (un enlace, la app
          // reabierta), vuelve al listado.
          redirect: (context, state) =>
              state.extra is (BookingHistoryEntry, HistoryFilters)
              ? null
              : '/admin',
          pageBuilder: (context, state) =>
              forwardPage(context, state, switch (state.extra) {
                final (BookingHistoryEntry, HistoryFilters) e =>
                  BookingDetailScreen(
                    booking: e.$1,
                    filters: e.$2,
                    history: adminHistory,
                    session: session,
                    spaces: spaces,
                    pending: pendingFilters,
                  ),
                _ => const SizedBox.shrink(),
              }),
        ),
      ],
    ),
  ];

  List<RouteBase> _adminVenueRoutes() => [
    GoRoute(
      path: '/admin/venues',
      pageBuilder: (context, state) => rootPage(
        context,
        state,
        AdminVenuesScreen(venues: venues, session: session),
      ),
      routes: [
        GoRoute(
          path: 'new',
          pageBuilder: (context, state) => forwardPage(
            context,
            state,
            VenueFormScreen(venues: venues, session: session),
          ),
        ),
        GoRoute(
          path: ':venue/edit',
          // Sin la sede que se tocó en el listado (un enlace, la app reabierta), vuelve al
          // listado.
          redirect: (context, state) =>
              state.extra is Venue ? null : '/admin/venues',
          pageBuilder: (context, state) =>
              forwardPage(context, state, switch (state.extra) {
                final Venue venue => VenueFormScreen(
                  venues: venues,
                  session: session,
                  editing: venue,
                ),
                _ => const SizedBox.shrink(),
              }),
        ),
        GoRoute(
          path: 'created',
          // Sin la sede recién guardada (un enlace, la app reabierta) no hay éxito que
          // mostrar: va al listado, donde está.
          redirect: (context, state) =>
              state.extra is Venue ? null : '/admin/venues',
          pageBuilder: (context, state) =>
              resultPage(context, state, switch (state.extra) {
                final Venue venue => VenueCreatedScreen(venue: venue),
                _ => const SizedBox.shrink(),
              }),
        ),
      ],
    ),
  ];

  List<RouteBase> _adminSpaceRoutes() => [
    GoRoute(
      path: '/admin/spaces',
      pageBuilder: (context, state) => rootPage(
        context,
        state,
        AdminSpacesScreen(spaces: spaces, session: session),
      ),
      routes: [
        GoRoute(
          path: ':space/edit',
          // Sin el espacio que se tocó en el listado (un enlace, la app reabierta), vuelve
          // al listado.
          redirect: (context, state) =>
              state.extra is Space ? null : '/admin/spaces',
          pageBuilder: (context, state) =>
              forwardPage(context, state, switch (state.extra) {
                final Space space => EditSpaceScreen(
                  space: space,
                  spaces: spaces,
                  session: session,
                ),
                _ => const SizedBox.shrink(),
              }),
        ),
        GoRoute(
          path: 'new',
          pageBuilder: (context, state) => forwardPage(
            context,
            state,
            NewSpaceScreen(spaces: spaces, venues: venues, session: session),
          ),
        ),
        GoRoute(
          path: 'created',
          // Sin el espacio recién guardado no hay éxito que mostrar: va al listado.
          redirect: (context, state) =>
              state.extra is Space ? null : '/admin/spaces',
          pageBuilder: (context, state) =>
              resultPage(context, state, switch (state.extra) {
                final Space space => SpaceCreatedScreen(space: space),
                _ => const SizedBox.shrink(),
              }),
        ),
      ],
    ),
  ];
}
