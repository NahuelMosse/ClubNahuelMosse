// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../../spaces/domain/space.dart';
import '../../spaces/presentation/sport_icons.dart';
import 'admin_card.dart';

/// `Card-Espacio`: sport, type, roofing and price, with the composed name below,
/// «Editar» and «Baja».
class AdminSpaceCard extends StatelessWidget {
  const AdminSpaceCard({
    super.key,
    required this.space,
    required this.catalog,
    this.onDeactivate,
    this.deactivating = false,
    this.enabled = true,
  });

  final Space space;
  final Catalog catalog;
  final VoidCallback? onDeactivate;

  /// The deactivation of this space is on its way.
  final bool deactivating;

  /// `false` disables its buttons (another deactivation is on its way).
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    final description = space.description(catalog);
    // The data is read as one; the buttons stay outside, each with its own name.
    final details = Semantics(
      container: true,
      excludeSemantics: true,
      label: '$description, ${space.venue}, ${space.name}',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: Spacing.touchTarget,
            height: Spacing.touchTarget,
            decoration: BoxDecoration(
              color: p.accentMuted,
              borderRadius: BorderRadius.circular(Spacing.radiusMd),
            ),
            child: Icon(sportIcon(space.sport), size: 22, color: p.accentInk),
          ),
          const SizedBox(width: Spacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: Texts.title.copyWith(color: p.textPrimary),
                ),
                const SizedBox(height: Spacing.s4),
                Text(
                  space.name,
                  style: Texts.mono.copyWith(color: p.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return AdminCard(
      details: details,
      name: space.name,
      editText: l10n.adminEditSpace,
      editLabel: l10n.adminEditSpaceNamed(space.name),
      onEdit: enabled
          ? () => context.go('/admin/espacios/${space.id}/editar', extra: space)
          : null,
      deactivateText: l10n.adminDeactivateSpace,
      deactivateLabel: l10n.adminDeactivateSpaceNamed(space.name),
      onDeactivate: enabled ? onDeactivate : null,
      deactivating: deactivating,
    );
  }
}
