import 'package:flutter/material.dart';

import '../comun/boton.dart';
import '../reservas/reservas.dart' show EstadoDeReserva;
import '../sesion/sesion.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'barra_de_pestanas_admin.dart';
import 'buscador_de_reservas.dart';
import 'historial_reservas.dart';
import 'listado_admin.dart';

/// El sliver de arriba del historial: título, buscador, pestañas por estado y el total.
class EncabezadoDeReservas extends StatelessWidget {
  const EncabezadoDeReservas({
    super.key,
    required this.sesion,
    required this.busqueda,
    required this.filtros,
    required this.resultado,
    required this.alAbrirFiltros,
    required this.alElegirEstado,
    required this.alLimpiarFiltros,
  });

  final Sesion sesion;
  final TextEditingController busqueda;
  final FiltrosDeHistorial filtros;
  final PaginaDeHistorial? resultado;
  final VoidCallback alAbrirFiltros;
  final ValueChanged<EstadoDeReserva?> alElegirEstado;
  final VoidCallback alLimpiarFiltros;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final resultado = this.resultado;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        Medidas.s24,
        Medidas.s24,
        Medidas.s16,
        0,
      ),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EncabezadoAdmin(titulo: 'Reservas', sesion: sesion),
            const SizedBox(height: Medidas.s16),
            BuscadorDeReservas(
              controlador: busqueda,
              alAbrirFiltros: alAbrirFiltros,
            ),
            const SizedBox(height: Medidas.s16),
            BarraDePestanasAdmin(
              elegido: filtros.estado,
              contadores: resultado?.contadores,
              alElegir: alElegirEstado,
            ),
            const SizedBox(height: Medidas.s12),
            if (resultado != null)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      filtros.hayFiltros
                          ? '${resultado.total} '
                                '${resultado.total == 1 ? 'RESULTADO' : 'RESULTADOS'}'
                          : '${resultado.total} '
                                '${resultado.total == 1 ? 'RESERVA EN TOTAL' : 'RESERVAS EN TOTAL'}',
                      style: Textos.sobretitulo.copyWith(color: p.textMuted),
                    ),
                  ),
                  // Con cero resultados, «Limpiar filtros» ya está en el estado
                  // vacío de abajo: no se duplica el botón.
                  if (filtros.hayFiltros && resultado.total > 0)
                    BotonTexto(
                      texto: 'LIMPIAR FILTROS',
                      alTocar: alLimpiarFiltros,
                    ),
                ],
              ),
            const SizedBox(height: Medidas.s8),
          ],
        ),
      ),
    );
  }
}
