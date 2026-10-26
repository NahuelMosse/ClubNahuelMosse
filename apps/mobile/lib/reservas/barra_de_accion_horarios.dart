import 'package:flutter/material.dart';
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.bgSurface,
        border: Border(top: BorderSide(color: p.borderDefault)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Medidas.s24,
            Medidas.s16,
            Medidas.s24,
            Medidas.s16,
          ),
          child: BotonPrimario(texto: texto, alTocar: alContinuar),
        ),
      ),
    );
  }
}
