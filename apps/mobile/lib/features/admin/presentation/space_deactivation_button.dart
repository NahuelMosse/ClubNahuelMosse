import 'package:flutter/material.dart';

import '../../../common/button.dart';
import '../../../common/in_progress.dart';
import '../../../l10n/app_localizations.dart';

/// «Dar de baja el espacio», or the notice that the deactivation is in flight. An
/// [onTap] of `null` disables the button.
class SpaceDeactivationButton extends StatelessWidget {
  const SpaceDeactivationButton({
    super.key,
    required this.deactivating,
    required this.onTap,
  });

  final bool deactivating;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (deactivating) return InProgress(l10n.adminDeactivatingSpace);
    return OutlineButton(
      label: l10n.adminDeactivateSpaceButton,
      danger: true,
      onTap: onTap,
    );
  }
}
