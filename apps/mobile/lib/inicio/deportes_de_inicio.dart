import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../comun/movimiento.dart';
import '../comun/tile_deporte.dart';
import '../espacios/espacio.dart';
import '../sedes/fotos.dart';
import '../tema/tokens.dart';
import 'animacion_de_tiles.dart';
import 'titulo_de_inicio.dart';

/// Los deportes del club. Cada uno abre «Buscar cancha» con ese deporte elegido.
class DeportesDeInicio extends StatelessWidget {
  const DeportesDeInicio({
    super.key,
    required this.catalogo,
    required this.yaEntro,
  });

  final Catalogo catalogo;
  final bool yaEntro;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Medidas.s32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: Medidas.s24),
            child: TituloDeInicio('DEPORTES'),
          ),
          const SizedBox(height: Medidas.s12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Medidas.s24),
            child: Row(
              children: [
                for (final (i, d) in catalogo.deportes.indexed) ...[
                  if (i > 0) const SizedBox(width: Medidas.s12),
                  Aparecer(
                    retraso: entradaDeTiles + pasoDeTiles * i,
                    duracion: const Duration(milliseconds: 550),
                    desdeX: 120,
                    desdeY: 0,
                    giro: -8 / 360,
                    curva: Movimiento.rebote,
                    yaEntro: yaEntro,
                    child: TileDeporte(
                      imagen: fotoDeDeporte(d.clave),
                      emoji: emojiDeDeporte(d.clave),
                      nombre: d.nombre,
                      alTocar: () => context.go(
                        Uri(
                          path: '/inicio/buscar',
                          queryParameters: {'deporte': d.clave},
                        ).toString(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// El emoji de un deporte del catálogo; uno que la app no conoce lleva 🏅.
String emojiDeDeporte(String clave) => switch (clave) {
  'Futbol' => '⚽',
  'Tenis' => '🎾',
  'Padel' => '🏓',
  'Voley' => '🏐',
  'Hockey' => '🏑',
  'Basquet' => '🏀',
  'Golf' => '⛳',
  _ => '🏅',
};
