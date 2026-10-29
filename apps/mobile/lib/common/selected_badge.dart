// kit-boundary: the app-wide widget kit, shared by every feature.
// kit-shape: a widget with its private parts kept together.
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/theme.dart';
import '../theme/tokens.dart';

/// The «ELEGIDO» label that marks a [SportTile] with the accent.
class SelectedBadge extends StatelessWidget {
  const SelectedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: p.accentBase,
        borderRadius: BorderRadius.circular(Spacing.radiusPill),
      ),
      child: Text(
        AppLocalizations.of(context).commonSelected,
        style: Texts.overline.copyWith(color: p.accentOn),
      ),
    );
  }
}
