import 'package:flutter/material.dart';
import '../comun/barra_fija.dart';
import '../comun/boton.dart';
import '../tema/tokens.dart';

class BarraDeAccionHorarios extends StatelessWidget {
  const BarraDeAccionHorarios({
    super.key,
    required this.texto,
    required this.alContinuar,
  });

  final String texto;
  final VoidCallback? alContinuar;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return BarraFija(
      color: p.bgSurface,
      child: BotonPrimario(texto: texto, alTocar: alContinuar),
    );
  }
}
