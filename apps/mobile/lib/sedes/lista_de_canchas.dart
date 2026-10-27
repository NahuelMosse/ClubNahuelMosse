import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../comun/estado_vacio.dart';
import '../espacios/espacio.dart';
import '../tema/tokens.dart';
import 'tarjeta_cancha.dart';

/// Las canchas de la sede, o el aviso de que no hay ninguna o ninguna pasa el filtro.
class ListaDeCanchas extends StatelessWidget {
  const ListaDeCanchas({
    super.key,
    required this.sedeId,
    required this.canchas,
    required this.todas,
    required this.catalogo,
  });

  final String sedeId;
  final List<Espacio> canchas;
  final List<Espacio> todas;
  final Catalogo catalogo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (todas.isEmpty)
          const EstadoVacio(
            titulo: 'Todavía no hay canchas',
            texto: 'Esta sede no tiene canchas disponibles por el momento.',
          )
        else if (canchas.isEmpty)
          const EstadoVacio(
            titulo: 'No hay canchas con este filtro',
            texto: 'Probá con otro deporte o con otro tipo.',
          ),
        for (final cancha in canchas) ...[
          TarjetaCancha(
            cancha: cancha,
            catalogo: catalogo,
            alReservar: () => context.go('/sedes/$sedeId/canchas/${cancha.id}'),
          ),
          const SizedBox(height: Medidas.s16),
        ],
      ],
    );
  }
}
