import 'package:flutter/material.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';

class SeccionDeHorarios extends StatelessWidget {
  const SeccionDeHorarios({
    super.key,
    required this.titulo,
    required this.child,
  });

  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Padding(
      padding: const EdgeInsets.only(bottom: Medidas.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              titulo,
              style: Textos.sobretitulo.copyWith(color: p.textMuted),
            ),
          ),
          const SizedBox(height: Medidas.s8),
          child,
        ],
      ),
    );
  }
}
