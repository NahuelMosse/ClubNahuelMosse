import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/motion.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../domain/tile_animation.dart';
import 'home_shortcut.dart';
import 'home_title.dart';

/// ACCESOS RÁPIDOS: buscar una cancha o recorrer las sedes.
class HomeShortcuts extends StatelessWidget {
  const HomeShortcuts({
    super.key,
    required this.primero,
    required this.yaEntro,
  });

  /// Cuándo entra el primer acceso; el otro, un paso después.
  final Duration primero;
  final bool yaEntro;

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
                    delay: primero,
                    alreadyEntered: yaEntro,
                    child: HomeShortcut(
                      icono: Icons.search_rounded,
                      titulo: l10n.homeFindCourt,
                      texto: l10n.homeFindCourtHint,
                      alTocar: () => context.go('/inicio/buscar'),
                    ),
                  ),
                ),
                const SizedBox(width: Spacing.s12),
                Expanded(
                  child: FadeIn(
                    delay: primero + tileStep,
                    alreadyEntered: yaEntro,
                    child: HomeShortcut(
                      icono: Icons.location_on_outlined,
                      titulo: l10n.homeViewVenues,
                      texto: l10n.homeViewVenuesHint,
                      alTocar: () => context.go('/sedes'),
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
