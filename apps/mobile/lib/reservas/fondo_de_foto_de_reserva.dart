import 'package:flutter/material.dart';

import '../sedes/fotos.dart';
import '../tema/tokens.dart';

/// La foto del deporte arriba de la pantalla, que se funde con el fondo hacia abajo.
class FondoDeFotoDeReserva extends StatelessWidget {
  const FondoDeFotoDeReserva({super.key, required this.deporte});

  final String deporte;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 440,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FotoConVelo(
            imagen: fotoDeDeporte(deporte),
            child: const SizedBox.expand(),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.6, 1],
                colors: [p.bgBase.withValues(alpha: 0), p.bgBase],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
