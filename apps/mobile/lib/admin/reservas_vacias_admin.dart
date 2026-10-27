import 'package:flutter/material.dart';

import '../comun/estado_vacio.dart';
import '../tema/tokens.dart';

/// El sliver del historial sin reservas: sin resultados para los filtros, o sin reservas.
class ReservasVaciasAdmin extends StatelessWidget {
  const ReservasVaciasAdmin({
    super.key,
    required this.hayFiltros,
    required this.alLimpiarFiltros,
  });

  final bool hayFiltros;
  final VoidCallback alLimpiarFiltros;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: Medidas.s24),
      sliver: SliverToBoxAdapter(
        child: hayFiltros
            ? EstadoVacio(
                titulo: 'Sin resultados',
                texto:
                    'Ninguna reserva coincide con los filtros '
                    'aplicados.',
                accion: 'LIMPIAR FILTROS',
                alTocar: alLimpiarFiltros,
              )
            : const EstadoVacio(
                titulo: 'No hay reservas',
                texto:
                    'Todavía no se registró ninguna reserva en '
                    'el sistema.',
              ),
      ),
    );
  }
}
