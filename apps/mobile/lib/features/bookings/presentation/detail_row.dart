import 'package:flutter/material.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';

/// Un dato de la reserva: el nombre a la izquierda y el valor a la derecha.
class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasized = false,
    this.code = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  /// Un código largo sin espacios (el nombre compuesto del espacio): va debajo del dato,
  /// en la fuente mono, para no partirse a mitad de palabra.
  final bool code;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (code) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Texts.body.copyWith(color: p.textSecondary)),
            const SizedBox(height: Spacing.s4),
            Text(value, style: Texts.mono.copyWith(color: p.textPrimary)),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.s12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Texts.body.copyWith(color: p.textSecondary)),
          const SizedBox(width: Spacing.s16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: (emphasized ? Texts.bodyStrong : Texts.body).copyWith(
                color: emphasized ? p.accentInk : p.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
