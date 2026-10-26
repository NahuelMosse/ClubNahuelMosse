import 'package:flutter/material.dart';
import '../comun/dorsal.dart';
import '../comun/etiqueta.dart';
import '../comun/fechas.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'fotos.dart';
import 'sede.dart';
import 'resumen_de_sede.dart';

/// `Card-Sede`: portada con nombre, dirección, horario y canchas; abajo, los deportes y
/// «Ver canchas». Se toca entera.
class TarjetaSede extends StatelessWidget {
  const TarjetaSede({
    super.key,
    required this.sede,
    required this.deportes,
    required this.alTocar,
  });

  final Sede sede;
  final List<String> deportes;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final canchas = cantidadDeCanchas(sede.canchas);
    return Semantics(
      container: true,
      button: true,
      excludeSemantics: true,
      label:
          '${sede.nombre}, ${sede.direccion}, '
          '${sede.diasLegibles} de ${sede.apertura} a ${sede.cierre}, '
          '$canchas${deportes.isEmpty ? '' : ': ${deportes.join(', ')}'}',
      onTap: alTocar,
      child: Material(
        color: p.bgSurface,
        borderRadius: BorderRadius.circular(Medidas.radioLg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: alTocar,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ConstrainedBox(
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
                                    style: Textos.h1.copyWith(
                                      color: p.textOnMedia,
                                    ),
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
                                    '${sede.apertura} a ${sede.cierre}',
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
              ),
              Padding(
                padding: const EdgeInsets.all(Medidas.s16),
                child: Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: Medidas.s4,
                        runSpacing: Medidas.s4,
                        children: [
                          for (final d in deportes) Etiqueta(texto: d),
                        ],
                      ),
                    ),
                    const SizedBox(width: Medidas.s8),
                    Text(
                      'Ver canchas',
                      style: Textos.cuerpoFuerte.copyWith(color: p.accentInk),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: p.accentInk,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
