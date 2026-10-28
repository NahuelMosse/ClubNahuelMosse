import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';

/// La etiqueta de deporte sobre la portada: borde claro sobre la foto.
class LightLabel extends StatelessWidget {
  const LightLabel({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      constraints: const BoxConstraints(minHeight: 26),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.s8,
        vertical: Spacing.s4,
      ),
      decoration: BoxDecoration(
        color: const Color(0x99000000),
        borderRadius: BorderRadius.circular(Spacing.radiusPill),
        border: Border.all(color: const Color(0x66FFFFFF)),
      ),
      child: Text(text, style: Texts.caption.copyWith(color: p.textOnMedia)),
    );
  }
}
