import 'package:flutter/material.dart';

import '../tema/tokens.dart';
import 'cabecera_de_ficha.dart';
import 'dorsal.dart';
import 'foto_de_ficha.dart';
import 'identidad_de_ficha.dart';
import 'marcador.dart';

/// Carnet del socio: iniciales, nombre, correo y un [Marcador] de estadísticas, con un dorsal de fondo.
class FichaSocio extends StatelessWidget {
  const FichaSocio({
    super.key,
    required this.iniciales,
    required this.nombre,
    required this.correo,
    required this.estadisticas,
    this.imagen,
    this.numero,
  });

  final String iniciales;
  final String nombre;
  final String correo;
  final List<CeldaMarcador> estadisticas;
  final ImageProvider? imagen;
  final String? numero;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final foto = imagen;
    final radio = BorderRadius.circular(24);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.bgSurfaceRaised,
        borderRadius: radio,
        border: Border.all(color: p.accentBase, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: radio,
        child: Stack(
          children: [
            if (foto != null) Positioned.fill(child: FotoDeFicha(imagen: foto)),
            Positioned(
              top: -10,
              right: -6,
              child: DorsalGigante(
                texto: '10',
                tamano: 170,
                color: p.accentBase.withValues(alpha: 0.28),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CabeceraDeFicha(numero: numero),
                  const SizedBox(height: 18),
                  IdentidadDeFicha(
                    iniciales: iniciales,
                    nombre: nombre,
                    correo: correo,
                  ),
                  if (estadisticas.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Marcador(celdas: estadisticas),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
