import 'package:flutter/material.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';

class SlotsSection extends StatelessWidget {
  const SlotsSection({super.key, required this.titulo, required this.child});

  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              titulo,
              style: Texts.overline.copyWith(color: p.textMuted),
            ),
          ),
          const SizedBox(height: Spacing.s8),
          child,
        ],
      ),
    );
  }
}
