import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../domain/slot.dart';
import 'grow.dart';
import 'selectable_frame.dart';

class SlotCard extends StatelessWidget {
  const SlotCard({
    super.key,
    required this.franja,
    required this.elegida,
    required this.alTocar,
    this.actual = false,
  });

  final Slot franja;
  final bool elegida;
  final VoidCallback? alTocar;

  /// Es el horario de la reserva que se modifica.
  final bool actual;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tinta = elegida ? p.accentOn : p.textPrimary;
    return Grow(
      activo: elegida,
      child: SelectableFrame(
        etiqueta: actual ? '${franja.text} (actual)' : franja.text,
        elegido: elegida,
        alTocar: alTocar,
        atenuado: !franja.available,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(franja.text, style: Texts.bodyStrong.copyWith(color: tinta)),
              if (actual)
                Text(
                  '(actual)',
                  style: Texts.caption.copyWith(
                    color: elegida ? p.accentOn : p.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
