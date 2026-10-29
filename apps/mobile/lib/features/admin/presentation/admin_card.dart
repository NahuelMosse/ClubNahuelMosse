import 'package:flutter/material.dart';

import '../../../common/button.dart';
import '../../../common/card_frame.dart';
import '../../../common/in_progress.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';

/// The card of a list item: its [details] and the edit and deactivate buttons, which under
/// enlarged text go one below the other.
class AdminCard extends StatelessWidget {
  const AdminCard({
    super.key,
    required this.details,
    required this.name,
    required this.editText,
    required this.editLabel,
    required this.onEdit,
    required this.deactivateText,
    required this.deactivateLabel,
    required this.onDeactivate,
    required this.deactivating,
  });

  final Widget details;
  final String name;
  final String editText;
  final String editLabel;

  /// `null` disables the button (another deactivation is on its way).
  final VoidCallback? onEdit;
  final String deactivateText;
  final String deactivateLabel;
  final VoidCallback? onDeactivate;

  /// The deactivation of this item is on its way.
  final bool deactivating;

  @override
  Widget build(BuildContext context) {
    // With any text enlargement, the side-by-side buttons no longer fit at 360.
    final large = MediaQuery.textScalerOf(context).scale(10) > 10.5;
    final edit = OutlineButton(
      label: editText,
      icon: Icons.edit_outlined,
      compact: true,
      semanticLabel: editLabel,
      onTap: onEdit,
    );
    final Widget deactivate = deactivating
        ? InProgress(AppLocalizations.of(context).adminDeactivatingNamed(name))
        : OutlineButton(
            label: deactivateText,
            icon: Icons.delete_outline_rounded,
            compact: true,
            danger: true,
            semanticLabel: deactivateLabel,
            onTap: onDeactivate,
          );
    return CardFrame(
      clip: Clip.none,
      padding: const EdgeInsets.all(Spacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          details,
          const SizedBox(height: Spacing.s12),
          if (large) ...[
            edit,
            const SizedBox(height: Spacing.s8),
            deactivate,
          ] else
            Row(
              children: [
                Expanded(child: edit),
                const SizedBox(width: Spacing.s8),
                Expanded(child: deactivate),
              ],
            ),
        ],
      ),
    );
  }
}
