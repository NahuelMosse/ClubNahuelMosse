// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../common/unhandled_errors.dart';
import '../../session/domain/role.dart';
import '../../session/domain/session_exceptions.dart';
import '../../session/presentation/session.dart';
import '../data/notifications_repository.dart';
import '../domain/app_notification.dart';
import '../domain/center_reading.dart';
import '../domain/notification_kind.dart';
import '../domain/notification_system.dart';

/// The state of the app's notifications: the list, how many are unread, the system's
/// permission and the panel that reports with the app open.
///
/// It only acts while there is a signed-in user: it registers the phone in the API,
/// queries the center every [every] while the app is visible, and unregisters the phone
/// before closing the session.
class NotificationCenter extends ChangeNotifier {
  NotificationCenter({
    required NotificationsRepository notifications,
    required Session session,
    required this.system,
    this.every = const Duration(seconds: 20),
    this.now = DateTime.now,
  }) : _repository = notifications,
       _session = session {
    _session.addListener(_onSessionChanged);
    _session.onClose.add(_unregisterDevice);
    _session.onExit.add(_forgetToken);
    _subscription = system.onArrive.listen((_) => _poll());
    _lifecycle = AppLifecycleListener(onStateChange: _onLifecycleChanged);
    _onSessionChanged();
  }

  final NotificationsRepository _repository;
  final Session _session;

  /// The notification system of the phone.
  final NotificationSystem system;

  /// How often the API is queried while the app is open; zero, never.
  final Duration every;

  /// The phone's clock, to know what arrived while the app was starting.
  final DateTime Function() now;

  StreamSubscription<void>? _subscription;
  late final AppLifecycleListener _lifecycle;
  Timer? _clock;
  bool _active = false;
  bool _disposed = false;

  /// The app is not visible (in the background): no query until it comes back.
  bool _hidden = false;

  /// Goes up with each start and sign-out: the response of a previous session is
  /// discarded.
  int _currentSession = 0;
  bool _readAny = false;

  /// The ones that already arrived in some read of this session: only one that is not
  /// here is new.
  final _seen = <String>{};

  /// Since when an unread notification counts as just arrived in the first read: one that
  /// arrived while the app was starting is announced; one from days ago stays in the
  /// bell.
  DateTime _since = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  /// The ones the panel already showed in this session.
  final _announced = <String>{};

  /// Cancellation confirmations that arrived while the person was in «Mis reservas»,
  /// where they already saw the success message: they stay unread, but the panel does not
  /// show them.
  final _silenced = <String>{};

  /// The route the person is on; the app connects it to the router.
  String Function() location = _noLocation;

  static String _noLocation() => '';

  List<AppNotification> _list = const [];
  int _unread = 0;
  bool _allowed = true;
  bool _panelOpen = false;

  /// From newest to oldest.
  List<AppNotification> get list => _list;

  /// How many are unread in total, according to the API.
  int get unread => _unread;

  /// Whether the operating system let the phone show notifications.
  bool get allowed => _allowed;

  /// Whether the center was already read at some point in this session.
  bool get loaded => _readAny;

  /// The unread ones, which is what the panel shows.
  List<AppNotification> get unreadList => [
    for (final n in _list)
      if (!n.read) n,
  ];

  /// The unread ones the panel can show.
  List<AppNotification> get inPanel => [
    for (final n in unreadList)
      if (!_silenced.contains(n.id)) n,
  ];

  /// The panel is shown with the app open when a new notification arrives and the system
  /// allowed showing them.
  bool get panelOpen => _panelOpen && inPanel.isNotEmpty;

  /// The person tapped a notice in the system tray.
  Stream<NoticeTapped> get onSystemTap => system.onTap;

  void _onSessionChanged() {
    final isUser = _session.profile?.role == Role.user;
    if (isUser && !_active) {
      unawaited(_start());
    } else if (!isUser && _active) {
      _stop();
    }
  }

  Future<void> _start() async {
    _active = true;
    final session = ++_currentSession;
    _since = inClubTime(now()).subtract(const Duration(minutes: 5));
    if (!await system.wasAsked()) await system.requestPermission();
    if (_disposed || session != _currentSession) return;
    await _checkPermission(register: true);
    if (_disposed || session != _currentSession) return;
    await _poll();
    if (_disposed || session != _currentSession) return;
    _schedule();
  }

  /// Starts the periodic query, if the app is visible and an interval is given.
  void _schedule() {
    _clock?.cancel();
    _clock = null;
    if (every > Duration.zero && !_hidden && _active && !_disposed) {
      _clock = Timer.periodic(every, (_) => unawaited(_poll()));
    }
  }

  /// While the app is not visible nothing is queried; on return it reads at once, because
  /// anything may have arrived.
  void _onLifecycleChanged(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      _hidden = true;
      _clock?.cancel();
      _clock = null;
    } else if (state == AppLifecycleState.resumed && _hidden) {
      _hidden = false;
      if (_active && !_disposed) {
        _schedule();
        unawaited(_poll());
      }
    }
  }

  void _stop() {
    _active = false;
    _currentSession++;
    _clock?.cancel();
    _clock = null;
    _list = const [];
    _unread = 0;
    _readAny = false;
    _seen.clear();
    _announced.clear();
    _silenced.clear();
    _panelOpen = false;
    notifyListeners();
  }

  /// Asks the system for the permission again and, if it changed, tells the API.
  Future<void> _checkPermission({bool register = false}) async {
    final allowed = await system.isAllowed();
    if (allowed == _allowed && !register) return;
    // The API is told first and only then does what is seen change: the screen does not
    // say «activadas» while the API still believes the phone has no permission.
    try {
      final token = await system.token();
      if (token != null) {
        await _repository.registerDevice(
          token: token,
          platform: system.platform,
          permission: allowed,
        );
      }
    } on Exception catch (e, stack) {
      // Without network the registration waits for the next time the permission changes
      // or the app is opened.
      logError(e, stack);
    }
    _allowed = allowed;
    notifyListeners();
  }

  /// Reads the center. Throws [SessionExpired], [NoConnection] or [ServerError].
  Future<void> load() async {
    final session = _currentSession;
    await _checkPermission();
    final reading = await _repository.center();
    if (_disposed || session != _currentSession) return;
    _apply(reading);
  }

  /// The periodic read: if it fails, what there was stays.
  Future<void> _poll() async {
    if (!_active || _disposed) return;
    try {
      await load();
    } on Exception catch (e, stack) {
      // Without network or with the API down the panel only finds out later.
      logError(e, stack);
    }
  }

  void _apply(CenterReading reading) {
    _list = reading.notifications;
    _unread = reading.unread;
    if (location() == '/bookings') {
      _silenced.addAll([
        for (final n in _list)
          if (!n.read &&
              n.kind == NotificationKind.userCancellation &&
              !_seen.contains(n.id))
            n.id,
      ]);
    }
    final arrivedNew = _list.any(
      (n) =>
          !n.read &&
          !_silenced.contains(n.id) &&
          !_seen.contains(n.id) &&
          (_readAny || n.createdAt.isAfter(_since)),
    );
    // If the person closed the panel without reading, what arrives afterwards adds to the
    // bell and does not cover the screen again.
    final stillAnnounced = _list.any(
      (n) => !n.read && _announced.contains(n.id),
    );
    if (arrivedNew && !stillAnnounced && _allowed) {
      _panelOpen = true;
      _announced.addAll(inPanel.map((n) => n.id));
    }
    _seen.addAll(_list.map((n) => n.id));
    _readAny = true;
    notifyListeners();
  }

  void closePanel() {
    if (!_panelOpen) return;
    _panelOpen = false;
    notifyListeners();
  }

  /// Marks [n] as read; if the API does not answer, the next read corrects it.
  Future<void> markRead(AppNotification n) async {
    if (!n.read) {
      _list = [for (final x in _list) x.id == n.id ? x.markedRead() : x];
      _unread = _unread > 0 ? _unread - 1 : 0;
    }
    _panelOpen = false;
    notifyListeners();
    try {
      await _repository.read(n.id);
    } on Exception catch (e, stack) {
      logError(e, stack);
      unawaited(_poll());
    }
  }

  /// The person tapped a notice in the tray: the unread ones of the same type and booking
  /// become read. The center is read again first, because the notice may have arrived
  /// with the app closed.
  Future<void> markNoticeRead(NoticeTapped notice) async {
    if (notice.kind == null || notice.bookingId == null) return;
    await _poll();
    final ofNotice = [
      for (final n in unreadList)
        if (n.kind == notice.kind && n.bookingId == notice.bookingId) n,
    ];
    await Future.wait(ofNotice.map(markRead));
  }

  Future<void> markAll() async {
    _list = [for (final n in _list) n.markedRead()];
    _unread = 0;
    _panelOpen = false;
    notifyListeners();
    try {
      await _repository.readAll();
    } on Exception catch (e, stack) {
      logError(e, stack);
      unawaited(_poll());
    }
  }

  /// Asks the operating system for the permission. If granted, registers the phone with
  /// permission.
  Future<bool> enable() async {
    final granted = await system.requestPermission();
    await _checkPermission(register: true);
    return granted;
  }

  /// On signing out: this phone stops receiving the account's notices, with the token of
  /// the session being closed.
  Future<void> _unregisterDevice(String session) async {
    if (!_active) return;
    final token = await system.token();
    if (token != null) {
      await _repository.unregisterDevice(token, session: session);
    }
  }

  /// However the exit happens —sign-out, a session that no longer applies, an account
  /// deletion—, the phone's token is deleted: even if the API does not find out, what it
  /// sends stops arriving.
  Future<void> _forgetToken() => system.forgetToken();

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _active = false;
    _currentSession++;
    _session.removeListener(_onSessionChanged);
    _session.onClose.remove(_unregisterDevice);
    _session.onExit.remove(_forgetToken);
    _lifecycle.dispose();
    unawaited(_subscription?.cancel());
    _clock?.cancel();
    super.dispose();
  }
}
