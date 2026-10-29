// kit-shape: a screen or error family kept with its private parts.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'api/api_client.dart';
import 'common/app_language.dart';
import 'common/appearance.dart';
import 'common/pending_booking.dart';
import 'features/admin/data/booking_history_api.dart';
import 'features/admin/domain/pending_panel_filters.dart';
import 'features/bookings/data/availability_api.dart';
import 'features/bookings/data/bookings_api.dart';
import 'features/bookings/domain/booking_choice.dart';
import 'features/bookings/presentation/bookings.dart';
import 'features/notifications/domain/app_notification.dart';
import 'features/notifications/domain/notification_system.dart';
import 'features/notifications/presentation/notice_panel.dart';
import 'features/notifications/presentation/notification_center.dart';
import 'features/session/data/password_recovery.dart';
import 'features/session/presentation/session.dart';
import 'features/spaces/data/spaces_repository.dart';
import 'features/spaces/presentation/spaces.dart';
import 'features/venues/data/venues_repository.dart';
import 'features/venues/presentation/venues.dart';
import 'l10n/app_localizations.dart';
import 'router.dart';
import 'theme/theme.dart';

class App extends StatefulWidget {
  const App({
    super.key,
    required this.api,
    required this.session,
    required this.appearance,
    this.notificationCenter,
    this.initialLocation = '/',
  });

  final ApiClient api;
  final Session session;
  final Appearance appearance;

  /// The app's notifications. Without it there is no bell, no panel and no center to query.
  final NotificationCenter? notificationCenter;

  /// Where the app starts: the login, or the home of whoever already had the session open.
  final String initialLocation;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final _recovery = PasswordRecovery(widget.api);
  late final _venues = Venues(
    repository: VenuesRepository(api: widget.api, session: widget.session),
  );
  late final _spaces = Spaces(
    repository: SpacesRepository(api: widget.api, session: widget.session),
  );
  late final _availability = AvailabilityApi(
    api: widget.api,
    sesion: widget.session,
  );
  late final _bookings = Bookings(
    BookingsApi(api: widget.api, sesion: widget.session),
  );
  late final _adminHistory = BookingHistory(
    api: widget.api,
    sesion: widget.session,
  );
  final _pending = PendingBooking<BookingChoice>();
  final _pendingFilters = PendingPanelFilters();

  StreamSubscription<NoticeTapped>? _onNotificationTapped;

  /// The app's navigator, to open the notifications panel from above the `Navigator`.
  final _navigator = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    final center = widget.notificationCenter;
    if (center == null) return;
    center.location = () =>
        _router.routerDelegate.currentConfiguration.uri.path;
    // A notification from the system tray opens the app on the booking it is about.
    _onNotificationTapped = center.onSystemTap.listen((notification) {
      unawaited(center.markNoticeRead(notification));
      _router.go(notification.route);
    });
    unawaited(
      center.system.openedBy().then((notification) {
        if (notification != null) {
          unawaited(center.markNoticeRead(notification));
          _router.go(notification.route);
        }
      }),
    );
  }

  late final GoRouter _router = AppRouter(
    api: () => widget.api,
    session: () => widget.session,
    appearance: () => widget.appearance,
    center: () => widget.notificationCenter,
    recovery: _recovery,
    venues: _venues,
    spaces: _spaces,
    availability: _availability,
    bookings: _bookings,
    adminHistory: _adminHistory,
    pending: _pending,
    pendingFilters: _pendingFilters,
  ).router(navigatorKey: _navigator, initialLocation: widget.initialLocation);

  @override
  void dispose() {
    unawaited(_onNotificationTapped?.cancel());
    widget.notificationCenter?.dispose();
    widget.api.cerrar();
    _venues.dispose();
    _spaces.dispose();
    _bookings.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appearance,
      builder: (context, _) => MaterialApp.router(
        onGenerateTitle: (context) => AppLocalizations.of(context).appName,
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: widget.appearance.mode,
        routerConfig: _router,
        builder: (context, child) {
          // Dates and days are written in the language the device resolved to.
          useLanguage(Localizations.localeOf(context));
          return Stack(
            children: [
              child ?? const SizedBox.shrink(),
              if (widget.notificationCenter case final center?)
                NoticePanel(
                  center: center,
                  navigator: _navigator,
                  onOpen: (n) {
                    center.markRead(n);
                    _router.go(noticeRoute(n.kind, n.bookingId));
                  },
                ),
            ],
          );
        },
        localeListResolutionCallback: resolveLanguage,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
      ),
    );
  }
}
