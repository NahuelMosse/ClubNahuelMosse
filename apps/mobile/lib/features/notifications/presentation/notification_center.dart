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

/// El estado de las notificaciones de la app: la lista, cuántas hay sin leer, el permiso del
/// sistema y el panel que avisa con la app abierta.
///
/// Sólo actúa mientras hay un usuario con la sesión iniciada: registra el teléfono en la API,
/// consulta el centro cada [every] mientras la app se ve, y baja el teléfono antes de cerrar la
/// sesión.
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

  /// El sistema de notificaciones del teléfono.
  final NotificationSystem system;

  /// Cada cuánto se consulta la API mientras la app está abierta; cero, nunca.
  final Duration every;

  /// El reloj del teléfono, para saber qué llegó mientras la app arrancaba.
  final DateTime Function() now;

  StreamSubscription<void>? _subscription;
  late final AppLifecycleListener _lifecycle;
  Timer? _clock;
  bool _active = false;
  bool _disposed = false;

  /// La app no se ve (en segundo plano): no se consulta hasta que vuelva.
  bool _hidden = false;

  /// Sube con cada arranque y cierre de sesión: la respuesta de una sesión anterior se
  /// descarta.
  int _currentSession = 0;
  bool _readAny = false;

  /// Las que ya llegaron en alguna lectura de esta sesión: sólo una que no está acá es nueva.
  final _seen = <String>{};

  /// Desde cuándo una notificación sin leer cuenta como recién llegada en la primera lectura:
  /// una que llegó mientras la app arrancaba avisa; una de hace días queda en la campana.
  DateTime _since = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  /// Las que el panel ya mostró en esta sesión.
  final _announced = <String>{};

  /// Confirmaciones de cancelación que llegaron con la persona en Mis reservas, donde ya vio
  /// el mensaje de éxito: siguen sin leer, pero el panel no las muestra.
  final _silenced = <String>{};

  /// La ruta en la que está la persona; la app la conecta al enrutador.
  String Function() location = _noLocation;

  static String _noLocation() => '';

  List<AppNotification> _list = const [];
  int _unread = 0;
  bool _allowed = true;
  bool _panelOpen = false;

  /// De la más nueva a la más vieja.
  List<AppNotification> get list => _list;

  /// Cuántas hay sin leer en total, según la API.
  int get unread => _unread;

  /// Si el sistema operativo dejó al teléfono mostrar notificaciones.
  bool get allowed => _allowed;

  /// Si ya se leyó el centro alguna vez en esta sesión.
  bool get loaded => _readAny;

  /// Las sin leer, que es lo que muestra el panel.
  List<AppNotification> get unreadList => [
    for (final n in _list)
      if (!n.read) n,
  ];

  /// Las sin leer que el panel puede mostrar.
  List<AppNotification> get inPanel => [
    for (final n in unreadList)
      if (!_silenced.contains(n.id)) n,
  ];

  /// El panel se muestra con la app abierta cuando llega una notificación nueva y el sistema
  /// dejó mostrarlas.
  bool get panelOpen => _panelOpen && inPanel.isNotEmpty;

  /// La persona tocó un aviso de la bandeja del sistema.
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

  /// Arranca la consulta periódica, si la app se ve y hay cada cuánto.
  void _schedule() {
    _clock?.cancel();
    _clock = null;
    if (every > Duration.zero && !_hidden && _active && !_disposed) {
      _clock = Timer.periodic(every, (_) => unawaited(_poll()));
    }
  }

  /// Mientras la app no se ve no se consulta; al volver se lee enseguida, porque pudo haber
  /// llegado cualquier cosa.
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

  /// Vuelve a preguntar el permiso al sistema y, si cambió, se lo cuenta a la API.
  Future<void> _checkPermission({bool register = false}) async {
    final allowed = await system.isAllowed();
    if (allowed == _allowed && !register) return;
    // Primero se le cuenta a la API y recién entonces cambia lo que se ve: la pantalla no dice
    // «activadas» mientras la API todavía cree que el teléfono no tiene permiso.
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
      // Sin red el registro queda para la próxima vez que cambie el permiso o se abra la app.
      logError(e, stack);
    }
    _allowed = allowed;
    notifyListeners();
  }

  /// Lee el centro. Lanza [SessionExpired], [SinConexion] o [ErrorDelServidor].
  Future<void> load() async {
    final session = _currentSession;
    await _checkPermission();
    final reading = await _repository.center();
    if (_disposed || session != _currentSession) return;
    _apply(reading);
  }

  /// La lectura periódica: si falla, queda lo que había.
  Future<void> _poll() async {
    if (!_active || _disposed) return;
    try {
      await load();
    } on Exception catch (e, stack) {
      // Sin red o con la API caída el panel sólo se entera después.
      logError(e, stack);
    }
  }

  void _apply(CenterReading reading) {
    _list = reading.notifications;
    _unread = reading.unread;
    if (location() == '/reservas') {
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
    // Si la persona cerró el panel sin leer, lo que llegue después suma a la campana y no
    // vuelve a tapar la pantalla.
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

  /// Marca [n] como leída; si la API no contesta, la próxima lectura lo corrige.
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

  /// La persona tocó un aviso de la bandeja: quedan leídas las sin leer del mismo tipo y reserva.
  /// Antes se vuelve a leer el centro, porque el aviso pudo llegar con la app cerrada.
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

  /// Pide el permiso al sistema operativo. Si lo concede, registra el teléfono con permiso.
  Future<bool> enable() async {
    final granted = await system.requestPermission();
    await _checkPermission(register: true);
    return granted;
  }

  /// Al cerrar la sesión: este teléfono deja de recibir los avisos de la cuenta, con el token
  /// de la sesión que se cierra.
  Future<void> _unregisterDevice(String session) async {
    if (!_active) return;
    final token = await system.token();
    if (token != null) {
      await _repository.unregisterDevice(token, session: session);
    }
  }

  /// Sea cual sea la forma de salir —cerrar, una sesión que ya no vale, una baja de cuenta—,
  /// el token del teléfono se borra: aunque la API no se entere, lo que mande deja de llegar.
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
