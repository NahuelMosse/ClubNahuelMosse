import 'dart:async';

import 'package:flutter/widgets.dart';

import '../comun/errores_no_manejados.dart';
import '../sesion/sesion.dart';
import 'notificacion.dart';
import 'notificaciones.dart';
import 'sistema.dart';

/// El estado de las notificaciones de la app: la lista, cuántas hay sin leer, el permiso del
/// sistema y el panel que avisa con la app abierta.
///
/// Sólo actúa mientras hay un usuario con la sesión iniciada: registra el teléfono en la API,
/// consulta el centro cada [cada] mientras la app se ve, y baja el teléfono antes de cerrar la
/// sesión.
class CentroDeNotificaciones extends ChangeNotifier {
  CentroDeNotificaciones({
    required Notificaciones notificaciones,
    required Sesion sesion,
    required SistemaDeNotificaciones sistema,
    this.cada = const Duration(seconds: 20),
    this.ahora = DateTime.now,
  }) : _repositorio = notificaciones,
       _sesion = sesion,
       _sistema = sistema {
    _sesion.addListener(_alCambiarLaSesion);
    _sesion.alCerrar.add(_darDeBajaElDispositivo);
    _sesion.alSalir.add(_olvidarElToken);
    _suscripcion = _sistema.alLlegar.listen((_) => _sondear());
    _ciclo = AppLifecycleListener(onStateChange: _alCambiarElCiclo);
    _alCambiarLaSesion();
  }

  final Notificaciones _repositorio;
  final Sesion _sesion;
  final SistemaDeNotificaciones _sistema;

  /// Cada cuánto se consulta la API mientras la app está abierta; cero, nunca.
  final Duration cada;

  /// El reloj del teléfono, para saber qué llegó mientras la app arrancaba.
  final DateTime Function() ahora;

  StreamSubscription<void>? _suscripcion;
  late final AppLifecycleListener _ciclo;
  Timer? _reloj;
  bool _activo = false;
  bool _liberado = false;

  /// La app no se ve (en segundo plano): no se consulta hasta que vuelva.
  bool _oculta = false;

  /// Sube con cada arranque y cierre de sesión: la respuesta de una sesión anterior se
  /// descarta.
  int _sesionActual = 0;
  bool _leyoAlguna = false;
  int _ultimoPresentado = 0;

  /// Desde cuándo una notificación sin leer cuenta como recién llegada en la primera lectura:
  /// una que llegó mientras la app arrancaba avisa; una de hace días queda en la campana.
  DateTime _desde = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  /// Las que el panel ya mostró en esta sesión.
  final _avisadas = <int>{};

  /// Confirmaciones de cancelación que llegaron con la persona en Mis reservas, donde ya vio
  /// el mensaje de éxito: siguen sin leer, pero el panel no las muestra.
  final _silenciadas = <int>{};

  /// La ruta en la que está la persona; la app la conecta al enrutador.
  String Function() ubicacion = _sinUbicacion;

  static String _sinUbicacion() => '';

  List<Notificacion> _lista = const [];
  int _noLeidas = 0;
  bool _permitido = true;
  bool _panelAbierto = false;

  /// De la más nueva a la más vieja.
  List<Notificacion> get lista => _lista;

  /// Cuántas hay sin leer en total, según la API.
  int get noLeidas => _noLeidas;

  /// Si el sistema operativo dejó al teléfono mostrar notificaciones.
  bool get permitido => _permitido;

  /// Si ya se leyó el centro alguna vez en esta sesión.
  bool get cargado => _leyoAlguna;

  /// Las sin leer, que es lo que muestra el panel.
  List<Notificacion> get sinLeer => [
    for (final n in _lista)
      if (!n.leida) n,
  ];

  /// Las sin leer que el panel puede mostrar.
  List<Notificacion> get enElPanel => [
    for (final n in sinLeer)
      if (!_silenciadas.contains(n.id)) n,
  ];

  /// El panel se muestra con la app abierta cuando llega una notificación nueva y el sistema
  /// dejó mostrarlas.
  bool get panelAbierto => _panelAbierto && enElPanel.isNotEmpty;

  /// La persona tocó un aviso de la bandeja del sistema.
  Stream<AvisoTocado> get alTocarDesdeElSistema => _sistema.alTocar;

  Future<AvisoTocado?> abiertaPor() => _sistema.abiertaPor();

  void _alCambiarLaSesion() {
    final esUsuario = _sesion.perfil?.rol == Rol.usuario;
    if (esUsuario && !_activo) {
      unawaited(_arrancar());
    } else if (!esUsuario && _activo) {
      _detener();
    }
  }

  Future<void> _arrancar() async {
    _activo = true;
    final sesion = ++_sesionActual;
    _desde = enDelClub(ahora()).subtract(const Duration(minutes: 5));
    if (!await _sistema.preguntado()) await _sistema.solicitarPermiso();
    if (_liberado || sesion != _sesionActual) return;
    await _revisarPermiso(registrar: true);
    if (_liberado || sesion != _sesionActual) return;
    await _sondear();
    if (_liberado || sesion != _sesionActual) return;
    _programar();
  }

  /// Arranca la consulta periódica, si la app se ve y hay cada cuánto.
  void _programar() {
    _reloj?.cancel();
    _reloj = null;
    if (cada > Duration.zero && !_oculta && _activo && !_liberado) {
      _reloj = Timer.periodic(cada, (_) => unawaited(_sondear()));
    }
  }

  /// Mientras la app no se ve no se consulta; al volver se lee enseguida, porque pudo haber
  /// llegado cualquier cosa.
  void _alCambiarElCiclo(AppLifecycleState estado) {
    if (estado == AppLifecycleState.hidden ||
        estado == AppLifecycleState.paused) {
      _oculta = true;
      _reloj?.cancel();
      _reloj = null;
    } else if (estado == AppLifecycleState.resumed && _oculta) {
      _oculta = false;
      if (_activo && !_liberado) {
        _programar();
        unawaited(_sondear());
      }
    }
  }

  void _detener() {
    _activo = false;
    _sesionActual++;
    _reloj?.cancel();
    _reloj = null;
    _lista = const [];
    _noLeidas = 0;
    _leyoAlguna = false;
    _ultimoPresentado = 0;
    _avisadas.clear();
    _silenciadas.clear();
    _panelAbierto = false;
    notifyListeners();
  }

  /// Vuelve a preguntar el permiso al sistema y, si cambió, se lo cuenta a la API.
  Future<void> _revisarPermiso({bool registrar = false}) async {
    final ahora = await _sistema.permitido();
    if (ahora == _permitido && !registrar) return;
    // Primero se le cuenta a la API y recién entonces cambia lo que se ve: la pantalla no dice
    // «activadas» mientras la API todavía cree que el teléfono no tiene permiso.
    try {
      final token = await _sistema.token();
      if (token != null) {
        await _repositorio.registrarDispositivo(
          token: token,
          plataforma: _sistema.plataforma,
          permiso: ahora,
        );
      }
    } on Exception catch (e, pila) {
      // Sin red el registro queda para la próxima vez que cambie el permiso o se abra la app.
      registrarError(e, pila);
    }
    _permitido = ahora;
    notifyListeners();
  }

  /// Lee el centro. Lanza [SesionVencida], [SinConexion] o [ErrorDelServidor].
  Future<void> cargar() async {
    final sesion = _sesionActual;
    await _revisarPermiso();
    final lectura = await _repositorio.centro();
    if (_liberado || sesion != _sesionActual) return;
    _aplicar(lectura);
  }

  /// La lectura periódica: si falla, queda lo que había.
  Future<void> _sondear() async {
    if (!_activo || _liberado) return;
    try {
      await cargar();
    } on Exception catch (e, pila) {
      // Sin red o con la API caída el panel sólo se entera después.
      registrarError(e, pila);
    }
  }

  void _aplicar(LecturaDelCentro lectura) {
    _lista = lectura.notificaciones;
    _noLeidas = lectura.noLeidas;
    final masNueva = _lista.fold<int>(0, (m, n) => n.id > m ? n.id : m);
    if (ubicacion() == '/reservas') {
      _silenciadas.addAll([
        for (final n in _lista)
          if (!n.leida &&
              n.tipo == TipoDeNotificacion.cancelacionUsuario &&
              n.id > _ultimoPresentado)
            n.id,
      ]);
    }
    final llegoUnaNueva = _lista.any(
      (n) =>
          !n.leida &&
          !_silenciadas.contains(n.id) &&
          n.id > _ultimoPresentado &&
          (_leyoAlguna || n.creada.isAfter(_desde)),
    );
    // Si la persona cerró el panel sin leer, lo que llegue después suma a la campana y no
    // vuelve a tapar la pantalla.
    final quedanAvisadas = _lista.any(
      (n) => !n.leida && _avisadas.contains(n.id),
    );
    if (llegoUnaNueva && !quedanAvisadas && _permitido) {
      _panelAbierto = true;
      _avisadas.addAll(enElPanel.map((n) => n.id));
    }
    if (masNueva > _ultimoPresentado) _ultimoPresentado = masNueva;
    _leyoAlguna = true;
    notifyListeners();
  }

  void cerrarPanel() {
    if (!_panelAbierto) return;
    _panelAbierto = false;
    notifyListeners();
  }

  /// Marca [n] como leída; si la API no contesta, la próxima lectura lo corrige.
  Future<void> marcarLeida(Notificacion n) async {
    if (!n.leida) {
      _lista = [for (final x in _lista) x.id == n.id ? x.comoLeida() : x];
      _noLeidas = _noLeidas > 0 ? _noLeidas - 1 : 0;
    }
    _panelAbierto = false;
    notifyListeners();
    try {
      await _repositorio.leer(n.id);
    } on Exception catch (e, pila) {
      registrarError(e, pila);
      unawaited(_sondear());
    }
  }

  Future<void> marcarTodas() async {
    _lista = [for (final n in _lista) n.comoLeida()];
    _noLeidas = 0;
    _panelAbierto = false;
    notifyListeners();
    try {
      await _repositorio.leerTodas();
    } on Exception catch (e, pila) {
      registrarError(e, pila);
      unawaited(_sondear());
    }
  }

  /// Pide el permiso al sistema operativo. Si lo concede, registra el teléfono con permiso.
  Future<bool> activar() async {
    final concedido = await _sistema.solicitarPermiso();
    await _revisarPermiso(registrar: true);
    return concedido;
  }

  /// Al cerrar la sesión: este teléfono deja de recibir los avisos de la cuenta, con el token
  /// de la sesión que se cierra.
  Future<void> _darDeBajaElDispositivo(String sesion) async {
    if (!_activo) return;
    final token = await _sistema.token();
    if (token != null) {
      await _repositorio.darDeBajaDispositivo(token, sesion: sesion);
    }
  }

  /// Sea cual sea la forma de salir —cerrar, una sesión que ya no vale, una baja de cuenta—,
  /// el token del teléfono se borra: aunque la API no se entere, lo que mande deja de llegar.
  Future<void> _olvidarElToken() => _sistema.olvidarToken();

  @override
  void notifyListeners() {
    if (!_liberado) super.notifyListeners();
  }

  @override
  void dispose() {
    _liberado = true;
    _activo = false;
    _sesionActual++;
    _sesion.removeListener(_alCambiarLaSesion);
    _sesion.alCerrar.remove(_darDeBajaElDispositivo);
    _sesion.alSalir.remove(_olvidarElToken);
    _ciclo.dispose();
    unawaited(_suscripcion?.cancel());
    _reloj?.cancel();
    super.dispose();
  }
}
