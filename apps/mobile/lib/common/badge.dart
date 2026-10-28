import 'package:flutter/material.dart';

import '../theme/theme.dart';
import '../theme/tokens.dart';

/// `Badge-Estado` with the [background] and [ink] given by the status it names.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.background,
    required this.ink,
  });

  final String label;
  final Color background;
  final Color ink;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: Spacing.s8,
      vertical: Spacing.s4,
    ),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(Spacing.radiusPill),
    ),
    child: Text(label, style: Texts.overline.copyWith(color: ink)),
  );
}

/// The prototype `Badge-Estado`, in its lime variant: «MIEMBRO ACTIVO», «ACTIVA».
class AccentBadge extends StatelessWidget {
  const AccentBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      constraints: const BoxConstraints(minHeight: 26),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.s12,
        vertical: Spacing.s4,
      ),
      decoration: BoxDecoration(
        color: p.accentMuted,
        borderRadius: BorderRadius.circular(Spacing.radiusPill),
      ),
      child: Text(label, style: Texts.overline.copyWith(color: p.accentInk)),
    );
  }
}
