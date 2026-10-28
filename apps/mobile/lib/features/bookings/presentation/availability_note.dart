import 'package:flutter/material.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';

/// `Nota-Ocupados`: cuántos inicios de la grilla no se pueden elegir.
class AvailabilityNote extends StatelessWidget {
  const AvailabilityNote({super.key, required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(Spacing.s12),
      decoration: BoxDecoration(
        color: p.bgSurface,
        borderRadius: BorderRadius.circular(Spacing.radiusMd),
        border: Border.all(color: p.borderDefault),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: p.textSecondary),
          const SizedBox(width: Spacing.s8),
          Expanded(
            child: Text(
              texto,
              style: Texts.caption.copyWith(color: p.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
