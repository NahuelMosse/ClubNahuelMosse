import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';

/// The booking belonged to a space or venue that was already deactivated (FA8): the
/// voiding is not attributed to the member.
class DeactivationNotice extends StatelessWidget {
  const DeactivationNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.s16,
        vertical: Spacing.s12,
      ),
      decoration: BoxDecoration(
        color: p.bgSurface,
        borderRadius: BorderRadius.circular(Spacing.radiusMd),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: p.textMuted),
          const SizedBox(width: Spacing.s8),
          Expanded(
            child: Text(
              AppLocalizations.of(context).adminSpaceDeactivated,
              style: Texts.caption.copyWith(color: p.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
