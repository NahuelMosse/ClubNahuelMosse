import 'package:flutter/material.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';

/// El horario de antes, con una cruz, o el de ahora, con un tilde y en lima.
class HorarioDeCambio extends StatelessWidget {
  const HorarioDeCambio({
    super.key,
    required this.titulo,
    required this.valor,
    required this.nuevo,
  });

  final String titulo;
  final String valor;
  final bool nuevo;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Semantics(
      container: true,
      label: '$titulo: $valor',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Medidas.s8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              nuevo ? Icons.check_rounded : Icons.close_rounded,
              size: 18,
              color: nuevo ? p.stateSuccessInk : p.stateDangerInk,
            ),
            const SizedBox(width: Medidas.s8),
            Text(
              titulo,
              style: Textos.sobretitulo.copyWith(color: p.textMuted),
            ),
            const SizedBox(width: Medidas.s16),
            Expanded(
              child: Text(
                valor,
                textAlign: TextAlign.end,
                style: nuevo
                    ? Textos.cuerpoFuerte.copyWith(color: p.accentInk)
                    : Textos.cuerpo.copyWith(color: p.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
