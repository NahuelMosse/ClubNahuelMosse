import 'package:flutter/material.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';

/// Un dato de la reserva: el nombre a la izquierda y el valor a la derecha.
class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.dato,
    required this.valor,
    this.destacado = false,
    this.codigo = false,
  });

  final String dato;
  final String valor;
  final bool destacado;

  /// Un código largo sin espacios (el nombre compuesto del espacio): va debajo del dato,
  /// en la fuente mono, para no partirse a mitad de palabra.
  final bool codigo;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (codigo) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dato, style: Texts.body.copyWith(color: p.textSecondary)),
            const SizedBox(height: Spacing.s4),
            Text(valor, style: Texts.mono.copyWith(color: p.textPrimary)),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.s12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dato, style: Texts.body.copyWith(color: p.textSecondary)),
          const SizedBox(width: Spacing.s16),
          Expanded(
            child: Text(
              valor,
              textAlign: TextAlign.end,
              style: (destacado ? Texts.bodyStrong : Texts.body).copyWith(
                color: destacado ? p.accentInk : p.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
