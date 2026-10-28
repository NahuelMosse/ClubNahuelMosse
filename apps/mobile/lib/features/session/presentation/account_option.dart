import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';

/// Una fila de la tarjeta de la cuenta: ícono, texto y, salvo «Cerrar sesión», una flecha.
class AccountOption extends StatelessWidget {
  const AccountOption({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String text;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = danger ? p.stateDangerInk : p.textPrimary;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Spacing.controlHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.s16),
            child: Row(
              children: [
                Icon(icon, size: 20, color: danger ? color : p.textSecondary),
                const SizedBox(width: Spacing.s12),
                Expanded(
                  child: Text(
                    text,
                    style: Texts.bodyStrong.copyWith(color: color),
                  ),
                ),
                if (!danger)
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: p.textSecondary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
