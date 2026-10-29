import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';

class ProfileDataRow extends StatelessWidget {
  const ProfileDataRow({
    super.key,
    required this.label,
    required this.value,
    this.fixed = false,
  });

  final String label;
  final String value;
  final bool fixed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final shown = value.trim().isEmpty ? '—' : value;
    return Semantics(
      container: true,
      label: fixed
          ? AppLocalizations.of(context).profileFixedField(label, shown)
          : '$label: $shown',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.s12),
        child: Row(
          children: [
            Text(label, style: Texts.caption.copyWith(color: p.textMuted)),
            const SizedBox(width: Spacing.s12),
            Expanded(
              child: Text(
                shown,
                textAlign: TextAlign.right,
                style: Texts.bodyStrong.copyWith(
                  color: fixed ? p.textMuted : p.textPrimary,
                ),
              ),
            ),
            if (fixed) ...[
              const SizedBox(width: Spacing.s8),
              Icon(Icons.lock_outline_rounded, size: 15, color: p.textMuted),
            ],
          ],
        ),
      ),
    );
  }
}
