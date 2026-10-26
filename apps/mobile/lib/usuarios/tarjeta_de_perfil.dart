import 'package:flutter/material.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';

class TarjetaDePerfil extends StatelessWidget {
  const TarjetaDePerfil({
    super.key,
    required this.titulo,
    required this.child,
    this.accion,
  });

  final String titulo;
  final Widget child;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final boton = accion;
    return Container(
      padding: const EdgeInsets.all(Medidas.s16),
      decoration: BoxDecoration(
        color: p.bgSurface,
        border: Border.all(color: p.borderDefault),
        borderRadius: BorderRadius.circular(Medidas.radioLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    titulo,
                    style: Textos.sobretitulo.copyWith(color: p.textMuted),
                  ),
                ),
              ),
              ?boton,
            ],
          ),
          const SizedBox(height: Medidas.s8),
          child,
        ],
      ),
    );
  }
}
