import 'package:flutter/material.dart';

import '../api/cliente_api.dart';
import '../sesion/sesion.dart';
import 'historial_reservas.dart';

/// Las páginas del historial de reservas que se llevan cargadas. Sube un contador con cada
/// pedido: la respuesta de un filtro que ya no se mira se descarta. Avisa cada cambio.
class HistorialPaginado extends ChangeNotifier {
  HistorialPaginado(this.historial);

  final HistorialDeReservas historial;
  PaginaDeHistorial? resultado;
  final reservas = <ReservaHistorial>[];
  bool fallo = false;
  bool cargandoMas = false;
  int _pedido = 0;
  bool _cerrado = false;

  bool _obsoleto(int pedido) => _cerrado || pedido != _pedido;

  /// Si al desplazarse hay que pedir la página que sigue.
  bool get faltaCargarMas =>
      (resultado?.hayMasPaginas ?? false) && !cargandoMas && !fallo;

  @override
  void notifyListeners() {
    if (!_cerrado) super.notifyListeners();
  }

  @override
  void dispose() {
    _cerrado = true;
    super.dispose();
  }

  /// Pide la primera página de [filtros]; devuelve por qué falló, o `null` si salió bien o
  /// la respuesta ya no se mira.
  Future<({bool vencida, Object? error})?> cargar(
    FiltrosDeHistorial filtros,
  ) async {
    final pedido = ++_pedido;
    resultado = null;
    reservas.clear();
    fallo = false;
    cargandoMas = false;
    notifyListeners();
    Object? error;
    var vencida = false;
    try {
      final pagina = await historial.pagina(filtros);
      if (_obsoleto(pedido)) return null;
      resultado = pagina;
      reservas.addAll(pagina.reservas);
      notifyListeners();
      return null;
    } on SesionVencida {
      vencida = true;
    } on FalloDeRed catch (e) {
      error = e;
    }
    if (_obsoleto(pedido)) return null;
    fallo = true;
    notifyListeners();
    return (vencida: vencida, error: error);
  }

  /// Pide la página que sigue; sin red o con el servidor caído, lo que ya se cargó sigue
  /// viéndose y el desplazamiento vuelve a intentar más adelante.
  Future<void> cargarMas(FiltrosDeHistorial filtros) async {
    final actual = resultado;
    if (actual == null) return;
    final pedido = _pedido;
    cargandoMas = true;
    notifyListeners();
    PaginaDeHistorial? siguiente;
    try {
      siguiente = await historial.pagina(filtros, pagina: actual.pagina + 1);
    } on Exception {
      siguiente = null;
    }
    if (_obsoleto(pedido)) return;
    if (siguiente != null) {
      resultado = siguiente;
      // Con la paginación por OFFSET, una reserva nueva o anulada entre dos páginas
      // corre las filas: se descartan las que ya están.
      final vistas = {for (final r in reservas) r.id};
      reservas.addAll(siguiente.reservas.where((r) => vistas.add(r.id)));
    }
    cargandoMas = false;
    notifyListeners();
  }
}
