import 'package:flutter/material.dart';

import '../espacios/espacio.dart';
import '../tema/tokens.dart';
import 'historial_reservas.dart';
import 'tarjeta_reserva_admin.dart';

/// El sliver con las tarjetas de las reservas cargadas. [alAnular] en `null` deshabilita
/// ANULAR RESERVA en todas.
class ListaDeReservasAdmin extends StatelessWidget {
  const ListaDeReservasAdmin({
    super.key,
    required this.reservas,
    required this.catalogo,
    required this.alTocar,
    required this.alAnular,
  });

  final List<ReservaHistorial> reservas;
  final Catalogo? catalogo;
  final ValueChanged<ReservaHistorial> alTocar;
  final ValueChanged<ReservaHistorial>? alAnular;

  @override
  Widget build(BuildContext context) {
    final anular = alAnular;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        Medidas.s24,
        0,
        Medidas.s24,
        Medidas.s40,
      ),
      sliver: SliverList.builder(
        itemCount: reservas.length,
        itemBuilder: (context, i) {
          final r = reservas[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: Medidas.s12),
            child: TarjetaReservaAdmin(
              reserva: r,
              catalogo: catalogo,
              alTocar: () => alTocar(r),
              alAnular: anular == null ? null : () => anular(r),
            ),
          );
        },
      ),
    );
  }
}
