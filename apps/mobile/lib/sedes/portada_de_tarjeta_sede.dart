import 'package:flutter/material.dart';

import '../comun/dorsal.dart';
import '../comun/fechas.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'fotos.dart';
import 'sede.dart';

/// La portada de la sede con su cantidad de canchas, el nombre, la dirección y el horario.
class PortadaDeTarjetaSede extends StatelessWidget {
  const PortadaDeTarjetaSede({super.key, required this.sede});

  final Sede sede;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return ConstrainedBox(
      // Un nombre largo pasa a dos líneas y la portada crece con él.
      constraints: const BoxConstraints(minHeight: 158),
      child: FotoConVelo(
        imagen: portadaDeSede(sede.id),
        child: Stack(
          children: [
            Positioned(
              top: Medidas.s12,
              right: Medidas.s16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  DorsalGigante(
                    texto: dosCifras(sede.canchas),
                    tamano: 92,
                    color: p.textOnMedia,
                  ),
                  Text(
                    sede.canchas == 1 ? 'CANCHA' : 'CANCHAS',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 11 * 0.08,
                      color: p.textOnMedia,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Medidas.s16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sede.nombre.toUpperCase(),
                          style: Textos.h1.copyWith(color: p.textOnMedia),
                        ),
                        const SizedBox(height: Medidas.s4),
                        Text(
                          sede.direccion,
                          style: Textos.leyenda.copyWith(
                            color: p.textOnMediaMuted,
                          ),
                        ),
                        Text(
                          // El rango no se parte entre líneas.
                          '${sede.diasLegibles} · '
                          '${sede.apertura} a ${sede.cierre}',
                          style: Textos.leyenda.copyWith(
                            fontSize: 12,
                            color: p.textOnMediaMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
