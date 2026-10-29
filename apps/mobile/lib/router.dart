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
          path: 'registro',
          pageBuilder: (context, state) => forwardPage(
            context,
            state,
            RegistrationScreen(registration: RegistrationService(api)),
          ),
        ),
        GoRoute(
          path: 'registro/exitoso',
          pageBuilder: (context, state) =>
              resultPage(context, state, const RegistrationDoneScreen()),
        ),
        GoRoute(
          path: 'recuperar-contrasena',
          pageBuilder: (context, state) => forwardPage(
            context,
            state,
            ForgotPasswordScreen(recovery: recovery),
          ),
        ),
      ],
    ),
    // Adonde abre el enlace del correo: clubnahuelmosse://app/recuperar?codigo=…
    GoRoute(
      path: '/recuperar',
      pageBuilder: (context, state) {
        final code = state.uri.queryParameters['codigo'] ?? '';
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
      path: '/inicio',
      pageBuilder: (context, state) => rootPage(
        context,
        state,
        HomeScreen(
          sesion: session,
          reservas: bookings,
          espacios: spaces,
          venues: venues,
          centro: center,
        ),
      ),
      routes: [
        GoRoute(
          path: 'buscar',
          pageBuilder: (context, state) => forwardPage(
            context,
            state,
            SpaceSearchScreen(
              venues: venues,
              espacios: spaces,
              horarios: availability,
              sesion: session,
              deporte: state.uri.queryParameters['deporte'],
            ),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/notificaciones',
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
      path: '/perfil',
      pageBuilder: (context, state) => rootPage(
        context,
        state,
        MyProfileScreen(session: session, appearance: appearance),
      ),
      routes: [
        GoRoute(
          path: 'contrasena',
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
      path: '/sedes',
      pageBuilder: (context, state) => rootPage(
        context,
        state,
        VenuesScreen(venues: venues, spaces: spaces, session: session),
      ),
      routes: [
        GoRoute(
          path: ':sede',
          pageBuilder: (context, state) => forwardPage(
            context,
            state,
            VenueScreen(
              key: ValueKey(state.pathParameters['sede']),
              venueId: state.pathParameters['sede'] ?? '',
              venues: venues,
              spaces: spaces,
              session: session,
            ),
          ),
          routes: [
            GoRoute(
              path: 'canchas/:cancha',
              pageBuilder: (context, state) => forwardPage(
                context,
                state,
                AvailabilityScreen(
                  key: ValueKey(state.pathParameters['cancha']),
                  sedeId: state.pathParameters['sede'] ?? '',
                  espacioId: state.pathParameters['cancha'] ?? '',
                  venues: venues,
                  espacios: spaces,
                  horarios: availability,
                  sesion: session,
                  date: _day(state.uri.queryParameters['fecha']),
                  hours: int.tryParse(state.uri.queryParameters['horas'] ?? ''),
                  start: state.uri.queryParameters['inicio'],
                ),
              ),
              routes: [
                GoRoute(
                  path: 'reservar',
                  redirect: (context, state) => state.extra is BookingChoice
                      ? null
                      : '/sedes/${state.pathParameters['sede']}'
                            '/canchas/${state.pathParameters['cancha']}',
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
    final BookingChoice eleccion => ConfirmBookingScreen(
      eleccion: eleccion,
      reservas: bookings,
      pendiente: pending,
      sesion: session,
    ),
    _ => const SizedBox.shrink(),
  };

  List<RouteBase> _bookingRoutes() => [
    GoRoute(
      path: '/reservas',
      pageBuilder: (context, state) => rootPage(
        context,
        state,
        MyBookingsScreen(
          reservas: bookings,
          espacios: spaces,
          sesion: session,
          reservaId: state.uri.queryParameters['reserva'],
          enHistorial: state.uri.queryParameters['historial'] == '1',
        ),
      ),
      routes: [
        _changeBookingRoute(),
        GoRoute(
          path: 'confirmada',
          redirect: (context, state) =>
              state.extra is Booking ? null : '/reservas',
          pageBuilder: (context, state) => resultPage(
            context,
            state,
            switch (state.extra) {
              final Booking reserva => BookingConfirmedScreen(reserva: reserva),
              _ => const SizedBox.shrink(),
            },
          ),
        ),
      ],
    ),
    // La reserva que quedó pendiente cuando venció la sesión, al volver a entrar.
    GoRoute(
      path: '/reservar',
      redirect: (context, state) =>
          state.extra is BookingChoice ? null : '/inicio',
      pageBuilder: (context, state) =>
          forwardPage(context, state, _confirmBooking(state)),
    ),
  ];

  GoRoute _changeBookingRoute() => GoRoute(
    path: ':reserva/modificar',
    // La confirmación está anidada acá y trae su propio extra.
    redirect: (context, state) => switch (state.extra) {
      Booking() || (Booking(), BookingChoice()) => null,
      _ => '/reservas',
    },
    pageBuilder: (context, state) =>
        forwardPage(context, state, switch (state.extra) {
          final Booking reserva => AvailabilityScreen(
            sedeId: reserva.venueId,
            espacioId: reserva.spaceId,
            venues: venues,
            espacios: spaces,
            horarios: availability,
            sesion: session,
            modificando: reserva,
            volverA: state.uri.queryParameters['desde'] == 'inicio'
                ? AppLocalizations.of(context).homeBackLabel
                : AppLocalizations.of(context).accountMyBookings,
          ),
          _ => const SizedBox.shrink(),
        }),
    routes: [
      GoRoute(
        path: 'confirmar',
        redirect: (context, state) =>
            state.extra is (Booking, BookingChoice) ? null : '/reservas',
        pageBuilder: (context, state) =>
            forwardPage(context, state, switch (state.extra) {
              (final Booking reserva, final BookingChoice eleccion) =>
                ConfirmChangeScreen(
                  reserva: reserva,
                  eleccion: eleccion,
                  reservas: bookings,
                  sesion: session,
                ),
              _ => const SizedBox.shrink(),
            }),
      ),
    ],
  );

  List<RouteBase> _adminRoutes() => [
    ..._adminBookingRoutes(),
    GoRoute(
      path: '/admin/acceso-denegado',
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
          path: 'reserva/:id',
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
      path: '/admin/sedes',
      pageBuilder: (context, state) => rootPage(
        context,
        state,
        AdminVenuesScreen(venues: venues, session: session),
      ),
      routes: [
        GoRoute(
          path: 'nueva',
          pageBuilder: (context, state) => forwardPage(
            context,
            state,
            VenueFormScreen(venues: venues, session: session),
          ),
        ),
        GoRoute(
          path: ':sede/editar',
          // Sin la sede que se tocó en el listado (un enlace, la app reabierta), vuelve al
          // listado.
          redirect: (context, state) =>
              state.extra is Venue ? null : '/admin/sedes',
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
          path: 'creada',
          // Sin la sede recién guardada (un enlace, la app reabierta) no hay éxito que
          // mostrar: va al listado, donde está.
          redirect: (context, state) =>
              state.extra is Venue ? null : '/admin/sedes',
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
      path: '/admin/espacios',
      pageBuilder: (context, state) => rootPage(
        context,
        state,
        AdminSpacesScreen(spaces: spaces, session: session),
      ),
      routes: [
        GoRoute(
          path: ':espacio/editar',
          // Sin el espacio que se tocó en el listado (un enlace, la app reabierta), vuelve
          // al listado.
          redirect: (context, state) =>
              state.extra is Space ? null : '/admin/espacios',
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
          path: 'nuevo',
          pageBuilder: (context, state) => forwardPage(
            context,
            state,
            NewSpaceScreen(spaces: spaces, venues: venues, session: session),
          ),
        ),
        GoRoute(
          path: 'creado',
          // Sin el espacio recién guardado no hay éxito que mostrar: va al listado.
          redirect: (context, state) =>
              state.extra is Space ? null : '/admin/espacios',
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
