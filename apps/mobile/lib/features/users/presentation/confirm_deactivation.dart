import 'package:flutter/material.dart';

import '../../../common/button.dart';
import '../../../common/error_dialog.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';

class ConfirmDeactivation extends StatelessWidget {
  const ConfirmDeactivation({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    return DialogFrame(
      children: [
        IconCircle(
          icon: Icons.warning_amber_rounded,
          background: p.stateDangerMuted,
          ink: p.stateDangerInk,
        ),
        const SizedBox(height: Spacing.s12),
        Text(
          l10n.profileDeleteTitle,
          textAlign: TextAlign.center,
          style: Texts.h2.copyWith(color: p.textPrimary),
        ),
        const SizedBox(height: Spacing.s12),
        Text(
          l10n.profileDeleteBody,
          textAlign: TextAlign.center,
          style: Texts.body.copyWith(color: p.textSecondary),
        ),
        const SizedBox(height: Spacing.s12),
        DangerButton(
          label: l10n.accountDeleteUpper,
          onTap: () => Navigator.of(context).pop(true),
        ),
        const SizedBox(height: Spacing.s8),
        OutlineButton(
          label: l10n.accountCancel,
          onTap: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}
