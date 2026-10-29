import 'package:flutter/material.dart';
import '../../../common/button.dart';
import '../../../common/card_frame.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';

/// La franja de arriba cuando hay avisos pero el sistema no deja mostrarlos.
class NotificationsDisabled extends StatelessWidget {
  const NotificationsDisabled({super.key, required this.onEnable});

  final Future<bool> Function() onEnable;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    return CardFrame(
      clip: Clip.none,
      padding: const EdgeInsets.all(Spacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.notificationsDisabledTitle,
            style: Texts.title.copyWith(color: p.textPrimary),
          ),
          const SizedBox(height: Spacing.s4),
          Text(
            l10n.notificationsDisabledText,
            style: Texts.caption.copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: Spacing.s16),
          PrimaryButton(label: l10n.notificationsEnable, onTap: onEnable),
        ],
      ),
    );
  }
}
