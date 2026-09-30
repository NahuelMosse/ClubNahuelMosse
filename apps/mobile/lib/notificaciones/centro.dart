import 'dart:async';

import 'package:flutter/foundation.dart';

import '../sesion/sesion.dart';
import 'notificacion.dart';
import 'notificaciones.dart';
import 'sistema.dart';

/// El estado de las notificaciones de la app: la lista, cuántas hay sin leer, el permiso del
/// sistema y el panel que avisa con la app abierta.
///
/// Sólo actúa mientras hay un usuario con la sesión iniciada: registra el teléfono en la API,
/// consulta el centro cada [cada] y baja el teléfono antes de cerrar la sesión.
class CentroDeNotificaciones extends ChangeNotifier {
  CentroDeNotificaciones({
    required Notificaciones notificaciones,
    required Sesion sesion,
    required SistemaDeNotificaciones sistema,
    this.cada = const Duration(seconds: 20),
  }) : _repositorio = notificaciones,
       _sesion = sesion,
       _sistema = sistema {
    _sesion.addListener(_alCambiarLaSesion);
    _sesion.alCerrar.add(_darDeBajaElDispositivo);
    _suscripcion = _sistema.alLlegar.listen((_) => _sondear());
    _alCambiarLaSesion();
  }

  final Notificaciones _repositorio;
  final Sesion _sesion;
  final SistemaDeNotificaciones _sistema;

  /// Cada cuánto se consulta la API mientras la app está abierta; cero, nunca.
  final Duration cada;

  StreamSubscription<int?>? _suscripcion;
  Timer? _reloj;
  bool _activo = false;

  /// Sube con cada arranque y cierre de sesión: la respuesta de una sesión anterior se
  /// descarta.
  int _sesionActual = 0;
  bool _leyoAlguna = false;
  int _ultimoPresentado = 0;

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

  /// El panel se muestra con la app abierta cuando llega una notificación nueva y el sistema
  /// dejó mostrarlas.
  bool get panelAbierto => _panelAbierto && sinLeer.isNotEmpty;

  /// La persona tocó un aviso de la bandeja del sistema.
  Stream<int?> get alTocarDesdeElSistema => _sistema.alTocar;

  Future<int?> abiertaPor() => _sistema.abiertaPor();

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
    await _revisarPermiso(registrar: true);
    if (sesion != _sesionActual) return;
    await _sondear();
    if (sesion != _sesionActual) return;
    if (cada > Duration.zero) {
      _reloj = Timer.periodic(cada, (_) => unawaited(_sondear()));
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
    _panelAbierto = false;
    notifyListeners();
  }

  /// Vuelve a preguntar el permiso al sistema y, si cambió, se lo cuenta a la API.
  Future<void> _revisarPermiso({bool registrar = false}) async {
    final ahora = await _sistema.permitido();
    if (ahora == _permitido && !registrar) return;
    _permitido = ahora;
    notifyListeners();
    try {
      final token = await _sistema.token();
      if (token != null) {
        await _repositorio.registrarDispositivo(
          token: token,
          plataforma: _sistema.plataforma,
          permiso: ahora,
        );
      }
    } on Exception {
      // Sin red el registro queda para la próxima vez que cambie el permiso o se abra la app.
    }
  }

  /// Lee el centro. Lanza [SesionVencida], [SinConexion] o [ErrorDelServidor].
  Future<void> cargar() async {
    final sesion = _sesionActual;
    await _revisarPermiso();
    final lectura = await _repositorio.centro();
    if (sesion != _sesionActual) return;
    _aplicar(lectura);
  }

  /// La lectura periódica: si falla, queda lo que había.
  Future<void> _sondear() async {
    if (!_activo) return;
    try {
      await cargar();
    } on Exception {
      // Sin red o con la API caída el panel sólo se entera después.
    }
  }

  void _aplicar(LecturaDelCentro lectura) {
    _lista = lectura.notificaciones;
    _noLeidas = lectura.noLeidas;
    final masNueva = _lista.fold<int>(0, (m, n) => n.id > m ? n.id : m);
    final llegoUnaNueva = _lista.any(
      (n) => !n.leida && n.id > _ultimoPresentado,
    );
    // Lo que ya estaba sin leer al abrir la app queda en la campana: sólo lo que llega con la
    // app abierta avisa con el panel.
    if (_leyoAlguna && llegoUnaNueva && _permitido) _panelAbierto = true;
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
    } on Exception {
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
    } on Exception {
      unawaited(_sondear());
    }
  }

  /// Pide el permiso al sistema operativo. Si lo concede, registra el teléfono con permiso.
  Future<bool> activar() async {
    final concedido = await _sistema.solicitarPermiso();
    await _revisarPermiso(registrar: true);
    return concedido;
  }

  /// Antes de cerrar la sesión: este teléfono deja de recibir los avisos de la cuenta.
  Future<void> _darDeBajaElDispositivo() async {
    if (!_activo) return;
    final token = await _sistema.token();
    if (token != null) await _repositorio.darDeBajaDispositivo(token);
  }

  @override
  void dispose() {
    _sesion.removeListener(_alCambiarLaSesion);
    _sesion.alCerrar.remove(_darDeBajaElDispositivo);
    unawaited(_suscripcion?.cancel());
    _reloj?.cancel();
    super.dispose();
  }
}
