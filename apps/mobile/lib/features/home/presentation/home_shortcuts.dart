import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/motion.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../domain/tile_animation.dart';
import 'home_shortcut.dart';
import 'home_title.dart';

/// «ACCESOS RÁPIDOS»: search for a court or browse the venues.
class HomeShortcuts extends StatelessWidget {
  const HomeShortcuts({
    super.key,
    required this.first,
    required this.alreadyEntered,
  });

  /// When the first shortcut enters; the other, one step later.
  final Duration first;
  final bool alreadyEntered;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.s24,
        Spacing.s32,
        Spacing.s24,
        Spacing.s40,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeTitle(l10n.homeQuickAccess),
          const SizedBox(height: Spacing.s12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: FadeIn(
                    delay: first,
                    alreadyEntered: alreadyEntered,
                    child: HomeShortcut(
                      icon: Icons.search_rounded,
                      title: l10n.homeFindCourt,
                      text: l10n.homeFindCourtHint,
                      onTap: () => context.go('/home/search'),
                    ),
                  ),
                ),
                const SizedBox(width: Spacing.s12),
                Expanded(
                  child: FadeIn(
                    delay: first + tileStep,
                    alreadyEntered: alreadyEntered,
                    child: HomeShortcut(
                      icon: Icons.location_on_outlined,
                      title: l10n.homeViewVenues,
                      text: l10n.homeViewVenuesHint,
                      onTap: () => context.go('/venues'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
