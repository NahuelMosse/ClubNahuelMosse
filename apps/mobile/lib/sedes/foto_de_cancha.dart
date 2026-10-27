import 'package:flutter/material.dart';

import '../comun/etiqueta.dart';
import '../espacios/espacio.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'fotos.dart';

/// La foto del deporte de la cancha, con su tipo arriba y su nombre abajo.
class FotoDeCancha extends StatelessWidget {
  const FotoDeCancha({super.key, required this.cancha, required this.tipo});

  final Espacio cancha;
  final String tipo;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return SizedBox(
      height: 180,
      child: FotoConVelo(
        imagen: fotoDeDeporte(cancha.deporte),
        child: Padding(
          padding: const EdgeInsets.all(Medidas.s12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Etiqueta(texto: tipo, sobreFoto: true),
              Text(
                cancha.nombre,
                style: Textos.mono.copyWith(fontSize: 12, color: p.textOnMedia),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
