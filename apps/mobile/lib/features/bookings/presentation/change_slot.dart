import 'package:flutter/material.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';

/// El horario de antes, con una cruz, o el de ahora, con un tilde y en lima.
class ChangeSlot extends StatelessWidget {
  const ChangeSlot({
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
    final p = context.palette;
    return Semantics(
      container: true,
      label: '$titulo: $valor',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.s8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              nuevo ? Icons.check_rounded : Icons.close_rounded,
              size: 18,
              color: nuevo ? p.stateSuccessInk : p.stateDangerInk,
            ),
            const SizedBox(width: Spacing.s8),
            Text(titulo, style: Texts.overline.copyWith(color: p.textMuted)),
            const SizedBox(width: Spacing.s16),
            Expanded(
              child: Text(
                valor,
                textAlign: TextAlign.end,
                style: nuevo
                    ? Texts.bodyStrong.copyWith(color: p.accentInk)
                    : Texts.body.copyWith(color: p.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
