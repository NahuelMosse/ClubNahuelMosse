import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../comun/movimiento.dart';
import '../tema/tokens.dart';
import 'acceso_de_inicio.dart';
import 'animacion_de_tiles.dart';
import 'titulo_de_inicio.dart';

/// ACCESOS RÁPIDOS: buscar una cancha o recorrer las sedes.
class AccesosDeInicio extends StatelessWidget {
  const AccesosDeInicio({
    super.key,
    required this.primero,
    required this.yaEntro,
  });

  /// Cuándo entra el primer acceso; el otro, un paso después.
  final Duration primero;
  final bool yaEntro;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      Medidas.s24,
      Medidas.s32,
      Medidas.s24,
      Medidas.s40,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TituloDeInicio('ACCESOS RÁPIDOS'),
        const SizedBox(height: Medidas.s12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Aparecer(
                  retraso: primero,
                  yaEntro: yaEntro,
                  child: AccesoDeInicio(
                    icono: Icons.search_rounded,
                    titulo: 'Buscar cancha',
                    texto: 'Por sede, fecha y horario',
                    alTocar: () => context.go('/inicio/buscar'),
                  ),
                ),
              ),
              const SizedBox(width: Medidas.s12),
              Expanded(
                child: Aparecer(
                  retraso: primero + pasoDeTiles,
                  yaEntro: yaEntro,
                  child: AccesoDeInicio(
                    icono: Icons.location_on_outlined,
                    titulo: 'Ver sedes',
                    texto: 'Horarios y canchas de cada una',
                    alTocar: () => context.go('/sedes'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
