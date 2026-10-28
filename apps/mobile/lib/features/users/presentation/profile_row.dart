import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';

class ProfileRow extends StatelessWidget {
  const ProfileRow({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
  });

  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Spacing.radiusMd),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Spacing.controlHeight),
          child: Row(
            children: [
              Icon(icon, size: 20, color: p.textSecondary),
              const SizedBox(width: Spacing.s12),
              Expanded(
                child: Text(
                  text,
                  style: Texts.bodyStrong.copyWith(color: p.textPrimary),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: p.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
