import 'package:flutter/material.dart';

import '../comun/boton.dart';
import '../espacios/espacio.dart';
import '../tema/tokens.dart';
import 'cargando_reservas_admin.dart';
import 'historial_reservas.dart';
import 'lista_de_reservas_admin.dart';
import 'reservas_vacias_admin.dart';

/// Lo que va debajo del encabezado del panel: cargando, el reintento, el listado o que no
/// hay reservas, y el indicador de la página que se está pidiendo.
List<Widget> cuerpoDelPanelAdmin({
  required PaginaDeHistorial? resultado,
  required bool fallo,
  required bool cargandoMas,
  required bool hayFiltros,
  required List<ReservaHistorial> reservas,
  required Catalogo? catalogo,
  required VoidCallback alReintentar,
  required VoidCallback alLimpiarFiltros,
  required void Function(ReservaHistorial) alTocar,
  required void Function(ReservaHistorial)? alAnular,
}) {
  return [
    if (resultado == null && !fallo) const CargandoReservasAdmin(),
    if (resultado == null && fallo)
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(Medidas.s24),
          child: Center(
            child: BotonTexto(texto: 'REINTENTAR', alTocar: alReintentar),
          ),
        ),
      ),
    if (resultado != null && resultado.total == 0)
      ReservasVaciasAdmin(
        hayFiltros: hayFiltros,
        alLimpiarFiltros: alLimpiarFiltros,
      ),
    if (resultado != null && resultado.total > 0)
      ListaDeReservasAdmin(
        reservas: reservas,
        catalogo: catalogo,
        alTocar: alTocar,
        alAnular: alAnular,
      ),
    if (cargandoMas)
      const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: Medidas.s16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
  ];
}
