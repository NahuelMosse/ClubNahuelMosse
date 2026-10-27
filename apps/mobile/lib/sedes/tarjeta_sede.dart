import 'package:flutter/material.dart';

import '../tema/tokens.dart';
import 'pie_de_tarjeta_sede.dart';
import 'portada_de_tarjeta_sede.dart';
import 'resumen_de_sede.dart';
import 'sede.dart';

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
              PortadaDeTarjetaSede(sede: sede),
              PieDeTarjetaSede(deportes: deportes),
            ],
          ),
        ),
      ),
    );
  }
}
