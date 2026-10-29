// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/empty_state.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../../spaces/domain/space.dart';
import 'space_card.dart';

/// Las canchas de la sede, o el aviso de que no hay ninguna o ninguna pasa el filtro.
class SpaceList extends StatelessWidget {
  const SpaceList({
    super.key,
    required this.venueId,
    required this.spaces,
    required this.allSpaces,
    required this.catalog,
  });

  final String venueId;
  final List<Space> spaces;
  final List<Space> allSpaces;
  final Catalog catalog;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (allSpaces.isEmpty)
          EmptyState(title: l.spaceNoneTitle, text: l.spaceNoneText)
        else if (spaces.isEmpty)
          EmptyState(title: l.spaceNoMatchTitle, text: l.spaceNoMatchText),
        for (final space in spaces) ...[
          SpaceCard(
            space: space,
            catalog: catalog,
            onBook: () => context.go('/sedes/$venueId/canchas/${space.id}'),
          ),
          const SizedBox(height: Spacing.s16),
        ],
      ],
    );
  }
}
